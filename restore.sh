#!/bin/bash

# Set the directory where backups are stored
BACKUP_DIR=/home/backup

# Set the database name, username, and password
DATABASE_NAME=duwit
DATABASE_USER=duwit
DATABASE_PASSWORD=g3Nd3LJckbYgH8MZ

# Set the host and port of the PostgreSQL server
REMOTE_SERVER=172.30.0.19
REMOTE_PORT=22

# create logs folder
if [ ! -d $BACKUP_DIR/log/ ]; then
  mkdir -p $BACKUP_DIR/log/
fi

# create logs file
LOG_FILE=$BACKUP_DIR/log/restore-$(date +%Y-%m-%d_%H-%M-%S).log
if [ ! -f "$LOG_FILE" ]; then
    touch $LOG_FILE
fi

# check if the backup file exists
BACKUP_FILE=$BACKUP_DIR/full/full_2023-01-17_04-13-35.tar

if [ ! -f $BACKUP_FILE ]; then
    echo "Backup file not found at $BACKUP_FILE, please check your backup location and try again" >> $LOG_FILE
    exit 1
fi

# terminate connection to database
sudo -u postgres psql -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DATABASE_NAME' AND pid <> pg_backend_pid();" >> $LOG_FILE

# drop the existing database
sudo -u postgres PGPASSWORD=$DATABASE_PASSWORD dropdb -h $DB_HOST -U $DATABASE_USER $DATABASE_NAME >> $LOG_FILE
 
# create a new database with the same name
sudo -u postgres PGPASSWORD=$DATABASE_PASSWORD createdb -h $DB_HOST -U $DATABASE_USER $DATABASE_NAME >> $LOG_FILE

# create restore folder
if [ ! -d $BACKUP_DIR/restore ]; then
  mkdir -p $BACKUP_DIR/restore
fi

# Extract the backup file
tar -xvf $BACKUP_FILE -C $BACKUP_DIR/restore 2>> $LOG_FILE

# check if extraction success
if [ $? -eq 0 ]; then
    echo "Extraction success at $(date +%Y-%m-%d_%H-%M-%S)" >> $LOG_FILE
else
    echo "Extraction failed at $(date +%Y-%m-%d_%H-%M-%S)" >> $LOG_FILE
    exit 1
fi

# find the latest backup file
LATEST_BACKUP_FILE=$(ls -t $BACKUP_DIR/restore/ | grep '.dat' | head -n 1)

# import data from backup file
PGPASSWORD=$DATABASE_PASSWORD psql -h $DB_HOST -U $DATABASE_USER $DATABASE_NAME < $BACKUP_DIR/restore/$LATEST_BACKUP_FILE 2>> $LOG_FILE

# import sql from restore.sql
PGPASSWORD=$DATABASE_PASSWORD psql -h $DB_HOST -U $DATABASE_USER $DATABASE_NAME < $BACKUP_DIR/restore/restore.sql 2>> $LOG_FILE

# check if restore success
if [ $? -eq 0 ]; then
    echo "Restore success at $(date +%Y-%m-%d_%H-%M-%S)" >> $LOG_FILE
else
    echo "Restore failed at $(date +%Y-%m-%d_%H-%M-%S)" >> $LOG_FILE
fi