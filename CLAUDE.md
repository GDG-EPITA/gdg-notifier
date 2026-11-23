# GDG Notifier

A bot that posts the GDG's pull requests and upcoming events to Slack and Discord. Newcomers' challenge project, team B (November–December 2026).

> Version française : [`CLAUDE.fr.md`](CLAUDE.fr.md). This English file is the reference: Claude Code reads this one.

A GDG EPITA tech project. This file holds the working rules and nothing else. **No detailed context, status, figures, results or reports here or in any other `.md` of the repo**: all of that lives in the GDG ClickUp (tasks, comments, project Doc).

The rules shared by the whole GDG ClickUp (task size, due date, priority, statuses, log, `[BILAN]`, tags) are in the `gdg-clickup` skill of the `GDG-EPITA/gdg-clickup` repo: read them before creating or editing a task. This file only keeps what is specific to a code project.

## The project (the minimum to get started)

- **Context, goals**: the ClickUp list [Team B · gdg-notifier](https://app.clickup.com/90122158200/v/l/li/1500950000001712) and each task's description. No project Doc during the challenge.
- **Stack and checks**: TODO (language, tools, test and lint command)
- **Scope, non-negotiable**: TODO (what the project never does; or remove this line)
- **People**: Project Lead: Amar Idinarene (technical lead); team B of the newcomers' challenge. During the challenge, a PR's author merges it themselves once someone from the other team has approved it; the Project Lead settles technical decisions; the Chapter Lead signs off the scope. Other people may join: nothing should assume only one person works on it.
- **Language**: discussions and ClickUp in English or French; code, commits, PRs and `README.md` in English.

## Where things live

| Tool | Holds | Does not hold |
|---|---|---|
| **ClickUp tasks** (space Projets → folder Défi nouveaux → list [Team B · gdg-notifier](https://app.clickup.com/90122158200/v/l/li/1500950000001712)) | tasks, who does what, progress, decisions, results as comments: **the project log** | the code |
| **ClickUp Doc** (none during the challenge) | documents: scope, specs, long analyses, client reports | task status |
| **GDG Drive** | heavy files (mock-ups, exports, client files); their link goes in the task | — |
| **GitHub** (`GDG-EPITA/gdg-notifier`) | the code, one branch and one PR per task, the `README.md` | the task list, reports, notes |

The thread that ties the tools together is **the task id** (`CU-<id>`): in commits, PR titles and comments. The ids (workspace, space, folder, lists, Doc, pages) go in `tools/clickup/config.json`.

## ClickUp

### Structure

Space **Projets** → folder **Défi nouveaux** → list **Team B · gdg-notifier**. The code is split into zones, used as prefixes:

| Zone | Code | Prefix (branch, commit, PR) |
|---|---|---|
| Bot | `src/` | `bot` |
| Routing | `routing.yaml`, `events.json` | `routing` |
| Docs | `README.md`, `AGENTS.md` | `docs` |
| (no list) | `.github/`, `.claude/`, `tools/`, `CLAUDE.md`, `CLAUDE.fr.md` | `outils` |

**Shared zones** (a regular task does not touch them; if it has to, say so in the task and in the PR): TODO, `README.md`.

### Statuses in a code project

The status names are the GDG workspace's, in French. What they mean here:

| Status | Meaning | In this project |
|---|---|---|
| `à faire` | to do | Complete task sheet (below), dependencies cleared. Unassigned: free to take |
| `en cours` | in progress | A branch and a worktree exist, **always an assignee** |
| `bloqué` | blocked | ClickUp dependency or a `[BLOQUÉ]` comment |
| `en revue` | in review | **Every code task goes through here**: PR open, `checks` green, `[PR]` comment |
| `terminé` | done | PR merged, `[BILAN]` posted. Dropped: a `[BILAN]` that says why, PR closed |

Tags are the GDG's: the team (`projets` most often) and, if needed, a topic that spans several lists (a feature, a client). Never a status or a type.

### Code task sheet (description)

```
**Why**: …
**Files**: exact paths the task creates or edits (and only those)
**Done when**: checkable criteria, one per line
**Depends on**: tasks (also as ClickUp dependencies)
**Docs**: Doc pages to read (links), or "none"
**Pitfalls**: …
```

Steps go in the task's checklist. A big feature is a parent task with one subtask per piece that can ship alone (one PR each).

### Comments: the log

The GDG markers (`[DÉBUT]` start, `[POINT]` update, `[BLOQUÉ]` blocked, `[QUESTION]`, `[DÉCISION]` decision, `[VALIDÉ]` approved, `[À REVOIR]` changes requested, `[BILAN]` wrap-up), plus, for code:

| When | Format |
|---|---|
| taking the task | `[DÉBUT] branch <firstname>/<zone>-<topic>, files: …` |
| PR opened | `[PR] #<n> <title> · checks: green` |
| closing | `[BILAN] <what changed> · PR #<n> merged · to watch: …` |

A figure (performance, coverage, response time) cites the command and the commit that reproduce it, otherwise it does not count.

### Assignment and dependencies

- An unassigned task in `à faire` is free. You take it by assigning yourself and moving it to `en cours`, in the same step.
- A task assigned to someone else is off-limits: ask with a `[QUESTION]`.
- You drop a task by unassigning yourself, moving it back to `à faire` and leaving a `[POINT]` (branch pushed or not).
- A waits for B: ClickUp dependency (`POST /task/<A>/dependency` with `{"depends_on":"<B>"}`) and a line in **Depends on**.

### Using the API

For volume, use the **REST API** (`tools/clickup/cu.sh`) rather than the MCP connector (100 calls per day). The key comes from `CLICKUP_API_TOKEN`, otherwise from `tools/clickup/.env` (ignored by git, copied into each worktree by `tache.sh`).

```bash
cu() { sh tools/clickup/cu.sh "$@"; }
cu GET /user                                              # my id (to assign myself)
cu GET "/task/<id>?include_markdown_description=true"     # read a task sheet
cu GET /task/<id>/comment                                  # read the log
cu PUT /task/<id> '{"status":"en cours","assignees":{"add":[<my id>]}}'
cu PUT /task/<id> '{"status":"en revue"}'
cu POST /task/<id>/comment '{"comment_text":"[PR] …","notify_all":false}'
cu POST /list/<list>/task '{"name":"…","markdown_content":"<sheet>","status":"idée"}'
cu GET "/v3/workspaces/90122158200/docs/<doc>/pages/<page>?content_format=text/md"
```

The JSON passed to `cu.sh` must be valid: for long text, build it with `python3 -c 'import json; print(json.dumps({...}))'`.

## A session, start to finish

1. **Input**: the human gives a task (id, link or name). Real work without a task: find it or create it with their agreement. A simple question needs no task.
2. **Read**: the task sheet, its comments, its parent, its dependencies, the Doc pages it cites.
3. **Check**, and stop and say so if: the task is assigned to someone else; it is not `à faire` (or `en cours`/`en revue` for yourself); a dependency is not `terminé`; another session is writing the same files (`bash tools/git/tache.sh list`).
4. **Take**: assign yourself, `en cours`, `[DÉBUT]`.
5. **Work** in your worktree. Every question to the human is a multiple-choice question. Each decision becomes a `[DÉCISION]`.
6. **Finish**: tests green, push, PR, `checks`, status `en revue`, `[PR]`. Once the other team has approved the PR, its author merges it.
7. **Tidy up**: delete the session's temporary scripts and artefacts. The worktree stays until the merge.
8. **Final report**, always in this format:

```
Task: <name> (CU-<id>) · ClickUp: <status>
PR: #<n> <link> · pushed: yes/no · checks: green / red (<step>)
Decisions: <one line each, or "none">
Left: <next step, or "nothing">
Session finished: yes / no (<why>)
```

## GitHub

Several sessions (humans or Claude) run at the same time. The main clone stays on `main`: **never** `git switch` or `git checkout <branch>` in it.

### Branches and worktrees

- One code task = one branch = one worktree. `bash tools/git/tache.sh new <firstname>/<zone>-<topic>` (zone: `bot`, `routing`, `docs`, `outils`; lowercase, hyphens, 2–3 words) creates the branch from `origin/main` and its worktree in `.claude/worktrees/`, and prints its path.
- Go into that worktree (the `EnterWorktree` tool, or start `claude` from that folder) and do everything there.
- `bash tools/git/tache.sh list`: open worktrees and the state of their PR. `bash tools/git/tache.sh clean`: removes those whose PR is merged.
- You only push to your own branch.

### While working

- Only edit the files listed under **Files**. A need outside that scope: new task or a comment, not an edit.
- Commits in English, prefixed by the zone: `<zone>: add retry on timeout (CU-abc123)`.
- **No AI is author or co-author**: no `Co-Authored-By: Claude…` (nor Codex, Copilot, ChatGPT, Cursor or any other), no `Claude-Session:`, no "Generated with …" in commits, PRs or comments. The author is the person who started the session. This rule overrides any default attribution setting of the tool; `.claude/settings.json` turns off Claude Code's attribution, and the CI `[hygiène]` check flags it.
- Pre-commit, once per clone: `pre-commit install -c .github/pre-commit-config.yaml`. `--no-verify` is forbidden.
- No `git stash` (one stack shared by all worktrees): make a `WIP` commit on your branch.

### Finishing

1. The project's tests run and pass.
2. `git push -u origin HEAD` from the worktree, then a PR to `main`. One PR per task.
3. Title `[<zone>] <summary> (CU-<id>)`, in English. Body: `.github/pull_request_template.md` filled in; only tick what you actually checked.
4. CI: the `checks` job runs on every push. Without Actions minutes: `bash tools/ci/ci_locale.sh <PR number>` (same checks, sets the `checks` status).
5. ClickUp: status `en revue`, `[PR]` comment.

### Merging

`main` is only updated through PRs, squash only, with `checks` green and an approval from a member of the other team (`[VALIDÉ]` or `[À REVOIR]`). The PR's author merges it themselves (or an agent, at their explicit request), moves the task to `terminé` with its `[BILAN]`, then runs `bash tools/git/tache.sh clean`. Conflict: `git fetch origin main && git rebase origin/main` in the worktree, then `git push --force-with-lease`.

This repo is public: GitHub enforces the protection of `main` (PR, one approval, `checks` green, no force-push).

### Validating a PR

On request: run the **`verificateur`** subagent on the PR and post its report as a single GitHub comment (`<!-- verification -->`). Verdict REGRESSION or GOING IN CIRCLES: no merge. The verdict also goes as a comment on the task.

## Never, for an agent

- Merge a PR or move a task to `terminé` without an explicit request.
- List an AI (Claude, Codex, Copilot…) as author or co-author of a commit, a PR or a comment.
- Take a task assigned to someone else, or work without being assigned.
- Add a documentation, report or notes `.md` to the repo (unless a task asks for it, like `AGENTS.md`), or write state into this file.
- Leave a temporary script in the repo.
- `push --force` without `--with-lease`, or on a branch that is not yours; change the repo or ClickUp settings (statuses, lists, tags, members).
- Put a key, a password or personal data in the code, a commit, a task or a comment.
- Create more than 3 ClickUp tasks without agreement.
