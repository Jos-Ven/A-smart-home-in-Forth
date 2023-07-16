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

sudo rsync -t -v -p -E -X  --modify-window=1 administrator-work-svgrepo-com.svg  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 avsampler.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 bme280-logger.fs    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 bme280-output.fs    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 bme280.fs   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 bsearch.f   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 CentralHeating.fs   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 Connect_ SNS-MQ135_to_MCP3008.jpg   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 Connect_Bme280_on_I2c.jpg   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 Connect_ldr_to_MCP3008.jpg  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 document-svgrepo-com.svg    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 DynamicPage.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 ldr.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 light-bulb-svgrepo-com.svg  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 linux-svgrepo-com.svg $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 mcp3008.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 mq135.fs    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 redit.fs    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 resetbutton.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 SensorWeb.rtf $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 SensorWeb2.fs $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 SitesIndex.fs $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 sound-system-svgrepo-com.svg  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 svg_plotter.f $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 thermometer-svgrepo-com.svg   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 thermostat-svgrepo-com.svg  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 Wifi_signal.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 window-svgrepo-com.svg  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1 _SensorWeb1.fs  $NAS/


ls -l $NAS/*

echo "$(hostname) done."
sudo umount -l $NASSYS
#
