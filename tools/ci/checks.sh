#!/usr/bin/env bash
# Contrôles de la CI (CLAUDE.md, « Finir »), les mêmes sur GitHub Actions et en local.
#   bash tools/ci/checks.sh [base]      base par défaut : origin/main
# Env optionnels : PR_TITLE, PR_BODY (étape [hygiène]). Écrit un rapport Markdown sur stdout ;
# sortie 1 si une étape bloquante échoue. Chaque étape tourne même si une autre a échoué.
set -uo pipefail
BASE="${1:-origin/main}"
cd "$(git rev-parse --show-toplevel)"
FAIL=0; ROWS=""; LOGS=""

row() {  # row <étape> <ok|fail|warn|skip> [log]
  local icon; case "$2" in ok) icon="ok";; fail) icon="ÉCHEC"; FAIL=1;; warn) icon="ATTENTION";; skip) icon="sauté";; esac
  ROWS+="| $1 | $icon |"$'\n'
  [ -n "${3:-}" ] && LOGS+=$'\n'"<details><summary>$icon $1</summary>"$'\n\n```\n'"$(printf '%s' "$3" | tail -n 40)"$'\n```\n</details>\n'
  return 0
}

# [secrets] motifs de tokens dans les lignes ajoutées
TOKENS='pk_[0-9]+_[A-Z0-9]{20,}|sk-ant-[A-Za-z0-9_-]{20,}|(^|[^A-Za-z0-9+/])AIza[0-9A-Za-z_-]{30,}|gh[pousr]_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9]{40,}'
hits="$(git diff "$BASE...HEAD" -U0 | grep '^+' | grep -v '^+++' | grep -nE "$TOKENS" | sed -E 's/(.{12}).*/\1…/')"
[ -z "$hits" ] && row "[secrets] tokens dans le diff" ok || row "[secrets] tokens dans le diff" fail "$hits"

# [gitleaks] commits de la branche
if command -v gitleaks >/dev/null; then
  out="$(gitleaks git --no-banner --redact --log-opts="$BASE..HEAD" . 2>&1)" \
    && row "[gitleaks] secrets dans les commits" ok || row "[gitleaks] secrets dans les commits" fail "$out"
else
  row "[gitleaks] secrets dans les commits" skip "gitleaks absent (brew install gitleaks)"
fi

# [files] JSON lisibles, gros fichiers ajoutés
bad=""; while IFS= read -r f; do
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>/dev/null || bad+="$f"$'\n'
done < <(git ls-files '*.json')
[ -z "$bad" ] && row "[files] JSON lisibles" ok || row "[files] JSON lisibles" fail "$bad"
big=""; huge=""; while IFS= read -r f; do
  [ -f "$f" ] || continue; s=$(wc -c < "$f")
  [ "$s" -gt 52428800 ] && huge+="$f ($((s/1048576)) Mo)"$'\n' || { [ "$s" -gt 5242880 ] && big+="$f ($((s/1048576)) Mo)"$'\n'; }
done < <(git diff --name-only --diff-filter=AM "$BASE...HEAD")
if [ -n "$huge" ]; then row "[files] taille des fichiers ajoutés" fail "$huge$big"
elif [ -n "$big" ]; then row "[files] taille des fichiers ajoutés" warn "$big"
else row "[files] taille des fichiers ajoutés" ok; fi

# [projet] tests et lint propres au projet
if [ -f tools/ci/projet.sh ]; then
  out="$(bash tools/ci/projet.sh 2>&1)" && row "[projet] tests et lint" ok "$(grep -i todo <<<"$out")" || row "[projet] tests et lint" fail "$out"
fi

# [hygiène] jamais bloquant
warn=""
[ -n "${PR_TITLE:-}" ] && ! grep -qE 'CU-[a-z0-9]+' <<<"$PR_TITLE" && warn+="titre sans CU-<id>"$'\n'
grep -qiE 'Co-Authored-By:.*(Claude|Codex|Copilot|ChatGPT|OpenAI|Cursor|Gemini|anthropic)|Claude-Session:|Generated (with|by) \[?(Claude|Codex|Copilot|ChatGPT|Cursor)' \
  <<<"$(git log --format=%B "$BASE..HEAD")${PR_BODY:-}" && warn+="attribution à une IA dans un commit ou la PR"$'\n'
md="$(git diff --name-only --diff-filter=A "$BASE...HEAD" | grep -E '\.md$' | grep -vE '^(README|CLAUDE)\.md$|^\.github/|^\.claude/' || true)"
[ -n "$md" ] && warn+="documentation ajoutée au dépôt (elle va dans le Doc ClickUp) : $md"$'\n'
[ -z "$warn" ] && row "[hygiène] id ClickUp, attribution, .md" ok || row "[hygiène] id ClickUp, attribution, .md" warn "$warn"

echo "### CI sur \`$(git rev-parse --short HEAD)\` : $([ $FAIL = 0 ] && echo 'vert' || echo 'ÉCHEC')"
echo; echo "| Étape | Résultat |"; echo "|---|---|"; printf '%s' "$ROWS"; printf '%s' "$LOGS"
exit $FAIL
