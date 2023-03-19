from pathlib import Path
import logging


# Load config items from config.yaml.
# Use Path.resolve() to get the absolute path of the parent directory
# config_dir = Path(__file__).resolve().parent
# config_path = config_dir / "config.yaml"  # Use Path / operator to join paths

# ----- REDIS CONFIG -----
REDIS_URL ="redis://localhost"

# ----- SSE SERVER ----
SSE_SERVER_HOST = "http://127.0.0.1"
SSE_SERVER_PORT = "80"
SSE_SERVER_PATH = "/stream"
SSE_MSG_TYPE = "broadcasting"
SSE_MSG_CHANNEL = "users.social"