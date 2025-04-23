# rAthena Docker

Este projeto contém arquivos de configuração Docker para executar facilmente um servidor rAthena, um emulador de servidor de MMORPG baseado no Ragnarok Online.

[![GitHub stars](https://img.shields.io/github/stars/rob-d3v/rathena-docker.svg)](https://github.com/rob-d3v/rathena-docker/stargazers)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/rathena/rathena/blob/master/LICENSE)

## Requisitos

- [Docker](https://www.docker.com/products/docker-desktop/) instalado e em execução
- [Docker Compose](https://docs.docker.com/compose/install/) (normalmente já incluído no Docker Desktop)
- Aproximadamente 1GB de espaço em disco para a instalação inicial
- Conexão à internet para baixar as imagens e dependências

## Arquivos incluídos

- `Dockerfile` - Define como construir a imagem do rAthena
- `docker-compose.yml` - Orquestra os containers do rAthena, banco de dados e FluxCP
- `start.sh` - Script de inicialização para os servidores dentro do container
- `rathena` - Arquivos base do rAthena, pode ser escolhido outro a preferência ou pode excluir, fazendo com que o script docker baixe o mais atual no repositório oficial do rAthena
- `fuxcp` - Arquivos base do fluxcp, pode ser escolhido outro a preferência ou pode excluir, fazendo com que o script docker baixe o mais atual no repositório oficial do rAthena fluxcp
  
## Instalação em diferentes sistemas operacionais

### Windows

#### Preparação

1. Certifique-se de que o Docker Desktop está instalado e em execução
2. O Docker Desktop no Windows usa WSL2 (Windows Subsystem for Linux). Se ainda não estiver instalado, o Docker geralmente solicita sua instalação durante a configuração.

#### Passos para instalação

1. Clone este repositório ou baixe os arquivos para uma pasta local
   ```bash
   git clone https://github.com/seu-usuario/rathena-docker.git
   cd rathena-docker
   ```

2. Inicie os containers com Docker Compose
   ```bash
   docker-compose up -d
   ```
   
   Este comando construirá a imagem do rAthena e iniciará os containers necessários.

3. Verifique se os containers estão rodando
   ```bash
   docker ps
   ```
   
   Você deve ver três containers em execução: `rathena-server`, `rathena-db` e `rathena-fluxcp`.

4. Verifique os logs para garantir que tudo está funcionando corretamente
   ```bash
   docker-compose logs -f
   ```

### Linux

#### Preparação

1. Instale o Docker e Docker Compose:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install docker.io docker-compose
   sudo systemctl enable --now docker

   # Fedora/CentOS
   sudo dnf install docker docker-compose
   sudo systemctl enable --now docker
   ```

2. Adicione seu usuário ao grupo docker (opcional, para executar Docker sem sudo):
   ```bash
   sudo usermod -aG docker $USER
   # Faça logout e login novamente para aplicar as mudanças
   ```

#### Passos para instalação

Siga os mesmos passos de clonagem e inicialização descritos na seção do Windows.

### macOS

#### Preparação

1. Instale o Docker Desktop para Mac a partir do site oficial do Docker
2. Inicie o Docker Desktop e aguarde até que ele esteja em execução (ícone verde na barra de status)

#### Passos para instalação

Siga os mesmos passos de clonagem e inicialização descritos na seção do Windows.

## Arquitetura do sistema

O projeto utiliza uma arquitetura de três containers principais:

1. **rathena-db** - Container MariaDB para armazenar todos os dados do jogo
   - Armazena contas, personagens, inventários, etc.
   - Dados persistentes em volume dedicado

2. **rathena-server** - Container com os serviços do rAthena
   - Login Server: Gerencia autenticação
   - Char Server: Gerencia seleção de personagens
   - Map Server: Gerencia o mundo do jogo
   - Web Server: Interface web opcional

3. **rathena-fluxcp** - Container com o painel de controle FluxCP
   - Painel de administração para o servidor rAthena
   - Interface web para gerenciamento de contas, personagens, etc.
   - Permite aos jogadores criar contas e gerenciar seus personagens

A comunicação entre os containers é feita através de uma rede Docker interna, garantindo segurança e desempenho.

## Portas utilizadas

O servidor rAthena usa as seguintes portas padrão:

- Login Server: 6900
- Char Server: 6121
- Map Server: 5121
- FluxCP: 80 (ou 8080, dependendo da configuração)

Estas portas são expostas do container para o host, permitindo conexões de clientes do Ragnarok Online.

## Configuração do cliente Ragnarok

https://1drv.ms/u/s!Ap-GSbZ2M5Mzh0S4cS0nG3ZFBwkx?e=H8ui15 (Client Renewal, Pre-Renewal e 4th)
https://1drv.ms/u/s!Ap-GSbZ2M5Mzh0UdO8crrx5zIUkA?e=xWbKQU (kRO)

Baixe os dois arquivos acima, escolha qual tipo de servidor Renewal, Pre-Renewal ou 4th e copie para dentro do kRO

Configure seu cliente Ragnarok Online para se conectar ao servidor usando:

- Endereço: 127.0.0.1 (para acesso local) ou seu IP local/público (para acesso remoto)
- Porta: 6900 (Login Server)

### Encontrando seu IP local

#### Windows
Abra o Prompt de Comando (cmd) e digite:
```bash
ipconfig
```

#### Linux
Abra o Terminal e digite:
```bash
hostname -I
```

#### macOS
Abra o Terminal e digite:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Configuração de arquivos do cliente 

Para a maioria dos clientes, você precisa editar, dentro da pasta data, ou criar.

1. **clientinfo.xml** 
   ```xml
   <address>
     <version>55</version>
     <langtype>1</langtype>
     <registrationweb>http://127.0.0.1:8080/</registrationweb>
     <address>127.0.0.1</address>
     <port>6900</port>
     <servertype>5</servertype>
     <serviceType>0</serviceType>
   </address>
   ```
## Estrutura de diretórios

A configuração do Docker monta os seguintes diretórios como volumes para permitir a personalização:

- `./conf` → `/home/rathena/rAthena/conf`: Arquivos de configuração do servidor
- `./log` → `/home/rathena/rAthena/log`: Logs do servidor
- `./npc` → `/home/rathena/rAthena/npc`: Scripts de NPCs
- `./db` → `/home/rathena/rAthena/db`: Bancos de dados do jogo
- `./fluxcp` → `/var/www/html`: Arquivos do FluxCP

## FluxCP - Painel de Controle

O FluxCP é um painel de controle web para o servidor rAthena que permite gerenciar contas, personagens, itens, e muito mais. Ele é incluído como um container separado nesta configuração.

### Acessando o FluxCP

Você pode acessar o FluxCP através do navegador usando:

- URL: http://localhost:8080 (ou a porta que você configurou)

### Configuração do FluxCP

Os principais arquivos de configuração do FluxCP estão localizados em:

- `./fluxcp/config/application.php` - Configurações gerais do FluxCP
- `./fluxcp/config/servers.php` - Configurações de conexão com os servidores rAthena

### Permissões para o FluxCP

**Nota Importante**: Se você encontrar problemas de permissão ao acessar o FluxCP, pode ser necessário ajustar as permissões da pasta `data` dentro do container. Execute o seguinte comando:

```bash
docker exec -it rathena-fluxcp bash -c "chown -R www-data:www-data /var/www/html/data"
# ou usando IDs
docker exec -it rathena-fluxcp bash -c "chown -R 33:33 /var/www/html/data"
```

Para automatizar este processo, o script `docker-entrypoint.sh` foi incluído no container do FluxCP para garantir que as permissões sejam configuradas corretamente na inicialização do container.

### Recursos do FluxCP

- Registro e gerenciamento de contas
- Visualização e edição de personagens
- Loja de itens
- Rankings de jogadores e guildas
- Sistema de doações
- Gerenciamento de GM
- Visualização de logs e estatísticas

## Comandos úteis

### Iniciar os containers
```bash
docker-compose up -d
```

### Verificar logs
```bash
docker-compose logs -f
```

### Parar os containers
```bash
docker-compose down
```

### Entrar no shell do container rAthena
```bash
docker exec -it rathena-server bash
```

### Entrar no shell do container FluxCP
```bash
docker exec -it rathena-fluxcp bash
```

### Entrar no MySQL do container de banco de dados
```bash
docker exec -it rathena-db mysql -uragnarok -pragnarok ragnarok
```

### Reiniciar os servidores
```bash
docker-compose restart
```

### Reconstruir a imagem do rAthena (após alterações no Dockerfile)
```bash
docker-compose build --no-cache
docker-compose up -d
```

### Verificar status dos serviços rAthena dentro do container
```bash
docker exec -it rathena-server ps aux | grep -E 'login-server|char-server|map-server|web-server'
```

### Fazer backup do banco de dados
```bash
docker exec rathena-db mysqldump -uragnarok -pragnarok ragnarok > backup_$(date +%Y%m%d).sql
```

### Restaurar backup do banco de dados
```bash
cat backup_20250417.sql | docker exec -i rathena-db mysql -uragnarok -pragnarok ragnarok
```

## Persistência de dados

Os dados do banco de dados MariaDB são armazenados em um volume Docker nomeado `db_data`. Isso significa que seus dados serão mantidos mesmo que você pare e reinicie os containers.

## Customização

### Modificar configurações do servidor

1. Edite os arquivos na pasta `conf/` que foi montada como um volume
2. Reinicie o container rAthena para aplicar as mudanças:
   ```bash
   docker-compose restart rathena
   ```

### Customizar o FluxCP

1. Edite os arquivos na pasta `fluxcp/` que foi montada como um volume
2. As alterações serão imediatamente visíveis no navegador, sem necessidade de reiniciar o container

### Adicionar ou modificar NPCs

1. Edite os arquivos na pasta `npc/` que foi montada como um volume
2. Recarregue os scripts dentro do jogo usando comandos @reloadscript ou reinicie o servidor

### Modificar bancos de dados

1. Edite os arquivos na pasta `db/` que foi montada como um volume
2. Use comandos @reloadxxxdb dentro do jogo para recarregar ou reinicie o servidor

## Segurança

Para um ambiente de produção:

1. Altere as senhas padrão no arquivo docker-compose.yml:
   ```yaml
   environment:
     MYSQL_ROOT_PASSWORD: sua_senha_segura
     MYSQL_PASSWORD: outra_senha_segura
   ```

2. Configure um firewall para limitar o acesso às portas do servidor:
   ```bash
   # UFW (Ubuntu/Debian)
   sudo ufw allow from 192.168.1.0/24 to any port 6900,6121,5121,8888,8080 proto tcp

   # firewalld (CentOS/Fedora)
   sudo firewall-cmd --permanent --add-port=6900/tcp --add-port=6121/tcp --add-port=5121/tcp --add-port=8888/tcp --add-port=8080/tcp
   sudo firewall-cmd --reload
   ```

3. Considere usar uma conexão HTTPS para o servidor web e FluxCP
4. Implemente uma solução de backup regular:
   ```bash
   # Adicione ao crontab
   0 3 * * * docker exec rathena-db mysqldump -uragnarok -pragnarok ragnarok > /backups/rathena_$(date +\%Y\%m\%d).sql
   ```

## Monitoramento

Para monitorar o desempenho dos seus containers, você pode usar:

1. **Docker Stats**
   ```bash
   docker stats rathena-server rathena-db rathena-fluxcp
   ```

2. **Portainer** - Interface web para gerenciamento de Docker
   ```bash
   docker volume create portainer_data
   docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
   ```
   Acesse http://localhost:9000

## Solução de problemas

### O Docker não inicia no Windows

- Verifique se o WSL2 está instalado e configurado corretamente
- Reinicie o Docker Desktop
- Se persistir, reinicie o computador

### Problemas com o FluxCP

Se você encontrar problemas ao acessar o FluxCP ou ver erros relacionados a permissões:

1. Verifique as permissões da pasta data:
   ```bash
   docker exec -it rathena-fluxcp bash -c "ls -la /var/www/html/data"
   ```

2. Corrija as permissões:
   ```bash
   docker exec -it rathena-fluxcp bash -c "chown -R www-data:www-data /var/www/html/data"
   docker exec -it rathena-fluxcp bash -c "chmod -R 777 /var/www/html/data"
   ```

3. Verifique as configurações de conexão com o banco de dados em `fluxcp/config/servers.php`:
   ```bash
   docker exec -it rathena-fluxcp bash -c "cat /var/www/html/config/servers.php | grep -A 5 Hostname"
   ```

4. Certifique-se de que as configurações de conexão com o servidor rAthena estejam corretas em `fluxcp/config/application.php`:
   ```bash
   docker exec -it rathena-fluxcp bash -c "cat /var/www/html/config/application.php | grep -A 5 ServerAddress"
   ```

### Problemas de compilação

- Verifique os logs com `docker-compose logs -f`
- Entre no container e tente compilar manualmente:
  ```bash
  docker exec -it rathena-server bash
  cd /home/rathena/rAthena
  ./configure && make clean && make server
  ```

### Erro "File not found: conf/inter_athena.conf"

Se você vir este erro nos logs, significa que os arquivos de configuração não foram criados corretamente:

1. Entre no container:
   ```bash
   docker exec -it rathena-server bash
   ```

2. Verifique se existem arquivos .conf.example:
   ```bash
   ls -la /home/rathena/rAthena/conf/*.example
   ```

3. Copie manualmente os arquivos de exemplo:
   ```bash
   cd /home/rathena/rAthena
   for f in conf/*.conf.example; do cp "$f" "${f%.example}"; done
   mkdir -p conf/import
   ```

4. Reinicie o container:
   ```bash
   exit
   docker-compose restart rathena
   ```

### Erro "Can't connect to MySQL server on '127.0.0.1'"

Se você vir este erro, significa que os servidores rAthena estão tentando conectar ao MySQL no endereço errado:

1. Entre no container:
   ```bash
   docker exec -it rathena-server bash
   ```

2. Edite o arquivo de configuração:
   ```bash
   cd /home/rathena/rAthena
   sed -i 's/127.0.0.1/db/g' conf/inter_athena.conf
   ```

3. Reinicie o container:
   ```bash
   exit
   docker-compose restart rathena
   ```

### Erro "Connection refused" ao tentar conectar ao login-server

1. Verifique se o login-server está rodando:
   ```bash
   docker exec -it rathena-server ps aux | grep login-server
   ```

2. Se não estiver rodando, verifique os logs:
   ```bash
   docker exec -it rathena-server cat /home/rathena/rAthena/log/login-server.log
   ```

3. Certifique-se de que o bind_ip está configurado para 0.0.0.0 em login_athena.conf:
   ```bash
   docker exec -it rathena-server grep bind_ip /home/rathena/rAthena/conf/login_athena.conf
   ```

4. Se necessário, corrija a configuração:
   ```bash
   docker exec -it rathena-server sed -i 's/^bind_ip: .*$/bind_ip: 0.0.0.0/' /home/rathena/rAthena/conf/login_athena.conf
   ```

5. Reinicie o container:
   ```bash
   docker-compose restart rathena
   ```

### Problemas de conexão com o cliente

- Verifique se as portas estão corretamente mapeadas (`docker ps`)
- Verifique se não há firewall bloqueando as conexões
- Verifique os logs do servidor para mensagens de erro

## Criando contas administrativas

Para criar uma conta administrativa no servidor:

1. Entre no MySQL do container de banco de dados:
   ```bash
   docker exec -it rathena-db mysql -uragnarok -pragnarok ragnarok
   ```

2. Crie uma conta com nível de acesso 99:
   ```sql
   INSERT INTO login (account_id, userid, user_pass, sex, group_id) VALUES (2000000, 'admin', 'senha', 'M', 99);
   ```
*OBS: se desejar pode ser adicionado criptografia MD5 no servidor para armazenar as senhas no banco.

3. Saia do MySQL:
   ```sql
   exit;
   ```

4. Ou use o painel FluxCP para criar e gerenciar contas com privilégios administrativos.

## Atualizando o rAthena

Para atualizar para a versão mais recente do rAthena:

1. Pare os containers:
   ```bash
   docker-compose down
   ```

2. Entre na pasta do rAthena no host (não no container):
   ```bash
   cd caminho/para/seu/projeto
   ```

3. Reconstrua a imagem:
   ```bash
   docker-compose build --no-cache
   ```

4. Inicie os containers novamente:
   ```bash
   docker-compose up -d
   ```

## Atualizações de segurança

Para garantir que seus containers estejam sempre seguros:

1. Atualize regularmente as imagens base:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

2. Verifique por vulnerabilidades:
   ```bash
   docker scan rathena-server
   docker scan rathena-db
   docker scan rathena-fluxcp
   ```

## Baseado em

- [rAthena](https://github.com/rathena/rathena)
- [FluxCP](https://github.com/rathena/FluxCP)
- [Documentação de instalação do rAthena para Debian](https://github.com/rathena/rathena/wiki/Install-on-Debian)

## Doações

Se este projeto foi útil para você, considere fazer uma doação para apoiar o desenvolvimento contínuo:

![QR Code PIX](qrCode.png)

Escaneie o código QR acima para fazer uma doação via PIX.

- LinkedIn: [https://www.linkedin.com/in/robseng/](https://www.linkedin.com/in/robseng/)
- GitHub: [https://github.com/rob-d3v](https://github.com/rob-d3v)

## Contribuições

Contribuições são bem-vindas! Abra um issue ou um pull request para melhorar este projeto.

## Licença

Este projeto de dockerização está disponível sob a mesma licença do rAthena: [GNU General Public License v3.0](https://github.com/rathena/rathena/blob/master/LICENSE)
