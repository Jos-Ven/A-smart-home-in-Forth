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

NAS=$NASSYS/nas

ls $NAS/_*

sudo rsync -t -v -p -E -X  --modify-window=1 avsampler.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 AxaLinbus.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 Connect_Axa_to_Rpi.jpg   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 LightSensor_TSL2561_on_Rpi_A+.JPG  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 resetbutton.fs   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 tsl2561.fs $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 tsl2561_h.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 WindowWeb2.fs $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 _WindowWeb1.fs   $NAS/


ls -l $NAS/*

echo "$(hostname) done."
sudo umount -l $NASSYS
#
