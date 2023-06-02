# GLPI Install Script 🖥️

## 📝 Descrição

Este é um script de shell que automatiza a instalação do GLPI (Gestionnaire libre de parc informatique), um software de código aberto que ajuda as empresas a gerenciar seus recursos de TI. Este script foi projetado para ser executado em sistemas baseados em Debian e instalará todas as dependências necessárias para executar o GLPI, bem como o próprio software.

## 🚀 Pré-requisitos

Para executar este script, você precisará de um sistema Linux baseado em Debian com privilégios de sudo.

## 🎮 Como usar

1. Faça download do script.
2. Torne o script executável usando o comando:
    ```bash
    chmod +x nome_do_script.sh
    ```
3. Execute o script com privilégios de sudo:
    ```bash
    sudo ./nome_do_script.sh
    ```

## ⚙️ Funcionalidade

O script executa as seguintes tarefas:

1. Verifica se o comando 'sudo' está disponível.
2. Atualiza todos os pacotes do sistema.
3. Instala uma lista pré-definida de pacotes necessários.
4. Configura o VirtualHost do Apache.
5. Verifica a existência do diretório /var/www e o cria, se necessário.
6. Baixa a versão especificada do GLPI.
7. Ajusta as permissões do diretório do GLPI.
8. Cria um banco de dados e um usuário para o GLPI no MySQL e concede a esse usuário todos os privilégios nesse banco de dados.
9. Configura a tarefa cron para executar o cron do GLPI.
10. Remove o arquivo de instalação do GLPI.
11. Configura o cache do GLPI para usar o Redis.
12. Verifica os requisitos do sistema para a instalação do GLPI.
13. Instala o GLPI usando o comando de instalação do GLPI.

## 📃 Detalhes do Código

O script usa uma série de funções auxiliares para verificar a existência de pacotes e comandos, instalar pacotes, verificar e criar diretórios e lidar com possíveis erros durante a execução de comandos MySQL.

## 🛠️ Variáveis Configuráveis

- `version`: Versão do GLPI a ser instalada. 🖥️
- `glpipassword`: Senha a ser usada para o usuário do banco de dados do GLPI. 🔒
- `glpiuser`: Nome de usuário a ser usado para autenticação do banco de dados pelo GLPI. 👤
- `glpidb`: Nome do banco de dados do GLPI. 🗄️

Essas variáveis podem ser alteradas conforme necessário para se adequar ao seu ambiente.
