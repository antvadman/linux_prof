#Comment mirror and replace base url with vault.centos.org  
sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo

#install zfs repo
yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm

#import gpg key 
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

#install DKMS style packages for correct work ZFS
yum install -y epel-release kernel-devel zfs

#change ZFS repo
yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod
yum install -y zfs

#Add kernel module zfs
modprobe zfs

#install wget
yum install -y wget
          
#load zfs kernel module 
/sbin/modprobe zfs

#Create pools
zpool create pool1 /dev/sdb /dev/sdc
zpool create pool2 /dev/sdd /dev/sde
zpool create pool3 /dev/sdf /dev/sdg
zpool create pool4 /dev/sdh /dev/sdi

#Set compression algs
zfs set compression=lzjb pool1
zfs set compression=lz4 pool2
zfs set compression=gzip-9 pool3
zfs set compression=zle pool4

#create testfile
base64 < /dev/urandom | head -c 100M > testfile

#copy testfile to pools
cp /home/vagrant/testfile /pool1
cp /home/vagrant/testfile /pool2
cp /home/vagrant/testfile /pool3
cp /home/vagrant/testfile /pool4

#download archive
curl -o archive.tar.gz https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb

#unzip archive
tar -xzvf archive.tar.gz

#import pool
zpool import -d zpoolexport/ otus

#download snapshot
sudo wget -O -f /home/vagrant/otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download

#recover from snapshot
zfs receive otus/test@today < /home/vagrant/otus_task2.file

