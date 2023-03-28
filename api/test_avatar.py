import python_avatars as pa
from pathlib import Path
import random

def generate_random_avatar(user_name: str) -> bool:
    random_avatar_1 = pa.Avatar.random()
    avatar_save_path = Path(Path(__file__).parent.absolute() / 'assets/avatar/')
    random_avatar_1.render(avatar_save_path / f'{user_name}.svg')
    return True

if __name__ == "__main__":
    random_user_name = f"test{random.randint(0, 1000)}"
    generate_random_avatar(random_user_name)