#!/bin/bash
# update_group_sync_emails.sh
# Script pour mettre à jour la liste des emails group_sync
#
# Usage:
#   ./update_group_sync_emails.sh
#
# Prérequis: gh CLI installé et authentifié (gh auth login)

set -e

REPO="StellaSecret/GameTracker"
SECRET_NAME="GROUP_SYNC_EMAILS"
LIST_FILE=".group_sync_emails.txt"

echo "=== Mise à jour des emails group_sync ==="
echo ""

# Affiche la liste actuelle (fichier local)
if [ -f "$LIST_FILE" ]; then
  echo "Liste actuelle :"
  cat -n "$LIST_FILE"
  echo ""
else
  echo "Aucune liste locale trouvée. Création..."
  touch "$LIST_FILE"
fi

echo "Édition de la liste (un email par ligne) :"
echo "Appuie sur Ctrl+X pour sauvegarder dans nano"
echo ""
sleep 1
vim "$LIST_FILE"

# Convertit en une seule ligne séparée par des virgules, lowercase, sans espaces
EMAILS=$(grep -v '^#' "$LIST_FILE" | grep -v '^$' | tr '[:upper:]' '[:lower:]' | tr -d ' ' | paste -sd ',' -)

if [ -z "$EMAILS" ]; then
  echo "❌ Liste vide, annulation."
  exit 1
fi

echo ""
echo "Emails qui seront enregistrés :"
echo "$EMAILS" | tr ',' '\n' | nl
echo ""

read -p "Confirmer la mise à jour du secret GitHub ? (o/N) " confirm
if [[ "$confirm" != "o" && "$confirm" != "O" ]]; then
  echo "Annulé."
  exit 0
fi

# Met à jour le secret GitHub
gh secret set "$SECRET_NAME" --body "$EMAILS" --repo "$REPO"

echo ""
echo "✓ Secret '$SECRET_NAME' mis à jour sur $REPO"
echo "✓ Liste locale sauvegardée dans $LIST_FILE"
echo ""
echo "⚠️  Pense à commiter .group_sync_emails.txt si tu veux garder l'historique"
echo "   (le fichier contient les emails en clair — repo privé recommandé,"
echo "    ou ajoute-le dans .gitignore si repo public)"
