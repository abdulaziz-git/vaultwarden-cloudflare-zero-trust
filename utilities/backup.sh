#!/usr/bin/env ash

# vaultwarden backup script for docker
# Copyright (C) 2021 Bradford Law
# Licensed under the terms of MIT

LOG=/var/log/backup.log

# Initialize rclone
RCLONE=/usr/bin/rclone
rclone_init() {
  # Install rclone - https://wiki.alpinelinux.org/wiki/Rclone
  curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
  unzip rclone-current-linux-amd64.zip
  cd rclone-*-linux-amd64
  cp rclone /usr/bin/
  chown root:root $RCLONE
  chmod 755 $RCLONE

  printf "Rclone installed to %b\n" "$RCLONE" > $LOG
}


# Create backup and prune old backups
# Borrowed heavily from https://github.com/shivpatel/bitwarden_rs-local-backup
# with the addition of backing up:
# * attachments directory
# * sends directory
# * icon_cache directory
# * config.json
# * rclone.conf
# * rsa_key* files
make_backup() {
  # use sqlite3 to create backup (avoids corruption if db write in progress)
  SQL_NAME="db.sqlite3"
  SQL_BACKUP_DIR="/tmp"
  SQL_BACKUP_NAME=$SQL_BACKUP_DIR/$SQL_NAME
  sqlite3 /data/$SQL_NAME ".backup '$SQL_BACKUP_NAME'"

  # build a string of files and directories to back up
  DATA="/data"
  cd $DATA
  FILES=""
  FILES="$FILES $([ -d attachments ] && echo attachments)"
  FILES="$FILES $([ -d sends ] && echo sends)"
  FILES="$FILES $([ -d icon_cache ] && echo icon_cache)"
  FILES="$FILES $([ -f config.json ] && echo config*)"
  FILES="$FILES $([ -f rclone.conf ] && echo rclone*)"
  FILES="$FILES $([ -f rsa_key.der -o -f rsa_key.pem -o -f rsa_key.pub.der ] && echo rsa_key*)"

  # tar up files and encrypt with openssl and encryption key
  BACKUP_DIR=$DATA/backups
  BACKUP_FILE=$BACKUP_DIR/"vaultwarden_backup_$(date "+%F-%H%M%S").tar.gz"

  # If a password is provided, run it through openssl
  if [ -n "$BACKUP_ENCRYPTION_KEY" ]; then
    BACKUP_FILE=$BACKUP_FILE.aes256
    tar -czf - -C $SQL_BACKUP_DIR $SQL_NAME -C $DATA $FILES | openssl enc -e -aes256 -salt -pbkdf2 -pass pass:${BACKUP_ENCRYPTION_KEY} -out $BACKUP_FILE
  else
    tar -czf $BACKUP_FILE -C $SQL_BACKUP_DIR $SQL_NAME -C $DATA $FILES
  fi
  printf "Backup file created at %b\n" "$BACKUP_FILE" > $LOG

  # cleanup tmp folder
  rm -f $SQL_BACKUP_NAME

  # rm any backups older than 30 days
  find $BACKUP_DIR/* -mtime +$BACKUP_DAYS -exec rm {} \;
  
  printf "$BACKUP_FILE"
}


##############################################################################################

# Initialize rclone and if $(which rclone) is blank
if [ -z "$(which rclone)" ]; then
  rclone_init
fi 

# Handle rclone Backup
printf "Running rclone backup\n" > $LOG
  
# Only run if $BACKUP_RCLONE_CONF has been setup
if [ -s "$BACKUP_RCLONE_CONF" ]; then
  RESULT=$(make_backup)

  # Sync with rclone
  REMOTE=$(rclone --config $BACKUP_RCLONE_CONF listremotes | head -n 1)
  rclone --config $BACKUP_RCLONE_CONF sync $BACKUP_DIR $REMOTE$BACKUP_RCLONE_DEST

fi
