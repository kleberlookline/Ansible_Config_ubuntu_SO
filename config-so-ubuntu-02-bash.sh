#!/bin/bash

# Função para imprimir uma linha em branco
print_blank_line() {
    printf "\n"
}

# Atualiza o sistema
echo -e "\nAtualizando o sistema..."
sudo apt update
sudo apt dist-upgrade -y
print_blank_line

# Função para verificar e instalar pacotes
install_package() {
    package_name=$1
    if dpkg -s "$package_name" &>/dev/null; then
        echo "O pacote $package_name já está instalado. Pulando este passo."
    else
        echo "Instalando o pacote $package_name..."
        sudo apt install -y "$package_name"
    fi
    print_blank_line
}

# Instalação de pacotes necessários
echo "Instalando pacotes necessários..."
packages=("curl" "vim" "git" "ed" "telnet" "realmd" "libnss-sss" "libpam-sss" "sssd" "sssd-tools" "adcli" "samba-common-bin" "oddjob" "oddjob-mkhomedir" "packagekit" "wget" "python3-pip" "openjdk-17-jdk" "openjdk-17-jre" "bat" "cifs-utils" "net-tools" "zip" "unzip" "jq")
for package in "${packages[@]}"; do
    install_package "$package"
done

# Configuração do fuso horário para São Paulo
echo "Configurando horário/timezone para Sao Paulo..."
current_timezone=$(timedatectl show --property=Timezone --value)
if [ "$current_timezone" != "America/Sao_Paulo" ]; then
    sudo timedatectl set-timezone America/Sao_Paulo
else
    echo "O fuso horário já está configurado para São Paulo. Pulando este passo."
fi
print_blank_line

# Modificações no arquivo /root/.bashrc
echo "Fazendo modificações no arquivo /root/.bashrc..."
if ! grep -qxF 'alias vi=vim' /root/.bashrc; then
    echo 'alias vi=vim' | sudo tee -a /root/.bashrc
fi
if grep -E -q '^(HISTSIZE=.*|HISTFILESIZE=.*|HISTTIMEFORMAT=.*)$' /root/.bashrc; then
    sudo sed -i '/^HISTSIZE=.*\|HISTFILESIZE=.*\|HISTTIMEFORMAT=.*$/d' /root/.bashrc
fi
if ! grep -qxF 'HISTSIZE=15000' /root/.bashrc; then
    echo 'HISTSIZE=15000' | sudo tee -a /root/.bashrc
fi
if ! grep -qxF 'HISTFILESIZE=15000' /root/.bashrc; then
    echo 'HISTFILESIZE=15000' | sudo tee -a /root/.bashrc
fi
if ! grep -qxF 'HISTTIMEFORMAT="%d/%m/%y %T "' /root/.bashrc; then
    echo 'HISTTIMEFORMAT="%d/%m/%y %T "' | sudo tee -a /root/.bashrc
fi
print_blank_line

# Remoção da linha do CD-ROM do arquivo sources.list
echo "Removendo linha do CD-ROM do arquivo sources.list..."
if grep -q '^deb cdrom:' /etc/apt/sources.list; then
    sudo sed -i '1d' /etc/apt/sources.list
else
    echo "A linha do CD-ROM já foi removida. Pulando este passo."
fi
print_blank_line

# Inserção de novas linhas no arquivo /etc/vim/vimrc
echo "Inserindo novas linhas no arquivo /etc/vim/vimrc..."
if ! grep -qxF 'set background=dark' /etc/vim/vimrc; then
    sudo tee -a /etc/vim/vimrc <<EOL
set background=dark
EOL
fi
print_blank_line

# Alteração do nome do servidor
new_hostname="geral-ubuntu-02"
current_hostname=$(hostname)
echo "Alterando o nome do servidor para $new_hostname..."
if [ "$current_hostname" != "$new_hostname" ]; then
    sudo hostnamectl set-hostname "$new_hostname"
    echo "Reiniciando o sistema..."
    sudo shutdown -r +1
else
    echo "O nome do servidor já está configurado como $new_hostname. Pulando este passo."
fi
print_blank_line
