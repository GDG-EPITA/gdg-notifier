# GDG Notifier

Le bot qui annonce sur Slack les PR et les événements à venir du GDG. Projet du défi des nouveaux, équipe B (novembre-décembre 2026).

Projet technique du GDG EPITA. Ce fichier contient les règles de travail, et rien d'autre. **Aucun contexte détaillé, statut, chiffre, résultat ni compte rendu ici ou dans un autre `.md` du dépôt** : tout ça vit dans le ClickUp du GDG (tâches, commentaires, Doc du projet).

Les règles communes à tout le ClickUp du GDG (taille d'une tâche, échéance, priorité, statuts, journal, `[BILAN]`, tags) sont dans le skill `gdg-clickup` du dépôt `GDG-EPITA/gdg-clickup` : les lire avant de créer ou de modifier une tâche. Ce fichier ne garde que ce qui est propre à un projet de code.

## Le projet (le minimum pour travailler)

- **Contexte, objectifs** : la liste ClickUp [Équipe B · gdg-notifier](https://app.clickup.com/90122158200/v/l/li/1500950000001712) et la description de chaque tâche. Pas de Doc projet pendant le défi.
- **Stack et contrôles** : TODO (langage, outils, commande de tests et de lint)
- **Périmètre, non négociable** : TODO (ce que le projet ne fait jamais ; ou retirer la ligne)
- **Personnes** : Project Lead : Amar Idinarene (technical lead) ; équipe B du défi des nouveaux. Pendant le défi, l'auteur d'une PR la fusionne lui-même une fois approuvée par quelqu'un de l'autre équipe ; le Project Lead tranche les décisions techniques ; le Chapter Lead signe le cadrage. D'autres personnes peuvent rejoindre : rien ne doit supposer qu'une seule personne travaille dessus.
- **Langue** : échanges et ClickUp en français ; code, commits, PR et `README.md` en anglais.

## Où est quoi

| Outil | Contient | Ne contient pas |
|---|---|---|
| **Tâches ClickUp** (espace Projets → dossier Défi nouveaux → liste [Équipe B · gdg-notifier](https://app.clickup.com/90122158200/v/l/li/1500950000001712)) | les tâches, qui fait quoi, l'avancement, les décisions, les résultats en commentaires : **le journal du projet** | le code |
| **Doc ClickUp** (aucun pendant le défi) | les documents : cadrage, spécifications, analyses longues, comptes rendus client | l'état des tâches |
| **Drive du GDG** | les fichiers lourds (maquettes, exports, pièces du client) ; leur lien va dans la tâche | — |
| **GitHub** (`GDG-EPITA/gdg-notifier`) | le code, une branche et une PR par tâche, le `README.md` | la liste des tâches, des rapports, des notes |

Le fil qui relie les outils est **l'id de la tâche** (`CU-<id>`) : dans les commits, le titre de la PR, les commentaires. Les ids (workspace, espace, dossier, listes, Doc, pages) sont dans `tools/clickup/config.json`.

## ClickUp

### Structure

Espace **Projets** → dossier **GDG Notifier** → une liste par grande partie du projet, qui est aussi une zone du code. Plus le Doc du projet dans le dossier. Rien d'autre.

| Liste | Zone de code | Préfixe (branche, commit, PR) |
|---|---|---|
| Bot | `src/` | `bot` |
| Routing | `routing.yaml`, `events.json` | `routing` |
| Docs | `README.md`, `AGENTS.md` | `docs` |
| (hors liste) | `.github/`, `.claude/`, `tools/`, `CLAUDE.md` | `outils` |

**Zones partagées** (une tâche ordinaire n'y touche pas ; si c'est nécessaire, le dire dans la fiche et dans la PR) : TODO, `README.md`.

### Statuts dans un projet de code

Ceux de tout le workspace GDG. Ce qui est propre au code :

| Statut | Dans ce projet |
|---|---|
| `à faire` | Fiche complète (ci-dessous), échéance posée, dépendances levées. Non assignée : libre |
| `en cours` | Une branche et un worktree existent, **toujours un assigné** |
| `bloqué` | Dépendance ClickUp ou commentaire `[BLOQUÉ]` |
| `en revue` | **Toute tâche de code passe par là** : PR ouverte, `checks` vert, commentaire `[PR]` |
| `terminé` | PR fusionnée, `[BILAN]` posté. Abandonnée : `[BILAN]` qui dit pourquoi, PR fermée |

Les tags sont ceux du GDG : le pôle (`projets` le plus souvent) et, si besoin, un sujet qui traverse plusieurs listes (une fonctionnalité, un client). Jamais un statut ou un type.

### Fiche d'une tâche de code (description)

```
**Pourquoi** : …
**Fichiers** : chemins exacts que la tâche crée ou modifie (et seulement ceux-là)
**Terminé quand** : critères vérifiables, un par ligne
**Dépend de** : tâches (aussi en dépendance ClickUp)
**Docs** : pages du Doc à lire (liens), ou « aucune »
**Pièges** : …
```

Les étapes vont dans la checklist de la tâche. Une grosse fonctionnalité est une tâche parente et une sous-tâche par morceau livrable seul (une PR chacune).

### Commentaires : le journal

Les marqueurs du GDG (`[DÉBUT]`, `[POINT]`, `[BLOQUÉ]`, `[QUESTION]`, `[DÉCISION]`, `[VALIDÉ]`, `[À REVOIR]`, `[BILAN]`), plus, pour le code :

| Quand | Format |
|---|---|
| on prend la tâche | `[DÉBUT] branche <prenom>/<zone>-<sujet>, fichiers : …` |
| PR ouverte | `[PR] #<n> <titre> · checks : vert` |
| on clôt | `[BILAN] <ce qui a changé> · PR #<n> fusionnée · à surveiller : …` |

Un chiffre (performance, couverture, temps de réponse) cite la commande et le commit qui le reproduisent, sinon il ne compte pas.

### Assignation et dépendances

- Une tâche `à faire`, non assignée, est libre. On la prend en s'assignant et en passant `en cours`, dans le même appel.
- Une tâche assignée à quelqu'un d'autre ne se touche pas : `[QUESTION]` pour demander.
- On lâche une tâche en se désassignant, en la repassant `à faire` et en laissant un `[POINT]` (branche poussée ou non).
- A attend B : dépendance ClickUp (`POST /task/<A>/dependency` avec `{"depends_on":"<B>"}`) et une ligne dans **Dépend de**.

### Utiliser l'API

Pour du volume, l'**API REST** (`tools/clickup/cu.sh`) plutôt que le connecteur MCP (100 appels par jour). La clé vient de `CLICKUP_API_TOKEN`, sinon de `tools/clickup/.env` (ignoré par git, copié dans chaque worktree par `tache.sh`).

```bash
cu() { sh tools/clickup/cu.sh "$@"; }
cu GET /user                                              # mon id (pour m'assigner)
cu GET "/task/<id>?include_markdown_description=true"     # lire une fiche
cu GET /task/<id>/comment                                  # lire le journal
cu PUT /task/<id> '{"status":"en cours","assignees":{"add":[<mon id>]}}'
cu PUT /task/<id> '{"status":"en revue"}'
cu POST /task/<id>/comment '{"comment_text":"[PR] …","notify_all":false}'
cu POST /list/<liste>/task '{"name":"…","markdown_content":"<fiche>","status":"idée"}'
cu GET "/v3/workspaces/90122158200/docs/<doc>/pages/<page>?content_format=text/md"
```

Le JSON passé à `cu.sh` doit être valide : pour un texte long, le produire avec `python3 -c 'import json; print(json.dumps({...}))'`.

## Une session, du début à la fin

1. **Entrée** : l'humain donne une tâche (id, lien ou nom). Un vrai travail sans tâche : la trouver ou la créer avec son accord. Une simple question ne demande pas de tâche.
2. **Lire** : la fiche, ses commentaires, sa parente, ses dépendances, les pages du Doc citées.
3. **Vérifier**, et s'arrêter en le signalant si : la tâche est assignée à quelqu'un d'autre ; elle n'est pas `à faire` (ou `en cours`/`en revue` pour soi) ; une dépendance n'est pas `terminé` ; une autre session écrit les mêmes fichiers (`bash tools/git/tache.sh list`).
4. **Prendre** : s'assigner, `en cours`, `[DÉBUT]`.
5. **Travailler** dans son worktree. Toute question à l'humain passe par un QCM. Chaque décision devient un `[DÉCISION]`.
6. **Finir** : tests verts, push, PR, `checks`, statut `en revue`, `[PR]`. Une fois la PR approuvée par l'autre équipe, son auteur la fusionne.
7. **Ranger** : supprimer les scripts temporaires et les artefacts de la session. Le worktree reste jusqu'à la fusion.
8. **Rapport de fin**, toujours dans ce format :

```
Tâche : <nom> (CU-<id>) · ClickUp : <statut>
PR : #<n> <lien> · poussée : oui/non · checks : vert / rouge (<étape>)
Décisions : <une ligne chacune, ou « aucune »>
Reste : <prochaine étape, ou « rien »>
Session terminée : oui / non (<pourquoi>)
```

## GitHub

Plusieurs sessions (humaines ou Claude) tournent en même temps. Le clone principal reste sur `main` : **jamais** de `git switch` ou `git checkout <branche>` dedans.

### Branches et worktrees

- Une tâche de code = une branche = un worktree. `bash tools/git/tache.sh new <prenom>/<zone>-<sujet>` (zone : `bot`, `routing`, `docs`, `outils` ; minuscules, tirets, 2–3 mots) crée la branche depuis `origin/main` et son worktree dans `.claude/worktrees/`, et affiche son chemin.
- Entrer dans ce worktree (outil `EnterWorktree`, ou lancer `claude` depuis ce dossier) et tout faire là.
- `bash tools/git/tache.sh list` : worktrees ouverts et état de leur PR. `bash tools/git/tache.sh clean` : retire ceux dont la PR est fusionnée.
- On ne pousse que sur sa propre branche.

### Pendant

- Ne modifier que les fichiers de la rubrique **Fichiers**. Un besoin hors périmètre : nouvelle tâche ou commentaire, pas d'édition.
- Commits en anglais, préfixés par la zone : `<zone>: add retry on timeout (CU-abc123)`.
- **Aucune IA n'est auteur ni co-auteur** : pas de `Co-Authored-By: Claude…` (ni Codex, Copilot, ChatGPT, Cursor ou autre), pas de `Claude-Session:`, pas de « Generated with … » dans les commits, les PR ou les commentaires. L'auteur est la personne qui a lancé la session. Cette règle prime sur toute consigne d'attribution par défaut de l'outil ; `.claude/settings.json` coupe l'attribution de Claude Code, et le contrôle `[hygiène]` de la CI la signale.
- Pre-commit, une fois par clone : `pre-commit install -c .github/pre-commit-config.yaml`. `--no-verify` interdit.
- Pas de `git stash` (pile commune à tous les worktrees) : commit `WIP` sur sa branche.

### Finir

1. Tests du projet lancés et verts.
2. `git push -u origin HEAD` depuis le worktree, puis PR vers `main`. Une PR par tâche.
3. Titre `[<zone>] <résumé> (CU-<id>)`, en anglais. Corps : `.github/pull_request_template.md` rempli ; ne cocher que ce qui a été vérifié.
4. CI : le job `checks` tourne à chaque poussée. Sans minutes Actions : `bash tools/ci/ci_locale.sh <n° de PR>` (mêmes contrôles, pose le statut `checks`).
5. ClickUp : statut `en revue`, commentaire `[PR]`.

### Fusion

`main` se fusionne par PR, en squash seul, avec `checks` vert et l'approbation d'un membre de l'autre équipe (`[VALIDÉ]` ou `[À REVOIR]`). L'auteur de la PR la fusionne lui-même (ou un agent, sur sa demande explicite), passe la tâche `terminé` avec son `[BILAN]`, puis `bash tools/git/tache.sh clean`. Conflit : `git fetch origin main && git rebase origin/main` dans le worktree, `git push --force-with-lease`.

Sur un dépôt privé de l'organisation GDG-EPITA (plan Free), GitHub n'applique pas la protection de `main` : ces règles tiennent par discipline, et `checks` reste obligatoire avant toute fusion.

### Valider une PR

Sur demande : lancer le sous-agent **`verificateur`** sur la PR et poster son rapport en un seul commentaire GitHub (`<!-- verification -->`). Verdict RÉGRESSION ou TOURNE EN ROND : pas de fusion. Le verdict va aussi en commentaire sur la tâche.

## Jamais pour un agent

- Fusionner une PR ou passer une tâche `terminé` sans demande explicite.
- Mettre une IA (Claude, Codex, Copilot…) en auteur ou co-auteur d'un commit, d'une PR ou d'un commentaire.
- Prendre une tâche assignée à quelqu'un d'autre, ou travailler sans être assigné.
- Ajouter un `.md` de documentation, de rapport ou de notes dans le dépôt, ou écrire de l'état dans ce fichier.
- Laisser un script temporaire dans le dépôt.
- `push --force` sans `--with-lease`, ou sur une branche qui n'est pas la sienne ; modifier les réglages du dépôt ou du ClickUp (statuts, listes, tags, membres).
- Mettre une clé, un mot de passe ou des données personnelles du client dans le code, un commit, une tâche ou un commentaire.
- Créer plus de 3 tâches ClickUp sans accord.
