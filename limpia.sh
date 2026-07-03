#!/bin/bash

set -e 

echo "🧹 Limpiando known_hosts..."
rm -f ~/.ssh/known_hosts

echo "🔑 Iniciando ssh-agent..."
eval "$(ssh-agent -s)"

echo "🔐 Cargando clave SSH..."
ssh-add ~/.ssh/id_rsa

echo "🌐 Probando conectividad..."

IPS=("192.168.100.11" "192.168.100.12" "192.168.100.13")

for ip in "${IPS[@]}"
do
  echo "➡ Probando $ip ..."
  ping -c 2 $ip > /dev/null || { echo "❌ No hay conectividad con $ip"; exit 1; }

  echo "➡ Probando SSH en $ip ..."
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$ip "echo OK" || {
    echo "❌ SSH falló en $ip"
    exit 1
  }
done

echo "✅ Conectividad OK"

echo "📡 Probando Ansible..."
ansible -i inventory.ini all -m ping

