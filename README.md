# openvpn-pihole-unbound
servidor  = Debian 11, instalacion de openvpn, pihole y unbound, 

## Instalacion de Openvpn para mikrotik
- Primero descargamos el script a nuestro sistema , ene ste caso, debian 11.
```
wget https://raw.githubusercontent.com/volstr/openvpn-install-routeros/main/openvpn-install-routeros.sh -O openvpn-install-routeros.sh
```
- Despues ejecutamos el script descargado
```
sudo bash ./openvpn-install-routeros.sh
```
> si te pregunta el tipo de conexion , selecciona tcp

- Despues cambiamos los dns con

```
nano /etc/openvpn/server/server.conf
```

_Comentamos las lineas siguientes y en su lugar colocamos una nueva con la ip que usaremos de DNS_
```
#Stop using Google DNS for our OpenVPN
#push "dhcp-option DNS 8.8.8.8"
#push "dhcp-option DNS 8.8.4.4"
```
- Colocamos esta nueva

```
push "dhcp-option DNS 10.8.0.1"
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
REV_SERVER=false" >> /etc/openvpn/server/server.conf
```

- Activamos con

```
systemctl enable pihole-FTL
```
## Conexion a mikrotik
- Subir los archivos del cliente correspondientes, al Administrador de archivos, en este caso el cliente se llama Mk17, por lo que se suben `Mk17.crt` y `Mk17.key`
<img width="454" alt="image" src="https://user-images.githubusercontent.com/13319563/222213812-80b61638-2fc8-4ee0-b79e-902e7316d32d.png">
- Despues en la terminal los importamos
```
certificate import file-name=Mk17.crt
certificate import file-name=Mk17.key
```
- Creamos el perfil que usaremos

```
ppp profile add name=OVPN-client change-tcp-mss=yes only-one=yes use-encryption=yes use-mpls=no use-compression=no
```
- Creamos la inteface ppp para ovpn
```
interface ovpn-client add name=ovpn-client connect-to=xxx.xxx.xxx.xxx port=1194 mode=ip user="openvpn" password="" profile=OVPN-client certificate=Mk17.crt_0 auth=sha1 cipher=blowfish128 add-default-route=yes
```
- Reiniciamos con
```
sudo reboot
```