#!/usr/bin/env zsh

zmodload zsh/net/tcp
AUTHORIZED="0"
main() {
  ztcp -l 333
  fd=$REPLY
  echo "Waiting for connection..."
  echo "listening on port 333    $(date +"%T")" >> /root/testing/servroot/server.log
  ztcp -a $fd
  clientfd=$REPLY
  echo "Client connected"
  echo "client connected    $(date +"%T")" >> /root/testing/servroot/server.log
  echo "$(tput setaf 2)Attempting to authenticate session...$(tput sgr 0)" >& $clientfd
  LOOPY="0"
  while [ $LOOPY = 0 ]; do
    if ! read -t 600 line <& $clientfd; then
      echo "$(tput setaf 5)No response from client in 600 seconds! $(tput sgr 0)" >& $clientfd
      line="close"
    fi
    IPLISTEN=${line:0:5}
    if [[ $IPLISTEN = "setip" ]]; then
      if [ $AUTHORIZED = "0" ]; then
        CLIENTIP=${line:5}
        echo "client reported ip address $CLIENTIP    $(date +"%T")" >> /root/testing/servroot/server.log
        echo "Confirming authkey is valid..." >& $clientfd
        read -t 600 line <& $clientfd
        if [[ "$line" = 'insert-key-here' ]]; then
          SHPASS=1
          MDPASS=1
        fi
        if [ $SHPASS = 0 ] || [ $MDPASS = 0 ]; then
          echo "$(tput setaf 1) identity key varification failure $(tput sgr 0)"
          line="close"
        fi
        ISIPSEND="1"
        AUTHORIZED="1"
        echo "$(tput setaf 2) authorization succesful$(tput sgr 0)" >& $clientfd
      else
        echo "client tried to report ip address twice    $(date +"%T")" >> /root/testing/servroot/server.log
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
      echo "client requested $line    $(date +"%T")" >> /root/testing/servroot/server.log
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
      echo "$(tput setaf 5)access denied - trying to pull some tomfuckery, are we?" >& $clientfd
    fi
  done
  echo "Client disconnected"
  echo "connection closed    $(date +"%T")" >> /root/testing/servroot/server.log
  ztcp -c $fd
  ztcp -c $clientfd
  AUTHORIZED="0"
  main
}
main
