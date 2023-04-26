from pathlib import Path
import python_avatars as pa
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


# Load config items from config.yaml.
# Use Path.resolve() to get the absolute path of the parent directory
# config_dir = Path(__file__).resolve().parent
# config_path = config_dir / "config.yaml"  # Use Path / operator to join paths

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

# ----- PROXY CONFIG -----
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
    return True