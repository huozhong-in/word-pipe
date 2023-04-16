# 使用方法

- 下载解压 https://github.com/skywind3000/ECDICT/raw/master/stardict.7z 放在api/db/stardict.db

- install miniconda
`conda config --set auto_activate_base false`
`conda create -n wordpipe python=3.10`
`conda activate wordpipe`
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