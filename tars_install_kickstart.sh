#!/bin/bash

function run() {
    echo ">>> $@"
    "$@"
    if [ $? -ne 0 ]; then
        echo ">>> ERROR!!! $@ return $?";
        exit;
    fi
    echo ">>> PASS!!! $@"
}

# install yum packages
run yum install -y glibc-devel
run yum install -y gcc
run yum install -y gcc-c++
run yum install -y ncurses-devel
run yum install -y zlib-devel
run yum install -y perl
run yum install -y git
run yum install -y flex
run yum install -y bison
run yum install -y perl-Module-Install.noarch
run yum install -y cmake


# install java jdk
run tar xf jdk-8u161-linux-x64.tar.gz
run mv jdk1.8.0_161/ /usr/local/
echo '' >> /etc/profile
echo 'JAVA_HOME=/usr/local/jdk1.8.0_161' >> /etc/profile
echo 'CLASSPATH=$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >> /etc/profile
echo 'PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
echo 'export PATH JAVA_HOME CLASSPATH' >> /etc/profile
run source /etc/profile

# test jdk run
java -version
if [ $? -ne 0 ]; then
  echo "ERROR!!! install jdk error";
  exit;
fi

# install maven
run tar xf apache-maven-3.5.2-bin.tar.gz
run mv apache-maven-3.5.2 /usr/local/
echo '' >> /etc/profile
echo 'export MAVEN_HOME=/usr/local/apache-maven-3.5.2' >> /etc/profile
echo 'export PATH=$PATH:$MAVEN_HOME/bin' >> /etc/profile
run source /etc/profile

# test maven run
mvn -v
if [ $? -ne 0 ]; then
  echo "ERROR!!! install maven error";
  exit;
fi

# install resin
run tar xf resin-pro-4.0.55.tar.gz
run mv resin-pro-4.0.55 /usr/local/
run ln -s /usr/local/resin-pro-4.0.55/ /usr/local/resin

# install mysql
run tar xf mysql-5.6.39.tar.gz
run mv mysql-5.6.39 /usr/local/

run cd /usr/local/mysql-5.6.39/
run cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql-5.6.39 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci
run make
run make install

run groupadd mysql
run useradd -g mysql mysql

run chown mysql:mysql ../mysql-5.6.39
run ln -s /usr/local/mysql-5.6.39 /usr/local/mysql

run rm -rf /usr/local/mysql/data
run mkdir -p /data/mysql-data
run ln -s /data/mysql-data /usr/local/mysql/data
run chown -R mysql:mysql /data/mysql-data /usr/local/mysql/data

run cp support-files/mysql.server /etc/init.d/mysql
run chmod u+x /etc/init.d/mysql

run rm -f /etc/my.cnf

run perl scripts/mysql_install_db --user=mysql

run cd ../

run service mysql start

# test1: is in background thread
IS_MYSQLD_IN_BG=`ps xuax | grep -v grep | grep mysqld`
if [ -z "$IS_MYSQLD_IN_BG" ]; then
  echo "ERROR!!! not found mysqld in background threads";
  exit;
fi
echo "found mysqld in background threads";

echo '' >> /etc/profile
echo 'PATH=$PATH:/usr/local/mysql/bin' >> /etc/profile
echo 'export PATH' >> /etc/profile
run source /etc/profile

run mysqladmin -u root password root

#test2: check mysql user/password
mysql -u root -proot -e ''
if [ $? -ne 0 ]; then
  echo "ERROR!!! mysql user/password error";
  exit;
fi
echo "mysql user/password pass";

echo '/usr/local/mysql/lib/' > /etc/ld.so.conf.d/mysql-x86_64.conf
run ldconfig

