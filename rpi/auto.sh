date
# Started from: /etc/rc.local before exit 0
# With: bash /home/pi/auto.sh

echo submiting gForth

cd /home/pi
sudo cp auto.log auto.old
sudo  nohup bash /home/pi/drop_caches.sh > /tmp/drop_caches.log < /home/pi/kb.txt &
nohup bash /home/pi/gf.sh > /home/pi/auto.log < /home/pi/kb.txt &

