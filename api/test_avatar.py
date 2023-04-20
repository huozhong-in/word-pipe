import python_avatars as pa
from pathlib import Path
import random
import os

def generate_random_avatar(user_name: str, rewrite: bool=False) -> bool:
    random_avatar_1 = pa.Avatar.random()
    avatar_save_path = Path(Path(__file__).parent.absolute() / 'assets/avatar/')
    avatar_file_path = avatar_save_path / f'{user_name}.svg'
    if not avatar_file_path.exists():
        random_avatar_1.render(avatar_file_path)
        return True
    else:
        if rewrite:
            os.remove(avatar_file_path)
            random_avatar_1.render(avatar_file_path)
            return True
        else:
            return False


if __name__ == "__main__":
    # random_user_name = f"test{random.randint(0, 1000)}"
    # generate_random_avatar(random_user_name)
    generate_random_avatar('Fang', rewrite=True)