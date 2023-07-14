# Overwrites   nupdate.sh  and  *.f*   files on a NAS when they are older.
# 0*.f* files are excluded.
# Depends on cifs-utils
# In case of: mount: wrong fs type, bad option, bad superblock on //192.168.0.1/volume1,
# Install cifs-utils with: sudo apt-get install cifs-utils
echo  ======= npush.sh =======
date
sudo chmod 777 *.f*

NASSYS=/mnt/nas


  if [ ! -d "$NAS" ]        # /mnt/nas will be created when it does not exist
  then
    echo Create $NASSYS
    sudo mkdir -p "$NASSYS"
    sudo chmod 777 "$NASSYS"
fi

echo $NASSYS

. Documents/pw.sh        # To fill $USR and $PW and $MOUNTING 
echo .

echo $USR
  if [ -z "$USR" ]
  then
  echo "ERROR: \$USR and \$PW and \$MOUNTING must filled in Documents/pw.sh"
  fi

sudo mount -t cifs $MOUNTING $NASSYS  -o username=$USR,password=$PW   # Perhaps to be adapted to your NAS !!!
  if df -T | grep -q $MOUNTING
  then

NAS=$NASSYS/nas

echo .
echo  updates:
sudo rsync -t -v -A -p -E -X  --modify-window=1 *.f*  --exclude="0*.f*" $NAS # skips older files
sudo rsync -t -v -A -p -E -X  --modify-window=1 nupdate.sh $NAS # skips older versions of nupdate.sh


echo "$(hostname) done. `ls -1 $NAS | wc -l` files on Nas."

sudo umount -l $NASSYS 

  else

echo ERROR: Mounting $MOUNTING FAILED. No updates. Device offline?
  fi
