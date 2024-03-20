#!/bin/bash

# Initialisation des variables
REMOTE_DIR=""
LOCAL_SAVE_PATH="."
REMOTE_HOST=""
SSH_USER=""
SSH_PORT="22" # Valeur par défaut pour SSH
USE_SUDO=false

# Lecture des options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--directory) REMOTE_DIR="$2"; shift ;;
        -l|--local) LOCAL_SAVE_PATH="$2"; shift ;;
        -h|--host) REMOTE_HOST="$2"; shift ;;
        -u|--user) SSH_USER="$2"; shift ;;
        -p|--port) SSH_PORT="$2"; shift ;;
        --sudo) USE_SUDO=true ;;
        --help) 
            echo "Usage: $0 --directory <remote_directory> --local <local_save_path> --host <remote_host> [--user <user> --port <port> --sudo]"
            exit 0 ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1 ;;
    esac
    shift
done

# Vérification des arguments obligatoires
if [ -z "$REMOTE_DIR" ] || [ -z "$REMOTE_HOST" ]; then
    echo "Les options --directory et --host sont obligatoires."
    exit 1
fi

# Construction de la commande SSH
SSH_CMD="ssh"
if [ -n "$SSH_USER" ]; then
  SSH_CMD="$SSH_CMD -l $SSH_USER"
fi
SSH_CMD="$SSH_CMD -p $SSH_PORT $REMOTE_HOST"

# Nom de l'archive basé sur le dossier et la date
ARCHIVE_NAME="$(basename "$REMOTE_DIR")_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"
REMOTE_ARCHIVE_PATH="/tmp/$ARCHIVE_NAME"

# Commande de création d'archive
CREATE_ARCHIVE_CMD="tar -czf $REMOTE_ARCHIVE_PATH -C $(dirname "$REMOTE_DIR") $(basename "$REMOTE_DIR")"
if [ "$USE_SUDO" = true ]; then
    CREATE_ARCHIVE_CMD="sudo $CREATE_ARCHIVE_CMD && sudo chmod 744 $REMOTE_ARCHIVE_PATH"
fi

# Exécution des commandes sur le serveur distant
$SSH_CMD "$CREATE_ARCHIVE_CMD"

# Téléchargement de l'archive
scp -P $SSH_PORT $SSH_USER@$REMOTE_HOST:$REMOTE_ARCHIVE_PATH $LOCAL_SAVE_PATH

# Suppression de l'archive sur le serveur distant
$SSH_CMD "sudo rm $REMOTE_ARCHIVE_PATH"

echo "Archive téléchargée dans $LOCAL_SAVE_PATH/$ARCHIVE_NAME"
