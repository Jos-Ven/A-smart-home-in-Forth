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

echo
printf "Submiting gForth "  # Using one of the following lines:
# sudo chrt 50 nohup gforth _demo1.f        1>gf.log 2>&1 &
# sudo chrt 50 nohup gforth _UploadServer.f 1>gf.log 2>&1 &
  sudo chrt 50 nohup gforth _DemoMaster.fs  1>gf.log 2>&1 &
# sudo chrt 50 nohup gforth _SensorWeb1.fs 1>gf.log 2>&1 &


 if [ -e "/tmp/ipadr.txt" ]
  then
         sudo chmod 777 /tmp/ipadr.txt
         sudo rm -f /tmp/ipadr.txt
  fi

i=23
until [ "$i" -eq 1 ]; do
  if [ -e "/tmp/ipadr.txt" ]; then
    sudo chmod 777 /tmp/ipadr.txt
    printf "\a\n"
    cat /tmp/ipadr.txt
    break
  else
    printf "."
    sleep 2
  fi
  i=$((i-1))
done
sudo chmod 777 gf.log
echo
exit 0



