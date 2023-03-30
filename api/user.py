import jwt
import time
import uuid
import hashlib
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import StaticPool
from config import *

Base: declarative_base = declarative_base()

class User(Base):
    __tablename__ = 't_user'

    pk_user = Column(Integer, primary_key=True)
    uuid = Column(String(36), nullable=False)
    unionid = Column(String, default='')
    access_token = Column(String(512), default='')
    access_token_expire_at = Column(Integer, nullable=False, default=0)
    refresh_token = Column(String(512), default='')
    refresh_token_expire_at = Column(Integer, nullable=False, default=0)
    mobile = Column(String(20), default='')
    user_name = Column(String(50), nullable=False, unique=True)
    password = Column(String(64))
    email = Column(String(64), default='')
    is_email_verified = Column(Integer, nullable=False, default=0)
    avatar = Column(String)
    last_ip = Column(String(15))
    sex = Column(Integer, nullable=False, default=0)
    ctime = Column(Integer)
    utime = Column(Integer)
    is_ban = Column(Integer, nullable=False, default=0)

    def __repr__(self):
        return f'<User(pk_user={self.pk_user}, uuid={self.uuid}, unionid={self.unionid}, mobile={self.mobile}, user_name={self.user_name}, avatar={self.avatar}, last_ip={self.last_ip}, sex={self.sex}, ctime={self.ctime}, utime={self.utime}, is_ban={self.is_ban})>'

class UserDB:
    def __init__(self):
        self.engine = create_engine(DB_URI, echo=False, poolclass=StaticPool, connect_args={'check_same_thread': False})
        Session = sessionmaker(bind=self.engine)
        self.session = Session()
        Base.metadata.create_all(self.engine)

    # Create
    def create_user_by_username(self, user_name='', password='', last_ip='') -> dict:
        if self.get_user_by_username(user_name):
            return {}
        if user_name == DEFAULT_AYONYMOUS_USER_ID:
            return {}
        myuuid: str = str(uuid.uuid4())
        pass_word = hashlib.sha256(str(myuuid+password).encode('utf-8')).hexdigest()
        ctime: int = int(time.time())
        try:
            generate_random_avatar(user_name)
            access_token, expire_at = self.generate_access_token(user_name)
            user = User(uuid=myuuid, user_name=user_name, password=pass_word, last_ip=last_ip, ctime=ctime, access_token=access_token, access_token_expire_at=expire_at)
            self.session.add(user)
            self.session.commit()
        except Exception as e:
            print(e)
            return {}
        
        return {"access_token": access_token,"expires_at": expire_at}

    def create_user_by_email(self, email='', password='', last_ip=''):
        myuuid: str = str(uuid.uuid4())
        pass_word = hashlib.sha256(str(myuuid+password).encode('utf-8')).hexdigest()
        ctime: int = int(time.time())
        try:
            user = User(uuid=myuuid, email=email, password=pass_word, last_ip=last_ip, ctime=ctime)
            self.session.add(user)
            self.session.commit()
        except Exception as e:
            print(e)
            return None
        
        return user

    # Read
    def get_user_by_uuid(self, uuid):
        return self.session.query(User).filter_by(uuid=uuid).first()

    def get_user_by_username(self, user_name):
        # t_user 's user_name is unique
        return self.session.query(User).filter_by(user_name=user_name).first()

    def get_users_by_multi_conditions(self, **kwargs):
        # users = session.query(User).filter(User.uuid == '123', User.unionid == '456').all()
        # for user in users:
        # print(user.pk_user, user.uuid, user.unionid, user.mobile, user.user_name, user.avatar, user.last_ip, user.sex, user.ctime, user.utime)
        return self.session.query(User).filter_by(**kwargs).all()

    def check_password(self, user_name, password) -> dict:
        user = self.get_user_by_username(user_name)
        if user is not None:
            pass_word = hashlib.sha256(str(user.uuid+password).encode('utf-8')).hexdigest()
            if user.password == pass_word:
                # update access_token
                access_token, expire_at = self.refresh_access_token(user_name)
                r: dict = {"access_token": access_token,"expires_at": expire_at}
                return r
            else:
                return {}
        else:
            return {}
    
    def modify_password(self, user_name, old_password, new_password):
        user = self.get_user_by_username(user_name)
        if user is not None:
            pass_word = hashlib.sha256(user.uuid+old_password).hexdigest()
            if user.password == pass_word:
                user.password = hashlib.sha256(user.uuid+new_password).hexdigest()
                self.session.commit()
                return True
            else:
                return False
        else:
            return False

    # Update
    def update_user_by_uuid(self, uuid, **kwargs):
        user = self.get_user_by_uuid( uuid)
        if user is not None:
            for key, value in kwargs.items():
                setattr(user, key, value)
            self.ession.commit()
            return user
        else:
            print("No matching record found")

    def update_user_by_username(self, user_name, **kwargs) -> User:
        user = self.get_user_by_username( user_name)
        if user is not None:
            try:
                for key, value in kwargs.items():
                    setattr(user, key, value)
                self.session.commit()
            except Exception as e:
                print(e)
                return None
            return user
        else:
            print("No matching record found")
            return None

    def update_users_by_multi_conditions(session, **kwargs) -> bool:
        # session.query(User).filter(User.uuid == '123', User.unionid == '456').update({"mobile": '123456789', "user_name": 'test'})
        # session.commit()
        try:
            session.query(User).filter_by(**kwargs).update(kwargs)
            session.commit()
        except Exception as e:
            print(e)
            return False
        return True

    # Delete, set t_user 's is_ban to 1 actually
    def delete_user(self, uuid):
        user = self.get_user_by_uuid( uuid)
        if user is not None:
            user.is_ban = 1
            self.session.commit()
            return user
        else:
            print("No matching record found")

    # 生成access_token
    def generate_access_token(self, user_name) -> tuple:
        payload = {
            'user_name': user_name,
            'exp': int(time.time()) + 3600 * 24
        }
        access_token = jwt.encode(payload, 't0uKan5h1x!aO90U', algorithm='HS256')
        return access_token, payload['exp']
    
    # refresh access_token
    def refresh_access_token(self, user_name) -> tuple:
        access_token, expire_at = self.generate_access_token(user_name)
        if self.update_user_by_username(user_name, access_token=access_token, access_token_expire_at=expire_at) is not None:
            return access_token, expire_at
        else:
            return None

if __name__ == '__main__':
    db = UserDB()
    db.refresh_access_token('dio')