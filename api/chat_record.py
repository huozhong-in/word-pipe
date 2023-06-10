#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from sqlalchemy import Column, Integer, String, or_
from sqlalchemy.orm import declarative_base
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
    conversation_id = Column(Integer, nullable=False, default=0)

    def __repr__(self):
        return f'<ChatRecord(pk_chat_record={self.pk_chat_record}, msgFrom={self.msgFrom}, msgTo={self.msgTo}, msgCreateTime={self.msgCreateTime}, msgContent={self.msgContent})>'

class ChatRecordDB:

    def __init__(self, session):
        self.session = session

    def get_chat_record(self, user_id: str, last_chat_record_id: int, limit: int=30, conversation_id: int=0):
        result: list = []
        if last_chat_record_id == 0:
            # 获取我发出或我收到的最新的30条消息，按照主键自增ID倒序排列
            result = self.session.query(ChatRecord).filter(ChatRecord.conversation_id == conversation_id).filter(or_(ChatRecord.msgFrom == user_id, ChatRecord.msgTo == user_id)).order_by(ChatRecord.pk_chat_record.desc()).limit(limit).all()
        else:
            result = self.session.query(ChatRecord).filter(ChatRecord.conversation_id == conversation_id).filter(or_(ChatRecord.msgFrom == user_id,  ChatRecord.msgTo == user_id), ChatRecord.pk_chat_record < last_chat_record_id).order_by(ChatRecord.pk_chat_record.desc()).limit(limit).all()
        return result

    def insert_chat_record(self, chat_record: ChatRecord) -> int:
        self.session.add(chat_record)
        self.session.commit()
        return chat_record.pk_chat_record
    

class Conversation(Base):
    __tablename__ = 't_conversation'
    '''
    CREATE TABLE `t_conversation` (
        `pk_conversation` int(11) unsigned NOT NULL AUTO_INCREMENT,
        `uuid` varchar(36) NOT NULL,
        `conversation_name` varchar(50) DEFAULT '',
        `is_deleted` int(1) NOT NULL DEFAULT 0,
        `conversation_create_time` int(11) NOT NULL,
        PRIMARY KEY (`pk_conversation`)
    ) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    '''
    pk_conversation = Column(Integer, primary_key=True)
    uuid = Column(String(36), nullable=False)
    conversation_name = Column(String(50), default="")
    is_deleted = Column(Integer, nullable=False, default=0)
    conversation_create_time = Column(Integer, nullable=False, default=0)

class ConversationDB:
    def __init__(self, session) -> None:
        self.session = session
    
    def get_conversation_list(self, user_id: str) -> list:
        result: list = []
        result = self.session.query(Conversation).filter(Conversation.uuid == user_id, Conversation.is_deleted == 0).order_by(Conversation.pk_conversation.desc()).all()
        return result
    
    def get_a_conversation(self, conversation_id: int) -> Conversation:
        result: Conversation = self.session.query(Conversation).filter(Conversation.pk_conversation == conversation_id).first()
        return result
    
    def delete_conversation(self, conversation_id: int) -> bool:
        try:
            self.session.query(Conversation).filter(Conversation.pk_conversation == conversation_id).update({'is_deleted': 1})
            self.session.commit()
            return True
        except Exception as e:
            print(e)
            self.session.rollback()
            return False
    
    def create_conversation(self, conversation: Conversation) -> int:
        self.session.add(conversation)
        self.session.commit()
        self.session.flush()
        return conversation.pk_conversation

    def update_conversation_name(self, conversation_id: int, conversation_name: str):
        self.session.query(Conversation).filter(Conversation.pk_conversation == conversation_id).update({'conversation_name': conversation_name})
        self.session.commit()


if __name__ == '__main__':
    # crdb = ChatRecordDB()
    # # create_time = int(time.time())
    # # cr = ChatRecord( msgFrom='Dio', msgTo='Jasmine', msgCreateTime=create_time, msgContent='北冰洋冰层厚度？', msgStatus=1, msgType=1, msgSource=1, msgDest=1)
    # # crdb.insert_chat_record(cr)
    # l: list = crdb.get_chat_record(user_id="b811abd7-c0bb-4301-9664-574d0d8b11f8", last_chat_record_id=0, limit=20, conversation_id=6)
    # print(len(l))
    # for cr in l:
    #     print(cr.msgContent)
    # crdb.close()
    # 反转打印
    # for i in r[::-1]:
    #     print(i.msgContent)
    # cvDB = ConversationDB()
    # cv = Conversation(uuid='b811abd7-c0bb-4301-9664-574d0d8b11f8', conversation_name='test conversation', conversation_create_time=int(time.time()))
    # r:int = cvDB.create_conversation(cv)
    # cvDB.close()
    # print(r)
    pass
