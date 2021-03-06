#!/bin/sh
echo ""
echo ""
echo ""
echo ""
echo "ipv6 adresiniz";read IP6
echo ""
echo ""
echo ""
echo ""
echo "/64 icin = 64 enter, /48 icin = 48 enter";read hlt24
vultd=$(find /sys/class/net ! -type d | xargs --max-args=1 realpath  | awk -F\/ '/pci/{print $NF}')
echo ""
echo ""
echo ""
echo ""
echo "network'u support ekledimi evet/hayır";read hlt2
if [ $hlt2 = "hayır" ] ; then
echo "NETWORKING_IPV6=yes" >> /etc/sysconfig/network-scripts/ifcfg-${vultd}
echo "IPV6INIT=yes" >> /etc/sysconfig/network-scripts/ifcfg-${vultd}
echo "IPV6ADDR=${IP6}::2" >> /etc/sysconfig/network-scripts/ifcfg-${vultd}
echo "IPV6_DEFAULTGW=${IP6}::1" >> /etc/sysconfig/network-scripts/ifcfg-${vultd}
ifup ${vultd}
ifup ${vultd}
elif [ $hlt2 = "evet" ] ; then
echo ""
fi
ip -6 addr add ${IP6}::2/48 dev ${vultd}
ip -6 route add default via ${IP6}::1
ip -6 route add local ${IP6}::/48 dev lo
yum update -y
sleep 0.4
yum install wget -y
sleep 0.4
yum install nano -y
yum -y install wget nano epel-release net-tools
sleep 0.4
yum install gcc -y
sleep 0.3
yum install git -y
sleep 0.4
yum install make -y
sleep 0.4
yum install curl -y
sleep 0.4
yum -y install gcc-c++
sleep 0.5
yum install psmisc -y
sleep 0.4
echo "guncelleme tamam"
sleep 1.3
clear && printf '\e[3J'

random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c5
	echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
	ip64() {
		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	if [ $hlt24 = "48" ] ; then
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64):$(ip64)"
	elif [ $hlt24 = "64" ] ; then
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
	fi
}
install_3proxy() {
    echo "installing 3proxy"
    URL="https://github.com/z3APA3A/3proxy/archive/3proxy-0.8.6.tar.gz"
    wget -qO- $URL | bsdtar -xvf-
    cd 3proxy-3proxy-0.8.6
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    cp src/3proxy /usr/local/etc/3proxy/bin/
    cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
    chmod +x /etc/init.d/3proxy
    chkconfig 3proxy on
    cd $WORKDIR
}

gen_3proxy() {
    cat <<EOF
daemon
maxconn 1000
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
flush
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})

$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
}

upload_proxy() {
    local PASS=$(random)
    zip --password $PASS proxy.zip proxy.txt
    URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from: ${URL}"
    echo "Password: ${PASS}"

}
gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "usr$(random)/pass$(random)/$IP4/$port/$(gen64 $IP6)"
    done
}

gen_iptables() {
    cat <<EOF
    $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" '{print "ifconfig eth0 inet6 add " $5 "/48"}' ${WORKDATA})
EOF
}
echo "installing apps"
yum -y install gcc net-tools bsdtar zip >/dev/null

install_3proxy

echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_

IP4=$(curl -4 -s icanhazip.com)

echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}"

echo "Kac adet istiyorsunuz? örnek 500"
read COUNT

FIRST_PORT=10000
LAST_PORT=$(($FIRST_PORT + $COUNT))

gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 10048
service 3proxy start
EOF

ip -6 addr add ${IP6}::2/48 dev eth0
ip -6 route add default via ${IP6}::1
ip -6 route add local ${IP6}::/48 dev lo

bash /etc/rc.local

gen_proxy_file_for_user

upload_proxy
