#!/usr/bin/env bash
# Une tâche = une branche = un worktree, pour que plusieurs sessions (humaines ou Claude) travaillent
# en parallèle sans se voler la branche courante. Règles : CLAUDE.md.
#
#   bash tools/git/tache.sh new <prenom>/<zone>-<sujet> crée la branche depuis origin/main et son worktree
#   bash tools/git/tache.sh list                       worktrees ouverts et état de leur PR
#   bash tools/git/tache.sh clean                      retire les worktrees dont la PR est fusionnée
#
# Les worktrees vivent dans .claude/worktrees/ (ignoré par git). Une session Claude y entre avec
# l'outil EnterWorktree (path), ou on lance `claude` depuis ce dossier.
set -euo pipefail

# Racine du clone principal, même lancé depuis un worktree.
ROOT="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
WT="$ROOT/.claude/worktrees"

case "${1:-}" in
  new)
    branch="${2:-}"
    [[ "$branch" =~ ^[a-z]+/(bot|routing|docs|outils)(-[a-z0-9]+)+$ ]] \
      || { echo "Nom attendu : <prenom>/<zone>-<sujet> (zone : bot, routing, docs, outils)" >&2; exit 1; }
    dir="$WT/${branch//\//-}"
    [ -e "$dir" ] && { echo "$dir"; exit 0; }   # déjà créé : on le réutilise
    git -C "$ROOT" fetch -q origin main
    # --no-track : sinon un simple `git push` partirait sur main.
    git -C "$ROOT" worktree add -q --no-track -b "$branch" "$dir" origin/main
    # Fichiers locaux non suivis dont les scripts ont besoin (clés, permissions Claude).
    while IFS= read -r f; do
      rel="${f#"$ROOT"/}"
      mkdir -p "$(dirname "$dir/$rel")" && cp "$f" "$dir/$rel"
    done < <(find "$ROOT" -path "$WT" -prune -o -path "$ROOT/.git" -prune -o -path "*/node_modules" -prune \
               -o \( -name .env -o -path "$ROOT/.claude/settings.local.json" \) -type f -print)
    echo "$dir"
    ;;
  list)
    git -C "$ROOT" worktree list --porcelain | while IFS= read -r line; do
      case "$line" in
        "worktree "*) path="${line#worktree }" ;;
        "branch "*)
          b="${line#branch refs/heads/}"
          state="$(gh pr view "$b" --json state,number --jq '"#\(.number) \(.state)"' 2>/dev/null || echo "pas de PR")"
          rel="${path#"$ROOT"}"; printf '%-40s %-45s %s\n' "$b" "${rel:-(clone principal)}" "$state" ;;
      esac
    done
    ;;
  clean)
    for dir in "$WT"/*/; do
      [ -d "$dir" ] || continue
      b="$(git -C "$dir" branch --show-current)"
      if [ "$(gh pr view "$b" --json state --jq .state 2>/dev/null)" = "MERGED" ]; then
        if [ -n "$(git -C "$dir" status --porcelain)" ]; then echo "garde $b : modifications non commitées"; continue; fi
        git -C "$ROOT" worktree remove "$dir"
        git -C "$ROOT" branch -D "$b" >/dev/null   # -D : après un squash, git ne voit pas la branche comme fusionnée
        echo "retiré $b"
      fi
    done
    git -C "$ROOT" worktree prune
    ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac
