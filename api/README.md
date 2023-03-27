# 使用方法

- 下载解压 https://github.com/skywind3000/ECDICT/raw/master/stardict.7z 放在api/db/stardict.db

- install miniconda
`conda config --set auto_activate_base false`
`conda create -n wordpipe python=3.10`


`sudo gunicorn flask_api:app --worker-class gevent --bind 127.0.0.1:80`