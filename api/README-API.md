# 使用方法

- clone codebase
`git clone https://github.com/huozhong-in/word-pipe.git`


`https://github.com/skywind3000/ECDICT/releases/download/1.0.28/ecdict-sqlite-28.zip`
- 下载解压 放在api/db/stardict.db


- install miniconda
`conda config --set auto_activate_base false`
`conda create -n wordpipe python=3.10`
`conda activate wordpipe`

## on macOS 
`conda install cairo pango gdk-pixbuf libffi cairosvg` 
`pip install cairosvg`

## on Ubuntu 
`sudo apt install python3-pip python3-cffi python3-brotli libpango-1.0-0 libharfbuzz0b libpangoft2-1.0-0` 
`sudo apt-get install libpangocairo-1.0-0` 
`pip install cairosvg`

- install dependents
`pip install -r requirements.txt`

- develop in localhost
`sudo gunicorn flask_api:app --workers=1 --worker-class=gevent --worker-connections=10 --bind 127.0.0.1:80 --env OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --keep-alive 300 --env DEBUG_MODE=1`

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
ExecStart=/root/miniconda3/envs/wordpipe/bin/gunicorn flask_api:app --workers=8 --worker-class=gevent --worker-connections=80 --bind 127.0.0.1:9000 --env OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX --keep-alive 60 --timeout 60

[Install]
WantedBy=multi-user.target
```

# maridb docker config

`server_config/mysq/run.sh`
`docker exec -it mariadb /bin/sh`
`mysql -uroot -p`
`create database wordpipe;`
`msyql wordpipe < /home/dio/word-pipe/api/db/wordpipe.sql`
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

# Python实现几种对OpenAI API的请求方式
- 第1见`https://github.com/huozhong-in/word-pipe/blob/129da47994635c5ac6bd4df6c930b221db94683d/api/flask_api.py`
- 第2、3见官方代码示例`https://github.com/openai/openai-cookbook`
- 第4见主分支`flask_api.py`，也是我最后选中的方式
- 第5见 `server_config/nginx/wordpipe.in.conf`

## 1. 用requests发请求
- 可以指定代理服务器，本地或公网均可
## 2. 用OpenAI包发请求
- 发起请求，拿到回复内容
- 没有代理选项，一般是自己搭建在墙外，或者指定墙外endpoint
## 3. 用OpenAI包发流式请求
- 发起请求流式内容，一般是客户端需要实时返回，用户体验好。但客户端实现复杂
- 没有代理选项
- 可以截留存库
## 4. 用requests从数据流层面转发，完整解析流协议，并能截留存库
- 有专门的客户端包，支持流、体验好，省事
- 也因为客户端无法直连OpenAI API，所以客户端包必须支持设置endpoint或baseurl
## 5. nginx配置转发流
- 搭建简单
- 可以预配OpenAI API key，也可以不配，让客户自己传
- 不能做应用级的认证，如access_token
- 无法截留存聊天记录

