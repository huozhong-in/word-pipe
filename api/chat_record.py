#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import mysql.connector
# from mysql.connector import errorcode
from sqlalchemy import create_engine, Column, Integer, String, or_
from sqlalchemy.orm import sessionmaker, declarative_base
# from sqlalchemy.pool import StaticPool
import time
from config import *

Base: declarative_base = declarative_base()

class ChatRecord(Base):
    __tablename__ = 't_chat_record'

    pk_chat_record = Column(Integer, primary_key=True)
    msgFrom = Column(String(36), nullable=False)
    msgTo = Column(String(36), nullable=False)
    msgCreateTime = Column(Integer, nullable=False, default=0)
    msgContent = Column(String, nullable=False)
    msgStatus = Column(Integer, nullable=False, default=1)
    msgType = Column(Integer, nullable=False, default=1)
    msgSource = Column(Integer, nullable=False, default=1)
    msgDest = Column(Integer, nullable=False, default=1)

    def __repr__(self):
        return f'<ChatRecord(pk_chat_record={self.pk_chat_record}, msgFrom={self.msgFrom}, msgTo={self.msgTo}, msgCreateTime={self.msgCreateTime}, msgContent={self.msgContent})>'

class ChatRecordDB:

    def __init__(self):
        connect_args = MYSQL_CONFIG
        self.cnx = mysql.connector.connect(**connect_args)
        self.engine = create_engine(f'mysql+mysqlconnector://{MYSQL_CONFIG["user"]}:{MYSQL_CONFIG["password"]}@{MYSQL_CONFIG["host"]}/{MYSQL_CONFIG["database"]}')

        Session = sessionmaker(bind=self.engine)
        self.session = Session()
        Base.metadata.create_all(self.engine)

    def get_chat_record(self, user_id: str, last_chat_record_id: int, limit: int=50):
        result: list = []
        if last_chat_record_id == 0:
            # 获取我发出或我收到的最新的50条消息，按照主键自增ID倒序排列
            result = self.session.query(ChatRecord).filter(or_(ChatRecord.msgFrom == user_id, ChatRecord.msgTo == user_id)).order_by(ChatRecord.pk_chat_record.desc()).limit(limit).all()
        else:
            result = self.session.query(ChatRecord).filter(or_(ChatRecord.msgFrom == user_id,  ChatRecord.msgTo == user_id), ChatRecord.pk_chat_record < last_chat_record_id).order_by(ChatRecord.pk_chat_record.desc()).limit(limit).all()
        return result

    def insert_chat_record(self, chat_record: ChatRecord):
        self.session.add(chat_record)
        self.session.commit()
    
    def close(self):
        self.session.close()
        self.cnx.close()

if __name__ == '__main__':
    crdb = ChatRecordDB()
    create_time = int(time.time())
    cr = ChatRecord( msgFrom='dio', msgTo='Jarvis', msgCreateTime=create_time, msgContent='北冰洋冰层厚度？', msgStatus=1, msgType=1, msgSource=1, msgDest=1)
    crdb.insert_chat_record(cr)
    # r = crdb.get_chat_record('Jarvis', -1)
    # print(r)
    crdb.close()
    # 反转打印
    # for i in r[::-1]:
    #     print(i.pk_chat_record)
