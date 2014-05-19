#!/bin/bash
### Запускать из под root ##############
### описание переменных ################
### на хост не добавлялись ключи нужно##
### скопировать их ssh-id-copy #########
dbuser=""
dbpass=""
dhost_ip=""
backupuser=""
### dblist ###############################
dblist="$(mysqlshow -u $dbuser -p$dbpass)"
### check bckp folder ####################
ssh root@$dhost_ip -C "[ -d /home/$backupuser/bckp ] || mkdir -p /home/$backupuser/bckp" 
### clean bckp folder from old backups ###
ssh root@$dhost_ip -C rm -f /home/$backupuser/bckp/*
### backup ###############################
echo "$dblist" | sed -e '1,3d' | sed -e '$d' | sed -e '/information_schema/d' | awk {'print$2'} > dblist.txt 
cat dblist.txt | while read line; do mysqldump --single-transaction -u $dbuser  -p$dbpass $line |  gzip -c |   ssh root@$dhost_ip  "cat > /home/$backupuser/bckp/$line- `date +%Y-%m-%d_%H-%M-%S`.sql.gz" ; done;
### unpack bck ###########################
ssh root@$dhost_ip -C "cd /home/$backupuser/bckp && gunzip"
### restore on dhost #####################
cat db.txt | while read line ; do ssh root@$dhost_ip -C "mysqladmin -u $dbuser -p$dbpass drop -f $line;  mysqladmin -u $dbuser -p$dbpass create $line ; mysql -u $dbuser -p$dbpass  $line < $line-* ;" ;  done;
### static content #######################
scp /var/www  root@$dhost_ip:/var/ && echo "succesfully backup www on"`date +%Y-%m-%d_%H-%M-%S` >> /var/log/backup.log
ssh root@$dhost_ip -C chown -R www-data:www-data /var/www
##########################################
