#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import random
import string
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import StaticPool
from config import *


Base: declarative_base = declarative_base()

class Promo(Base):
    __tablename__ = 't_promo'

    id = Column(Integer, primary_key=True)
    promo = Column(String(32), nullable=False)
    bind_userid = Column(String(36))
    gen_by = Column(String(36), nullable=False)


class PromoDB():
    def __init__(self):
        self.engine = create_engine(DB_URI, echo=False, poolclass=StaticPool, connect_args={'check_same_thread': False})
        Session = sessionmaker(bind=self.engine)
        self.session = Session()
        Base.metadata.create_all(self.engine)

    def create_promo(self, count, gen_by) -> bool:
        result: bool = False
        # generate promo code in format: 8 chars random string
        code_str = string.ascii_letters + string.digits
        def gen_code(len=6):
            code = ''
            for _ in range(len):
                new_s = random.choice(code_str)
                code += new_s
            return code
        try:
            i = 0
            while i < count:
                promo: str = gen_code()
                # insert into datatable after check unique
                is_exist = self.session.query(Promo).filter_by(promo=promo).first() != None
                if is_exist:
                    continue
                promo = Promo(promo=promo, gen_by=gen_by)
                self.session.add(promo)
                self.session.commit()
                i += 1
        except Exception as e:
            print(e)
            return result
        return True

    def bind_promo(self, promo, bind_userid) -> bool:
        try:
            promo = self.session.query(Promo).filter_by(promo=promo).first()
            if promo == None:
                return False
            if promo.bind_userid != None:
                return False
            promo.bind_userid = bind_userid
            self.session.commit()
        except Exception as e:
            print(e)
            return False
        return True
        
    def get_promos_by_userid(self, userid, bind_filter:bool=True) -> list:
        result: list = []
        try:
            if bind_filter:
                result = self.session.query(Promo).filter_by(gen_by=userid).filter(Promo.bind_userid == None).all()
                print(len(result))
            else:
                result = self.session.query(Promo).filter_by(gen_by=userid).all()
                print(len(result))
        except Exception as e:
            print(e)
            return result
        return result
    
if __name__ == '__main__':
    # promoDB = PromoDB()
    # userDB = UserDB()
    
    # user_id = userDB.get_user_by_username('dio').uuid
    # promoDB.create_promo(10, user_id)
    # for promo in  promoDB.get_promos_by_userid(user_id, bind_filter=True):
    #     print(promo.promo, promo.bind_userid)

    # user_id = userDB.get_user_by_username('Bonny').uuid
    # promoDB.bind_promo('DZNpRD', user_id)
    pass