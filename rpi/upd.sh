echo Updating, Upgrading and cleanup.

# sudo nice --15 nohup ./upd.sh >upd.log &  # Manual option
# sudo rpi-update # Firmware

date
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y

# sudo shutdown 0 -r
