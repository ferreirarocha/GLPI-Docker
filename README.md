Esse projeto cria imagens do GLPI executando sob o Ubuntu 18.04 LTS
faz uso do docker  swarm e  o traefik para trabalhar como proxy reverso, tanto  o docker  swarm quanto o traefik são opcionais mas o adotamos  para trabalhar como cluster  e  proxy reverso em nosso ambiente.



​     


#### Iniciando o Swarm

```bash
docker swarm init
```


​     


#### Inicializando o rede

```bash
docker network create -d overlay net
```


​     


#### Criando uma  imagem

Caso queira  buildar a images com suas próprias modificações baixe e altere o dockerfile acima

[Dockerfile](https://github.com/ferreirarocha/GLPI-Docker/blob/master/Dockerfile)



```
docker  build \
--build-arg LAST_RELEASE=9.3.0 \
--build-arg GLPI_VERSION=9.3 \
-t=ferreirarocha/glpi:9.3 .
```


​     


#### Criand  o serviço Traefik - Proxy Reverso

```yaml
docker service create --name traefik \
--constraint 'node.role==manager' \
--publish 80:80 \
--publish 8080:8080 \
--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
--network net \
traefik:camembert \
--docker \
--docker.swarmmode \
--docker.domain=alfabe.ch \
--docker.watch \
--logLevel=DEBUG \
--web
```


​     


#### Criando  o serviço  MariaDB  - Banco de Dados

Estamos usando a imagem oficial do MariaDB para esse projeto, mas  no  mundo docker   não há um consenso sobre a segurança do uso de  banco de dados   executando via container, seu uso é muitas vezes é indicado  para local onde não  há uma carga de trabalho excessiva.


​     



```yaml
docker service create \
--name dataserver \
--replicas 1 \
--restart-condition any \
--network net \
--mount type=volume,source=maria-vol,destination=/var/lib/mysql \
--hostname dataserver \
--env MYSQL_ROOT_PASSWORD=12345 \
--env MYSQL_DATABASE=glpi \
--env MYSQL_PASSWORD=12345 \
--env MYSQL_USER=glpi \
-p 3306:3306 \
mariadb

```

​     

#### Criando o serviço GLPI - Helpdesk

Estamos utilizando a imagem  ferreirarocha/glpi:9.3, mas recomendomos o uso de suas próprias imagens em ambiente de produção.

```yaml
docker service create \
--name helpdesk \
--replicas 1 \
--restart-condition any \
--network net \
--label 'traefik.port=80' \
--label traefik.frontend.rule="Host:suporte.alfabe.ch;" \
--mount type=volume,src=glpi,dst=/var/www/html/glpi \
--hostname helpdesk \
ferreirarocha/glpi:9.3

```


​     

#### Criando o serviço para o Portainer

```
docker volume create portainer_data
```


​     


```
docker service create \
--name portainer \
--publish 9000:9000 \
--restart-condition any \
--replicas=1 \
--constraint 'node.role == manager' \
--mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
--mount type=volume,src=portainer_data,dst=/data \
--label 'traefik.port=80' \
--label traefik.frontend.rule="Host:monitor.alfabech.eti.br;" \
portainer/portainer \
-H unix:///var/run/docker.sock
```


​     

#### Configurando o DNS

Nesse momento você deve apontar  o domínio do seu serviço  para  o servidor que está executando o Docker com Traefik, essa tarefa  é bem simples, seja em um Windows Server, Bind , Zero-Shell ou qulqer outro servidor de DNS que você  possua em sua rede.
nesse laboratório faremos a ateração diretamente no arquivo de hosts do sistema

Abra-o e insira o  novo dominio

```
nano /etc/hosts
```

​     


Ficará algo como na figura abaixo

```
127.0.0.1    localhost
192.168.1.111   http://suporte.alfabe.ch
```


​     


A  próxima etapa  e tão esperada é acessar o serviço via  web, e consumir o serviço, nesse caso

http://suporte.alfabe.ch


​     


Conclua o processo de instalação do GLPI

