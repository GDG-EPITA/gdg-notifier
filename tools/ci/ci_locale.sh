#!/usr/bin/env bash
# CI en local : lance tools/ci/checks.sh sur la tête d'une PR et pose le résultat sur GitHub.
#   bash tools/ci/ci_locale.sh            branche courante contre origin/main, rien n'est posté
#   bash tools/ci/ci_locale.sh <n°>       tête de la PR dans un worktree temporaire, puis commentaire
#                                         unique <!-- ci-locale --> et statut de commit `checks`
#   bash tools/ci/ci_locale.sh <n°> --no-post
# Une nouvelle poussée laisse le nouveau commit sans statut : relancer.
set -euo pipefail
ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
HERE="$(cd "$(dirname "$0")" && pwd)"
PR="${1:-}"; POST=1; [ "${2:-}" = "--no-post" ] && POST=0

if [ -z "$PR" ]; then
  git fetch -q origin main
  bash "$HERE/checks.sh" origin/main; exit $?
fi

REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
read -r SHA TITLE < <(gh pr view "$PR" --json headRefOid,title --jq '"\(.headRefOid) \(.title)"')
export PR_TITLE="$TITLE" PR_BODY="$(gh pr view "$PR" --json body --jq .body)"
TMP="$(mktemp -d)"; trap 'git -C "$ROOT" worktree remove --force "$TMP/wt" >/dev/null 2>&1; rm -rf "$TMP"' EXIT
git -C "$ROOT" fetch -q origin main "pull/$PR/head"
git -C "$ROOT" worktree add -q --detach "$TMP/wt" "$SHA"
# checks.sh de main : une PR ne peut pas assouplir ses propres contrôles.
git -C "$ROOT" show origin/main:tools/ci/checks.sh > "$TMP/checks.sh" 2>/dev/null || cp "$HERE/checks.sh" "$TMP/checks.sh"
set +e; (cd "$TMP/wt" && bash "$TMP/checks.sh" origin/main) > "$TMP/report.md"; RC=$?; set -e
cat "$TMP/report.md"
[ "$POST" = 1 ] || exit $RC

BODY="<!-- ci-locale -->"$'\n'"$(cat "$TMP/report.md")"$'\n\n'"_Lancé en local par \`bash tools/ci/ci_locale.sh $PR\`._"
CID="$(gh api "repos/$REPO/issues/$PR/comments" --paginate --jq '.[] | select(.body | startswith("<!-- ci-locale -->")) | .id' | head -n1)"
if [ -n "$CID" ]; then gh api -X PATCH "repos/$REPO/issues/comments/$CID" -f body="$BODY" >/dev/null
else gh api "repos/$REPO/issues/$PR/comments" -f body="$BODY" >/dev/null; fi
STATE=$([ $RC = 0 ] && echo success || echo failure)
gh api "repos/$REPO/statuses/$SHA" -f state="$STATE" -f context=checks -f description="CI locale (tools/ci/ci_locale.sh)" >/dev/null
echo "→ commentaire et statut checks=$STATE posés sur #$PR ($SHA)"
exit $RC
