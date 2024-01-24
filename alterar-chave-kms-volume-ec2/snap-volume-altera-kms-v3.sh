#!/bin/bash
# Script para atualizar a chave kms dos volumes do ec2
# Autor: Kleber Oliveira - data 22/01/2024

# Nome do arquivo que contém os IDs das instâncias
lista_ec2_file="lista_ec2.txt"

# Chave KMS
kms_key_id="arn:aws:kms:us-east-1:794804641874:key/ba5cf071-9ae2-454e-9d92-cc9c2a1a7b3d"

# Loop sobre cada ID da instância no arquivo
while IFS= read -r instance_id; do
    echo "Processando instância: $instance_id"

    # Obter detalhes do mapeamento de bloco
    block_mapping=$(aws ec2 describe-instance-attribute --instance-id "$instance_id" --attribute blockDeviceMapping)

    # Obter o VolumeId
    volume_id=$(echo "$block_mapping" | jq -r '.BlockDeviceMappings[0].Ebs.VolumeId')

    # Extrair valores específicos
    device=$(echo "$block_mapping" | jq -r '.BlockDeviceMappings[0].DeviceName')
    availability_zone=$(aws ec2 describe-volumes --volume-ids "$volume_id" | jq -r '.Volumes[0].AvailabilityZone')
    partition=$(echo "$device" | sed 's|/dev/||')

    # Desatachar volume da instância
    aws ec2 detach-volume --volume-id "$volume_id"

    # Aguardar até que o volume esteja realmente desatachado
    aws ec2 wait volume-available --volume-ids "$volume_id"

    # Criar snapshot do volume desatachado
    snapshot_id=$(aws ec2 create-snapshot --volume-id "$volume_id" --description "Snapshot para volume $volume_id" | jq -r '.SnapshotId')

    # Aguardar até que o snapshot seja concluído
    aws ec2 wait snapshot-completed --snapshot-ids "$snapshot_id"

    # Criar novo volume a partir do snapshot
    new_volume_id=$(aws ec2 create-volume --availability-zone "$availability_zone" --snapshot-id "$snapshot_id" --encrypted --kms-key-id "$kms_key_id" --volume-type gp3 | jq -r '.VolumeId')

    # Aguardar até que o novo volume esteja disponível
    aws ec2 wait volume-available --volume-ids "$new_volume_id"

    # Anexar novo volume à instância usando a mesma partição
    aws ec2 attach-volume --volume-id "$new_volume_id" --instance-id "$instance_id" --device "$device"

    echo "Processamento concluído para a instância: $instance_id"
    echo "--------------------"

done < "$lista_ec2_file"
