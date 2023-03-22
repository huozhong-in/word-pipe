from pathlib import Path
import logging


# Load config items from config.yaml.
# Use Path.resolve() to get the absolute path of the parent directory
# config_dir = Path(__file__).resolve().parent
# config_path = config_dir / "config.yaml"  # Use Path / operator to join paths

# ----- REDIS CONFIG -----
REDIS_URL ="redis://localhost"

# ----- SSE SERVER ----
SSE_SERVER_HOST = "https://wordpipe.huozhong.in"
SSE_SERVER_PORT = "443"
SSE_SERVER_PATH = "/api/stream"
SSE_MSG_TYPE = "broadcasting"
SSE_MSG_CHANNEL = "users.social"
