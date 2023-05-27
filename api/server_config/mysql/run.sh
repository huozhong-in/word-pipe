sudo docker run -d  \
    --name=mariadb \
    --cpus="2" \
    -m="2g" \
    --restart=unless-stopped \
    -v /opt/mysql_data:/var/lib/mysql \
    -v /opt/word-pipe/api/server_config/mysql/my.cnf:/etc/mysql/my.cnf \
    -p 127.0.0.1:3306:3306 \
    -e MARIADB_ROOT_PASSWORD=dswybs-yoqoo \
    -e TZ='Asia/Shanghai' \
    mariadb:latest
