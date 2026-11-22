#!/usr/bin/env bash
# Contrôles propres au projet, appelés par tools/ci/checks.sh (étape [projet], bloquante).
# Lancé à la racine du dépôt. Sortie non nulle = échec. Exemples :
#   uvx ruff check --select E9,F63,F7,F82 . && python3 -m pytest -q tests/
#   npm ci && npm test
set -euo pipefail
echo "TODO : tests et lint du projet (tools/ci/projet.sh)"
