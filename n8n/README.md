# n8n Workflows

Two exported [n8n](https://github.com/n8n-io/n8n) workflows that connect CI to the deployment and notification layers. Both are triggered by webhooks from Forgejo Actions and report through [Apprise](https://github.com/caronc/apprise), with the destination passed on each request rather than stored in the workflow.

## Highlights

- **Automatic rollback.** A failed deployment triggers a rollback task, and a failed rollback triggers an escalation asking for manual intervention.
- **Stateless notifications.** The Apprise endpoint arrives as request data, so no notification target is hardcoded.
- **Authenticated and minimal.** Both webhooks require a shared-secret header, and the only other credential is an HTTP Bearer Auth token for the Semaphore API. Neither value is included in the export.

## Layout

| File | Webhook | Purpose |
| --- | --- | --- |
| `docker-image-deployment.json` | `POST /webhook/forgejo-deploy` | Runs a deployment through [Ansible Semaphore](https://github.com/semaphoreui/semaphore), polls it, and rolls back on failure. |
| `forgejo-action-status.json` | `POST /webhook/forgejo-action` | Formats and forwards a pass/fail status from any Forgejo Actions workflow. |

## How it works

![Docker Image Deployment workflow](../.assets/docker-image-deployment.png)

**Deployment workflow**

1. Extract variables from the request body.
2. Start the Semaphore deploy task with the image tag, then poll every 15 seconds until its status is `success`, `error` or `stopped`, or until 40 polls (about 10 minutes) have passed. A timeout counts as a failure.
3. If the task status is `success`, send a success notification.
4. Otherwise, start the rollback task (with `reason: "health check failed"`) and poll it the same way. Notify the outcome, or send a "manual intervention required" escalation if the rollback task did not succeed.

![Forgejo Action Status workflow](../.assets/forgejo-action-status.png)

**Status workflow:** extract variables, branch on `status == "success"`, and send a success or failure notification.

**Request bodies**

| Workflow | Fields |
| --- | --- |
| Deployment | `repository`, `image_tag`, `semaphore_url` (API base, ending in `/api/project`), `semaphore_project_id`, `semaphore_deploy_template_id`, `semaphore_rollback_template_id`, `apprise_url` |
| Status | `status` (`"success"`, or anything else for failure), `workflow`, `repository`, `run_url`, `apprise_url` |

Any extra fields CI sends are ignored. Everything else the playbooks need is defined in the Semaphore task templates (see [`semaphore/`](../semaphore/)).

## Design decisions

- **Data over configuration.** Project IDs, template IDs and notification targets travel in the payload, so one workflow serves many repositories.
- **Polling over callbacks.** A 15-second poll keeps the workflow simple and self-contained, at the cost of some latency. Each status request has a 10-second timeout and up to three tries, only terminal task states end the loop, and the loop is capped so a hung task cannot poll forever.
- **Orchestrator owns recovery.** The playbooks only report success or failure, and n8n decides whether to roll back, notify or escalate.

**Stack:** n8n · Ansible Semaphore · Apprise · Webhooks · REST APIs
