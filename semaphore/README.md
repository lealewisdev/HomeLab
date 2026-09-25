# Deployment Playbooks

Two [Ansible](https://github.com/ansible/ansible) playbooks run as
 [Ansible Semaphore](https://github.com/semaphoreui/semaphore) task templates
 and are triggered by the [n8n](../n8n/) deployment workflow. One rolls out a
 new image tag with a health check, and the other reverts to the last known-good
 tag when that check fails.

## Highlights

- **Rollback-ready deploys.** A healthy deploy saves its own image as a local
  tarball and pushes it to the registry as `:last-good`, so there's always
  something to fall back to — even if the registry is unreachable, or a run of
  failed deploys precedes it (a failed deploy never overwrites the marker).
- **Health-gated in both directions.** Both playbooks poll `health_url` after
  recreating the service and fail the play if it doesn't return `200`, deploy
  fails to signal n8n to roll back; rollback fails to signal that manual
  intervention is needed.
- **Credential hygiene.** The registry login task runs with `no_log: true`, and
  the password is read from the runner's environment rather than passed as a
  variable.
- **Fully parameterised.** No host, path, registry or image name is hardcoded in
  the playbooks.

## Layout

| File | Purpose |
| --- | --- |
| `deploy.yml` | Deploys a new image tag to `app_servers` and verifies it. |
| `rollback.yml` | Restores the last known-good tag on `app_servers`. |

Both playbooks need the
[`community.docker`](https://github.com/ansible-collections/community.docker)
collection, which is installed in the custom Semaphore image
(see [`docker/`](../docker/)).

## How it works

<!-- d2 diagram: deploy.yml (pull -> recreate -> health check) -> [healthy] ->
save last_good.tar + push :last-good tag -> [unhealthy] -> fail -> rollback.yml
(load last_good.tar, or pull :last-good on failure -> recreate --pull never ->
health check) -> fail if still unhealthy -->

**`deploy.yml`**

1. Log in to the registry and pull the new image.
2. Write the new tag to `.env` and recreate the service with
   `docker compose up -d --no-deps --force-recreate`.
3. Poll `health_url` (10 retries, 3 seconds apart) for a `200`, failing the play
   if it never arrives.
4. If (and only if) healthy: save the deployed image to `last_good.tar`
   (via a temp file and an atomic `mv`), record its tag in `.last_good_tag`,
   tag it `:last-good` locally, and push that tag to the registry. A failed push
   only logs a warning — the local tarball is enough to roll back on.

**`rollback.yml`**

1. Confirm `.last_good_tag` exists, failing with a clear message if it does not
   (for example, on a first-ever deploy).
2. Try to `docker load` `last_good.tar`. If it's missing or fails to load, fall
   back to pulling `:last-good` from the registry and retagging it as the
   recorded version.
3. Rewrite `.env` to the last-good tag and recreate the service with
   `--pull never`, since the image is already loaded or pulled locally.
4. Poll `health_url` the same way `deploy.yml` does, failing with a
   "manual intervention required" message if it's still unhealthy.

## Usage

Variables are supplied at run time. n8n passes only the tag
 (plus a `reason` on rollback); the rest live in each Semaphore task template's
 environment, so one pair of playbooks serves every service.

| Variable | Source | Purpose |
| --- | --- | --- |
| `image_tag` | n8n | Tag to deploy |
| `compose_dir`, `service_name` | Template environment | Directory holding `compose.yaml` and `.env`, and the Compose service to operate on |
| `image_repo`, `registry`, `registry_user` | Template environment | Image path (without registry host), registry hostname and username |
| `health_url` | Template environment | Endpoint polled after deployment and after rollback |
| `registry_password` | Runner environment | Read via `lookup('env', ...)`, never an extra var |

## Design decisions

- **Failure as a signal.** `deploy.yml` doesn't roll itself back, it fails
  cleanly and lets n8n decide, keeping each playbook small and independently
  testable. `rollback.yml` follows the same logic one level up: if the rollback
  is itself unhealthy, it fails loudly instead of trying anything further, since
  there's no other known-good image left to fall back to.
- **Two sources for the last-good image.** Keeping both a local tarball and a
  registry tag means rollback still works if either one is unavailable, and only
  a *healthy* deploy overwrites either of them, so a run of failed deploys can't
  erode the fallback.

**Stack:** Ansible · Ansible Semaphore · Docker Compose · community.docker
