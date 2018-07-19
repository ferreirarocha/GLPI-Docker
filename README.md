# GLPI-Docker

Esse  projeto cria imagens do GLPI   executando sob o  Ubuntu 18.04 LTS.
Para  buildar uma imagems execute a seguitne instrução em seu docker  host.
Altere a tag  ferreirarocha para outra qualquer caso  desejar.


```
docker  build \
--build-arg LAST_RELEASE=9.3.0 \
--build-arg GLPI_VERSION=9.3 \
-t=ferreirarocha/glpi:9.3 .
```

