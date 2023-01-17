#!/bin/bash

# Set the directory where backups will be stored
BACKUP_DIR=/home/backup

# Set the database name, username, and password
DATABASE_NAME=duwit
DATABASE_USER=duwit
DATABASE_PASSWORD=g3Nd3LJckbYgH8MZ

# Set the hostname and port of the remote server
REMOTE_SERVER=172.30.0.19
REMOTE_PORT=22

# Set the host and port of the PostgreSQL server
DB_HOST=localhost
DB_PORT=5432

# Set the username and directory on the remote server
REMOTE_USER=clouduser
REMOTE_DIR=/home/backup

# Get the current date and time
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# create logs folder
if [ ! -d $BACKUP_DIR/log/ ]; then
  mkdir -p $BACKUP_DIR/log/
fi

# create logs file
LOG_FILE=$BACKUP_DIR/log/backup-$DATE.log
if [ ! -f "$LOG_FILE" ]; then
    touch $LOG_FILE
fi

# create full backup directory
FULL_DIR=$BACKUP_DIR/full
if [ ! -d $FULL_DIR ]; then
  mkdir -p $FULL_DIR
fi

# create incremental backup directory
INC_DIR=$BACKUP_DIR/inc
if [ ! -d $INC_DIR ]; then
  mkdir -p $INC_DIR
fi

# Create a full backup of the database
pg_dump --dbname="postgresql://$DATABASE_USER:$DATABASE_PASSWORD@$DB_HOST:$DB_PORT/$DATABASE_NAME" -F t -f $FULL_DIR/full_$DATE.tar 2>> $LOG_FILE

# check if backup success
if [ $? -eq 0 ]; then
    echo "Full Backup Success at $DATE" >> $LOG_FILE
    # send the backup to remote server
    scp -P $REMOTE_PORT $FULL_DIR/full_$DATE.tar $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/full/ 2>> $LOG_FILE
    # check if file transfer success
    if [ $? -eq 0 ]; then
        echo "Full Backup file transfer success at $DATE" >> $LOG_FILE
        # rm $FULL_DIR/full_$DATE.tar
    else
        echo "Full Backup file transfer failed at $DATE" >> $LOG_FILE
    fi
else
    echo "Full Backup failed at $DATE" >> $LOG_FILE
fi

# Create an incremental backup of the database
pg_dump --dbname="postgresql://$DATABASE_USER:$DATABASE_PASSWORD@$DB_HOST:$DB_PORT/$DATABASE_NAME" -F t -f $INC_DIR/incremental_$DATE.tar 2>> $LOG_FILE

# check if backup success
if [ $? -eq 0 ]; then
    echo "Incremental Backup Success at $DATE" >> $LOG_FILE
    # send the backup to remote server
    scp -P $REMOTE_PORT $INC_DIR/incremental_$DATE.tar $REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR/inc/ 2>> $LOG_FILE
    # check if file transfer success
    if [ $? -eq 0 ]; then
        echo "Incremental Backup file transfer success at $DATE" >> $LOG_FILE
        # rm $INC_DIR/incremental_$DATE.tar
    else
        echo "Incremental Backup file transfer failed at $DATE" >> $LOG_FILE
    fi
else
    echo "Incremental Backup failed at $DATE" >> $LOG_FILE
fi