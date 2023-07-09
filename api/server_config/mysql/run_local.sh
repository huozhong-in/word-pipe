docker run -d  --name=mariadb --restart=unless-stopped -v mysql_data:/var/lib/mysql -p 0.0.0.0:3306:3306 -e MARIADB_ROOT_PASSWORD=dswybs-yoqoo -e TZ='Asia/Shanghai' mariadb:latest
