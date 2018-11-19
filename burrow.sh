#!/bin/bash
# script to tunnel to remote databases
# ksankar Nov 2018

# Auth
HOST_IP=''
U="ubuntu"
P=""

# Options
cassandra=''
es=''
kafka=''
mongo=''

# Extra
status=''
terminate=''

# begin
echo "Remote Tunneling Script"
echo "-------------------"

print_usage() {
  printf "
    h - Host IP
    u - user login name (Default is 'ubuntu')
    p - password (recommended you save it inside the file itself on the local for ease of use)
    c - connect to Cassandra DB port
    e - connect to ElasticSearch port
    k - connect to Kafka port
    m - connect to Mongo DB port
    s - print status of all open tunnels
    t - terminate all open tunnels
  "
}

# command line options
while getopts 'h:u:p:cekmst' flag; do
  case "${flag}" in
    c) cassandra='true' ;;
    e) es='true' ;;
    k) kafka='true' ;;
    m) mongo='true' ;;
    s) status='true' ;;
    t) terminate='true' ;;
    h) HOST_IP="${OPTARG}" ;;
    u) U="${OPTARG}" ;;
    p) P="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

# verbose
echo "Host Details"
echo "Host:$HOST_IP, User:$U"

# connecting routine
# -f for background, N - not gonna execute commands, T - disable psedotty, M - master mode, S - control socket
groundhog() {
expect <(cat <<EOD
spawn ssh -fNT -o ExitOnForwardFailure=yes -M -S $1 -L $2:localhost:$2 $U@$HOST_IP
expect "*assword:*"
send "$P\r"
sleep 1
expect "\n"
sleep 1
EOD
)
}

# prints connection status using control socket file
stat() {
  if [ -e "$2" ]
  then
    echo "$1 status:"
    ssh -S $2 -O check $U@$HOST_IP
  fi
}

# kills a connection using control socket file
killsock() {
  if [ -e $2 ]
  then
    echo "Killing tunnel for $1"
    ssh -S $2 -O exit $U@$HOST_IP
  fi
}

# connect to Cassandra DB
if [ $cassandra ]
then
  echo "Connecting to Cassandra DB"
  groundhog "cass-sock" "9042"
  stat "Cassandra" "cass-sock"
fi

# connect to Elasticsearch DB
if [ $es ]
then
  echo "Connecting to Elasticsearch DB"
  groundhog "es-sock" "9200"
  stat "ElasticSearch" "es-sock"
fi

# connect to MongoDB
if [ $mongo ]
then
  echo "Connecting to Mongo DB"
  groundhog "mongo-sock" "27017"
  stat "Mongodb" "mongo-sock"
fi

# connect to Kafka
if [ $kafka ]
then
  echo "Connecting to Kafka"
  groundhog "kafka-sock" "9092"
  stat "Kafka" "kafka-sock"
fi

# Status of all open tunnels
if [ $status ]
then
  echo "--- Script status ---"
  stat "Cassandra" "cass-sock"
  stat "ElasticSearch" "es-sock"
  stat "Kafka" "kafka-sock"
  stat "Mongodb" "mongo-sock"
fi

# Terminate all open tunnels
if [ $terminate ]
then
  echo "--Terminating tunnels"
  killsock "Cassandra" "cass-sock"
  killsock "ElasticSearch" "es-sock"
  killsock "Kafka" "kafka-sock"
  killsock "Mongodb" "mongo-sock"
fi
