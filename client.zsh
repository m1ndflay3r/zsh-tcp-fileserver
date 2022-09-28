#!/usr/bin/env zsh

AuthKey="insert-key-here"
TARGET="NULL"
PORT="NULL"
zmodload zsh/net/tcp
echo -n "Target server: "
read TARGET
echo -n "Target port: "
read PORT
if ! ztcp $TARGET $PORT; then
  exit 1
fi
hostfd=$REPLY
read line <& $hostfd
echo $line
LOOPY="0"
IPINFO="setip $(ip route get $TARGET)"
IPINFO=$(echo $IPINFO | head -n 1)
FIRSTRUN="1"
while [ $LOOPY = 0 ]; do
  if [ $FIRSTRUN = "0" ]; then
    echo -n "Name of file to request (or type index for a list): "
    read mcfiley
    echo "Requesting $mcfiley from server..."
    echo $mcfiley >& $hostfd
    if [[ $mcfiley = close ]]; then
      break
    fi
    read line <& $hostfd
    if [ $line = bigrip ]; then
      echo "File $mcfiley does not exist on server!"
    elif [ $mcfiley = index ]; then
      echo " "
      WRITE=${line//.PLACEYMCPLACEHOLD/'\n'}
      tput setaf 4
      tput bold
      echo "$WRITE"
      tput sgr 0
    else
      unset SAVEDAT
      SAVEDAT=$mcfiley:t
      WRITE=${line//.PLACEYMCPLACEHOLD/'\n'}
      echo "$WRITE" > ./$SAVEDAT
      echo "Received data is stored at ./$SAVEDAT"
    fi
  else
    echo "$IPINFO" >& $hostfd
    read line <& $hostfd
    echo $line
    echo $AuthKey >& $hostfd
    read line <& $hostfd
    echo $line
    FIRSTRUN="0"
  fi
done
ztcp -c $hostfd
