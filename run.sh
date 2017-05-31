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

source ./vars/global

# check OS
if [[ $OS == *"Ubuntu"* ]]
then
  source ./vars/ubuntu
elif [[ $OS == *"Darwin"* ]]
then
  source ./vars/darwin
fi

showHelp()
{
  echo "Usage: sudo ./run.sh [-help] | [-create <sitename.com>] | [-delete <sitename.com>] [-y <confirm delete>]"
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
  echo "==> The site does not exist, create : ${SITEPATH}..."
  mkdir -m $PERMISSIONS $SITEPATH
  mkdir -m $PERMISSIONS "${HTTPDOCS_FOLDER}"
  mkdir -m $PERMISSIONS "${SITEPATH}/logs"
  echo "==> Site folder ${SITEPATH} created successfully..."
  echo "***********************************"
}

createDB()
{
  mysql -u"${USER_DB}" -p"${PASS_DB}" -e "CREATE DATABASE ${NAME_DB}"
}

deleteDB()
{
  mysql -u"${USER_DB}" -p"${PASS_DB}" -e "DROP DATABASE ${NAME_DB}"
}

backupHosts()
{
  if cp $HOSTS ${HOSTS}.bkp
  then
    echo "==> Backup file ${HOSTS}.bkp created..."
    echo "127.0.0.1 ${SITE_NAME} www.${SITE_NAME}" >> ${HOSTS}
    echo "==> File ${HOSTS} modified..."
    echo "***********************************"
  else
    echo "==> Error, file $HOSTS unmodified!"
    echo "***********************************"
    exit 1
  fi
}

crateVHostFileUbuntu()
{
  if [ ! -f $VHOSTSFILE ]
  then
    source ./vhosts/ubuntu
    echo "==> File $VHOSTSFILE created..."
    echo "***********************************"
  else
    echo "==> Error, file $VHOSTSFILE not created!"
    echo "***********************************"
    exit 1
  fi
}

downloadWP()
{
  echo "==> Download ${ZIP_NAME} start..."
  wget $WORDPRESS_LASTEST 2>&1 -P $HTTPDOCS_FOLDER --show-progress
  echo "==> Complete download ${ZIP_NAME}"
  echo "***********************************"
}

createWPConfig()
{
  # https://gist.github.com/bgallagh3r/2853221
  #create wp config
  cp "${WP_CONFIG_SAMPLE}" "${WP_CONFIG}"
  #set database details with perl find and replace
  perl -pi -e "s/database_name_here/${NAME_DB}/g" "${WP_CONFIG}"
  perl -pi -e "s/username_here/${USER_DB}/g" "${WP_CONFIG}"
  perl -pi -e "s/password_here/${PASS_DB}/g" "${WP_CONFIG}"

  #set WP salts
  perl -i -pe'
    BEGIN {
      @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
      push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
      sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/put your unique phrase here/salt()/ge
  ' "${WP_CONFIG}"
}

commandsCreateUbuntu()
{
  echo "==> Enabled ${HTTPDOCS_FOLDER}..."
  a2ensite $VHOSTFILE_CONF
  echo "==> Reload apache..."
  service apache2 reload
}

commandsCreate()
{
  echo "==> Unzip file..."
  unzip "${HTTPDOCS_FOLDER}/${ZIP_NAME}" "wordpress/*" -d ${HTTPDOCS_FOLDER}
  echo "==> Copy to ${HTTPDOCS_FOLDER}..."
  cp -a "${HTTPDOCS_FOLDER}/wordpress/." "${HTTPDOCS_FOLDER}"
  echo "==> Delete ${HTTPDOCS_FOLDER}/wordpress and ${ZIP_NAME}..."
  rm -r "${HTTPDOCS_FOLDER}/wordpress/"
  rm "${HTTPDOCS_FOLDER}/${ZIP_NAME}"
  echo "==> Create database ${SITE_NAME}..."
  createDB
  echo "==> Create wp-config.php..."
  createWPConfig
  chmod -R ${PERMISSIONS} ${HTTPDOCS_FOLDER}

  if [[ "$IS_OS" = "Ubuntu" ]]
  then
    commandsCreateUbuntu
  fi

  echo ""
  echo "====> FIM <===="
  echo "***********************************"
}

commandsDeleteUbuntu()
{
  echo "==> Delete $VHOSTSFILE..."
  rm $VHOSTSFILE
  echo "==> Delete $VHOSTSFILE_EN..."
  rm $VHOSTSFILE_EN
  echo "==> Delete ${SITE_NAME} from ${HOSTS}..."
  sed -i "/127.0.0.1 ${SITE_NAME} www.${SITE_NAME}/d" $HOSTS
  rm -r $SITEPATH
  echo "==> Delete database ${SITE_NAME}..."
  deleteDB
  echo "==> The ${SITE_NAME} configuration has been completely deleted"
  echo ""
  echo "====> FIM <===="
  echo "***********************************"
}

commandsDeleteDarwin()
{
  # criar um delete comum
  echo "==> Delete ${SITE_NAME} from ${HOSTS}..."
  sed -i "/127.0.0.1 ${SITE_NAME} www.${SITE_NAME}/d" $HOSTS
  echo "==> Delete ${SITE_NAME} from ${VHOSTSFILE}..."
  sed -n '1h;1!H;${;g;s/#start_${SITE_NAME}.*#end_${SITE_NAME}//g;p;}' $VHOSTSFILE > $VHOSTSFILE
  rm -r $SITEPATH
  echo "==> Delete database ${SITE_NAME}..."
  deleteDB
  echo "==> The ${SITE_NAME} configuration has been completely deleted"
  echo ""
  echo "====> FIM <===="
  echo "***********************************"
}

confirmDelete()
{
  if [[ "$YES_DELETE" = "-y" ]]
  then
    commandsDelete
  else
    read -p "Delete project? [y]/[n]: " YES_OR_NO
    if [[ "$YES_OR_NO" = "y" ]]
    then
      commandsDelete
    else
      exit 1
    fi
  fi
}

commandsDelete()
{
  if [[ "$SITE_NAME" = "" ]]
  then
    echo "==> Insert the name project first!"
    echo "***********************************"
    exit 1
  else
    if [[ "$IS_OS" = "Ubuntu" ]]
    then
      commandsDeleteUbuntu
    elif [[ "$IS_OS" = "Darwin" ]]
    then
      commandsDeleteDarwin
    fi
  fi
}

# criar init pra cada os
initCreate()
{
  checkSiteFolder
  backupHosts
  if [[ "$IS_OS" = "Ubuntu" ]]
  then
    crateVHostFileUbuntu
  elif [[ "$IS_OS" = "Darwin" ]]
  then
    commandsDeleteDarwin
  fi
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
  confirmDelete
else
  echo "==> For show help : sudo ./run.sh -help"
  echo "***********************************"
  exit 1
fi
