#!/bin/sh
# Appel à l'API REST ClickUp : sh tools/clickup/cu.sh METHODE /chemin [json]
#   /chemin en v2 par défaut (tâches, commentaires, listes) ; /v3/... pour l'API v3 (Docs et pages).
# Clé : variable CLICKUP_API_TOKEN (réglée une fois dans ~/.claude/settings.json, clé env, ou dans le shell),
# sinon tools/clickup/.env (CLICKUP_API_TOKEN=pk_…, ignoré par git). Quota : 100 requêtes/minute.
TOKEN=${CLICKUP_API_TOKEN:-$(sed -n 's/^CLICKUP_API_TOKEN=//p' "$(dirname "$0")/.env" 2>/dev/null)}
case "$TOKEN" in pk_?*) ;; *) echo "CLICKUP_API_TOKEN absent (ni variable d'environnement, ni $(dirname "$0")/.env)" >&2; exit 1 ;; esac
case "$2" in /v3/*) URL="https://api.clickup.com/api$2" ;; *) URL="https://api.clickup.com/api/v2$2" ;; esac
curl -s -X "$1" "$URL" -H "Authorization: $TOKEN" -H "Content-Type: application/json" ${3:+-d "$3"}
