#!/bin/bash
set -x

##### Set up variables
######################
SSHUSER="${sshuser}"
SSHKEY=${ssh_priv_key}
CONTROLLER="${controller}"
DBINSTANCE="${dbinstance}"
HUBINSTANCE="${hubinstance}"
PKG_TMP_PATH="${install_pkg_dest}"
INSTALL_PKG="${install_pkg}"
INSTALL_DIR="/var/automation_platform"
VARLV="40G"
TMPLV="10G"
SSHKEYPATH=/home/$SSHUSER/.ssh/$SSHKEY
SSH_OPTS="-o StrictHostKeyChecking=no"
CTRLINPUT=/tmp/ctrl_input_file.tmp
DBINPUT=/tmp/db_input_file.tmp
ROOTDEV=/dev/sda
MYIP=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
EXCUTIONNODE="${execinstance}"

BASE_ENV_PREP () {
  
  ##### Set configure environment
  ###############################
  timedatectl set-timezone "${timezone}"
  echo "set -o vi"             >> /home/$SSHUSER/.bashrc
  echo "export EDITOR=vim"     >> /home/$SSHUSER/.bashrc
  echo "export HISTSIZE=10000" >> /home/$SSHUSER/.bashrc
  echo "set -o vi"             >> /root/.bashrc
  echo "export EDITOR=vim"     >> /root/.bashrc
  echo "export HISTSIZE=10000" >> /home/$SSHUSER/.bashrc
  #echo "PEERDNS=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  sed -i".bak" '/\[main\]/ adns=none' /etc/NetworkManager/NetworkManager.conf

  # Make root accessable
  cp -f /home/$SSHUSER/.ssh/* /root/.ssh/
  chmod 400 /root/.ssh/*
  
  # Install some needed packages
  subscription-manager register --username ${username} --password ${password} --auto-attach --force
  
  max_attempts=10
  attempt_num=1
  success=false
  while [ $success = false ] && [ $attempt_num -le $max_attempts ]; do
    echo "Trying yum install"
    yum update -y >> /var/log/yum_update.log
    yum install wget vim ansible-core zip -y
    # Check the exit code of the command
    if [ $? -eq 0 ]; then
      echo "Yum install succeeded"
      success=true
    else
      echo "Attempt $attempt_num failed. Sleeping for 3 seconds and trying again..."
      sleep 5
      ((attempt_num++))
    fi
  done
}

PREPARE_APPDISK () {

  set -x
  ##### Configure app disk
  ########################
    fdisk $ROOTDEV <<EOI
n



w
EOI
  # extend root volume group
  vgextend rootvg /dev/sda3

  %{ for fsname, fssize_mnt in filesystems ~}
  
  FSNAME=${fsname}
  FSSIZE=`echo ${fssize_mnt} | awk -F: '{ print $1 * 1000 }'`
  FSMNT=`echo ${fssize_mnt} | awk -F: '{ print $2 }'`
  echo "FSNAME is $FSNAME"
  echo "FSSIZE is $FSSIZE"
  echo "FSMNT is $FSMNT"

  FREEGB=`vgdisplay rootvg | awk '/Free  PE/ { print int($5 * 1000 / 256 ) }'`

  if [[ $FREEGB -gt $FSSIZE ]]
  then
    if [[ -b /dev/rootvg/$FSNAME ]]
    then
      lvextend -L $FSSIZE -r /dev/rootvg/$FSNAME
    else
      lvcreate -L $FSSIZE -n $FSNAME rootvg
      mkfs.xfs /dev/rootvg/$FSNAME
      mkdir $FSMNT
      echo "/dev/mapper/rootvg-$FSNAME $FSMNT                    xfs     defaults        0 0" >> /etc/fstab
      mount -a
    fi
  else
      echo "ERROR: not enough free space to create $FSNAME"
  fi

  if [[ $FREEGB -gt $FSSIZE ]]
  then
    lvextend -L $FSSIZE -r /dev/rootvg/$FSNAME
  fi

  %{ endfor ~}

}

CREATE_INVENTORY_ENTRIES () {
  # Prepare inventory file entries
  > $CTRLINPUT
  > $DBINPUT
  if [ -z "${controller}" ]
  then
  	CONTROLLER=$MYIP
  	echo "$CONTROLLER ansible_ssh_private_key_file=\/root\/.ssh\/$SSHKEY ansible_ssh_common_args=\"$SSH_OPTS\"" >> $CTRLINPUT
  else
  	CONTROLLER="${controller}" 
  	if [[ -z $EXECUTIONNODE ]]
  	then
  		AC_NODE_TYPE="hybrid"
  	else
  		AC_NODE_TYPE="control"
  	fi
  	for CTRL in $CONTROLLER
  	do
  		echo "$CTRL node_type=$AC_NODE_TYPE ansible_ssh_private_key_file=\/root\/.ssh\/$SSHKEY ansible_ssh_common_args=\"$SSH_OPTS\"" >> $CTRLINPUT
  		HUB=$MYIP
  	done
  fi
  if [ -n "${dbinstance}" ]
  then
  	DBINSTANCE="${dbinstance}"
  else
  	#DBINSTANCE=$MYIP
  	:
  fi
  
  cd $INSTALL_DIR/ansible-automation-platform*/
  
  cp ./inventory ./inventory.was
  echo '---------------- CTRL inputs'
  while read -r ENTRY
  do
      echo "ENTRY is \"$ENTRY\""
      sed -i.bak1 -e '/^\[automationcontroller\]/ a'"$ENTRY"'' \
           $INSTALL_DIR/ansible-automation*/inventory
  done < $CTRLINPUT

  echo 'Password inputs'
  sed -i.bak2 -e 's/^admin_password=.*$/admin_password=\x27password123\x27/' \
              -e 's/^pg_password=.*$/pg_password=\x27password123\x27/' \
              -e 's/^registry_username=.*$/registry_username=\x27admin\x27/' \
              -e 's/^automationhub_pg_password=.*$/automationhub_pg_password=\x27password123\x27/' \
              -e 's/^automationhub_admin_password=.*$/automationhub_admin_password=\x27password123\x27/' \
              -e 's/^registry_password=.*$/registry_password=\x27password123\x27/' \
            $INSTALL_DIR/ansible-automation*/inventory
  
  echo '---------------- Hub inputs'
  if [[ -n "$HUB" ]]
  then
      sed -i.bak3 -e '/^\[automationhub\]/ a'"$HUB"' ansible_ssh_private_key_file=\/root\/.ssh\/'"$SSHKEY"' ansible_ssh_common_args=\x27'"$SSH_OPTS"'\x27' \
           $INSTALL_DIR/ansible-automation*/inventory
  fi
  echo '---------------- DB inputs'
  if [[ -n "$DBINSTANCE" ]]
  then
      sed -i.bak4 -e 's/^pg_host=.*/pg_host=\x27'$DBINSTANCE'\x27/' \
                  -e 's/^automationhub_pg_host=.*/automationhub_pg_host=\x27'$DBINSTANCE'\x27/' \
           $INSTALL_DIR/ansible-automation*/inventory
      echo "DBINSTANCE is \"$DBINSTANCE\""
      sed -i.bak1 -e '/^\[database\]/ a'"$DBINSTANCE"' ansible_ssh_private_key_file=\/root\/.ssh\/'"$SSHKEY"' ansible_ssh_common_args=\x27'"$SSH_OPTS"'\x27' \
           $INSTALL_DIR/ansible-automation*/inventory
  fi
}

BASE_ENV_PREP

PREPARE_APPDISK 

##### Install App
#################

mkdir -p $INSTALL_DIR
tar xzf $PKG_TMP_PATH/$INSTALL_PKG -C $INSTALL_DIR/ && rm -f $PKG_TMP_PATH/$INSTALL_PKG

CREATE_INVENTORY_ENTRIES

cd $INSTALL_DIR/ansible-automation-platform*/
echo 'Setup Script'
./setup.sh -e "_automationhub_main_host=`hostname`" > /var/log/ansible_install.log 2>&1
#./setup.sh > /var/log/ansible_install.log 2>&1
