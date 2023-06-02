#!/bin/bash

set -e

#Funções do Script.

function check_package() {
    dpkg -s "$1" >/dev/null 2>&1
}

function check_command() {
    command -v "$1" >/dev/null 2>&1
}

function install_package() {
    local package=$1
    if check_package "$package"; then
        echo "$package já está instalado."
    else
        echo "Instalando $package..."
        sudo apt-get -y install "$package"
        echo "Instalação de $package concluída."
    fi
}

function verify_directory() {
    local directory=$1
    if [ ! -d "$directory" ]; then
        echo "Diretório $directory não encontrado. Criando diretório..."
        mkdir -p "$directory"
        if [ $? -ne 0 ]; then
            echo "Erro ao criar o diretório: $directory"
            exit 1
        fi
        echo "Diretório $directory criado."
    fi
}

function check_mysql_command() {
    local command_status=$1
    local error_message=$2
    local user_message=$3

    if [ $command_status -ne 0 ]; then
        if [[ $command_status -eq 1396 ]]; then
            echo "$user_message já existe."
        else
            echo "Erro ao $error_message."
            exit 1
        fi
    fi
}

# Verificar comando sudo
if ! check_command sudo; then
    echo "Erro: 'sudo' não encontrado. Este script deve ser executado com privilégios de sudo."
    exit 1
fi

# Atualizar pacotes do sistema
echo "Atualizando os pacotes do sistema..."
sudo apt-get -y update
echo "Atualização concluída."

# Variaveis

# Variavél responsavel pela instalação de pacotes.
packages=(
  "xz-utils"
  "bzip2"
  "unzip"
  "curl"
  "apache2"
  "libapache2-mod-php"
  "php-soap"
  "php-cas"
  "php"
  "php-apcu"
  "php-cli"
  "php-common"
  "php-curl"
  "php-gd"
  "php-imap"
  "php-ldap"
  "php-mysql"
  "php-xmlrpc"
  "php-xml"
  "php-mbstring"
  "php-bcmath"
  "php-intl"
  "php-zip"
  "php-redis"
  "php-bz2"
  "mariadb-server"
  "redis"
)

#Versão que deseja instalar do GLPI
version="10.0.7"            #---- Versão do GLPI que irá utilizar

glpipassword=123456         #---- Senha que será usadano banco de dados.
glpiuser=glpiuser           #---- Usuario que será utilizado na autenticação do banco de dados por parte do GLPI
glpidb=glpidb               #---- Nome do banco de dados do GLPI.

# Instalar pacotes
for package in "${packages[@]}"; do
    install_package "$package"
done

# Configurar VirtualHost do Apache
cat > /etc/apache2/conf-available/glpi10.conf << EOF
<VirtualHost *:80>
    ServerName glpi10.local
    ServerAdmin suporte@it.com
    DocumentRoot /var/www/glpi/
    ErrorLog \${APACHE_LOG_DIR}/glpi.error.log
    CustomLog \${APACHE_LOG_DIR}/glpi.access.log combined
</VirtualHost>
EOF

# Habilitar módulo e configuração do Apache
a2enmod rewrite
a2enconf glpi10.conf

# Reiniciar Apache
systemctl restart apache2
if [ $? -ne 0 ]; then
    echo "Erro ao reiniciar o Apache2"
    exit 1
fi

# Verificar diretório /var/www/
verify_directory "/var/www"

# Baixar o GLPI com o Wget
cd /var/www
if [ ! -d "/var/www/glpi" ]; then
    echo "Diretório /var/www/glpi não encontrado. baixando o GLPI-$version..."
    wget https://github.com/glpi-project/glpi/releases/download/$version/glpi-$version.tgz
    tar -xvzf glpi-$version.tgz
    rm glpi-$version.tgz
    if [ $? -ne 0 ]; then
        echo "Erro ao clonar o repositório."
        exit 1
    fi
    echo "Diretório /var/www/glpi criado."
fi

# Ajustar propriedades e permissões
chown www-data. /var/www/glpi -Rf
find /var/www/glpi -type d -exec chmod 755 {} +
find /var/www/glpi -type f -exec chmod 644 {} +

# Comandos para criar o banco de dados
mysql -e "CREATE DATABASE IF NOT EXISTS $glpidb CHARACTER SET utf8"
check_mysql_command $? "criar o banco de dados" "O banco de dados '$glpidb'"

# Comandos para criar o usuário
mysql -e "CREATE USER IF NOT EXISTS '$glpiuser'@'localhost' IDENTIFIED BY '$glpipassword'"
check_mysql_command $? "criar o usuário '$glpiuser'" "O usuário '$glpiuser'"

# Comandos para conceder privilégios
mysql -e "GRANT ALL PRIVILEGES ON $glpidb.* TO '$glpiuser'@'localhost' WITH GRANT OPTION"
check_mysql_command $? "conceder privilégios ao usuário" "Os privilégios"

echo "DB configurado, concluído com sucesso."

# Configurar cron
echo -e "* *\t* * *\troot\tphp /var/www/glpi/front/cron.php" >> /etc/crontab
systemctl restart cron

# Remover arquivo de instalação
rm -Rf /var/www/glpi/install/install.php

# Verificar remoção do arquivo de instalação
if [ ! -f "/var/www/glpi/install/install.php" ]; then
    echo "O arquivo install.php foi excluído com sucesso."
else
    echo "Erro ao excluir o arquivo: /var/www/glpi/install/install.php"
    exit 1
fi

# Configurar cache com Redis
php /var/www/glpi/bin/console cache:configure --context=core --dsn=redis://127.0.0.1:6379
# Verifica os requisitos do sistema
php /var/www/glpi/bin/console glpi:system:check_requirements
# Faz a instalação do GLPI por meio de CLI
php /var/www/glpi/bin/console db:install -H localhost -P  -d $glpidb -u $glpiuser -p $glpipassword

echo " O GLPI foi instalado na $version e para acessar pode colocar apenas `hostname -I`"
