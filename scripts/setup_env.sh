#!/bin/bash
set -eu

if [ $# -eq 0 ]; then
    set -- --all
fi

install_dependencies() {
    echo "# Installing dependencies..."
    apt-get update
    apt-get -y install software-properties-common
    add-apt-repository -y ppa:deadsnakes/ppa && apt-get update
    apt-get -y install libc-bin nginx mysql-server libmysqlclient21 python3.7
    apt-get clean
}

mysql_create_db() {
    echo "# Creating MySQL database..."
    (
        echo "DROP DATABASE IF EXISTS ralph_ng;"
        echo "CREATE DATABASE ralph_ng DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
    ) | mysql -uroot
}

# Function to create MySQL user
mysql_create_user() {
    echo "# Creating MySQL user..."
    (
        echo "CREATE USER 'ralph_ng'@'localhost' IDENTIFIED BY 'ralph_ng';"
        echo "GRANT ALL PRIVILEGES ON ralph_ng.* TO 'ralph_ng'@'localhost';"
        echo "FLUSH PRIVILEGES;"
    ) | mysql -uroot
}

configure_nginx() {
    echo "# Configuring NGINX..."
    tee /etc/nginx/sites-available/default > /dev/null << EOF
server {
    listen 80 default_server;
    server_name _;

    client_max_body_size 512M;
    proxy_connect_timeout 300;
    proxy_read_timeout 300;

    access_log /var/log/nginx/ralph-access.log;
    error_log /var/log/nginx/ralph-error.log;

    location /static {
        alias /usr/share/ralph/static;
        expires 1M;
        access_log off;
        log_not_found off;
    }

    location /media {
        alias /var/local/ralph/media;
        add_header Content-Disposition "attachment";
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        include /etc/nginx/uwsgi_params;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    nginx -s reload
}

run_all=false
for arg in "$@"; do
    if [ "$arg" == "--all" ]; then
        run_all=true
        break
    fi
done

if [ "$run_all" == true ]; then
    install_dependencies
    mysql_create_db
    mysql_create_user
    configure_nginx
else
    for arg in "$@"; do
        case $arg in
            --install-dependencies)
                install_dependencies
                ;;
            --mysql-create-db)
                mysql_create_db
                ;;
            --mysql-create-user)
                mysql_create_user
                ;;
            --configure-nginx)
                configure_nginx
                ;;
            *)
                echo "Usage: $0 [--install-dependencies|--mysql-create-db|--mysql-create-user|--configure-nginx|--all]"
                exit 1
                ;;
        esac
    done
fi

echo "DONE."
