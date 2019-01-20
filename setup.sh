#!/usr/bin/env bash

echo "Updating system..."
sudo yum update -y

echo "Installing tools and libs.."
sudo yum install -y vim curl wget tree
sudo yum groupinstall -y 'Development Tools'
sudo yum install -y epel-release
sudo yum install -y perl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel libxml2 libxml2-devel gd gd-devel GeoIP GeoIP-devel

echo "Downloading sources..."
# Stable Nginx 1.14.2
wget http://nginx.org/download/nginx-1.14.2.tar.gz && tar xvf nginx-1.14.2.tar.gz

# PCRE version 8.42
wget https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.gz && tar xzf pcre-8.42.tar.gz

# zlib version 1.2.11
wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzf zlib-1.2.11.tar.gz

# OpenSSL version 1.1.1a
wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz && tar xzf openssl-1.1.1a.tar.gz

# Upload progress module
curl https://codeload.github.com/masterzen/nginx-upload-progress-module/tar.gz/master \
	-o nginx-upload-progress.tar.gz && tar xzf nginx-upload-progress.tar.gz

# Upload module
curl https://codeload.github.com/fdintino/nginx-upload-module/tar.gz/2.3.0 \
	-o nginx-upload.tar.gz && tar xzf nginx-upload.tar.gz

rm -rf *.tar.gz

echo "Setup nginx..."
cd nginx-1.14.2

./configure --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib64/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=nginx \
            --group=nginx \
            --build=CentOS \
            --builddir=nginx-1.14.2 \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --with-http_perl_module=dynamic \
            --with-perl_modules_path=/usr/lib64/perl5 \
            --with-perl=/usr/bin/perl \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../pcre-8.42 \
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-openssl=../openssl-1.1.1a \
            --with-openssl-opt=no-nextprotoneg \
            --with-debug \
            --add-module="../nginx-upload-module-2.3.0" \
            --add-module="../nginx-upload-progress-module-master"

echo "building & installing nginx..."
make > make.log 2>&1
sudo make install > install.log 2>&1
cd ..

echo "Setup nginx"
sudo mkdir -p /var/cache/nginx
sudo ln -f -s /usr/lib64/nginx/modules /etc/nginx/modules 
sudo useradd --system --home /var/cache/nginx --shell /sbin/nologin --comment "nginx user" --user-group nginx

sudo bash -c 'cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl enable nginx.service
sudo mkdir -p /etc/nginx/{conf.d,snippets,sites-available,sites-enabled}
sudo chmod -R 640 /var/log/nginx
sudo chown nginx:adm /var/log/nginx/access.log /var/log/nginx/error.log

sudo bash -c 'cat > /etc/logrotate.d/nginx << EOF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 nginx adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 \`cat /var/run/nginx.pid\`
        fi
    endscript
}
EOF'

sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig 

sudo cp nginx.conf /etc/nginx

sudo cp dynhost.conf /etc/nginx/conf.d

sudo mkdir -p /var/www/tmp/{0,1,2,3,4,5,6,7,8,9} 

sudo mkdir -p /var/www/dynhost.test

sudo cp -r www /var/www/dynhost.test

echo "Installing php-fpm..."
sudo yum install php php-mysql php-fpm -y

echo "Setup php..."
sudo bash -c 'echo "cgi.fix_pathinfo=0" >> /etc/php.ini'
sudo cp  php-fpm.conf /etc
sudo systemctl enable php-fpm.service
echo "Statring php-fpm..."
sudo systemctl start php-fpm

echo "Disabling SELinux..."
sudo setenforce 0
#restorecon -R -v /var/www/dynhost.test/www/upload.php
#restorecon -R -v /var/www/dynhost.test/www/check.php

sudo chown -R nginx.nginx /var/www

echo "Openining 80 port"
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

echo "Starting nginx..."
sudo systemctl start nginx.service

echo "Done"
