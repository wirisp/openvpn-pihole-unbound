# openvpn-pihole-unbound
servidor  = Debian 11, instalacion de openvpn, pihole y unbound, 

## Instalacion de Openvpn para mikrotik en servidor debian / ubuntu..

- Primero descargamos el script a nuestro sistema , en este caso, debian 11.

```
wget https://raw.githubusercontent.com/volstr/openvpn-install-routeros/main/openvpn-install-routeros.sh -O openvpn-install-routeros.sh
#wget https://raw.githubusercontent.com/wirisp/openvpn-pihole-unbound/main/openvpn-install-routeros.sh -O openvpn-install-routeros.sh
```
- Despues ejecutamos el script descargado
```
sudo bash ./openvpn-install-routeros.sh
```
> si te pregunta el tipo de conexion , selecciona tcp

```
systemctl start openvpn-server@server.service
systemctl status openvpn-server@server.service
```

Con esto ya tenemos openvpn en el servidor, podemos usarlo con dispocitivos y funcionara muy bien, todo el trafico pasara por su interfaz, ahora si queremos usar pihole y unbound, ademas solamente usarlo como resolvedor DNS, entonces en la configuracion de openvpn hacemos lo siguiente.

- Permitir redireccion de trafico
```
echo "net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6 = 1" >/etc/sysctl.conf
```
- Guardamos cambios
```
sysctl -p
```

- Checar nuestra Ip 

```
SERVER_PUB_IPV4=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}')
read -rp "IPv4 public address: " -e -i "$SERVER_PUB_IPV4" SERVER_PUB_IP
```

_Con el comando anterior ya tendras tu Ip, si no te funciono, pero ya sabes cual es la ip de tu servidor publico, entonces en el paso siguiente solo cambia la variable $SERVER_PUB_IP por la ip ejemplo **local 38.242.229.xyz**_

- Reiniciar o borrar la config por default

```
> /etc/openvpn/server/server.conf
```

- Enviar los datos o configuraciones al servidor **server.conf**
```
echo "local $SERVER_PUB_IP
port 1194
proto tcp
dev tun
user nobody
group nogroup
persist-key
persist-tun
client-to-client
client-config-dir /etc/openvpn/client/
#topology subnet
ca ca.crt
cert server.crt
key server.key
dh dh.pem
#tls-crypt tc.key
#tls-auth tls-auth.key 0
#tls-server
#tls-version-min 1.2
#tls-cipher TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256
auth SHA1
server 10.8.0.0 255.255.255.0
#server-ipv6 fddd:1194:1194:1194::/64
#push "redirect-gateway def1 ipv6 bypass-dhcp"
ifconfig-pool-persist ipp.txt
#push "dhcp-option DNS 161.97.189.51"
#push "dhcp-option DNS 161.97.189.52"
push "10.8.0.1"
#push "route 10.8.0.1 255.255.255.255"
push "dhcp-option DNS 10.8.0.1"
keepalive 10 120
crl-verify crl.pem
cipher AES-256-CBC
ncp-ciphers AES-256-CBC
status /var/log/openvpn
verb 3
management localhost 7777" >/etc/openvpn/server/server.conf
```

Tambien comentamos unas lineas en el cliente , por lo que quedara asi

```
nano /etc/openvpn/server/client-common.txt
```

Deberia de quedar asi (cambia la ip publica por la de tu servidor**38.242.229.xyz** )

```
client
dev tun
proto tcp
remote 38.242.229.xyz 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA1
cipher AES-256-CBC
#ignore-unknown-option block-outside-dns
#block-outside-dns
verb 3
```

- Despues hacemos la siguiente instalacion de pihole y unbound

## Instalacion de pihole en el servidor

- Lo Instalamos primero con este comando, el cual posiblemente dara error por lo que usaremos el segundos seguido.

```
curl -sSL https://install.pi-hole.net | sudo bash
```

- Si recibes un error, entonces usar:

```
curl -sSL https://install.pi-hole.net | PIHOLE_SKIP_OS_CHECK=true bash
```

_En la configuracion, seleccionar la interfaz que fue creada al instalar openvpn, la cual deveria ser `tun0` o algo parecido._

- Reiniciamos el servicio de openvpn con

```
systemctl stop openvpn
systemctl start openvpn-server@server.service
systemctl status openvpn-server@server.service
```
_Si recibes un error checa mas abajo hay posibles errores y soluciones_
- Cambio de password con

```
pihole -a -p
```
- Este comando es para desinstalar pihole por si salio mal la instalacion

```
pihole uninstall
```

## Instalacion y configuracion de unbound
Instalamos unbound con el siguiente comando, no antes de darle permisos
```
wget https://raw.githubusercontent.com/wirisp/openvpn-pihole-unbound/main/unbound.sh -O unbound.sh
```

```
chmod +x *.sh
./unbound.sh 
```
Despues editamos el archivo

```
> /etc/pihole/setupVars.conf 
```

```
echo "PIHOLE_INTERFACE=tun0
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
CACHE_SIZE=10000
DNS_FQDN_REQUIRED=true
DNS_BOGUS_PRIV=true
DNSMASQ_LISTENING=single
WEBPASSWORD=a31c87c18e9ff2eca7edb3aa0f7ee8ec24e92157a6f55d873115fd4084c37b0c
BLOCKING_ENABLED=true
PIHOLE_DNS_1=127.0.0.1#5335
PIHOLE_DNS_2=127.0.0.1#5335
DNSSEC=false
REV_SERVER=false" >> /etc/pihole/setupVars.conf 
```

```
wget https://raw.githubusercontent.com/wirisp/openvpn-pihole-unbound/main/unbound.conf -O unbound.conf
\mv unbound.conf /etc/unbound/unbound.conf
```

- Activamos con

```
systemctl enable pihole-FTL
```

- Reiniciamos con
```
sudo reboot
```
- Despues de reiniciar checar los servicios

```
systemctl status openvpn
systemctl status unbound
systemctl status pihole-FTL
```

## Errores y soluciones posibles
- Error de que openvpn no inicia correctamente por que no encuentra algun certificado

```
systemctl start openvpn
systemctl status openvpn
```
Checamos el nombre del certificado faltante por ejemplo **Mk43**
Ahora creamos ese cliente con
```
sudo bash openvpn-install-routeros.sh
````
le damos en crear nuevo y colocamos el nombre tal cual aparece el faltante, posteriormente volcemos a ejecutar el comando y ahora lo eliminamos, despues reiniciamos openvpn con 

```
systemctl stop openvpn
systemctl start openvpn
systemctl status openvpn
```

- El Status de apache2 marca error

Instalamos net-tools para solucionar el error del puerto 80
```
apt install net-tools
```
```
netstat -ltnp | grep :80
```
Ahora hacemos kill al pid que obtuvimos, por ejemplo el 1047
```
sudo kill -9 1047
```
```
sudo systemctl stop apache2.service 
sudo systemctl enable apache2.service 
sudo systemctl start apache2.service
sudo systemctl status apache2.service
```

- Dns no resolve dominios

_Si hacemos un ping google.com y no da respuesta, entonces hay que modificar los dns_

Checar nuestro archivo resolv.conf
```
cat /etc/resolv.conf
```
Si el resultado da el siguiente y no da ping a ningun sitio

```
nameserver 127.0.0.1
```
Entonces lo cambiamos para tener ping.

```
nano /etc/resolv.conf
```
Colocar
```
nameserver 8.8.8.8
```
Y si al reiniciar se borran los datos entonces hay que editar alguno de estos dos archivos

Editar
```
nano /etc/resolvconf/resolv.conf.d/head
#Colocar dentro
nameserver 1.1.1.1
nameserver 1.0.0.1
```
o si no funciona este

```
nano /etc/resolvconf/resolv.conf.d/tail
#Colocar dentro
nameserver 1.1.1.1
nameserver 1.0.0.1
```


## Conexion a mikrotik
- Subir los archivos del cliente correspondientes, al Administrador de archivos, en este caso el cliente se llama Mk17, por lo que se suben `Mk17.crt` y `Mk17.key`
<img width="454" alt="image" src="https://user-images.githubusercontent.com/13319563/222213812-80b61638-2fc8-4ee0-b79e-902e7316d32d.png">

- Del servidor descargamos el .key y .crt que se encuentran en

```
/etc/openvpn/server/easy-rsa/pki/private/Mk17.key
/etc/openvpn/server/easy-rsa/pki/issued/Mk17.crt
```

- Despues en la terminal los importamos


```
certificate import passphrase="" file-name=Mk17.crt
certificate import passphrase="" file-name=Mk17.key
```

- Creamos el perfil que usaremos

```
/ppp profile add name=OVPN-client change-tcp-mss=yes only-one=yes use-encryption=yes use-mpls=no use-compression=no
```
- Creamos la inteface ppp para ovpn, cambia **xxx.xxx.xxx.xxx** por la ip de tu servidsor openvpn

<img width="291" alt="image" src="https://user-images.githubusercontent.com/13319563/222987665-9967a841-7c20-498e-8d89-a64fe9927757.png">

```
/interface ovpn-client add name=ovpn-client connect-to=xxx.xxx.xxx.xxx port=1194 mode=ip user="openvpn" password="" profile=OVPN-client certificate=Mk17.crt_0 auth=sha1 cipher=aes256 add-default-route=yes
```
- Cambia los Dns en 
```
/ip dns
set allow-remote-requests=yes servers=10.8.0.1
```

- Bloqueamos todas las peticiones entrantes de DNS
```
/ip firewall filter
add action=drop chain=input connection-state=new dst-port=53 in-interface-list=WANs protocol=udp
add action=drop chain=input connection-state=new dst-port=53 in-interface-list=WANs protocol=tcp
```

-Redirigimos las peticiones Dns a nuestro pihole u openvpn

```
/ip firewall nat add chain=dstnat action=redirect to-ports=53 protocol=udp dst-port=53 to-address=10.8.0.1 comment="DIRECT ALL DNS REQUESTS TO MIKROTIK INTERNAL DNS SERVER."
```

- y en el mangle
```
/ip firewall mangle
add action=change-mss chain=forward connection-mark=under_OPV new-mss=1360 \
    passthrough=yes protocol=tcp tcp-flags=syn tcp-mss=!0-1375
```

<img width="319" alt="image" src="https://user-images.githubusercontent.com/13319563/222987641-ad3f3498-df98-4f7f-8a7b-784f5a89027e.png">


>Listo ya tenemos configurado y corriendo Openvpn con pihole y unbound, podemos administrar desde `IP/admin`

- Cliente openvpn linux pop Os
`https://support.system76.com/articles/use-openvpn/`




