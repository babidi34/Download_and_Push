#!/bin/bash

# Initialisation des variables
LOCAL_ARCHIVE_PATH=""
REMOTE_DIR=""
REMOTE_HOST=""
SSH_USER="$USER"
SSH_PORT="22" # Valeur par défaut pour SSH
USE_SUDO=false

# Lecture des options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -a|--archive) LOCAL_ARCHIVE_PATH="$2"; shift ;;
        -d|--destination) REMOTE_DIR="$2"; shift ;;
        -h|--host) REMOTE_HOST="$2"; shift ;;
        -u|--user) SSH_USER="$2"; shift ;;
        -p|--port) SSH_PORT="$2"; shift ;;
        --sudo) USE_SUDO=true ;;
        --help) echo "Usage: $0 --archive <local_archive_path> --destination <remote_directory> --host <remote_host> [--user <user> --port <port> --use-tmp]"; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Vérification des arguments obligatoires
if [ -z "$LOCAL_ARCHIVE_PATH" ] || [ -z "$REMOTE_DIR" ] || [ -z "$REMOTE_HOST" ]; then
    echo "Les options --archive, --destination, et --host sont obligatoires."
    exit 1
fi

REMOTE_ARCHIVE_PATH="$REMOTE_DIR/$(basename "$LOCAL_ARCHIVE_PATH")"
TMP_ARCHIVE_PATH="/tmp/$(basename "$LOCAL_ARCHIVE_PATH")"

if [ "$USE_SUDO" = true ]; then
    # Étape 1 : Transfert vers /tmp sur le serveur distant
    scp -P "$SSH_PORT" "$LOCAL_ARCHIVE_PATH" "${SSH_USER}@${REMOTE_HOST}:$TMP_ARCHIVE_PATH"
    # Étape 2 : Déplacer l'archive de /tmp vers le répertoire final avec sudo
    ssh -p "$SSH_PORT" "${SSH_USER}@${REMOTE_HOST}" "sudo mv $TMP_ARCHIVE_PATH $REMOTE_ARCHIVE_PATH"
else
    # Transfert direct vers le répertoire final
    scp -P "$SSH_PORT" "$LOCAL_ARCHIVE_PATH" "${SSH_USER}@${REMOTE_HOST}:$REMOTE_ARCHIVE_PATH"
fi

# Décompression de l'archive
ssh -p "$SSH_PORT" "${SSH_USER}@${REMOTE_HOST}" "cd $REMOTE_DIR && sudo tar -xzf $(basename "$REMOTE_ARCHIVE_PATH") && sudo rm $(basename "$REMOTE_ARCHIVE_PATH")"

echo "Archive transférée et extraite dans $REMOTE_DIR sur le serveur distant"
