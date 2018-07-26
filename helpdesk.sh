RETVAL=0
## get mini UID limit ##

case "$1" in
   "") 

# Este script envia automatiza a geração e inserção de chave  pública em um servidor ssh.
# Para ficar mais comodo envie esse arquivo para o diretório /usr/bin
# Uso 

# acesso vyos vyos@192.168.1.1
echo -e "\Provisionameto Helpdesk GLPI  no Docker \n"

echo -e "
install -- Instala o helpldesk, Traefik, Rancher Agent, Portainer, Banco de dados
remove  -- Remove o arquivo de configuração do GLPI
	"


	RETVAL=1
		;;
	remove-install|-r)

	docker exec -it $(docker ps -qf name=helpdesk) rm /var/www/html/glpi/install/install.php
	;;

	--install|-i)
	docker swarm init

	docker network create -d overlay net

	docker volume create portainer_data

	echo "Criando Traefik"

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



	echo "Criando dataserver"

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


	echo "Criando Helpdesk"

	docker service create \
	--name helpdesk \
	--replicas 1 \
	--restart-condition any \
	--network net \
	--label 'traefik.port=80' \
	--label traefik.frontend.rule="Host:wik.alfabe.ch;" \
	--mount type=volume,src=glpi,dst=/var/www/html/glpi \
	--hostname helpdesk \
	ferreirarocha/glpi:9.3


	echo "Criando Portainer"

	docker service create \
	--name portainer \
	--restart-condition any \
	--replicas=1 \
	--constraint 'node.role == manager' \
	--mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
	--mount type=volume,src=portainer_data,dst=/data \
	--label traefik.port=9000 \
	--label traefik.frontend.rule="Host:monitor.alfabe.ch;" \
	--network net \
	portainer/portainer \
	-H unix:///var/run/docker.sock


	echo "Criando Rancher"

	docker service create \
	--name rancher \
	--replicas 1 \
	--restart-condition any \
	--network net \
	--label 'traefik.port=8080' \
	--label traefik.frontend.rule="Host:rancher.alfabe.ch;" \
	--mount type=volume,src=rancher,dst=/var/lib/mysql \
	--mount type=volume,src=rancherdata,dst=/var/lib/rancher \
	--hostname rancher \
	rancher/server:stable
	

	esac
exit $RETVAL
