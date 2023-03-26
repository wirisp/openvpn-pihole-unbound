# openvpn-pihole-unbound
servidor  = Debian 11, instalacion de openvpn, pihole y unbound, 

## Instalacion de Openvpn para mikrotik
- Primero descargamos el script a nuestro sistema , ene ste caso, debian 11.
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
## Instalacion de pihole
1. Instalamos primero con este comando, el cual posiblemente dara error por lo que usaremos el segundos seguido.

```
curl -sSL https://install.pi-hole.net | sudo bash
```
Si da error entonces usar:
```
curl -sSL https://install.pi-hole.net | PIHOLE_SKIP_OS_CHECK=true bash
```
En la configuracion, seleccionar la interfaz que fue creada al instalar openvpn, la cual deveria ser `tun0` o algo parecido.

- Reiniciamos el servicio de openvpn con

```
systemctl start openvpn-server@server.service
systemctl status openvpn-server@server.service
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

- Activamos con

```
systemctl enable pihole-FTL
```

- Reiniciamos con
```
sudo reboot
```

## Conexion a mikrotik
- Subir los archivos del cliente correspondientes, al Administrador de archivos, en este caso el cliente se llama Mk17, por lo que se suben `Mk17.crt` y `Mk17.key`
<img width="454" alt="image" src="https://user-images.githubusercontent.com/13319563/222213812-80b61638-2fc8-4ee0-b79e-902e7316d32d.png">
- Despues en la terminal los importamos


```
certificate import passphrase="" file-name=Mk17.crt
certificate import passphrase="" file-name=Mk17.key
```

- Creamos el perfil que usaremos

```
ppp profile add name=OVPN-client change-tcp-mss=yes only-one=yes use-encryption=yes use-mpls=no use-compression=no
```
- Creamos la inteface ppp para ovpn

<img width="291" alt="image" src="https://user-images.githubusercontent.com/13319563/222987665-9967a841-7c20-498e-8d89-a64fe9927757.png">

```
interface ovpn-client add name=ovpn-client connect-to=xxx.xxx.xxx.xxx port=1194 mode=ip user="openvpn" password="" profile=OVPN-client certificate=Mk17.crt_0 auth=sha1 cipher=aes256 add-default-route=yes
```
- Cambia los Dns en 
```
/ip dns
set allow-remote-requests=no servers=10.8.0.1
```
<img width="319" alt="image" src="https://user-images.githubusercontent.com/13319563/222987641-ad3f3498-df98-4f7f-8a7b-784f5a89027e.png">


>Listo ya tenemos configurado y corriendo Openvpn con pihole y unbound, podemos administrar desde `IP/admin`

- Cambio de password con

```
pihole -a -p
```

- Desinstalacion de pihole
```
pihole uninstall
```
- Cliente openvpn linux pop Os
`https://support.system76.com/articles/use-openvpn/`

- posibles errores de apache2
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
```
nano /etc/resolv.conf
```
Colocar
```
nameserver 8.8.8.8
```
