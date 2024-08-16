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

    # Armazena as informações inseridas pelo usuário nas variáveis globais
    DOMINIO_INPUT=$DOMINIO
}

# Função para instalar o n8n de acordo com os comandos fornecidos
function instalar_n8n {
    # Criação do volume Docker para persistência de dados
    docker volume create n8n_data

    # Solicita informações ao usuário
    solicitar_informacoes

    # Executa o n8n com o túnel e configurações especificadas
    docker run -it --rm \
    --name n8n \
    -p 5678:5678 \
    -v n8n_data:/home/node/.n8n \
    docker.n8n.io/n8nio/n8n \
    start --tunnel --tunnel.domain="$DOMINIO_INPUT"

    echo "n8n instalado e configurado com sucesso! Acesse-o em http://$DOMINIO_INPUT:5678."
}

# Chamada das funções
instalar_n8n
