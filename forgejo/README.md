# CI/CD Pipeline

Self-hosted CI/CD on [Forgejo Actions](https://codeberg.org/forgejo/forgejo) that builds, scans, signs and publishes container images. This repository uses the pipeline on itself to build the CI toolchain image in `docker/`.

## Highlights

- **Supply-chain security.** Every image gets a CycloneDX SBOM, is scanned for fixable CRITICAL/HIGH vulnerabilities before push, and is signed with [cosign](https://github.com/sigstore/cosign) by digest with the SBOM attached as an attestation.
- **Reusable pipeline.** One callable workflow handles build, scan, push and signing for any build context, publishing `latest`, git SHA and full, major.minor and major semver tags (branch builds get branch-scoped tags).
- **Shift-left checks.** Pull requests run linting, secret scanning and a version-bump guard before anything merges.
- **Continuous re-scanning.** The published image is re-scanned daily to catch vulnerabilities disclosed after the build passed.
- **Pinned and hardened.** Third-party actions are pinned to commit SHAs, tools and base images are pinned by digest, and registry credentials are logged out after every run. Workflow values reach scripts through `env:` rather than being interpolated into them.
- **Automated updates.** A self-hosted [Renovate](https://github.com/renovatebot/renovate) opens dependency PRs daily, including for pinned apt package versions, and bumps `VERSION` when it changes the Dockerfile.

## Layout

| Path | Purpose |
| --- | --- |
| `.forgejo/workflows/_build-scan-push.yml` | Reusable pipeline: [buildx](https://github.com/docker/buildx) build, [Trivy](https://github.com/aquasecurity/trivy) SBOM and scan, multi-tag push, cosign sign and attest. |
| `.forgejo/workflows/docker-runner.yml` | On push to `main` (path-filtered) or manual dispatch, builds the forgejo runner image via the reusable workflow. |
| `.forgejo/workflows/pr-checks.yml` | On pull request: [Hadolint](https://github.com/hadolint/hadolint), [TruffleHog](https://github.com/trufflesecurity/trufflehog) and the version-bump guard. |
| `.forgejo/workflows/scan-live-image.yml` | Daily Trivy re-scan of the published image. |
| `.forgejo/workflows/renovate.yml` | Daily Renovate run that autodiscovers repositories on the Forgejo instance. |
| `docker/` | Toolchain image `Dockerfile` (Docker CLI plus Trivy, cosign, TruffleHog and Hadolint), its `VERSION`, and `.trivyignore` for documented vulnerability exceptions. |
| `renovate.json` | Repository rule that patch-bumps `docker/VERSION` whenever Renovate updates the Dockerfile. |
| `.pre-commit-config.yaml` | Local [pre-commit](https://github.com/pre-commit/pre-commit) hooks for Hadolint and TruffleHog, mirroring the PR checks. |
| `cosign.pub` | Public key for verifying image signatures. |

## How it works

<!-- d2 diagram to be added: PR checks -> merge -> build (buildx, registry cache) -> SBOM + Trivy gate -> push (multi-tag) -> cosign sign + attest -> n8n webhook; daily cron -> live-image scan -->

1. **Gate.** Pull requests must pass Hadolint, a TruffleHog scan for verified secrets, and a `VERSION` bump for any Dockerfile change.
2. **Build.** Buildx pulls fresh base images and caches layers in the registry (`type=registry,mode=max`), independent of runner-local state. `VERSION` must be plain semver.
3. **Scan.** Trivy generates the SBOM, then the run fails on any fixable CRITICAL or HIGH finding not listed in `.trivyignore`.
4. **Publish.** All tags are pushed, then the image is signed and its SBOM attested against the pushed digest.
5. **Notify.** The build, live-scan and Renovate workflows post their status, repository and run URL to n8n's status webhook (authenticated with a shared-secret header), decoupled from the pipeline with `continue-on-error`.

## Design decisions

- **Version guard, twice.** The `VERSION` bump is enforced pre-merge (blocking) and again post-merge, as defence in depth for direct pushes.
- **Documented exceptions.** Accepted vulnerabilities live in `.trivyignore` with a stated reason (a vendored dependency awaiting an upstream fix), and only fixable findings block a build.
- **Fail closed.** A vulnerable image is never pushed, and a published one is re-checked daily rather than trusted.

**Stack:** Forgejo Actions · Docker Buildx · Trivy · cosign · Hadolint · TruffleHog · Renovate · pre-commit
