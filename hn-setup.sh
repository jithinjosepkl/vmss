#!/bin/bash

USER=$1

IP=`ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
localip=`echo $IP | cut --delimiter='.' -f -3`

cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
*               hard    nofile          65535
*               soft    nofile          65535
EOF

mkdir -p /mnt/resource/scratch
chmod a+rwx /mnt/resource/scratch

yum --enablerepo=extras install -y -q epel-release
yum install -y -q nfs-utils nmap htop pdsh screen git axel 
# need to update for git work
yum update -y nss curl libcurl

cat << EOF >> /etc/exports
/home $localip.*(rw,sync,no_root_squash,no_all_squash)
/mnt/resource/scratch $localip.*(rw,sync,no_root_squash,no_all_squash)
EOF

systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap
systemctl restart nfs-server

mkdir -p /home/$USER/bin
chown $USER:$USER /home/$USER/bin

cat << EOF >> /home/$USER/.bashrc
export WCOLL=/home/$USER/bin/hostlist
EOF
chown $USER:$USER /home/$USER/.bashrc

touch /home/$USER/bin/hostlist
chown $USER:$USER /home/$USER/bin/hostlist

ssh-keygen -f /home/$USER/.ssh/id_rsa -t rsa -N ''
cat << EOF > /home/$USER/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    PasswordAuthentication no
    LogLevel QUIET
EOF
cat /home/$USER/.ssh/id_rsa.pub >> /home/$USER/.ssh/authorized_keys
chmod 644 /home/$USER/.ssh/config
chown $USER:$USER /home/$USER/.ssh/*

# Don't require password for HPC user sudo
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

