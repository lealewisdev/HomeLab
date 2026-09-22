# Deployment Playbooks

Two [Ansible](https://github.com/ansible/ansible) playbooks run as [Ansible Semaphore](https://github.com/semaphoreui/semaphore) task templates and are triggered by the [n8n](../n8n/) deployment workflow. One rolls out a new image tag with a health check, and the other reverts to the last known-good tag when that check fails.

## Highlights

- **Rollback-ready deploys.** The running image tag is recorded before anything changes, so there is something to fall back to.
- **Health-gated rollout.** The deployment polls a health endpoint, and a failed check fails the play, which is the signal n8n uses to start a rollback.
- **Credential hygiene.** The registry login task runs with `no_log: true`, and the password is read from the runner's environment rather than passed as a variable.
- **Fully parameterised.** No host, path, registry or image name is hardcoded in the playbooks.

## Layout

| File | Purpose |
| --- | --- |
| `deploy.yml` | Deploys a new image tag to `app_servers` and verifies it. |
| `rollback.yml` | Restores the previous tag on `app_servers`. |

Both playbooks need the [`community.docker`](https://github.com/ansible-collections/community.docker) collection, which is installed in the custom Semaphore image (see [`docker/`](../docker/)).

## How it works

<!-- d2 diagram: deploy.yml (record tag -> .previous_tag -> pull -> recreate -> health check) -> fail -> rollback.yml (read .previous_tag -> recreate) -->

**`deploy.yml`**

1. Resolve the target container's name from `compose.yaml` (`container_name`, falling back to the service name).
2. Record the running image tag with `docker inspect` and persist it to `.previous_tag` in the compose directory. If the container is not running yet, any stale `.previous_tag` is removed instead, so a rollback fails clearly rather than reverting to an older tag.
3. Log in to the registry and pull the new image.
4. Write the new tag to `.env` and recreate the service with `docker compose up -d --no-deps --force-recreate`.
5. Poll `health_url` (10 retries, 3 seconds apart) for a `200`, failing the play if it never arrives.

**`rollback.yml`**

1. Confirm `.previous_tag` exists, failing with a clear message if it does not (for example, on a first-ever deploy).
2. Rewrite `.env` to the previous tag and recreate the service the same way.

## Usage

Variables are supplied at run time. n8n passes only the tag (plus a `reason` on rollback); the rest live in each Semaphore task template's environment, so one pair of playbooks serves every service.

| Variable | Source | Purpose |
| --- | --- | --- |
| `image_tag` | n8n | Tag to deploy |
| `compose_dir`, `service_name` | Template environment | Directory holding `compose.yaml` and `.env`, and the Compose service to operate on |
| `image_repo`, `registry`, `registry_user` | Template environment | Image path (without registry host), registry hostname and username |
| `health_url` | Template environment | Endpoint polled after deployment |
| `registry_password` | Runner environment | Read via `lookup('env', ...)`, never an extra var |

## Design decisions

- **Failure as a signal.** The playbook does not roll itself back. It fails cleanly and lets the orchestrator decide, keeping each playbook small and independently testable.
- **Verified by the orchestrator.** `rollback.yml` runs no health probe of its own. n8n confirms the rollback task finished successfully and escalates if it did not.

**Stack:** Ansible · Ansible Semaphore · Docker Compose · community.docker
