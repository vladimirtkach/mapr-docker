FROM vladimirtkach/base_master
RUN yum install -y mapr-hbase-master  mapr-hive mapr-hivemetastore mapr-hiveserver2 sudo unzip java-1.7.0-openjdk-devel.x86_64
ADD MariaDB.repo /etc/yum.repos.d/
RUN yum install -y MariaDB-server MariaDB-client
ADD hive-site.xml /opt/mapr/hive/hive-1.2/conf/

RUN service mysql start && mysql -uroot --execute "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('root'); CREATE DATABASE metastore_db; CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'hivepassword'; GRANT all on *.* to 'hiveuser'@localhost identified by 'hivepassword'; flush privileges;"
RUN service mysql start && mysql -uroot -proot metastore_db --execute "SOURCE /opt/mapr/hive/hive-1.2/scripts/metastore/upgrade/mysql/hive-schema-1.2.0.mysql.sql;"
RUN service mysql start && mysql -uroot -proot metastore_db --execute "SOURCE /opt/mapr/hive/hive-1.2/scripts/metastore/upgrade/mysql/hive-txn-schema-0.13.0.mysql.sql;"

ENTRYPOINT /bin/bash
