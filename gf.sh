date

if [ "$(pidof gforth)" ]
then
  echo Killing a previous gforth-fast process
  sudo kill -9 $(ps aux | grep -e gforth| awk '{ print $2 }')
fi

cd /home/pi

 if [ -d "/tmp" ]
  then
         sudo rm -f /tmp/background.log
         echo yes   >/tmp/background.log
         sudo chmod 777 /tmp/background.log

  else
         sudo rm -f background.log
         echo yes   >background.log
         sudo chmod 777 background.log
  fi
  

 if [ -e "/gf.log" ]
  then
        sudo rm -f gf.tmp
        sudo cp -f gf.log gf.tmp
        sudo rm -f gf.log
 fi

echo submiting gForth  # Using one of the following lines:
# sudo nice --10 nohup gforth _demo1.f        1>gf.log 2>&1 &
# sudo nice --10 nohup gforth _UploadServer.f 1>gf.log 2>&1 &
 sudo nice --10 nohup gforth _DemoMaster.fs  1>gf.log 2>&1 &
#  sudo nice --10 nohup gforth _SensorWeb1.fs 1>gf.log 2>&1 &

exit 0


