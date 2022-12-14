#!/usr/bin/env zsh

zmodload zsh/net/tcp

AUTHORIZED="0"

PrivateKey=/Path/To/Private/Key

TEST1=$(md5sum $PrivateKey)
TEST1=${TEST1:0:32}
TEST2=$(sha1sum $PrivateKey)
TEST2=${TEST2:0:40}
export ExpectPubKey=""$TEST1"l0l1m50rand0m"$TEST2""
ExpectPubLen="0"
while read -k1 -u0 character; do
  ExpectPubLen=$((ExpectPubLen+1))
done < <(echo -n $ExpectPubKey)

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
        CLIENTIP=${line//setip/ }
        CLIENTIP=${CLIENTIP/ISWEARIFSOMEONEACTUALLYHASTHISASTHEIRHOSTORUSER/@}
        echo "$(date +"%T")    client reported ip address $CLIENTIP" >> /root/testing/servroot/server.log
        echo "Checking authkey..." >& $clientfd
        read -t 600 line <& $clientfd
        if [ -z "$line" ]; then
          echo "$(date +"%T")    client sent a nullkey" >> /root/testing/servroot/server.log
          line="NULLKEY"
        fi
        CLPUBLEN="0"
        while read -k1 -u0 character; do
          CLPUBLEN=$((CLPUBLEN+1))
        done < <(echo -n $line)
        if [[ "$line" = "$ExpectPubKey" ]] && [[ "$CLPUBLEN" = "$ExpectPubLen" ]]; then
          SHPASS=1
          MDPASS=1
        else
          SHPASS=0
          MDPASS=0
        fi
        if [ $SHPASS = 0 ] || [ $MDPASS = 0 ]; then
          echo "$(tput setaf 1) key verification failed $(tput sgr 0)" >& $clientfd
          echo "fail" >& $clientfd
          echo "$(date +"%T")    connection closed - bad pubkey" >> /root/testing/servroot/server.log
          line="close"
        else
          ISIPSEND="1"
          AUTHORIZED="1"
          echo "$(tput setaf 2)Authentication successful$(tput sgr 0)" >& $clientfd
          echo "pass" >& $clientfd
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
      if [ -z "$line" ]; then
        line=index
      fi
      REQUESTPATH=$line:h
      REQUESTFILE=$line:t
      REQUESTPATH=${REQUESTPATH//../.}
      TOBESERVED="$REQUESTPATH/$REQUESTFILE"
      echo "Received request for file $line"
      echo "$(date +"%T")    client requested $line" >> /root/testing/servroot/server.log
      if [[ -f "/root/testing/servroot/$TOBESERVED" ]]; then
        dd if=/root/testing/servroot/$TOBESERVED | xxd -p >& $clientfd
        echo "xfercomp" >& $clientfd
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
  ExpectPubKey="$ExpectPubKey" ExpectPubLen="$ExpectPubLen" main
}
main
