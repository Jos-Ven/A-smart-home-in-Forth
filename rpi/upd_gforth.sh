# wget http://www.complang.tuwien.ac.at/forth/gforth/Snapshots/current/gforth.tar.xz
# sudo nice --15 nohup ./upd_gforth.sh >upd_gforth.log &  # Manual option

echo Running upd_gforth.sh

sudo rm -rf /home/pi/Downloads/gforth-*

tar xvfJ gforth.tar.xz -C Downloads

installdir=$( ls Downloads | grep "gforth-")
echo  Downloads/"$installdir"
cd /home/pi/Downloads/"$installdir"

sudo ./install-deps.sh
sudo ./configure 
sudo make
sudo make install

date
sudo shutdown -r now
