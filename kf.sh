# Kills gforth
sudo kill -9 $(ps aux | grep -e gforth| awk '{ print $2 }')
