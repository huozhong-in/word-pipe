from pathlib import Path
import python_avatars as pa
import cairosvg
import os
# import logging


try:
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    ip = s.getsockname()[0]
    s.close()
    # print(ip)
except Exception as e:
    ip = '127.0.0.1'

# ----- REDIS CONFIG -----
REDIS_URL ="redis://localhost"

# ----- SSE SERVER ----
SSE_SERVER_PATH = "/api/stream"
SSE_MSG_EVENTTYPE = "prod" # prod, dev, test
SSE_MSG_DEFAULT_CHANNEL = "users.social"

# ----- DB CONFIG -----
SQLITE_DB_PATH = Path(Path(__file__).parent.absolute() / 'db/')
SQLITE_DB_NAME = "wordpipe.db"
DB_URI = "sqlite:///" + str(SQLITE_DB_PATH / SQLITE_DB_NAME)

# ----- USER CONFIG -----
DEFAULT_AYONYMOUS_USER_ID: str = "anonymous"
## access_token有效期
DEFAULT_ACCESS_TOKEN_EXPIRE_SECONDS: int = 60 * 60 * 24 * 7 # 7 days
## 新用户免费使用时长
DEFAULT_FREE_TRIAL_TIME: int = 48 * 60 * 60 # 48 hours
## 保存用户头像目录
USER_AVATAR_SERVER_PATH = 'avatar'
USER_AVATAR_PATH = Path('/Users/dio/Downloads/temp/' + USER_AVATAR_SERVER_PATH)
## 保存语音文件目录
USER_AUDIO_SERVER_PATH = 'stt'
USER_AUDIO_PATH = Path('/Users/dio/Downloads/temp/' + USER_AUDIO_SERVER_PATH)

# ----- PROXY CONFIG (for local dev) -----
PROXIES = {
    "http": "127.0.0.1:7890",
    "https": "127.0.0.1:7890",
    "socks5": "127.0.0.1:7890"
}

# ----- MYSQL CONFIG -----
MYSQL_CONFIG = {
  'user': 'wordpipe',
  'password': 'dswybs-yoqoo',
  'host': '127.0.0.1',
  'port': 3306,
  'database': 'wordpipe',
  'raise_on_warnings': True,
}
# ----- OPENAI CONFIG  -----
OPENAI_PROXY_BASEURL = {
    "dev": f"http://{ip}/api/openai", # for intranet Mobile Web testing
    "prod": "https://wordpipe.in/api/openai",
}

def generate_random_avatar(user_name: str) -> bool:
    random_avatar = pa.Avatar.random()
    avatar_save_path = Path(Path(__file__).parent.absolute() / 'assets/avatar/')
    random_avatar.render(avatar_save_path / f'{user_name}.svg')
    with open(avatar_save_path / f'{user_name}.svg', 'r') as f:
        svg = f.read()
        cairosvg.svg2png(bytestring=svg.encode('utf-8'), write_to=Path(avatar_save_path / f'{user_name}.png').as_posix())
        os.remove(avatar_save_path / f'{user_name}.svg')
    return True

if __name__ == '__main__':
    # generate_random_avatar('test04')
    if not os.path.exists(USER_AVATAR_PATH):
        os.makedirs(USER_AVATAR_PATH)
    if not os.path.exists(USER_AUDIO_PATH):
        os.makedirs(USER_AUDIO_PATH)
    # ln -s ./assets/avatar/Jasmine.png `USER_AVATAR_PATH`/Jasmine.png
    if not os.path.exists(USER_AVATAR_PATH / 'Jasmine.png'):
        os.symlink(Path(Path(__file__).parent.absolute() / 'assets/avatar/Jasmine.png'), USER_AVATAR_PATH / 'Jasmine.png')
    # ln -s ./assets/avatar/Jasmine-freechat.png `USER_AVATAR_PATH`/Jasmine-freechat.png
    if not os.path.exists(USER_AVATAR_PATH / 'Jasmine-freechat.png'):
        os.symlink(Path(Path(__file__).parent.absolute() / 'assets/avatar/Jasmine-freechat.png'), USER_AVATAR_PATH / 'Jasmine-freechat.png')
    
    