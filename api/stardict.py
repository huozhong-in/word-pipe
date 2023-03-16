#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 tw=0 et :
#======================================================================
#
# stardict.py - 
#
# Created by skywind on 2011/05/13
# Last Modified: 2019/11/09 23:47
#
#======================================================================
from __future__ import print_function
import sys
import time
import os
# import io
# import csv
import sqlite3
# import codecs
import json
from pathlib import Path

MySQLdb = None


#----------------------------------------------------------------------
# python3 compatible
#----------------------------------------------------------------------
if sys.version_info[0] >= 3:
    unicode = str
    long = int
    xrange = range


#----------------------------------------------------------------------
# word strip
#----------------------------------------------------------------------
def stripword(word):
    return (''.join([ n for n in word if n.isalnum() ])).lower()


#----------------------------------------------------------------------
# StarDict 
#----------------------------------------------------------------------
class StarDict (object):

    def __init__ (self, filename, verbose = False):
        self.__dbname = filename
        if filename != ':memory:':
            os.path.abspath(filename)
        self.__conn = None
        self.__verbose = verbose
        self.__open()

    # 初始化并创建必要的表格和索引
    def __open (self):
        sql = '''
        CREATE TABLE IF NOT EXISTS "stardict" (
            "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
            "word" VARCHAR(64) COLLATE NOCASE NOT NULL UNIQUE,
            "sw" VARCHAR(64) COLLATE NOCASE NOT NULL,
            "phonetic" VARCHAR(64),
            "definition" TEXT,
            "translation" TEXT,
            "pos" VARCHAR(16),
            "collins" INTEGER DEFAULT(0),
            "oxford" INTEGER DEFAULT(0),
            "tag" VARCHAR(64),
            "bnc" INTEGER DEFAULT(NULL),
            "frq" INTEGER DEFAULT(NULL),
            "exchange" TEXT,
            "detail" TEXT,
            "audio" TEXT
        );
        CREATE UNIQUE INDEX IF NOT EXISTS "stardict_1" ON stardict (id);
        CREATE UNIQUE INDEX IF NOT EXISTS "stardict_2" ON stardict (word);
        CREATE INDEX IF NOT EXISTS "stardict_3" ON stardict (sw, word collate nocase);
        CREATE INDEX IF NOT EXISTS "sd_1" ON stardict (word collate nocase);
        '''

        self.__conn = sqlite3.connect(self.__dbname, isolation_level = "IMMEDIATE")
        self.__conn.isolation_level = "IMMEDIATE"

        sql = '\n'.join([ n.strip('\t') for n in sql.split('\n') ])
        sql = sql.strip('\n')

        self.__conn.executescript(sql)
        self.__conn.commit()

        fields = ( 'id', 'word', 'sw', 'phonetic', 'definition', 
            'translation', 'pos', 'collins', 'oxford', 'tag', 'bnc', 'frq', 
            'exchange', 'detail', 'audio' )
        self.__fields = tuple([(fields[i], i) for i in range(len(fields))])
        self.__names = { }
        for k, v in self.__fields:
            self.__names[k] = v
        self.__enable = self.__fields[3:]
        return True

    # 数据库记录转化为字典
    def __record2obj (self, record):
        if record is None:
            return None
        word = {}
        for k, v in self.__fields:
            word[k] = record[v]
        if word['detail']:
            text = word['detail']
            try:
                obj = json.loads(text)
            except:
                obj = None
            word['detail'] = obj
        return word

    # 关闭数据库
    def close (self):
        if self.__conn:
            self.__conn.close()
        self.__conn = None
    
    def __del__ (self):
        self.close()

    # 输出日志
    def out (self, text):
        if self.__verbose:
            print(text)
        return True

    # 查询单词
    def query (self, key):
        c = self.__conn.cursor()
        record = None
        if isinstance(key, int) or isinstance(key, long):
            c.execute('select * from stardict where id = ?;', (key,))
        elif isinstance(key, str) or isinstance(key, unicode):
            c.execute('select * from stardict where word = ?', (key,))
        else:
            return None
        record = c.fetchone()
        return self.__record2obj(record)

    # 查询单词匹配
    def match (self, word, limit = 10, strip = False):
        c = self.__conn.cursor()
        if not strip:
            sql = 'select id, word from stardict where word >= ? '
            sql += 'order by word collate nocase limit ?;'
            c.execute(sql, (word, limit))
        else:
            sql = 'select id, word from stardict where sw >= ? '
            sql += 'order by sw, word collate nocase limit ?;'
            c.execute(sql, (stripword(word), limit))
        records = c.fetchall()
        result = []
        for record in records:
            result.append(tuple(record))
        return result

    # 批量查询
    def query_batch (self, keys):
        sql = 'select * from stardict where '
        if keys is None:
            return None
        if not keys:
            return []
        querys = []
        for key in keys:
            if isinstance(key, int) or isinstance(key, long):
                querys.append('id = ?')
            elif key is not None:
                querys.append('word = ?')
        sql = sql + ' or '.join(querys) + ';'
        query_word = {}
        query_id = {}
        c = self.__conn.cursor()
        c.execute(sql, tuple(keys))
        for row in c:
            obj = self.__record2obj(row)
            query_word[obj['word'].lower()] = obj
            query_id[obj['id']] = obj
        results = []
        for key in keys:
            if isinstance(key, int) or isinstance(key, long):
                results.append(query_id.get(key, None))
            elif key is not None:
                results.append(query_word.get(key.lower(), None))
            else:
                results.append(None)
        return tuple(results)

    # 取得单词总数
    def count (self):
        c = self.__conn.cursor()
        c.execute('select count(*) from stardict;')
        record = c.fetchone()
        return record[0]

    # 注册新单词
    def register (self, word, items, commit = True):
        sql = 'INSERT INTO stardict(word, sw) VALUES(?, ?);'
        try:
            self.__conn.execute(sql, (word, stripword(word)))
        except sqlite3.IntegrityError as e:
            self.out(str(e))
            return False
        except sqlite3.Error as e:
            self.out(str(e))
            return False
        self.update(word, items, commit)
        return True

    # 删除单词
    def remove (self, key, commit = True):
        if isinstance(key, int) or isinstance(key, long):
            sql = 'DELETE FROM stardict WHERE id=?;'
        else:
            sql = 'DELETE FROM stardict WHERE word=?;'
        try:
            self.__conn.execute(sql, (key,))
            if commit:
                self.__conn.commit()
        except sqlite3.IntegrityError:
            return False
        return True

    # 清空数据库
    def delete_all (self, reset_id = False):
        sql1 = 'DELETE FROM stardict;'
        sql2 = "UPDATE sqlite_sequence SET seq = 0 WHERE name = 'stardict';"
        try:
            self.__conn.execute(sql1)
            if reset_id:
                self.__conn.execute(sql2)
            self.__conn.commit()
        except sqlite3.IntegrityError as e:
            self.out(str(e))
            return False
        except sqlite3.Error as e:
            self.out(str(e))
            return False
        return True

    # 更新单词数据
    def update (self, key, items, commit = True):
        names = []
        values = []
        for name, id in self.__enable:
            if name in items:
                names.append(name)
                value = items[name]
                if name == 'detail':
                    if value is not None:
                        value = json.dumps(value, ensure_ascii = False)
                values.append(value)
        if len(names) == 0:
            if commit:
                try:
                    self.__conn.commit()
                except sqlite3.IntegrityError:
                    return False
            return False
        sql = 'UPDATE stardict SET ' + ', '.join(['%s=?'%n for n in names])
        if isinstance(key, str) or isinstance(key, unicode):
            sql += ' WHERE word=?;'
        else:
            sql += ' WHERE id=?;'
        try:
            self.__conn.execute(sql, tuple(values + [key]))
            if commit:
                self.__conn.commit()
        except sqlite3.IntegrityError:
            return False
        return True

    # 浏览词典
    def __iter__ (self):
        c = self.__conn.cursor()
        sql = 'select "id", "word" from "stardict"'
        sql += ' order by "word" collate nocase;'
        c.execute(sql)
        return c.__iter__()

    # 取得长度
    def __len__ (self):
        return self.count()

    # 检测存在
    def __contains__ (self, key):
        return self.query(key) is not None

    # 查询单词
    def __getitem__ (self, key):
        return self.query(key)

    # 提交变更
    def commit (self):
        try:
            self.__conn.commit()
        except sqlite3.IntegrityError:
            self.__conn.rollback()
            return False
        return True

    # 取得所有单词
    def dumps (self):
        return [ n for _, n in self.__iter__() ]



#----------------------------------------------------------------------
# startup MySQLdb
#----------------------------------------------------------------------
def mysql_startup():
    global MySQLdb
    if MySQLdb is not None:
        return True
    try:
        import mysql.connector as _mysql
        MySQLdb = _mysql
    except ImportError:
        return False
    return True


#----------------------------------------------------------------------
# DictMysql
#----------------------------------------------------------------------
class DictMySQL (object):

    def __init__ (self, desc, init = False, timeout = 10, verbose = False):
        self.__argv = {}
        self.__uri = {}
        if isinstance(desc, dict):
            argv = desc
        else:
            argv = self.__url_parse(desc)
        for k, v in argv.items():
            self.__argv[k] = v
            if k not in ('engine', 'init', 'db', 'verbose'):
                self.__uri[k] = v
        self.__uri['connect_timeout'] = timeout
        self.__conn = None
        self.__verbose = verbose
        self.__init = init
        if 'db' not in argv:
            raise KeyError('not find db name')
        self.__open()

    def __open (self):
        mysql_startup()
        if MySQLdb is None:
            raise ImportError('No module named MySQLdb')
        fields = [ 'id', 'word', 'sw', 'phonetic', 'definition', 
            'translation', 'pos', 'collins', 'oxford', 'tag', 'bnc', 'frq', 
            'exchange', 'detail', 'audio' ]
        self.__fields = tuple([(fields[i], i) for i in range(len(fields))])
        self.__names = { }
        for k, v in self.__fields:
            self.__names[k] = v
        self.__enable = self.__fields[3:]
        self.__db = self.__argv.get('db', 'stardict')
        if not self.__init:
            uri = {}
            for k, v in self.__uri.items():
                uri[k] = v
            uri['db'] = self.__db
            self.__conn = MySQLdb.connect(**uri)
        else:
            self.__conn = MySQLdb.connect(**self.__uri)
            return self.init()
        return True

    # 输出日志
    def out (self, text):
        if self.__verbose:
            print(text)
        return True

    # 初始化数据库与表格
    def init (self):
        database = self.__argv.get('db', 'stardict')
        self.out('create database: %s'%database)
        self.__conn.query("SET sql_notes = 0;")
        self.__conn.query('CREATE DATABASE IF NOT EXISTS %s;'%database)
        self.__conn.query('USE %s;'%database)
        # self.__conn.query('drop table if exists stardict')
        sql = '''
            CREATE TABLE IF NOT EXISTS `%s`.`stardict` (
            `id` INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
            `word` VARCHAR(64) NOT NULL UNIQUE KEY,
            `sw` VARCHAR(64) NOT NULL,
            `phonetic` VARCHAR(64),
            `definition` TEXT,
            `translation` TEXT,
            `pos` VARCHAR(16),
            `collins` SMALLINT DEFAULT 0,
            `oxford` SMALLINT DEFAULT 0,
            `tag` VARCHAR(64),
            `bnc` INT DEFAULT NULL,
            `frq` INT DEFAULT NULL,
            `exchange` TEXT,
            `detail` TEXT,
            `audio` TEXT,
            KEY(`sw`, `word`),
            KEY(`collins`),
            KEY(`oxford`),
            KEY(`tag`)
            )
            '''%(database)
        sql = '\n'.join([ n.strip('\t') for n in sql.split('\n') ])
        sql = sql.strip('\n')
        sql += ' ENGINE=MyISAM DEFAULT CHARSET=utf8;'
        self.__conn.query(sql)
        self.__conn.commit()
        return True

    # 读取 mysql://user:passwd@host:port/database
    def __url_parse (self, url):
        if url[:8] != 'mysql://':
            return None
        url = url[8:]
        obj = {}
        part = url.split('/')
        main = part[0]
        p1 = main.find('@')
        if p1 >= 0:
            text = main[:p1].strip()
            main = main[p1 + 1:]
            p1 = text.find(':')
            if p1 >= 0:
                obj['user'] = text[:p1].strip()
                obj['passwd'] = text[p1 + 1:].strip()
            else:
                obj['user'] = text
        p1 = main.find(':')
        if p1 >= 0:
            port = main[p1 + 1:]
            main = main[:p1]
            obj['port'] = int(port)
        main = main.strip()
        if not main:
            main = 'localhost'
        obj['host'] = main.strip()
        if len(part) >= 2:
            obj['db'] = part[1]
        return obj

    # 数据库记录转化为字典
    def __record2obj (self, record):
        if record is None:
            return None
        word = {}
        for k, v in self.__fields:
            word[k] = record[v]
        if word['detail']:
            text = word['detail']
            try:
                obj = json.loads(text)
            except:
                obj = None
            word['detail'] = obj
        return word

    # 关闭数据库
    def close (self):
        if self.__conn:
            self.__conn.close()
        self.__conn = None

    def __del__ (self):
        self.close()

    # 查询单词
    def query (self, key):
        record = None
        if isinstance(key, int) or isinstance(key, long):
            sql = 'select * from stardict where id = %s;'
        elif isinstance(key, str) or isinstance(key, unicode):
            sql = 'select * from stardict where word = %s;'
        else:
            return None
        with self.__conn as c:
            c.execute(sql, (key,))
            record = c.fetchone()
        return self.__record2obj(record)

    # 查询单词匹配
    def match (self, word, limit = 10, strip = False):
        c = self.__conn.cursor()
        if not strip:
            sql = 'select id, word from stardict where word >= %s '
            sql += 'order by word limit %s;'
            c.execute(sql, (word, limit))
        else:
            sql = 'select id, word from stardict where sw >= %s '
            sql += 'order by sw, word limit %s;'
            c.execute(sql, (stripword(word), limit))
        records = c.fetchall()
        result = []
        for record in records:
            result.append(tuple(record))
        return result

    # 批量查询
    def query_batch (self, keys):
        sql = 'select * from stardict where '
        if keys is None:
            return None
        if not keys:
            return []
        querys = []
        for key in keys:
            if isinstance(key, int) or isinstance(key, long):
                querys.append('id = %s')
            elif key is not None:
                querys.append('word = %s')
        sql = sql + ' or '.join(querys) + ';'
        query_word = {}
        query_id = {}
        with self.__conn as c:
            c.execute(sql, tuple(keys))
            for row in c:
                obj = self.__record2obj(row)
                query_word[obj['word'].lower()] = obj
                query_id[obj['id']] = obj
        results = []
        for key in keys:
            if isinstance(key, int) or isinstance(key, long):
                results.append(query_id.get(key, None))
            elif key is not None:
                results.append(query_word.get(key.lower(), None))
            else:
                results.append(None)
        return tuple(results)

    # 注册新单词
    def register (self, word, items, commit = True):
        sql = 'INSERT INTO stardict(word, sw) VALUES(%s, %s);'
        try:
            with self.__conn as c:
                c.execute(sql, (word, stripword(word)))
        except MySQLdb.Error as e:
            self.out(str(e))
            return False
        self.update(word, items, commit)
        return True

    # 删除单词
    def remove (self, key, commit = True):
        if isinstance(key, int) or isinstance(key, long):
            sql = 'DELETE FROM stardict WHERE id=%s;'
        else:
            sql = 'DELETE FROM stardict WHERE word=%s;'
        try:
            with self.__conn as c:
                c.execute(sql, (key,))
        except MySQLdb.Error as e:
            self.out(str(e))
            return False
        return True

    # 清空数据库
    def delete_all (self, reset_id = False):
        sql1 = 'DELETE FROM stardict;'
        try:
            with self.__conn as c:
                c.execute(sql1)
        except MySQLdb.Error as e:
            self.out(str(e))
            return False
        return True

    # 更新单词数据
    def update (self, key, items, commit = True):
        names = []
        values = []
        for name, id in self.__enable:
            if name in items:
                names.append(name)
                value = items[name]
                if name == 'detail':
                    if value is not None:
                        value = json.dumps(value, ensure_ascii = False)
                values.append(value)
        if len(names) == 0:
            if commit:
                try:
                    self.__conn.commit()
                except MySQLdb.Error as e:
                    self.out(str(e))
                    return False
            return False
        sql = 'UPDATE stardict SET ' + ', '.join(['%s=%%s'%n for n in names])
        if isinstance(key, str) or isinstance(key, unicode):
            sql += ' WHERE word=%s;'
        else:
            sql += ' WHERE id=%s;'
        try:
            with self.__conn as c:
                c.execute(sql, tuple(values + [key]))
        except MySQLdb.Error as e:
            self.out(str(e))
            return False
        return True

    # 取得数据量
    def count (self):
        sql = 'SELECT count(*) FROM stardict;'
        try:
            with self.__conn as c:
                c.execute(sql)
                row = c.fetchone()
                return row[0]
        except MySQLdb.Error as e:
            self.out(str(e))
            return -1
        return 0

    # 提交数据
    def commit (self):
        try:
            self.__conn.commit()
        except MySQLdb.Error as e:
            self.out(str(e))
            return False
        return True

    # 取得长度
    def __len__ (self):
        return self.count()

    # 检测存在
    def __contains__ (self, key):
        return self.query(key) is not None

    # 查询单词
    def __getitem__ (self, key):
        return self.query(key)

    # 取得所有单词
    def dumps (self):
        return [ n for _, n in self.__iter__() ]




#----------------------------------------------------------------------
# 词形衍生：查找动词的各种时态，名词的复数等，或反向查找
# 格式为每行一条数据：根词汇 -> 衍生1,衍生2,衍生3
# 可以用 Hunspell数据生成，下面有个日本人做的简版（1.8万组数据）：
# http://www.lexically.net/downloads/version4/downloading%20BNC.htm
#----------------------------------------------------------------------
class LemmaDB (object):

    def __init__ (self):
        self._stems = {}
        self._words = {}
        self._frqs = {}

    # 读取数据
    def load (self, filename, encoding = None):
        content = open(filename, 'rb').read()
        if content[:3] == b'\xef\xbb\xbf':
            content = content[3:].decode('utf-8', 'ignore')
        elif encoding is not None:
            text = content.decode(encoding, 'ignore')
        else:
            text = None
            match = ['utf-8', sys.getdefaultencoding(), 'ascii']
            for encoding in match + ['gbk', 'latin1']:
                try:
                    text = content.decode(encoding)
                    break
                except:
                    pass
            if text is None:
                text = content.decode('utf-8', 'ignore')
        number = 0
        for line in text.split('\n'):
            number += 1
            line = line.strip('\r\n ')
            if (not line) or (line[:1] == ';'):
                continue
            pos = line.find('->')
            if not pos:
                continue
            stem = line[:pos].strip()
            p1 = stem.find('/')
            frq = 0
            if p1 >= 0:
                frq = int(stem[p1 + 1:].strip())
                stem = stem[:p1].strip()
            if not stem:
                continue
            if frq > 0:
                self._frqs[stem] = frq
            for word in line[pos + 2:].strip().split(','):
                p1 = word.find('/')
                if p1 >= 0:
                    word = word[:p1].strip()
                if not word:
                    continue
                self.add(stem, word.strip())
        return True

    # 保存数据文件
    def save (self, filename, encoding = 'utf-8'):
        stems = list(self._stems.keys())
        stems.sort(key = lambda x: x.lower())
        import codecs
        fp = codecs.open(filename, 'w', encoding)
        output = []
        for stem in stems:
            words = self.get(stem)
            if not words:
                continue
            frq = self._frqs.get(stem, 0)
            if frq > 0:
                stem = '%s/%d'%(stem, frq)
            output.append((-frq, u'%s -> %s'%(stem, ','.join(words))))
        output.sort()
        for _, text in output:
            fp.write(text + '\n')
        fp.close()
        return True

    # 添加一个词根的一个衍生词
    def add (self, stem, word):
        if stem not in self._stems:
            self._stems[stem] = {}
        if word not in self._stems[stem]:
            self._stems[stem][word] = len(self._stems[stem]) 
        if word not in self._words:
            self._words[word] = {}
        if stem not in self._words[word]:
            self._words[word][stem] = len(self._words[word])
        return True

    # 删除一个词根的一个衍生词
    def remove (self, stem, word):
        count = 0
        if stem in self._stems:
            if word in self._stems[stem]:
                del self._stems[stem][word]
                count += 1
            if not self._stems[stem]:
                del self._stems[stem]
        if word in self._words:
            if stem in self._words[word]:
                del self._words[word][stem]
                count += 1
            if not self._words[word]:
                del self._words[word]
        return (count > 0) and True or False

    # 清空数据库
    def reset (self):
        self._stems = {}
        self._words = {}
        return True

    # 根据词根找衍生，或者根据衍生反向找词根
    def get (self, word, reverse = False):
        if not reverse:
            if word not in self._stems:
                if word in self._words:
                    return [word]
                return None
            words = [ (v, k) for (k, v) in self._stems[word].items() ]
        else:
            if word not in self._words:
                if word in self._stems:
                    return [word]
                return None
            words = [ (v, k) for (k, v) in self._words[word].items() ]
        words.sort()
        return [ k for (v, k) in words ]

    # 知道一个单词求它的词根
    def word_stem (self, word):
        return self.get(word, reverse = True)

    # 总共多少条词根数据
    def stem_size (self):
        return len(self._stems)

    # 总共多少条衍生数据
    def word_size (self):
        return len(self._words)

    def dump (self, what = 'ALL'):
        words = {}
        what = what.lower()
        if what in ('all', 'stem'):
            for word in self._stems:
                words[word] = 1
        if what in ('all', 'word'):
            for word in self._words:
                words[word] = 1
        return words

    def __len__ (self):
        return len(self._stems)

    def __getitem__ (self, stem):
        return self.get(stem)

    def __contains__ (self, stem):
        return (stem in self._stems)

    def __iter__ (self):
        return self._stems.__iter__()







#----------------------------------------------------------------------
# testing
#----------------------------------------------------------------------
if __name__ == '__main__':
    db = Path(Path(__file__).parent.absolute() / 'db/stardict.db')
    my = {'host':'??', 'user':'skywind', 'passwd':'??', 'db':'skywind_t1'}
    def test1():
        t = time.time()
        sd = StarDict(db, False)
        print(time.time() - t)
        # sd.delete_all(True)
        print(sd.register('kiss2', {'definition':'kiss me'}, False))
        print(sd.register('kiss here', {'definition':'kiss me'}, False))
        print(sd.register('Kiss', {'definition':'BIG KISS'}, False))
        print(sd.register('kiss', {'definition':'kiss me'}, False))
        print(sd.register('suck', {'definition':'suck me'}, False))
        print(sd.register('give', {'definition':'give me', 'detail':[1,2,3]}, False))
        sd.commit()
        print('')
        print(sd.count())
        print(sd.query('kiSs'))
        print(sd.query(2))
        print(sd.match('kis', 10))
        print('')
        print(sd.query_batch(['give', 2]))
        print(sd.match('kisshere', 10, True))
        return 0
    def test2():
        t = time.time()
        dm = DictMySQL(my, init = True)
        print(time.time() - t)
        # dm.delete_all(True)
        print(dm.register('kiss2', {'definition':'kiss me'}, False))
        print(dm.register('kiss here', {'definition':'kiss me'}, False))
        print(dm.register('Kiss', {'definition':'kiss me'}, False))
        print(dm.register('kiss', {'definition':'BIG KISS'}, False))
        print(dm.register('suck', {'definition':'suck me'}, False))
        print(dm.register('give', {'definition':'give me'}, False))
        print(dm.query('kiss'))
        print(dm.match('kis'))
        print('')
        print(dm.query('KiSs'))
        print(dm.query_batch(['give', 2, 9]))
        print('count: %d'%len(dm))
        print(dm.match('kisshere', 10, True))
        return 0
    def test3():
        tic = time.perf_counter()
        sd = StarDict(db, False)
        print(sd.query('process'))
        print(sd.match(stripword('Proba'), 10, True))
        sd.close()
        toc = time.perf_counter()
        print(f"Processed in {toc - tic:0.4f} seconds")
        return 0
    
    test3()



