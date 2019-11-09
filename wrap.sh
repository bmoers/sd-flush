#! /bin/sh

DIR=$(cd `dirname $0` && pwd)
. $DIR/env.sh

echo $DIR/$FLUSH $1 | /usr/bin/at now