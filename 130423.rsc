# apr/13/2023 17:46:07 by RouterOS 6.48.6

#
# model = RB750Gr3
# 
/interface bridge
add comment=LAN name=bridge
/interface ethernet
set [ find default-name=ether1 ] comment=WAN
/interface list
add name=WANs
add name=LANs
/ip hotspot profile
add dns-name=wifi3.info hotspot-address=192.168.3.1 html-directory=\
    flash/hotspot login-by=http-chap,http-pap,mac-cookie name=WIRISP \
    nas-port-type=ethernet use-radius=yes
/ip pool
add name=Mk3-pool-hotspot ranges=192.168.3.2-192.168.3.253
add name=Mk3-pool-pppoe ranges=172.3.0.2-172.3.0.10
/ip dhcp-server
add address-pool=Mk3-pool-hotspot disabled=no interface=bridge lease-time=1h \
    name=dhcp1
/ip hotspot
add address-pool=Mk3-pool-hotspot addresses-per-mac=unlimited disabled=no \
    idle-timeout=none interface=bridge name=WIRISP profile=WIRISP
/ppp profile
add dns-server=8.8.8.8 local-address=172.3.0.1 name=2Mbps_PPPoE rate-limit=\
    2M/2M remote-address=Mk3-pool-pppoe
add change-tcp-mss=yes name=OVPN-client only-one=yes use-compression=no \
    use-encryption=yes use-mpls=no
/interface ovpn-client
add add-default-route=yes certificate=MkSnJose.crt_0 cipher=aes256 \
    connect-to=38.X42.2X9.1X1 name=ovpn-client \
    profile=OVPN-client use-peer-dns=no user=openvpn
/system logging action
set 0 memory-lines=150
/interface bridge port
add bridge=bridge interface=ether2
add bridge=bridge interface=ether3
add bridge=bridge interface=ether4
add bridge=bridge interface=ether5
/interface list member
add interface=ether1 list=WANs
add interface=bridge list=LANs
/interface pppoe-server server
add disabled=no interface=bridge max-mru=1480 max-mtu=1480 \
    one-session-per-host=yes service-name=pppoe_server1
/ip address
add address=192.168.3.1/24 comment=Hotspot interface=bridge network=\
    192.168.3.0
add address=172.3.0.1/24 comment=PPPoE interface=bridge network=\
    172.3.0.0
/ip dhcp-client
add disabled=no interface=ether1 use-peer-dns=no use-peer-ntp=no
/ip dhcp-server network
add address=192.168.3.0/24 comment="hotspot network" dns-server=10.8.0.1 \
    domain=wifi3.info gateway=192.168.3.1
/ip dns
set servers=10.8.0.1,1.1.1.1
/ip firewall address-list
add address=192.168.3.0/24 list="Red LAN"
add address=192.168.1.0/24 comment="MAQUINA DEL ADMINISTRADOR" list=\
    ssh-permitido
add address=192.168.3.0/24 comment="MAQUINA DEL ADMINISTRADOR" list=\
    ssh-permitido
add address=10.8.0.0/24 comment="MAQUINA DEL ADMINISTRADOR" list=\
    ssh-permitido
add address=10.8.0.0/24 list="Red LAN"
/ip firewall filter
add action=passthrough chain=unused-hs-chain comment=\
    "===============INICIAN-REGLAS===============" disabled=yes
add action=drop chain=input connection-state=new dst-port=53 \
    in-interface-list=WANs protocol=udp
add action=drop chain=input connection-state=new dst-port=53 \
    in-interface-list=WANs protocol=tcp
add action=accept chain=input comment="Salida ssh" dst-address-list=\
    ssh-permitido
add action=accept chain=output comment="Salida ssh" dst-address-list=\
    ssh-permitido
add action=accept chain=input comment="OVPN pass" dst-port=1194 protocol=tcp \
    src-address-list=ssh-permitido
add action=accept chain=input comment="Winbox Acept" dst-port=8291 protocol=\
    tcp src-address-list=ssh-permitido
add action=drop chain=input comment=\
    "ACEPTO SSH DESDE LAS MAQUINAS EN LA LISTA ssh-permitido" dst-port=22 \
    protocol=tcp src-address-list=!ssh-permitido
add action=accept chain=input comment=IN_CONN_ESTABLISHED_Y_RELATED \
    connection-state=established,related
add action=drop chain=input comment=IN_DROP_CONN_INVALID connection-state=\
    invalid
add action=accept chain=input comment=IN_CONN_RED_LAN src-address-list=\
    "Red LAN"
add action=drop chain=input comment=IN_DROP_ALL
add action=accept chain=forward comment=FW_CONN_ESTABLISHED_Y_RELATED \
    connection-state=established,related
add action=drop chain=forward comment=FW_DROP_CONN_INVALID connection-state=\
    invalid
add action=accept chain=forward comment=FW_CONN_RED_LAN src-address-list=\
    "Red LAN"
add action=drop chain=forward comment="FW_DROP_ALL, Excepto DST-NAT" \
    connection-nat-state=!dstnat
/ip firewall mangle
add action=change-ttl chain=postrouting dst-address=192.168.3.0/24 new-ttl=\
    set:3 passthrough=no
add action=change-mss chain=forward connection-mark=under_Piwire new-mss=1360 \
    passthrough=yes protocol=tcp tcp-flags=syn tcp-mss=!0-1375
/ip firewall nat
add action=passthrough chain=unused-hs-chain comment=\
    "======================INICIAN-REGLAS=================" disabled=yes
add action=masquerade chain=srcnat disabled=yes dst-address=10.8.0.1 \
    dst-port=53 out-interface=bridge protocol=tcp src-address=192.168.3.0/24
add action=masquerade chain=srcnat disabled=yes dst-address=10.8.0.1 \
    dst-port=53 out-interface=bridge protocol=udp src-address=192.168.3.0/24
add action=dst-nat chain=dstnat disabled=yes dst-port=53 protocol=tcp \
    to-addresses=10.8.0.1 to-ports=53
add action=dst-nat chain=dstnat disabled=yes dst-port=53 protocol=udp \
    to-addresses=10.8.0.1 to-ports=53
add action=accept chain=pre-hotspot comment=PERMITIR-HOTSPOT disabled=yes \
    dst-address-type=!local hotspot=auth
add action=redirect chain=dstnat comment=DNS-REDIRECT dst-port=53 protocol=\
    udp to-addresses=10.8.0.1 to-ports=53
add action=redirect chain=dstnat comment=DNS-REDIRECT dst-port=53 protocol=\
    tcp to-addresses=10.8.0.1 to-ports=53
add action=masquerade chain=srcnat comment=Masquerade-WANs \
    out-interface-list=WANs
/ip hotspot walled-garden
add comment="place hotspot rules here" disabled=yes
add dst-host=*bibliaparalela.com* dst-port=80,443
/ip hotspot walled-garden ip
add action=accept disabled=no dst-host=www.uniq.edu.mx dst-port=443 protocol=\
    tcp
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/ppp aaa
set use-radius=yes
/ppp secret
add name=ppoe_cliente password=ppoe_cliente profile=2Mbps_PPPoE service=pppoe
add disabled=yes name=pppoe_user1 password=pppoe_user1 profile=2Mbps_PPPoE \
    service=pppoe
/radius
add address=38.XXX.2XX.XX1 secret=MyPswd service=ppp,hotspot timeout=3s
/radius incoming
set accept=yes
/system clock
set time-zone-name=America/Mexico_City
/system identity
set name=SnJose3
/system logging
add disabled=yes topics=hotspot,account,info,debug
/system ntp client
set enabled=yes primary-ntp=216.239.35.8
/system scheduler
add comment=">>RENEW DHCP" interval=5m name=Renew-dhcp-client on-event=\
    renew-dhcp-client policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jan/01/1970 start-time=18:45:37
add disabled=yes interval=1h name=USUARIOS-CONECTADOS on-event=":local userakt\
    if [/ip hotspot active print count-only];\r\
    \n/tool fetch url=\"https://api.callmebot.com/whatsapp.php\?phone=+5214891\
    115990&text=Usuarios+conectados+:+\$useraktif+&apikey=8008462\" keep-resul\
    t=no" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
add disabled=yes interval=2m name=PIHOLE-DNS on-event=DNS policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-time=startup
/system script
add comment=">>RENEW DHCP" dont-require-permissions=no name=renew-dhcp-client \
    owner=Rivera policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    if ( [/ping 8.8.8.8 interface=ether1 count=6 ] = 0 ) do={/ip dhcp-client r\
    enew ether1}"
add dont-require-permissions=no name=DNS owner=Rivera policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    ##### define variables here\r\
    \n\r\
    \n:local sysname [/system identity get name];\r\
    \n##:local Email \"[YOUR EMAIL ADDRESS FOR NOTIFICATIONS HERE]\"; ###### p\
    lease configure SMTP in /tools/email to use mail notifications\r\
    \n\r\
    \n:local PrimaryDNS \"10.8.0.1\";\r\
    \n:local BackupDNS \"1.1.1.1\"; #### CloudFare public DNS as backup (bette\
    r than Google's)\r\
    \n:local TestDomain \"mikrotik.com\"\r\
    \n:local c \"DNS-REDIRECT\"\r\
    \n:local ConfiguredDNS [/ip dns get servers];\r\
    \n\r\
    \n###### when router is in its primary configuration\r\
    \n:if (\$PrimaryDNS = \$ConfiguredDNS) do={\r\
    \n    :do { \r\
    \n        ###### test resolution\r\
    \n        :put [:resolve \$TestDomain server \$ConfiguredDNS];\r\
    \n\r\
    \n        ###### generate syslog messages\r\
    \n        /log info \"Primary DNS \$PrimaryDNS healthcheck completed, no i\
    ssues\";\r\
    \n\r\
    \n    } on-error={ \r\
    \n        :put \"resolver failed\"; \r\
    \n\r\
    \n        ###### generate syslog messages\r\
    \n        /log info \"name resolution using primary DNS \$PrimaryDNS faile\
    d\";\r\
    \n        /log info \"temporary setting backup DNS \$BackupDNS as primary\
    \";\r\
    \n\r\
    \n        ###### update DNS with backup DNS\r\
    \n        /ip dns set servers=\$BackupDNS; \r\
    \n\t/ip firewall nat disable [find comment=\$c];\r\
    \n        ###### send notification em\r\
    \n\r\
    \n/tool fetch url=\"https://api.callmebot.com/whatsapp.php\\\?phone=+52148\
    91115990&text=DNS+Cambiados+a+\$BackupDNS+&apikey=8008462\" keep-result=no\
    \r\
    \n#/tool fetch url=\"https://api.callmebot.com/whatsapp.php\?phone=+521489\
    1115990&apikey=8008462&text=Test+mikrotik\" keep-result=no\r\
    \n#/tool fetch url=\"https://api.callmebot.com/whatsapp.php\?phone=+521489\
    1115990&text=Se+cambiaron=los+DNS+:+%0ADNS:+\$PrimaryDNS+-+Device&apikey=8\
    008462\" keep-result=no\r\
    \n       # /tool e-mail send to=\"\$Email\" subject=\"\$sysname script not\
    ification: Primary DNS \$PrimaryDNS down\" body=\"Primary DNS \$PrimaryDNS\
    \_is down.\\r\\nDNS configuration changed to backup DNS \$BackupDNS.\"\r\
    \n       /log info \"Dns usados 1.1.1.1\";\r\
    \n    }\r\
    \n}\r\
    \n\r\
    \n###### when router is in its backup configuration\r\
    \n:if (\$BackupDNS = \$ConfiguredDNS) do={\r\
    \n    :do { \r\
    \n        ###### test resolution\r\
    \n        :put [:resolve \$TestDomain server \$PrimaryDNS];\r\
    \n\r\
    \n        ###### generate syslog messages\r\
    \n        /log info \"name resolution using primary DNS \$PrimaryDNS worki\
    ng now\";\r\
    \n        /log info \"restoring original DNS configuration\";\r\
    \n\r\
    \n        ###### revert back DNS configuration to original\r\
    \n        /ip dns set servers=\$PrimaryDNS;\r\
    \n\t/ip firewall nat enable [find comment=\$c];\r\
    \n        ###### send notification email\r\
    \n       #/tool fetch url=\"https://api.callmebot.com/whatsapp.php\?phone=\
    +5214891115990&text=Se+cambiaron=los+DNS+:+%0ADNS:+\$PrimaryDNS+-+Device&a\
    pikey=8008462\" keep-result=no\r\
    \n        #/tool e-mail send to=\"\$Email\" subject=\"\$sysname script not\
    ification: Primary DNS \$PrimaryDNS up\" body=\"Primary DNS \$PrimaryDNS i\
    s up.\\r\\nOriginal DNS configuration restored.\r\
    \n\t/tool fetch url=\"https://api.callmebot.com/whatsapp.php\\\?phone=+521\
    4891115990&text=DNS+Cambiados+a+Pihole+\$PrimaryDNS+&apikey=8008462\" keep\
    -result=no\r\
    \n\t/log info \"Dns cambiados a pihole\";\r\
    \n        \r\
    \n    } on-error={ \r\
    \n        :put \"resolver failed\";\r\
    \n\r\
    \n        ###### generate syslog messages\r\
    \n        /log info \"system is configured with backup DNS \$BackupDNS\";\
    \r\
    \n        /log info \"Primary DNS \$PrimaryDNS is still down, next check i\
    n 300 seconds\";\r\
    \n    }\r\
    \n}"
/tool bandwidth-server
set enabled=no
