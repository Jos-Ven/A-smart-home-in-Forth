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

sudo rsync -t -v -p -E -X  --modify-window=1     auto.sh $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     drop_caches.sh  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     autogen_ip_table.fs     $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     calencal.f      $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     Common-extensions.f     $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     Config.f        $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     down.sh $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     favicon.ico     $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     FileLister.f    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     gf.sh   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     gpio.fs $NAS/
# sudo rsync -t -v -p -E -X  --modify-window=1     InstallationGuide44.rtf $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     itools.frt      $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     jd.f    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     kb.txt  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     kf.sh   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     LoadAvg.fs      $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     Master.fs       $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     mshell_r_v2.f   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     nget.sh $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     npush.sh        $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     ntptime.sh      $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     nupdate.sh      $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     schedule_daily.fs     $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     Server-controller.f     $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     SetVersionPage.fs       $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     sitelinks.fs    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     slave.fs        $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     Sun.f   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     TimeDiff.f      $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     upd.sh  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     upd_cleanup.sh  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     upd_gforth.sh   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     upd_os.sh       $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     upd_reboot.sh   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     upd_shutdown.sh $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     uptime.fs       $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     version.fbin    $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     Web-server-light.f      $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     webcontrols.f   $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     wiringPi.fs     $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     _demo1.f        $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     _DemoMaster.fs  $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     _down.fs        $NAS/
sudo rsync -t -v -p -E -X  --modify-window=1     _LightSwitch.fs $NAS/

ls -l $NAS/*

echo "$(hostname) done."
sudo umount -l $NASSYS
#
