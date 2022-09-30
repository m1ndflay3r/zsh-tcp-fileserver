#!/usr/bin/env zsh

AuthKey=$(cat /Path/To/Pub/Key)

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
RESOLVED=$(ping $TARGET -c 1 | head -n 1)
unset nRESOLVED
nRESOLVED=" "
while read -k1 -u0 character; do
  i=${character/')'/BRACEDETECT}
  if [[ "$i" != BRACEDETECT ]]; then
    nRESOLVED=""$nRESOLVED""$i""
  else
    break
  fi
done < <(echo -n $RESOLVED)
RESOLVED=$(echo ${nRESOLVED/*'('/ })
IPINFO="setip $(ip route get $RESOLVED)"
IPINFO=${IPINFO/*src/ }
IPINFO=${IPINFO/uid*/ }
IPINFO="setip "$IPINFO" "$USER"ISWEARIFSOMEONEACTUALLYHASTHISASTHEIRHOSTORUSER"$(hostname)""
FIRSTRUN="1"
while [ $LOOPY = 0 ]; do
  if [ $FIRSTRUN = "0" ]; then
    echo -n "Name of file to request (or type index for a list): "
    read mcfiley
    echo "Requesting $mcfiley from server..."
    echo $mcfiley >& $hostfd
    if [[ $mcfiley = close ]] || [[ $line = bigrip ]]; then
      break
    fi
    rm -rf /$(pwd)/MYAAH
    while IFS= n=1 N=1 read line <& $hostfd; do
      if [ "$(echo -n $line)" = xfercomp ]; then
        break
      fi
      echo -n $line | xxd -r -p >>/$(pwd)/MYAAH
    done
    if [ $line = bigrip ]; then
      echo "File $mcfiley does not exist on server!"
    elif [ $mcfiley = index ]; then
      echo " "
      tput setaf 4
      tput bold
      cat /$(pwd)/MYAAH
      tput sgr 0
    else
      unset SAVEDAT
      SAVEDAT=$mcfiley:t
      mv /$(pwd)/MYAAH /$(pwd)/$SAVEDAT
      echo "Received data is stored at ./$SAVEDAT"
      echo -n 'View now without closing connection? Know what youre opening or you could mess your term (Y/n) '
      read VIEWER
      if [ -z $VIEWER ]; then
        VIEWER=y
      fi
      if [ $VIEWER = y ] || [ $VIEWER = Y ]; then
        cat /$(pwd)/$SAVEDAT
      fi
    fi
  else
    echo "$IPINFO" >& $hostfd
    read line <& $hostfd
    echo $line
    echo $AuthKey >& $hostfd
    read line <& $hostfd
    echo $line
    read line <& $hostfd
    if [ "$line" = fail ]; then
      break
    fi
    FIRSTRUN="0"
  fi
done
ztcp -c $hostfd
