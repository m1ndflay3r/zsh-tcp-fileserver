#!/usr/bin/env zsh

zmodload zsh/net/tcp

AUTHORIZED="0"

PrivateKey=/Path/To/Private/Key

TEST1=$(md5sum $PrivateKey)
TEST1=${TEST1:0:32}
TEST2=$(sha1sum $PrivateKey)
TEST2=${TEST2:0:40}
export ExpectPubKey=""$TEST1"l0l1m50rand0m"$TEST2""

main() {
  ztcp -l 333
  fd=$REPLY
  echo "Waiting for connection..."
  echo "$(date +"%T")    listening on port 333" >> /root/testing/servroot/server.log
  ztcp -a $fd
  clientfd=$REPLY
  echo "Client connected"
  echo "$(date +"%T")    client connected" >> /root/testing/servroot/server.log
  echo "$(tput setaf 2)Authenticating session...$(tput sgr 0)" >& $clientfd
  LOOPY="0"
  while [ $LOOPY = 0 ]; do
    if ! read -t 600 line <& $clientfd; then
      echo "$(tput setaf 5)No response from client in 600 seconds! $(tput sgr 0)" >& $clientfd
      echo "$(date +"%T")    connection closed - client timed out " >> /root/testing/servroot/server.log
      line="close"
    fi
    IPLISTEN=${line:0:5}
    if [[ $IPLISTEN = "setip" ]]; then
      if [ $AUTHORIZED = "0" ]; then
        CLIENTIP=${line:5}
        echo "$(date +"%T")    client reported ip address $CLIENTIP" >> /root/testing/servroot/server.log
        echo "Checking authkey..." >& $clientfd
        read -t 600 line <& $clientfd
          if [ -z "$line" ]; then
            echo "$(date +"%T")    client sent a nullkey" >> /root/testing/servroot/server.log
            line="NULLKEY"
          fi
        if [[ "$line" = "$ExpectPubKey" ]]; then
          SHPASS=1
          MDPASS=1
        else
          SHPASS=0
          MDPASS=0
        fi
        if [ $SHPASS = 0 ] || [ $MDPASS = 0 ]; then
          echo "$(tput setaf 1) identity key verification failure $(tput sgr 0)" >& $clientfd
          echo "$(date +"%T")    connection closed - bad pubkey" >> /root/testing/servroot/server.log
          line="close"
        else
          ISIPSEND="1"
          AUTHORIZED="1"
          echo "$(tput setaf 2) authorization successful$(tput sgr 0)" >& $clientfd
          echo "$(date +"%T")    authentication successful" >> /root/testing/servroot/server.log
        fi
      else
        echo "$(date +"%T")    client tried to report ip address twice" >> /root/testing/servroot/server.log
        echo "$(tput setaf 1) trying to pull some tomfuckery are we?$(tput sgr 0)" >& $clientfd
      fi
    else
      ISIPSEND="0"
    fi
    if [[ $line = "close" ]]; then
      break
    elif [ $AUTHORIZED = 1 ] && [ $ISIPSEND = 0 ]; then
      REQUESTPATH=$line:h
      REQUESTFILE=$line:t
      REQUESTPATH=${REQUESTPATH//../.}
      TOBESERVED="$REQUESTPATH/$REQUESTFILE"
      echo "Received request for file $line"
      echo "$(date +"%T")    client requested $line" >> /root/testing/servroot/server.log
      if [[ -f "/root/testing/servroot/$TOBESERVED" ]]; then
        IFS=$'\n'
        DODODODO=($(cat /root/testing/servroot/$TOBESERVED))
        unset FACC
        for h in ${DODODODO[@]}; do
          FACC+=(""$h" .PLACEYMCPLACEHOLD")
        done
        unset IFS
        DODODODODO=$(echo ${FACC[@]})
        interlude="$DODODODODO"
        echo "$interlude" >& $clientfd
      else
        echo "bigrip" >& $clientfd
      fi
    elif [ $ISIPSEND = 0 ] && [ $AUTHORIZED = 0 ]; then
      echo "$(tput setaf 5)access denied" >& $clientfd
      echo "$(date +"%T")    connection closed - access denied" >> /root/testing/servroot/server.log
    fi
  done
  echo "Client disconnected"
  echo "$(date +"%T")    connection closed - client disconnect" >> /root/testing/servroot/server.log
  ztcp -c $fd
  ztcp -c $clientfd
  AUTHORIZED="0"
  ExpectPubKey="$ExpectPubKey" main
}
main
