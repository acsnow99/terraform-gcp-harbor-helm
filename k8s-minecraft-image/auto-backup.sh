while true
do
    cp -r /minecraft/worlds/$WORLDNAME/db/* /worlds-backup/$WORLDNAME
    sleep 180
done