# 使用方法

`https://github.com/skywind3000/ECDICT/releases/download/1.0.28/ecdict-sqlite-28.zip`
- 下载解压 放在api/db/stardict.db


- install miniconda
`conda config --set auto_activate_base false`
`conda create -n wordpipe python=3.10`
`conda activate wordpipe`
`git pull `
`pip install -r requirements.txt`
`sudo gunicorn flask_api:app --workers=1 --worker-class=gevent --worker-connections=1000 --bind 127.0.0.1:80 --env OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --keep-alive 300`


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
ExecStart=/root/miniconda3/envs/wordpipe/bin/gunicorn flask_api:app --workers=1 --worker-class=gevent --worker-connections=1000 --bind 127.0.0.1:9000 --env OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --keep-alive 300

[Install]
WantedBy=multi-user.target
```

# cloudflare配置转发

`https://github.com/noobnooc/noobnooc/discussions/9`

# maridb docker config

`docker run -d --name redis-stack -p 127.0.0.1:6379:6379 -p 127.0.0.1:8001:8001 redis/redis-stack:latest`
`docker exec -it mariadb /bin/sh`

```
CREATE USER 'wordpipe'@'localhost' IDENTIFIED BY 'dswybs-yoqoo';
GRANT ALL PRIVILEGES ON wordpipe.* TO 'wordpipe'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

# redis docker config

`docker run -d  --name=mariadb --restart=unless-stopped -v ~/OrbStack/docker/volumes/mysql_data:/var/lib/mysql -p 127.0.0.1:3306:3306 -e MARIADB_ROOT_PASSWORD=dswybs-yoqoo mariadb:latest`