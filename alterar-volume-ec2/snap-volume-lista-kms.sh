#!/bin/bash
# Script para listar a chave kms e os volumes do ec2
# Autor: Kleber Oliveira - data 22/01/2024

# Nome do arquivo que contém os IDs das instâncias
lista_ec2_file="lista_ec2.txt"

# Loop sobre cada ID da instância no arquivo
while IFS= read -r instance_id; do
    echo "Detalhes para a instância: $instance_id"

    # Obter detalhes do mapeamento de bloco
    block_mapping=$(aws ec2 describe-instance-attribute --instance-id "$instance_id" --attribute blockDeviceMapping)

    # Obter o VolumeId
    volume_id=$(echo "$block_mapping" | jq -r '.BlockDeviceMappings[0].Ebs.VolumeId')

    # Obter detalhes do volume
    volume_details=$(aws ec2 describe-volumes --volume-ids "$volume_id")

    # Extrair valores específicos
    device=$(echo "$block_mapping" | jq -r '.BlockDeviceMappings[0].DeviceName')  # Corrigido para .DeviceName
    availability_zone=$(echo "$volume_details" | jq -r '.Volumes[0].AvailabilityZone')
    kms_key_id=$(echo "$volume_details" | jq -r '.Volumes[0].KmsKeyId')

    # Imprimir os valores
    echo "Device: $device"
    echo "AvailabilityZone: $availability_zone"
    echo "KmsKeyId: $kms_key_id"
    echo "--------------------"

done < "$lista_ec2_file"

