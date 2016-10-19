#!/bin/bash

echo "Parando servico..."
service mysql.server stop
rm -f /tmp/mysql.sock
echo "Removendo pacote..."
dpkg -P mysql
echo "Removendo diretorios..."
rm -r /run/mysqld
rm -r /var/log/mysql
rm -r /opt/mysql
echo "Removendo arquivos..."
rm /usr/local/mysql
rm /etc/init.d/mysql.server
rm /etc/my.cnf
echo "Removendo servicos..."
update-rc.d mysql.server remove
echo "Removendo usuarios..."
userdel mysql
echo "Limpando variaveis de ambiente..."
cp /etc/environment /tmp/environment
sed -e 's/\:\/usr\/local\/mysql\/bin//' /tmp/environment > /etc/environment
rm /tmp/environment
