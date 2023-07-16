echo upd_os.sh
date

# sudo nice --15 nohup ./upd_os.sh >upd_os.log &  # Manual option

sudo ./upd.sh

date
echo Rebooting......
sudo shutdown -r now
