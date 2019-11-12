#! /bin/sh

DIR=$(cd `dirname $0` && pwd)
. $DIR/env.sh

echo "remove lock files " >> $LOG
rm -rf $DIR/lock_*

# init pins and blink
initPin(){
    echo "init pin $1" >> $LOG
    pigs modes $1 w
    # blink
    pigs w $1 $ON mils 1000 w $1 $OFF &
}

echo "init LED" >> $LOG
for i in $(seq 0 3)
do
    eval "R=\$RED_0$i"
    eval "G=\$GREEN_0$i"
    initPin ${R}
    initPin ${G}
done
