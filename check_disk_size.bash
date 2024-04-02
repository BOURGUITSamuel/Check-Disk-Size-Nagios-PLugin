#!/bin/bash

# Fonction pour afficher l'aide sur la façon d'utiliser le script
show_help() {
    echo "Utilisation: $0 <point_de_montage> <seuil_avertissement> <seuil_critique>"
    echo "Description: Ce script vérifie l'espace disque utilisé sur le point de montage spécifié et affiche des avertissements ou des alertes critiques en fonction des seuils spécifiés."
    echo
    echo "Arguments:"
    echo "  <point_de_montage>: Le chemin du point de montage que vous souhaitez vérifier."
    echo "  <seuil_avertissement>: Le pourcentage d'utilisation de l'espace disque à partir duquel un avertissement sera généré."
    echo "  <seuil_critique>: Le pourcentage d'utilisation de l'espace disque à partir duquel une alerte critique sera générée."
}

# Fonction pour vérifier l'espace disque restant
check_used_disk_space() {
    local mount_point="$1"
    local warning_threshold="$2"
    local critical_threshold="$3"

    local used_disk_space=$(df -h "$mount_point" | awk 'NR==2 {sub(/%/, "", $5); print $5}')
    local disk_size=$(df -h "$mount_point" | awk 'NR==2 {print $2}')
    local used_size=$(df -h "$mount_point" | awk 'NR==2 {print $3}')
    local free_space=$(df -h "$mount_point" | awk 'NR==2 {print $4}')

    if ((used_disk_space >= warning_threshold && used_disk_space < critical_threshold)); then
        echo "WARNING - $mount_point at $used_disk_space% : Size $disk_size : Used : $used_size Free : $free_space"
        exit 1  # Code de sortie pour Nagios : Warning
    elif ((used_disk_space >= critical_threshold)); then
        echo "CRITICAL - $mount_point at $used_disk_space% : Size $disk_size : Used : $used_size Free : $free_space"
        exit 2  # Code de sortie pour Nagios : Critical
    else
        echo "OK - $mount_point at $used_disk_space% : Size $disk_size : Used : $used_size Free : $free_space"
        exit 0  # Code de sortie pour Nagios : OK
    fi
}

# Vérifier le nombre d'arguments
if [ $# -lt 3 ]; then
    show_help
    exit 1
fi

mount_point="$1"
warning_threshold="$2"
critical_threshold="$3"

# Vérifier si le point de montage existe
df -h "$mount_point" > /dev/null
if [ $? -ne 0 ]; then
    echo "Le point de montage n'existe pas"
    exit 3
else
    check_used_disk_space "$mount_point" "$warning_threshold" "$critical_threshold"
fi
