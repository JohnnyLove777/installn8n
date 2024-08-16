#!/bin/bash

# Função para solicitar informações ao usuário e armazená-las em variáveis
function solicitar_informacoes {
    # Loop para solicitar e verificar o domínio
    while true; do
        read -p "Digite o domínio para o n8n (por exemplo, meuapp.com.br): " DOMINIO
        # Verifica se o domínio tem um formato válido
        if [[ $DOMINIO =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo "Por favor, insira um domínio válido no formato, por exemplo 'meuapp.com.br'."
        fi
    done    

    # Loop para solicitar e verificar o e-mail
    while true; do
        read -p "Digite o e-mail para cadastro do Certbot (sem espaços): " EMAIL
        # Verifica se o e-mail tem o formato correto e não contém espaços
        if [[ $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo "Por favor, insira um endereço de e-mail válido sem espaços."
        fi
    done

    # Armazena as informações inseridas pelo usuário nas variáveis globais
    EMAIL_INPUT=$EMAIL
    DOMINIO_INPUT=$DOMINIO
}

# Função para instalar o n8n de acordo com os comandos fornecidos
function instalar_n8n {
    # Atualização e upgrade do sistema
    sudo apt update
    sudo apt upgrade -y
    sudo apt-add-repository universe

    # Instalação das dependências
    sudo apt install -y python2-minimal nodejs npm git curl apt-transport-https ca-certificates software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
    sudo apt update
    sudo apt install -y docker-ce docker-compose
    sudo apt update
    sudo apt install nginx
    sudo apt update
    sudo apt install certbot
    sudo apt install python3-certbot-nginx
    sudo apt update

    # Adiciona usuário ao grupo Docker
    sudo usermod -aG docker ${USER}

    # Solicita informações ao usuário
    solicitar_informacoes

    # Criação do volume Docker para persistência de dados
    docker volume create n8n_data

    # Criação do arquivo de configuração do Nginx para o n8n
cat <<EOF > n8n_config.sh
server {
    server_name n8n.$DOMINIO_INPUT;

    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    # Copia o arquivo de configuração para o diretório do nginx
    sudo cp n8n_config.sh /etc/nginx/sites-available/n8n

    # Cria link simbólico para ativar o site no nginx
    sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled

    # Solicita e instala certificados SSL usando Certbot
    sudo certbot --nginx --email $EMAIL_INPUT --redirect --agree-tos -d n8n.$DOMINIO_INPUT

    # Instalação e execução do n8n usando Docker em segundo plano (detached)
    docker run -d --name n8n \
    -p 5678:5678 \
    -v n8n_data:/home/node/.n8n \
    docker.n8n.io/n8nio/n8n \
    start --tunnel

    echo "n8n instalado e configurado com sucesso! Acesse-o em https://n8n.$DOMINIO_INPUT."
}

# Chamada das funções
instalar_n8n
