# rAthena Docker

Este projeto contém arquivos de configuração Docker para executar facilmente um servidor rAthena, um servidor de MMORPG baseado no Ragnarok Online.

## Requisitos

- [Docker](https://www.docker.com/products/docker-desktop/) instalado e em execução
- [Docker Compose](https://docs.docker.com/compose/install/) (normalmente já incluído no Docker Desktop)
- Aproximadamente 1GB de espaço em disco para a instalação inicial

## Arquivos incluídos

- `Dockerfile` - Define como construir a imagem do rAthena
- `docker-compose.yml` - Orquestra os containers do rAthena e do banco de dados
- `start.sh` - Script de inicialização para os servidores dentro do container

## Configuração no Windows

### Preparação

1. Certifique-se de que o Docker Desktop está instalado e em execução
2. O Docker Desktop no Windows usa WSL2 (Windows Subsystem for Linux). Se ainda não estiver instalado, o Docker geralmente solicita sua instalação durante a configuração.

### Passos para instalação

1. Clone este repositório ou baixe os arquivos para uma pasta local
   ```
   git clone https://github.com/seu-usuario/rathena-docker.git
   cd rathena-docker
   ```

2. Inicie os containers com Docker Compose
   ```
   docker-compose up -d
   ```
   
   Este comando construirá a imagem do rAthena e iniciará os containers necessários.

3. Verifique se os containers estão rodando
   ```
   docker ps
   ```
   
   Você deve ver dois containers em execução: `rathena-server` e `rathena-db`.

4. Verifique os logs para garantir que tudo está funcionando corretamente
   ```
   docker-compose logs -f
   ```

## Portas utilizadas

O servidor rAthena usa as seguintes portas padrão:

- Login Server: 6900
- Char Server: 6121
- Map Server: 5121
- Web Server: 8888

## Configuração do cliente Ragnarok

Configure seu cliente Ragnarok Online para se conectar ao servidor usando:

- Endereço: 127.0.0.1 (ou o IP do seu servidor se estiver acessando remotamente)
- Porta: 6900 (Login Server)

## Estrutura de diretórios

A configuração do Docker monta os seguintes diretórios como volumes para permitir a personalização:

- `./conf` → `/home/rathena/rAthena/conf`: Arquivos de configuração do servidor
- `./log` → `/home/rathena/rAthena/log`: Logs do servidor
- `./npc` → `/home/rathena/rAthena/npc`: Scripts de NPCs
- `./db` → `/home/rathena/rAthena/db`: Bancos de dados do jogo

## Comandos úteis

### Iniciar os containers
```
docker-compose up -d
```

### Verificar logs
```
docker-compose logs -f
```

### Parar os containers
```
docker-compose down
```

### Entrar no shell do container rAthena
```
docker exec -it rathena-server bash
```

### Reiniciar os servidores
```
docker-compose restart
```

### Reconstruir a imagem do rAthena (após alterações no Dockerfile)
```
docker-compose build --no-cache
docker-compose up -d
```

## Persistência de dados

Os dados do banco de dados MariaDB são armazenados em um volume Docker nomeado `db_data`. Isso significa que seus dados serão mantidos mesmo que você pare e reinicie os containers.

## Customização

### Modificar configurações do servidor

1. Edite os arquivos na pasta `conf/` que foi montada como um volume
2. Reinicie o container rAthena para aplicar as mudanças:
   ```
   docker-compose restart rathena
   ```

### Adicionar ou modificar NPCs

1. Edite os arquivos na pasta `npc/` que foi montada como um volume
2. Recarregue os scripts dentro do jogo usando comandos @reloadscript ou reinicie o servidor

### Modificar bancos de dados

1. Edite os arquivos na pasta `db/` que foi montada como um volume
2. Use comandos @reloadxxxdb dentro do jogo para recarregar ou reinicie o servidor

## Segurança

Para um ambiente de produção:

1. Altere as senhas padrão no arquivo docker-compose.yml
2. Configure um firewall para limitar o acesso às portas do servidor
3. Considere usar uma conexão HTTPS para o servidor web

## Solução de problemas

### O Docker não inicia no Windows

- Verifique se o WSL2 está instalado e configurado corretamente
- Reinicie o Docker Desktop
- Se persistir, reinicie o computador

### Problemas de compilação

- Verifique os logs com `docker-compose logs -f`
- Entre no container e tente compilar manualmente:
  ```
  docker exec -it rathena-server bash
  cd /home/rathena/rAthena
  ./configure && make clean && make server
  ```

### Erro "File not found: conf/inter_athena.conf"

Se você vir este erro nos logs, significa que os arquivos de configuração não foram criados corretamente:

1. Entre no container:
   ```
   docker exec -it rathena-server bash
   ```

2. Verifique se existem arquivos .conf.example:
   ```
   ls -la /home/rathena/rAthena/conf/*.example
   ```

3. Copie manualmente os arquivos de exemplo:
   ```
   cd /home/rathena/rAthena
   for f in conf/*.conf.example; do cp "$f" "${f%.example}"; done
   mkdir -p conf/import
   ```

4. Reinicie o container:
   ```
   exit
   docker-compose restart rathena
   ```

### Erro "Can't connect to MySQL server on '127.0.0.1'"

Se você vir este erro, significa que os servidores rAthena estão tentando conectar ao MySQL no endereço errado:

1. Entre no container:
   ```
   docker exec -it rathena-server bash
   ```

2. Edite o arquivo de configuração:
   ```
   cd /home/rathena/rAthena
   sed -i 's/127.0.0.1/db/g' conf/inter_athena.conf
   ```

3. Reinicie o container:
   ```
   exit
   docker-compose restart rathena
   ```

### Problemas de conexão com o cliente

- Verifique se as portas estão corretamente mapeadas (`docker ps`)
- Verifique se não há firewall bloqueando as conexões
- Verifique os logs do servidor para mensagens de erro

## Baseado em

- [rAthena](https://github.com/rathena/rathena)
- [Documentação de instalação do rAthena para Debian](https://github.com/rathena/rathena/wiki/Install-on-Debian)

## Contribuições

Contribuições são bem-vindas! Abra um issue ou um pull request para melhorar este projeto.

## Licença

Este projeto de dockerização está disponível sob a mesma licença do rAthena: [GNU General Public License v3.0](https://github.com/rathena/rathena/blob/master/LICENSE)