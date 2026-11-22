# GDG Notifier

A bot that posts pull requests and upcoming events of GDG on Campus EPITA to Slack.

This is a newcomers' challenge project (team B, November–December 2026). Team A reviews every pull request here, and this team reviews theirs in `GDG-EPITA/gdg-link-hub`.

## How we work

- One ClickUp task = one branch = one pull request. Put the task id (`CU-<id>`) in your commits and in the PR title.
- Nobody pushes to `main`. A PR merges (squash only) once the `checks` job is green and one reviewer approves.
- Before your first commit: `pre-commit install -c .github/pre-commit-config.yaml`.
- The Slack webhook URL lives only in the `SLACK_WEBHOOK_URL` repository secret. Never paste it in code, an issue or a chat.
- The full rules are in [`CLAUDE.md`](CLAUDE.md).

## Getting started

The workflow skeleton is the first task (B1). Update this section when it lands.
