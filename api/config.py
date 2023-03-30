from pathlib import Path
import python_avatars as pa
# import logging


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

def generate_random_avatar(user_name: str) -> bool:
    random_avatar = pa.Avatar.random()
    avatar_save_path = Path(Path(__file__).parent.absolute() / 'assets/avatar/')
    random_avatar.render(avatar_save_path / f'{user_name}.svg')
    return True