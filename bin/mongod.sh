#! /bin/bash

dbpath=$HOME/.data/var/lib/mongod

if [ $# -eq 1 ]; then
  port=$1
  shift
fi

: ${port:=27017}

echo "---- MongoDB dbpath:"
ls -ld $dbpath
echo "--------------------------"
$HOME/.mongo/bin/mongod --httpinterface --smallfiles --dbpath $dbpath --port $port "$@"
