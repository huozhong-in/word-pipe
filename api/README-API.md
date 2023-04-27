# 使用方法

`https://github.com/skywind3000/ECDICT/releases/download/1.0.28/ecdict-sqlite-28.zip`
- 下载解压 放在api/db/stardict.db


- install miniconda
`conda config --set auto_activate_base false`
`conda create -n wordpipe python=3.10`
`conda activate wordpipe`

- clone codebase
`git clone `

- install dependents
`pip install -r requirements.txt`

- develop in localhost
`sudo gunicorn flask_api:app --workers=1 --worker-class=gevent --worker-connections=10 --bind 127.0.0.1:80 --env OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --keep-alive 300`

- register system service
`vim /etc/systemd/system/wordpipe.service`
```
[Unit]
Description=Gunicorn instance to serve wordpipe
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/root/word-pipe/api
Environment="PATH=/root/miniconda3/envs/wordpipe/bin"
ExecStart=/root/miniconda3/envs/wordpipe/bin/gunicorn flask_api:app --workers=4 --worker-class=gevent --worker-connections=40 --bind 127.0.0.1:9000 --env OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --keep-alive 60 --timeout 60

[Install]
WantedBy=multi-user.target
```

# maridb docker config

`docker run -d  --name=mariadb --restart=unless-stopped -v /opt/mysql_data:/var/lib/mysql -p 127.0.0.1:3306:3306 -e MARIADB_ROOT_PASSWORD=dswybs-yoqoo mariadb:latest`
`docker exec -it mariadb /bin/sh`
`mysql -uroot -p`
`create database wordpipe;`
`msyql wordpipe < /var/lib/mysql/temp/t_user.sql`
```
CREATE USER 'wordpipe'@'localhost' IDENTIFIED BY 'dswybs-yoqoo';
GRANT ALL PRIVILEGES ON wordpipe.* TO 'wordpipe'@'localhost' WITH GRANT OPTION;

CREATE USER 'wordpipe'@'%' IDENTIFIED BY 'dswybs-yoqoo';
GRANT ALL PRIVILEGES ON wordpipe.* TO 'wordpipe'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

# redis docker config
`docker run -d --name redis-stack --restart=unless-stopped -p 127.0.0.1:6379:6379 -p 127.0.0.1:8001:8001 redis/redis-stack:latest`

# ngixn conf 
See: `server_config/nginx/wordpipe.in.conf`