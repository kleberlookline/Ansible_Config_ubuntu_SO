#!/bin/bash

# Criar diretório para scripts
mkdir -p /root/scripts

# Configurar nome de usuário e email no Git
git config --global user.name "Kleber Oliveira"
git config --global user.email "kleber.lookline@gmail.com"

# Listar conteúdo da pasta ~/.ssh
ls -al ~/.ssh

# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -C "kleber.lookline@gmail.com"

# Iniciar o agente SSH
eval "$(ssh-agent -s)"

# Adicionar chave privada ao agente SSH
ssh-add ~/.ssh/id_rsa

# Exibir chave pública
cat ~/.ssh/id_rsa.pub

# Testar conexão SSH com GitHub
ssh -T git@github.com

