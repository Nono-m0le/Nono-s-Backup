#!/bin/bash
# Auteur :      Nono @ blog.m0le.net
# Date :        06/02/2012
# Version :     1.0
# MaJ :         16/02/2012
 
#############
# Variables #
#############
 
# Une date est généré, pour avoir la date de début de processus de backup
date_start=`date +'%d/%m/%Y @ %H:%M:%S'`;
 
# Choix du format de la date utilisé pour les dossiers
format_date='%d%m%Y'
 
# Variable de date du jour, en fonction du format choisi
date=`date +${format_date}`;
 
# Le nombre de jour que vous souhaitez archiver
keepday="5";
 
# Calcul du nombre de jour, remontant à plus de "$keepday" jour(s)
keepdate=`date --date "-${keepday} days" +${format_date}`;
 
# Le répertoire de création du backup journalier
backup_dir='/home/archives/'${date};
 
# Le chemin du rapport (celui-ci sera gardé, et envoyé par mail)
rapport='/home/archives/rapport.log';
 
# Le mot de pass root de la base de donnée
sql_password='lepassdeladb';
 
# L'ip ou le hostname de votre serveur FTP
ftp_host='ftphost';
 
# L'utilisateur de votre serveur FTP
ftp_user='user';
 
# Le mot de passe de votre serveur FTP
ftp_pass='pass';
 
# L'adresse mail qui recevra le rapport
mail='mail@du_rapport.com';
 
##########
# Script #
##########
 
# Création du repertoire de backup + Initialisation du rapport
mkdir -p ${backup_dir};
echo 'Rapport du '${date_start} > ${rapport};
echo " " >> ${rapport};
 
# Les répertoires + exclusions des dossiers à archiver ...
# (à modifier à la main ... On peut pas tout avoir dans la vie)
# Syntaxe :
#     tar jcf le_nom_de_larchive.tar.bz2 --exclude='/le/repertoire/a/exclure' --exclude='/eventuellement/le/deuxieme/repertoire/a/exclure' /le/dossier/a/archiver/ 2>/dev/null
tar jcf ${backup_dir}/m0le.net-${date}-home-m0le.tar.bz2 --exclude='/home/m0le/ledossieraexclure1' --exclude='/home/m0le/ledossieraexclure2'  /home/m0le/ 2>/dev/null
tar jcf ${backup_dir}/m0le.net-${date}-home-blog.tar.bz2 --exclude='*.mp3' /home/blog/ 2>/dev/null
tar jcf ${backup_dir}/m0le.net-${date}-var-lib-mysql.tar.bz2 /var/lib/mysql/ 2>/dev/null
tar jcf ${backup_dir}/m0le.net-${date}-etc.tar.bz2 /etc 2>/dev/null
 
#Création du dump de la base de donnée avec mysqldump
mysqldump -u root --password=${sql_password} --all-databases | gzip -9 > ${backup_dir}/dump_${date}.sql.gz;
echo "Etat du dossier local :" >> ${rapport};
ls -lh ${backup_dir} -I rapport* >> ${rapport};
echo " " >> ${rapport};
 
# Envoie du dossier de sauvegarde vers le FTP
echo "Etat du dossier distant :" >> ${rapport};
lftp ftp://${ftp_user}:${ftp_pass}@${ftp_host} -e "mirror -R ${backup_dir} /${date} ; ls ${date} ; quit" >> ${rapport};
echo " " >> ${rapport};
 
# Suppresion du dossier en local
echo "Suppression du dossier local : ${backup_dir}" >> ${rapport};
rm -rf ${backup_dir};
echo " " >> ${rapport};
 
# Suppression du dossier distant de plus de "$keepday" jour(s)
echo "Suppression du dossier distant de plus de ${keepday} jours : ${keepdate}" >> ${rapport};
echo " " >> ${rapport};
 
# Copie de l'état des dossiers sur le FTP pour le rapport
echo "Etat du FTP :" >> ${rapport};
lftp ftp://${ftp_user}:${ftp_pass}@${ftp_host} -e "rm -rf ${keepdate} ;ls ; quit" >> ${rapport};
 
# Une date est généré, pour avoir la date de fin de processus de backup
date_end=`date +'%d/%m/%Y @ %H:%M:%S'`;
echo " " >> ${rapport};
 
#Finalisation du rapport + envoie par mail
echo 'Fini le '${date_end} >> ${rapport};
mail -s "Backup ${date}" ${mail} < ${rapport};
