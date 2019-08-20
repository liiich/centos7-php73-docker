FROM centos:7

RUN set -ex; \
echo "1. set timezone to CST"; \
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
echo "2, config yum"; \
yum -y install epel-release yum-utils; \
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm; \
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm; \
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org; \
rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm; \
echo "3. update"; \
yum clean all; yum makecache; yum install -y epel-release; yum -y update; \
echo "4. Nginx & PHP"; \
yum install -y gcc wget curl nginx php73 php73-php-cli php73-php-fpm php73-php-mysqlnd \
    php73-php-zip php73-php-devel php73-php-gd php73-php-mcrypt \
    php73-php-mbstring php73-php-curl php73-php-xml php73-php-pear \
    php73-php-bcmath php73-php-json php73-php-common php73-php-opcache \
    php73-php-mysql php73-php-odbc php73-php-pecl-memcached \
    php73-php-pecl-redis php73-php-pecl-rdkafka php73-php-pdo \
    php73-php-pecl-apcu php73-php-pecl-apcu-bc; \
ln -svf /opt/remi/php73/root/usr/bin/* /usr/bin/; \
ln -svf /opt/remi/php73/root/usr/sbin/* /usr/sbin/; \
mkdir /tmp/build; cd /tmp/build; \
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
cd /tmp/build; wget https://github.com/redis/hiredis/archive/v0.13.3.tar.gz -O hiredis-v0.13.3.tar.gz; \
tar -xf hiredis-v0.13.3.tar.gz; cd hiredis-0.13.3; make && make install; \
cd /tmp/build; wget https://github.com/nrk/phpiredis/archive/v1.0.0.tar.gz -O phpiredis-v1.0.0.tar.gz; \
tar -xf phpiredis-v1.0.0.tar.gz; cd phpiredis-1.0.0; phpize; ./configure --enable-phpiredis; make && make install; \
echo 'extension=phpiredis.so' >> /etc/opt/remi/php73/php.ini; \
cd /tmp/build; wget https://github.com/edenhill/librdkafka/archive/v1.1.0.tar.gz; \
tar -xf v1.1.0.tar.gz; cd librdkafka-1.1.0; ./configure && make && make install; \
rm -f /usr/lib64/librdkafka*.so.1; cp /usr/local/lib/librdkafka*.so.1 /usr/lib64/; \
echo "5. config php & nginx"; \
groupadd -g 900 www; adduser --system --no-user-group -u 1000 -g www www; \
sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/g'            /etc/opt/remi/php73/php.ini; \
sed -i 's/daemonize = yes/daemonize = no/g'                             /etc/opt/remi/php73/php-fpm.conf; \
sed -i 's/user = apache/user = www/g'                                   /etc/opt/remi/php73/php-fpm.d/www.conf; \
sed -i 's/group = apache/group = www/g'                                 /etc/opt/remi/php73/php-fpm.d/www.conf; \
sed -i 's/listen = 127.0.0.1\:9000/listen = \/tmp\/php-fpm.sock/g'      /etc/opt/remi/php73/php-fpm.d/www.conf; \
sed -i 's/listen.allowed_clients = /;listen.allowed_clients = /g'       /etc/opt/remi/php73/php-fpm.d/www.conf; \
sed -i 's/worker_processes  1;/worker_processes  auto;\ndaemon off;/'   /etc/nginx/nginx.conf; \
sed -i 's/#tcp_nopush/client_max_body_size 2048M;\n\t#tcp_nopush/'      /etc/nginx/nginx.conf; \
sed -i 's/user  nginx/user  www/g' /etc/nginx/nginx.conf; \
chown -R www:www /var/opt/remi/php73; \
echo 'server { include /srv/*_nginx.conf; }' > /etc/nginx/conf.d/default.conf; \
echo "6. start nginx and php service"; \
cd /tmp/build; \
wget -O /usr/bin/phpunit https://phar.phpunit.de/phpunit-8.phar; \
chmod +x /usr/bin/phpunit; \
wget https://cr.yp.to/daemontools/daemontools-0.76.tar.gz; \
tar -xf daemontools-0.76.tar.gz; cd admin/daemontools-0.76; \
sed -i 's/gcc/gcc -include \/usr\/include\/errno.h/g' src/conf-cc; \
./package/install; \
cp command/* /usr/bin/; \
mkdir /etc/service; \
mkdir /opt/service_nginx; \
mkdir /opt/service_php-fpm; \
echo -e '#!/bin/bash\n\nexec nginx >> /var/log/nginx/run.log 2>&1' > /opt/service_nginx/run; \
chmod +x /opt/service_nginx/run; \
echo -e '#!/bin/bash\n\nexec setuidgid www php-fpm >> /var/log/php-fpm_run.log 2>&1' > /opt/service_php-fpm/run; \
chmod +x /opt/service_php-fpm/run; \
ln -s /opt/service_nginx /etc/service/nginx; \
ln -s /opt/service_php-fpm /etc/service/php-fpm; \
rm -rf /tmp/build; \
yum remove -y wget; \
yum autoremove -y;

WORKDIR /srv

EXPOSE 80

ENTRYPOINT [ "svscan", "/etc/service" ]
