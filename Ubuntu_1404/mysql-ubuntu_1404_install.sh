#!/bin/bash

#################################################
# VERSION: 140324-1 -> .cnf
# VERSION: 141017-1 -> .sh
# AUTHOR: Thell Sam
##################################################
# VARIAVEIS
##################################################
DIRETORIOARQS=/root/mysql/
PACOTEINSTALACAO=
DIRETORIODADOS=/dados/
SENHAROOT=password
##################################################

echo "Iniciando a instalacao do MySQL..."

cd $DIRETORIOARQS

echo "Instalando biblioteca libaio-dev..."; sleep 1
apt-get -y install libaio-dev

echo "Criando usuario e grupo mysql..."; sleep 1
groupadd mysql
useradd --system --home=/nonexistent --gid=mysql --shell=/bin/false mysql

echo "Criando diretorios..."; sleep 1
[ ! -d "$DIRETORIODADOS" ]             && mkdir -p "$DIRETORIODADOS"
[ ! -d "$DIRETORIODADOS"bkp ]          && mkdir -p "$DIRETORIODADOS"bkp
[ ! -d "$DIRETORIODADOS"mysql/data00 ] && mkdir -p "$DIRETORIODADOS"mysql/data00
[ ! -d "$DIRETORIODADOS"mysql/logs00 ] && mkdir -p "$DIRETORIODADOS"mysql/logs00
mkdir /var/log/mysql
mkdir /run/mysqld
[ ! -d /opt ] && mkdir /opt

echo "Setando permissoes..."; sleep 1
chown -R mysql:mysql "$DIRETORIODADOS"mysql
chown mysql /var/log/mysql
chown mysql /run/mysqld

echo "Desempacotando aplicacao..."; sleep 1
if [ ! -z "$PACOTEINSTALACAO" -a -f $DIRETORIOARQS$PACOTEINSTALACAO ]
then
   dpkg -i $DIRETORIOARQS$PACOTEINSTALACAO
else
   a=`ls "$DIRETORIOARQS"mysql*.deb | sort -r`
   if [ -z "$a" ]
   then
      echo
      echo "ARQUIVO DE INSTALACAO NAO EXISTE!!!"
      echo
      exit
   fi
   set -- $a
   dpkg -i $1
fi

echo "Criando link e permissoes para a aplicacao..."; sleep 1
cd /usr/local
dirbase=`ls -d /opt/mysql/server*`
ln -s $dirbase mysql
cd mysql
chown -R mysql:mysql .
chown -R root .

echo "Instalando banco de dados..."; sleep 1
scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir="$DIRETORIODADOS"mysql/data00/

echo "Corrigindo permissoes para diretorio de banco de dados..."; sleep 1
chown -R mysql "$DIRETORIODADOS"mysql/data00/

echo "Copiando manuais..."; sleep 1
cp man/man1/* /usr/share/man/man1
cp man/man8/* /usr/share/man/man8

echo "Criando servico..."; sleep 1
cp support-files/mysql.server /etc/init.d/mysql.server
update-rc.d mysql.server defaults

echo "Criando arquivo de configuracao..."; sleep 1
echo $DIRETORIODADOS | sed -e 's/\//\\\//g' > /tmp/sedtmp
b=`cat /tmp/sedtmp`
rm /tmp/sedtmp
cat "$DIRETORIOARQS"mysql-ubuntu_1404.cnf | sed -e "s/DDDDDDDDDD/$b/g" > /etc/my.cnf

echo "renomeando arquivo my.cnf default do diretorio de instalacao"; sleep 1
[ -f /usr/local/mysql/my.cnf ] && mv /usr/local/mysql/my.cnf /usr/local/mysql/my.cnf.old

echo "Iniciando o servico..."; sleep 1
service mysql.server start

echo "Informando a senha de root..."; sleep 1
/usr/local/mysql/bin/mysqladmin -u root password "$SENHAROOT"
/usr/local/mysql/bin/mysql -uroot -p"$SENHAROOT" -e"grant all privileges on *.* to 'root'@'%' identified by '$SENHAROOT' with grant option;"

echo "Configurando variavel de ambiente PATH..."; sleep 1
a=`cat /etc/environment`
if [ -z `echo "$a" | grep PATH | grep mysql`  ]; then
   echo "$a" | sed -e 's/^PATH=".*[^"]/&:\/usr\/local\/mysql\/bin/g' > /etc/environment
fi
echo "PATH=$PATH:/usr/local/mysql/bin; export PATH" >> /root/.profile

echo "Criando link no tmp para sock..."; sleep 1
ln -s /run/mysqld/mysqld.sock /tmp/mysql.sock

echo "Atualizando bibliotecas..."; sleep 1
echo "/usr/local/mysql/lib" > /etc/ld.so.conf.d/mysql.conf
ldconfig

echo ""
echo "Executando o comando mysql_secure_installation para configurar opcoes de seguranca do MySQL..."; sleep 1
echo ""
/usr/local/mysql/bin/mysql_secure_installation

echo "Execute a linha abaixo para setar o caminho para os executaveis do mysql sem precisar reiniciar o servidor:"
echo ""
echo "source /etc/environment"
echo ""
echo "Fim da instalacao!"