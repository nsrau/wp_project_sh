#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]
then
  echo " "
  echo "==> This script must be run as root" 1>&2
  echo "***********************************"
  exit 1
fi

echo " "
echo "###################################"
echo "# WP bash project                 #"
echo "# Create or delete                #"
echo "###################################"
echo " "

# possible templates vhosts, os/template
# if OS === OS_NAME => os_name.sh
# check inject args to another sh file

source ./vars/global

# check OS
if [[ $OS == *"Ubuntu"* ]]
then
  source ./vars/ubuntu
elif [[ $OS == *"darwin"* ]]
then
  source ./vars/darwin
fi

showHelp()
{
  echo "Usage: run.sh [-help] [-create <sitename.com>] [-delete <sitename.com>] [-y <confirm delete>]"
  echo
  echo "Options"
  echo "  -help, --h"
  echo "    Show this information"
  echo "  -create, --c sitename.com"
  echo "    Create new wordpress project sitename.com"
  echo "  -delete, --d sitename.com"
  echo "    Complete delete wordpress project sitename.com"
}

checkSiteFolder()
{
  if [ ! -d $SITEPATH ]
  then
    createFolder
  else
    echo "==> The site already exists!"
    echo "***********************************"
    exit 1
  fi
}

createFolder()
{
  echo "==> The site does not exist, create : ${SITEPATH}"
  mkdir -m $PERMISSIONS $SITEPATH
  mkdir -m $PERMISSIONS "${HTTPDOCS_FOLDER}"
  mkdir -m $PERMISSIONS "${SITEPATH}/logs"
  echo "site folder ${SITEPATH} created successfully..."
  echo "***********************************"
}

backupHosts()
{
  if cp $HOSTS ${HOSTS}.bkp
  then
    echo "==> Backup file ${HOSTS}.original created..."
    echo "127.0.0.1 ${SITE_NAME} www.${SITE_NAME}" >> ${HOSTS}
    echo "File ${HOSTS} modified..."
    echo "***********************************"
  else
    echo "Error, file $HOSTS unmodified!"
    echo "***********************************"
    exit 1
  fi
}

crateVHostFile()
{
  if [ ! -f $VHOSTSFILE ]
  then
    source ./vhosts/ubuntu
    echo "File $VHOSTSFILE created..."
    echo "***********************************"
  else
    echo "Error, file $VHOSTSFILE not created!"
    echo "***********************************"
    exit 1
  fi
}

downloadWP()
{
  echo "==> Download ${ZIP_NAME} start..."
  wget $WORDPRESS_LASTEST 2>&1 -P $HTTPDOCS_FOLDER --show-progress
  echo "Complete download ${ZIP_NAME}"
  echo "***********************************"
}

commandsCreateUbuntu()
{
  a2ensite $VHOSTFILE_CONF
  service apache2 restart
}

commandsCreate()
{
  unzip "${HTTPDOCS_FOLDER}/${ZIP_NAME}" "wordpress/*" -d ${HTTPDOCS_FOLDER}
  cp -a "${HTTPDOCS_FOLDER}/wordpress/." "${HTTPDOCS_FOLDER}"
  rm -r "${HTTPDOCS_FOLDER}/wordpress/"
  rm "${HTTPDOCS_FOLDER}/${ZIP_NAME}"
  if [ "$OS" = "Ubuntu" ]
  then
    commandsCreateUbuntu
  fi
  # create db, parse _  - delete db
  # mysql -u $USER_DB -p $PASS_DB -e "create database ${SITE_NAME}"
  echo ""
  echo "====> FIM <===="
  echo "***********************************"
}

commandsDeleteUbuntu()
{
  rm $VHOSTSFILE
  rm $VHOSTSFILE_EN
  sed -i "/127.0.0.1 ${SITE_NAME} www.${SITE_NAME}/d" $HOSTS
}

commandsDeleteDarwin()
{
  sed -n '1h;1!H;${;g;s/#start_${SITE_NAME}.*#end_${SITE_NAME}//g;p;}' $VHOSTSFILE > $VHOSTSFILE
}

confirmDelete()
{
  read -p "Delete project? [y]/[n]" YES_OR_NO
  if [ "$YES_OR_NO" = "n" ]
  then
    exit 1
  fi
}

commandsDelete()
{
  if [ "$SITE_NAME" = "" ]
  then
    echo "==> Insert the name project first!"
    echo "***********************************"
    exit 1
  else

    if [[ "$3" = "" ]]
    then
      confirmDelete
    else
      if [[ "$OS" = "Ubuntu" ]]
      then
        commandsDeleteUbuntu
      elif [[ "$OS" = "Darwin" ]] 
      then
        commandsDeleteDarwin
      fi
    fi

    rm -r $SITEPATH

    echo "==> The ${SITE_NAME} configuration has been completely deleted"
    echo ""
    echo "====> FIM <===="
    echo "***********************************"
  fi

}

initCreate()
{
  checkSiteFolder
  backupHosts
  crateVHostFile
  downloadWP
  commandsCreate
}

initDelete()
{
  commandsDelete
}

# check args script
if [[ "$1" = "-help" || "$1" = "--h" ]]
then
  showHelp
elif [[ "$1" = "-create" || "$1" = "--c" ]]
then
  initCreate
elif [[ "$1" = "-delete" || "$1" = "--d" ]]
then
  initDelete
else
  echo "==> Insert -create or -delete options!"
  echo "***********************************"
fi
