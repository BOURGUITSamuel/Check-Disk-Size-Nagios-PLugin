#!/bin/bash

# Fonction pour afficher l'aide sur la façon d'utiliser le script
show_help() {
    echo "Utilisation : $0 <point_de_montage> <seuil_avertissement> <seuil_critique>"
    echo "Description : Ce script vérifie l'utilisation de l'espace disque sur un point de montage spécifié et déclenche des avertissements ou des alertes critiques en fonction des seuils donnés."
    echo
    echo "Options :"
    echo "-h, -help : Afficher cette aide et quitter."
    echo
    echo "Arguments :"
    echo "<point_de_montage> : Chemin du point de montage à vérifier."
    echo "<seuil_avertissement> : Pourcentage d'utilisation de l'espace disque à partir duquel un avertissement est généré."
    echo "<seuil_critique> : Pourcentage d'utilisation de l'espace disque à partir duquel une alerte critique est générée."
}

# vérification de l'appel de la fonction show_help
if [[ "$1" == "-h" || "$1" == "-help" ]]; then
    show_help
    exit 0
fi

# Vérification si l'argument fournit par l'utilisateur est différent de -h ou -help
if [[ "$1" == -* && "$1" != "-h" && "$1" != "-help" ]]; then
    echo "UNKNOWN - Erreur : Option invalide fournie. Utilisez -h ou -help pour afficher l'aide."
    exit 3 # Code de sortie pour Nagios : UNKNOW
fi

# Affectation des arguments
mount_point="$1"
warning_threshold="$2"
critical_threshold="$3"

# Vérification du nombre d'arguments
if [ $# -ne 3 ]; then
    echo "UNKNOWN - Erreur : Nombre d'arguments incorrect ou argument invalide. Attendu : <point_de_montage> <seuil_avertissement> <seuil_critique>"
    exit 3 # Code de sortie pour Nagios : UNKNOW
fi

# Vérification que le point de montage existe
if ! df -h "${mount_point}" > /dev/null 2>&1; then
    echo "UNKNOWN - Erreur : Le point de montage ${mount_point} n'existe pas."
    exit 3 # Code de sortie pour Nagios : UNKNOW
fi

# Vérification que les seuils sont des entiers positifs
if ! [[ "${warning_threshold}" =~ ^[0-9]+$ ]] || ! [[ "${critical_threshold}" =~ ^[0-9]+$ ]]; then
    echo "UNKNOWN - Erreur : Les seuils doivent être des entiers positifs."
    exit 3 # Code de sortie pour Nagios : UNKNOW
fi

# Vérification que les seuils sont dans la plage appropriée
if [ "${warning_threshold}" -ge "${critical_threshold}" ]; then
    echo "UNKNOWN - Erreur : Le seuil critique doit être supérieur au seuil d'avertissement."
    exit 3 # Code de sortie pour Nagios : UNKNOW
fi

# Fonction pour vérifier l'utilisation de l'espace disque
check_disk_space() {
    # Récupération des données de la commande df
    local used_percentage=$(df -h "${mount_point}" | awk 'NR==2 {sub(/%/, "", $5); print $5}')
    local total_size=$(df -h "${mount_point}" | awk 'NR==2 {print $2}')
    local used_size=$(df -h "${mount_point}" | awk 'NR==2 {print $3}')
    local free_space=$(df -h "${mount_point}" | awk 'NR==2 {print $4}')

    # Vérification des seuils et affichage des messages appropriés
    if (( ${used_percentage} >= ${critical_threshold} )); then
        echo "CRITICAL - ${mount_point} à ${used_percentage}% : Taille totale ${total_size} : Utilisé ${used_size}: Espace libre ${free_space}"
        exit 2  # Code de sortie pour Nagios : Critique
    elif (( used_percentage >= warning_threshold )); then
        echo "WARNING - ${mount_point} à ${used_percentage}% : Taille totale ${total_size} : Utilisé ${used_size}: Espace libre ${free_space}"
        exit 1  # Code de sortie pour Nagios : Avertissement
    else
        echo "OK - ${mount_point} à ${used_percentage}% : Taille totale ${total_size} : Utilisé ${used_size}: Espace libre ${free_space}"
        exit 0  # Code de sortie pour Nagios : OK
    fi
}

# Exécution de la fonction check_disk_space 
check_disk_space "${mount_point}" "${warning_threshold}" "${critical_threshold}"
