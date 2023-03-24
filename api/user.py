import time
import uuid
import hashlib
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.pool import StaticPool
from config import DB_URI

Base: declarative_base = declarative_base()

class User(Base):
    __tablename__ = 't_user'

    pk_user = Column(Integer, primary_key=True)
    uuid = Column(String(36), nullable=False)
    unionid = Column(String, default='')
    refresh_token = Column(String, default='')
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
    def create_user_by_password(self, user_name='', password='', last_ip=''):
        myuuid: str = str(uuid.uuid4())
        pass_word = hashlib.sha256(str(myuuid+password).encode('utf-8')).hexdigest()
        ctime: int = int(time.time())
        try:
            user = User(uuid=myuuid, user_name=user_name, password=pass_word, last_ip=last_ip, ctime=ctime)
            self.session.add(user)
            self.session.commit()
        except Exception as e:
            print(e)
        
        return user

    def create_user_by_email(self, email='', password='', last_ip=''):
        uuid: str = str(uuid.uuid4())
        pass_word = hashlib.sha256(uuid+password).hexdigest()
        ctime: int = int(time.time())
        user = User(uuid=uuid, email=email, password=pass_word, last_ip=last_ip, ctime=ctime)
        self.session.add(user)
        self.session.commit()
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

    def check_password(self, user_name, password):
        user = self.get_user_by_username(user_name)
        if user is not None:
            pass_word = hashlib.sha256(user.uuid+password).hexdigest()
            if user.password == pass_word:
                return True
            else:
                return False
        else:
            return False
    
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

