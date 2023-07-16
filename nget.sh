# Overwrites *.* files from a NAS to /home/pi/ when they are newer and
# a new version of version.fbin exist.
# Depends on cifs-utils
# In case of error: 
# mount: wrong fs type, bad option, bad superblock on...
# Install cifs-utils with: sudo apt-get install cifs-utils

cd $home
echo ======= nget.sh =======
date

NASSYS=/mnt/nas
TARGET=/home/pi

  if [ ! -d "$NAS" ]   # /mnt/nas will be created when it does not exist
  then
    echo Create $NAS
    sudo mkdir -p "$NASSYS"
    sudo chmod 777 "$NASSYS"
  else echo $NASSYS found
fi

. /home/pi/Documents/pw.sh
echo $USR

  if [ -z "$USR" ]
  then
  echo "ERROR: \$USR and \$PW and \$MOUNTING must filled in Documents/pw.sh"
  fi

echo .
sudo mount -t cifs $MOUNTING $NASSYS  -o username=$USR,password=$PW # Needs to be adapted to your NAS !!!

  if df -T | grep -q $MOUNTING
  then

NAS=$NASSYS/nas

ls $NAS/*.fbin


echo .
echo Updating: 
    sudo rsync -t -v -p -E -X --modify-window=1 $NAS/*.* $TARGET/  # skips older files

  if [ ! -f $TARGET/ip_table.fbin ]
  then
      cp -u $TARGET/ip_table.fbin $TARGET/ip_table.bin
  fi


echo "$(hostname) done."
sudo umount -l $NASSYS
sudo chmod 777  /home/pi/*.*

  else
echo ERROR: Mounting $MOUNTING FAILED. No updates. Device offline?
  fi
