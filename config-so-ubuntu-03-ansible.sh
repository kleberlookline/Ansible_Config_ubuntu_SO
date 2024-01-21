#!/bin/bash
# Script criado para subir novo servidor ubuntu - data 15/01/2024 - kleber oliveira - equipe SRE

# Atualiza o sistema
echo "Atualizando o sistema..."
apt update
apt dist-upgrade -y

# Instala o Ansible
echo "Instalando o Ansible..."
apt install ansible -y

# Verifica se a coleção community.general já está instalada
if [ -d /root/.ansible/collections/ansible_collections/community/general ]; then
    echo "A coleção community.general já está instalada. Pulando este passo."
else
    echo "Instalando a coleção community.general..."
    ansible-galaxy collection install community.general
fi

# Cria o arquivo playbook.yml
cat <<EOL > playbook.yml
---
- hosts: localhost
  become: true
  become_user: root
  vars:
    created_username: kleber
    new_hostname: geral-ubuntu-02  # Novo nome do servidor

  tasks:
    - name: Obter versão do kernel antes da atualização
      command: uname -r
      register: kernel_version_before

    - name: Obter nome do host antes da atualização
      command: hostname
      register: current_hostname

    - name: Remover linhas do arquivo /root/.bashrc
      replace:
        path: /root/.bashrc
        regexp: '^(HISTSIZE=.*|HISTFILESIZE=.*|HISTTIMEFORMAT=.*)$'
        replace: ''

    - name: Inserir linha alias vi='vim' no arquivo /root/.bashrc se não existir
      lineinfile:
        path: /root/.bashrc
        line: 'alias vi=vim'
        state: present

    - name: Remover linha do CD-ROM do arquivo sources.list
      command: sudo sed -i '1d' /etc/apt/sources.list
      register: sources_list_output

    - name: Configurar horário/timezone para Sao Paulo
      community.general.timezone:
        name: America/Sao_Paulo

    - name: Instalação de mais pacotes necessários
      apt:
        pkg:
          - curl
          - vim
          - git
          - ed
          - telnet
          - realmd
          - libnss-sss
          - libpam-sss
          - sssd
          - sssd-tools
          - adcli
          - samba-common-bin
          - oddjob
          - oddjob-mkhomedir
          - packagekit
          - wget
          - python3-pip
          - openjdk-17-jdk
          - openjdk-17-jre
          - bat
          - cifs-utils
          - net-tools
          - zip
          - unzip
          - jq
          - awscli
        state: latest
        update_cache: true

    - name: Inserir novas linhas no arquivo /etc/vim/vimrc
      blockinfile:
        path: /etc/vim/vimrc
        block: |
          set background=dark

    - name: Inserir novas linhas no arquivo /root/.bashrc
      lineinfile:
        path: /root/.bashrc
        line: |
          HISTSIZE=15000
          HISTFILESIZE=15000
          HISTTIMEFORMAT="%d/%m/%y %T "

    - name: Alterar o nome do servidor
      hostname:
        name: "{{ new_hostname }}"
      changed_when: current_hostname.stdout != new_hostname

    - name: Obter versão do kernel após a atualização
      command: uname -r
      register: kernel_version_after
      ignore_errors: true  # Ignora erros para garantir que a tarefa seja sempre concluída

    - name: Reboot se necessário
      command: shutdown -r +1
      async: 0
      poll: 0
      become: true
      become_user: root
      when: kernel_version_after.stdout != kernel_version_before.stdout or current_hostname.stdout != new_hostname

EOL

# Executa o playbook do Ansible
echo "Executando o playbook do Ansible..."
ansible-playbook playbook.yml
