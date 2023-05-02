#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import threading
import time
import hashlib
from pathlib import Path
import marisa_trie
from flask import (
    Flask, 
    Response, 
    make_response, 
    jsonify, 
    request, 
    render_template, 
    url_for, 
    send_file,
    g,
)
from flask_sse import sse
from stardict import *
from config import *
from io import BytesIO
from PIL import Image
from user import User,UserDB
from chat_record import *
from flask_cors import CORS
import requests
# import openai
import logging
# import streamtologger
from Crypto.Cipher import AES
import base64
from queue import Queue
import tiktoken

app = Flask(__name__)
CORS(app)

# logging
if not os.path.exists('logs'):
    os.mkdir('logs')
logging.basicConfig(
    filename='logs/api_{starttime}.log'.format(starttime=time.strftime('%Y%m%d', time.localtime(time.time()))),
    filemode='a',
    level=logging.DEBUG,
    format='%(levelname)s:%(asctime)s:%(message)s'
)
stderr_logger = logging.getLogger('STDERR')
# streamtologger.redirect(target="logs/print.log", append=False, header_format="[{timestamp:%Y-%m-%d %H:%M:%S} - {level:5}] ")

# for SSE nginx configuration https://serverfault.com/questions/801628/for-server-sent-events-sse-what-nginx-proxy-configuration-is-appropriate
app.config["REDIS_URL"] = REDIS_URL
@sse.after_request
def add_header(response):
    response.headers['X-Accel-Buffering'] = 'no'
    # response.headers['Cache-Control'] = 'no-cache'
    # response.headers['Connection'] = 'keep-alive'
    response.headers['Content-Type'] = 'text/event-stream'
    return response
app.register_blueprint(sse, url_prefix=SSE_SERVER_PATH, headers={'X-Accel-Buffering': 'no'})

# load json
vocab_file = Path(Path(__file__).parent.absolute() / 'db/vocab.json')
vocab = set()
with vocab_file.open() as f:
    data: dict = json.load(f)
logging.info(data.keys())
vocab = set(data['JUNIOR']).union(set(data['SENIOR'])).union(set(data['IELTS'])).union(set(data['TOEFL'])).union(set(data['GRE'])).union(set(data['TOEIC']))
logging.info(f'total: {len(vocab)} words.')

# marisa-trie for prefix search
trie = marisa_trie.Trie(vocab, order=marisa_trie.LABEL_ORDER)

# parse wordroot.txt
wordroot_file = Path(Path(__file__).parent.absolute() / 'db/wordroot.txt')
with wordroot_file.open() as f:
    wordroot= json.load(f)
logging.info(f"wordroot.txt including {len(wordroot.keys())} roots.")
word2root: dict = {}
for key, value in wordroot.items():
    if 'example' in value:
        for word in value['example']:
            if word in word2root:
                word2root[word].append(key)
            else:
                word2root[word] = [key]

# init user db
userDB = UserDB()
crdb = ChatRecordDB()

@app.teardown_appcontext
def shutdown_session(exception=None):
    # 请求上下文结束时自动释放 session
    # g.session.close()
    userDB.session.close()
    crdb.session.close()

@app.before_request
def before_request():
    # 请求开始时将连接和 session 绑定到请求上下文
    g.db = userDB.engine.connect()
    g.session = userDB.session
    g.db2= crdb.engine.connect()
    g.session2 = crdb.session

@app.after_request
def after_request(response):
    # 请求结束时断开连接
    g.db.close()
    g.db2.close()
    return response


def generate_time_based_client_id(prefix='client_'):
    current_time = time.time()
    raw_client_id = f"{prefix}{current_time}".encode('utf-8')
    hashed_client_id = hashlib.sha256(raw_client_id).hexdigest()
    return hashed_client_id

@app.route('/api/test', methods = ['GET'])
def test() -> Response:    
    return make_response(jsonify(), 200)

@app.route('/api/s', methods = ['GET'])
def prefix_search() -> Response:
    '''
    从vocab.json中搜索前缀，
    '''
    
    if not request.args.get('k'):
        return make_response(jsonify({}), 200)
    k:str = request.args.get('k')
    if k == '':
        return make_response(jsonify({}), 200)
    
    # tic = time.perf_counter()

    global trie    
    r = trie.keys(k)[0:50]
    result = dict()
    result["result"] = list(r)
    x = list()
    x.append(result)
    # print(f"prefix_search() result: {x}")

    # toc = time.perf_counter()
    # print(f"[Processed in {toc - tic:0.4f} seconds]")
    response =  make_response(jsonify(x), 200)
    # response.headers.add("Access-Control-Allow-Origin", "*")
    # response.headers.add("Access-Control-Allow-Credentials", "true")
    # response.headers.add("Access-Control-Allow-Headers", "*")
    # response.headers.add("Access-Control-Allow-Methods", "*")
    # response.headers.add("Access-Control-Allow-Methods", "GET,PUT,PATCH,POST,DELETE")
    # response.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
    return response

@app.route('/api/p', methods = ['GET'])
def point_search():
    '''
    查询单词的意思，返回一个结果
    '''
    if not request.args.get('k'):
        return make_response(jsonify({}), 200)
    k: str = request.args.get('k')
    if k == '':
        return make_response(jsonify({}), 200)
    
    # tic = time.perf_counter()
    sd = StarDict(Path(Path(__file__).parent.absolute() / 'db/stardict.db'), False)
    r: dict = sd.query(k)
    sd.close()
    x = list()
    x.append(r)
    # toc = time.perf_counter()
    # print(f"point_search() word: {k}")
    # print(f"[Processed in {toc - tic:0.4f} seconds]")
    return make_response(jsonify(x), 200)

@app.route('/api/m', methods = ['GET'])
def match_words():
    """
    通过sw精确匹配单词，返回多个结果
    """
    if not request.args.get('k'):
        return make_response(jsonify({}), 200)
    k: str = request.args.get('k')
    if k == '':
        return make_response(jsonify({}), 200)
    tic = time.perf_counter()
    sd = StarDict(Path(Path(__file__).parent.absolute() / 'db/stardict.db'), False)
    r: list = sd.match2(prefix=k)
    sd.close()
    toc = time.perf_counter()
    logging.info(f"match_words() word: {k}")
    logging.info(f"[Processed in {toc - tic:0.4f} seconds]")
    return make_response(jsonify(r), 200)

@app.route('/api/qb', methods = ['POST'])
def query_batch():
    """
    批量查询单词的意思，传入多个单词（不是sw）返回结果包括全部字段
    """
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        json_list: list = request.get_json()
    except:
        return make_response('JSON data required', 500)
    tic = time.perf_counter()
    sd = StarDict(Path(Path(__file__).parent.absolute() / 'db/stardict.db'), False)
    r: list = sd.query_batch(json_list)
    sd.close()
    toc = time.perf_counter()
    logging.info(f"query_batch() word: {r}")
    logging.info(f"[Processed in {toc - tic:0.4f} seconds]")
    return make_response(jsonify(r), 200)
    
@app.route('/favicon.ico')
def favicon():
    r = make_response("data:;base64,iVBORw0KGgo=", 200)
    r.mimetype = "image/x-icon"
    return r

@app.route('/api/sse-test.html')
def sse_test():
    """
    渲染SSE测试页面
    """
    sse_url = url_for('sse.stream', channel=SSE_MSG_DEFAULT_CHANNEL, _external=False)
    return render_template('sse-test.html', sse_url=sse_url)

@app.route('/api/pub-test', methods = ['POST'])
def publish_test():
    """
    SSE测试页面的发布测试
    """
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        json: dict = request.get_json()
        message: str = json.get('message')
    except:
        return make_response('JSON data required', 500)
    r: list = list()
    id: str = generate_time_based_client_id()
    back_data: json = {}
    back_data['username'] = "Jasmine"
    back_data['type'] = 1
    r.append(message)
    back_data['dataList'] = r
    sse.publish(id=id, data=back_data, type=SSE_MSG_EVENTTYPE, channel=SSE_MSG_DEFAULT_CHANNEL)
    return jsonify({"success": True, "message": f"Server response:{message}"})

@app.route('/api/chat', methods = ['POST'])
def chat():
    '''
    接收用户发送的任何消息
    替用户发消息，就不会有时间错乱的问题了，否则SSE太快，比HTTP先返回数据。
    '''
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        data: dict = request.get_json()
        username: str = data.get('username')
        message: str = data.get('message')
        conversation_id: int = data.get('conversation_id')
    except:
        return make_response('JSON data required', 500)
    if message == '':
        return make_response('message required', 500)
    
    # tic = time.perf_counter()

    logging.info(f'[{username}]: {message}')
    if request.headers.get('X-access-token'):
        # print('X-access-token: ', request.headers['X-access-token'])
        u: User = userDB.get_user_by_username(username)
        if u is None:
            return make_response('', 500)
        if u.access_token != request.headers['X-access-token']:
            return make_response('', 500)
        if u.access_token_expire_at < int(time.time()):
            return make_response(jsonify({"errcode":50007,"errmsg":"access_token expired"}), 401)
    else:
        return make_response('access_token required', 500)

    # 将用户消息记录到数据库
    myuuid: str = userDB.get_user_by_username(username).uuid
    s: str = json.loads(json.dumps(message, ensure_ascii=False)) # 防止被SQLAlchemy转义双引号、回车符、制表符和斜杠
    cr = ChatRecord(msgFrom=myuuid, msgTo=userDB.get_user_by_username('Jasmine').uuid, msgCreateTime=int(time.time()), msgContent=s, msgType=1, conversation_id=conversation_id)
    crdb.insert_chat_record(cr)

    # 替用户发消息
    back_data: json = {}
    back_data['username'] = username
    back_data['uuid'] = myuuid
    dataList: list = list()
    dataList.append(message)
    back_data['dataList'] = dataList
    back_data['type'] = 1 # WordPipeMessageType.text format. See: config.dart
    back_data['createTime'] = int(time.time())
    id = generate_time_based_client_id(prefix=username)
    sse.publish(id=id, data=back_data, type=SSE_MSG_EVENTTYPE, channel=username)

    if conversation_id != 0:
        return make_response('', 200)

    # 检查message中是否包含英文单词
    import re
    pattern1 = re.compile(r'([a-zA-Z]{3,})') # 注意是3个字符以上的才认为是单词
    result: list = pattern1.findall(message)
    # print(result)
    # 根据用户消息中不同的单词数量，让客户端出现不同的选择界面
    back_data['username'] = "Jasmine"
    back_data['uuid'] = userDB.get_user_by_username('Jasmine').uuid
    dataList: list = list()
    if len(result) == 1:
        # 句子中只包含一个单词，大概率是用户想要查询单词的意思
        dataList.append(f"关于`{result[0]}`的具体意思，你是想直接知道答案呢 ，还是想通过例句来猜一猜？")
        dataList.append(result[0]) # 附上单词本身，方便客户端处理
        back_data['type'] = 101 # WordPipeMessageType.flask_reply_for_Word, See: config.dart
    elif len(result) > 1:
        # 句子中包含多个单词，可能是用户想要翻译句子，TODO 顺便可以猜猜哪个是用户的生词
        dataList.append(message) # 附上用户发来的原文，方便客户端处理 # dataList.append(f"```{message}```")
        dataList.append("句中单词已经高亮，可点击查询。你想让我翻译句子呢？还是在问我问题？")
        back_data['type'] = 102 # WordPipeMessageType.flask_reply_for_sentence, See: config.dart
    else:
        # 句子中不包含英文单词，可能是用户想要翻译中文到英文
        dataList.append(message)
        dataList.append("你想让我翻译成英文呢？还是在问我问题？")
        back_data['type'] = 107 # WordPipeMessageType.flask_reply_for_sentence_zh_en, See: config.dart
    back_data['dataList'] = dataList
    back_data['createTime'] = int(time.time())
    id = generate_time_based_client_id(prefix=username)
    sse.publish(id=id, data=back_data, type=SSE_MSG_EVENTTYPE, channel=username)


    # toc = time.perf_counter()
    # print(f"[Processed in {toc - tic:0.4f} seconds]")
    return make_response('', 200)

@app.route('/api/tts', methods = ['POST'])
def tts():
    '''
    语音合成
    '''
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        data: dict = request.get_json()
        username: str = data.get('username')
        text: str = data.get('text')
        key: str = data.get('key')
        voice: str = data.get('voice')
        rate: str = data.get('rate')
    except:
        return make_response('JSON data required', 500)
    if text == '':
        return make_response('text required', 500)
    
    # 每个登录用户都分配到一个channel，用于SSE推送，取得这个channel字符串
    channel: str = ''
    if request.headers.get('X-access-token'):
        # print('X-access-token: ', request.headers['X-access-token'])
        u: User = userDB.get_user_by_username(username)
        if u is None:
            return make_response('', 500)
        if u.access_token != request.headers['X-access-token']:
            return make_response('', 500)
        if u.access_token_expire_at < int(time.time()):
            return make_response(jsonify({"errcode":50007,"errmsg":"access_token expired"}), 401)
        channel = username
    else:
        return make_response('access_token required', 500)

    import asyncio
    import edge_tts
    async def _main(key: str, text: str) -> None:
        with app.app_context():
            back_data: json = {}
            back_data['type'] = 35 # WordPipeMessageType.tts_audio format. See: config.dart
            mp3FilePrefix = Path(Path(__file__).parent.absolute() / 'assets/tts')
            mp3File = Path(mp3FilePrefix / f'{key}.mp3')
            if not mp3File.exists():
                if int(rate) == 0:
                    communicate = edge_tts.Communicate(text=text, voice=voice)
                else:
                    rate_str = f'{rate}%'
                    if rate > 0:
                        rate_str = f'+{rate_str}'
                    communicate = edge_tts.Communicate(text=text, voice=voice, rate=rate_str)
                
                await communicate.save(mp3File)
            back_data['key'] = key
            back_data['mp3_url'] = '/tts/' + f'{key}.mp3'
            id = generate_time_based_client_id(prefix=username)
            sse.publish(id=id, data=back_data, type=SSE_MSG_EVENTTYPE, channel=channel)
    
    def fn_thread(key: str, text: str):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        loop.run_until_complete(_main(key=key, text=text))
    
    thread = threading.Thread(target=fn_thread, args=(key, text))
    thread.start()

    return make_response('', 200)

@app.route('/api/chat-root', methods = ['POST'])
def chat_root():
    '''
    通过对话的方式，将用户查询的字符串拆分成单个单词，分别查找词根词缀。
    - 可能命中多个词根词缀，所以要有list结构
    - TODO 单词是动词的话只有原型，将lemma.en.txt的内容实现转成键值对，拼接到结果中，供前端显示
    - 给出相同词根的其他单词。TODO 按频次倒序。 TODO 只出现在选定范围（四六雅思）内的词
    '''
    
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        data: dict = request.get_json()
        username: str = data.get('username')
        message: str = data.get('message')
    except:
        return make_response('JSON data required', 500)
    
    tic = time.perf_counter()

    logging.info(f'[{username}]: {message}')
    # 给每一个登录用户分配一个channel，用于SSE推送
    channel: str = SSE_MSG_DEFAULT_CHANNEL
    if request.headers.get('X-access-token'):
        # print('X-access-token: ', request.headers['X-access-token'])
        u: User = userDB.get_user_by_username(username)
        if u is None:
            return make_response('', 500)
        if u.access_token != request.headers['X-access-token']:
            return make_response('', 500)
        if u.access_token_expire_at < int(time.time()):
            return make_response(jsonify({"errcode":50007,"errmsg":"access_token expired"}), 401)
        channel = username
    
    if message.startswith('/root '):
        back_data: json = {}
        back_data = get_root_by_word(message)
        id = generate_time_based_client_id(prefix=username)
        logging.info("chat() /root publish id:", id)
        # 须publish两次，一次替用户说话，一次返回结果
        sse.publish(id=id, data=back_data, type=SSE_MSG_EVENTTYPE, channel=channel)

    elif message.startswith('/config '):
        pass

    toc = time.perf_counter()
    logging.info(f"[Processed in {toc - tic:0.4f} seconds]")

    return make_response('', 200)


def get_root_by_word(message: str) -> json:
    '''
    根据单词查找词根词缀
    print(word2root['tactful']) # 输出 ["-ful1","tact, tang, ting, tig"]
    TODO example里单词可能有大写或带空格的情况，如"-ite2"
    '''
    
    message = message.split('/root ')[1]
    dataList: list = list()
    import re
    # message= 'This is a long-time example with hyphenated-words, including some non-alpha character...'
    exp = r'\b[a-zA-Z]+(?:-[a-zA-Z]+)*\b'
    matches = re.finditer(exp, message)
    for match in matches:
        word = match.group(0)
        rootlist: list = list(word2root.get(word)) if word2root.get(word) != None else list()
        if len(rootlist) != 0:
            a_word: list = list()
            for root in rootlist:
                a_root: list = list()
                if wordroot[root].get('meaning') != None:
                    a_root.append({'meaning': wordroot[root]['meaning']})
                if wordroot[root].get('class') != None:
                    a_root.append({'class':  wordroot[root]['class']})
                if wordroot[root].get('origin') != None:
                    a_root.append({'origin': wordroot[root]['origin']})
                if wordroot[root].get('function') != None:
                    a_root.append({'function': wordroot[root]['function']})
                if wordroot[root].get('example') != None:
                    a_root.append({'example': wordroot[root]['example']})
                a_word.append({root: a_root}) 
            dataList.append({word: a_word})
            
    back_data: json = {}
    back_data['username'] = "Jasmine"
    back_data['uuid'] = userDB.get_user_by_username("Jasmine").uuid
    back_data['type'] = 101
    back_data['dataList'] = dataList
    back_data['createTime'] = int(time.time())
    logging.info(f'back_data: {back_data}')
    return back_data

@app.route('/api/avatar/<user_name>')
def get_user_avatar(user_name: str):
    imgFilePrefix = Path(Path(__file__).parent.absolute() / 'assets/avatar')
    jpgImgFile = Path(imgFilePrefix / f'{user_name}.jpg')
    svgImgFile = Path(imgFilePrefix / f'{user_name}.svg')
    if jpgImgFile.exists():
        img = Image.open(jpgImgFile)
        img_byte_arr = BytesIO()
        img.save(img_byte_arr, format='JPEG')
        img_byte_arr.seek(0)
        # 发送图像数据
        return send_file(img_byte_arr, mimetype='image/jpeg')
    elif svgImgFile.exists():
        with open(svgImgFile, 'r') as f:
            svg = f.read()
        return Response(svg, mimetype='image/svg+xml')
    else:
        return make_response('', 404)

@app.route('/api/tts/<key>.mp3', methods = ['GET'])
def tts_audio(key: str):
    mp3FilePrefix = Path(Path(__file__).parent.absolute() / 'assets/tts')
    mp3File = Path(mp3FilePrefix / f'{key}.mp3')
    if not mp3File.exists():
        return make_response('', 404)
    return send_file(mp3File, 'audio/mpeg')

@app.route('/api/contact-us')
def contact_us():
    '''
    联系我们
    '''
    imgFilePrefix = Path(Path(__file__).parent.absolute() / 'assets')
    jpgImgFile = Path(imgFilePrefix / 'contact-us.jpg')
    img = Image.open(jpgImgFile)
    img_byte_arr = BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr.seek(0)
    return send_file(img_byte_arr, mimetype='image/jpeg')

# @app.route('/api/user/signup', methods = ['POST'])
# def signup():
#     '''
#     用户注册
#     '''
#     if request.method != 'POST':
#         return make_response(jsonify({"errcode":50001,"errmsg":"Please use POST method"}), 500)
#     try:
#         data: dict = request.get_json()
#         username: str = data.get('username')
#         password: str = data.get('password')
#     except:
#         return make_response(jsonify({"errcode":50002,"errmsg":"JSON data required"}), 500)
#     if username == None or password == None:
#         return make_response('Please provide username and password', 500)
#     user: User = userDB.get_user_by_username(username)
#     if user != None:
#         return make_response(jsonify({"errcode":50005,"errmsg":"User already exists"}), 500)
#     r: dict = userDB.create_user_by_username(user_name=username, password=password)
#     if r == {}:
#         return make_response(jsonify({"errcode": 50006,"errmsg": 'User create failed'}), 500)
#     r.update(get_openai_apikey())
#     return make_response(jsonify(r), 200)

@app.route('/api/user/signup_with_promo', methods = ['POST'])
def signup_with_promo():
    '''
    用户用邀请码注册
    '''
    if request.method != 'POST':
        return make_response(jsonify({"errcode":50001,"errmsg":"Please use POST method"}), 500)
    try:
        data: dict = request.get_json()
        username: str = data.get('username')
        password: str = data.get('password')
        promo: str = data.get('promo')
    except:
        return make_response(jsonify({"errcode":50002,"errmsg":"JSON data required"}), 500)
    if username == None or password == None or promo == None:
        return make_response('Please provide username, password and promo code.', 500)
    if promo == '':
        return make_response('Please provide promo code.', 500)
    user: User = userDB.get_user_by_username(username)
    if user != None:
        return make_response(jsonify({"errcode":50005,"errmsg":"User already exists"}), 500)
    r: dict = userDB.create_user_by_username(user_name=username, password=password, promo=promo)
    if r == {}:
        return make_response(jsonify({"errcode": 50006,"errmsg": 'User create failed'}), 500)
    r.update(get_openai_apikey())
    return make_response(jsonify(r), 200)

@app.route('/api/user/signin', methods = ['POST'])
def signin():
    '''
    用户登录
    '''
    if request.method != 'POST':
        return make_response(jsonify({"errcode":50001,"errmsg":"Please use POST method"}), 500)
    try:
        data: dict = request.get_json()
        username: str = data.get('username')
        password: str = data.get('password')
    except:
        return make_response(jsonify({"errcode":50002,"errmsg":"JSON data required"}), 500)
    if username == None or password == None:
        return make_response(jsonify({"errcode":50003,"errmsg":"Please provide username and password"}), 500)
    r: dict = userDB.check_password(username, password)
    if r == {}:
        return make_response(jsonify({"errcode":50004,"errmsg":"Username Or Password is incorrect"}), 500)
    ip = request.headers.get('X-Forwarded-For')
    if ip:
        ip = ip.split(',')[0]
    else:
        ip = request.headers.get('X-Real-IP')
    if not ip:
        ip = request.remote_addr
    if ip:
        userDB.write_user_ip(username, ip)
    r.update(get_openai_apikey())
    r['errcode'] = 0
    r['errmsg'] = 'Success'
    response: Response = make_response(jsonify(r), 200)
    response.headers['Cache-Control'] = 'no-cache'
    return make_response(jsonify(r), 200)

@app.route('/api/openai/<path:path>', methods=['POST'])
def openai_proxy(path):
    '''
    代理到OpenAI的请求，并将聊天记录存入数据库
    '''
    api_url = f'https://api.openai.com/{path}'
    headers = {key: value for (key, value) in request.headers if key != 'Host'}
    data = request.get_data()
    params = request.args
    username = request.json['user']
    messages = request.json['messages']
    # print("use tokens: " + str(num_tokens_from_messages(messages)))
    # data_json = json.dumps(data.decode('utf-8'))
    
    # 检查消息是否为空
    last_message: dict  = messages[-1]
    if last_message['content'] == '':
        return make_response(jsonify({"errcode":50007,"errmsg":"Message is empty"}), 500)
    
    # TODO 检查消息的类型是否是查询单词，是的话记录到数据库，进入用户生词本。一种方法是检查message，另一种方法是在按钮上再发起一次请求，走另外接口。
    #  携带上文在对话中
    if "[FREECHAT]" in username:
        orig_username = username
        username = orig_username.split('[FREECHAT]')[1]
        conversation_id = orig_username.split('[FREECHAT]')[0]
        # 从数据库中取出此用户最近的20条记录，按顺序拼接到messages前面
        myuuid: str = userDB.get_user_by_username(username).uuid
        data_json = json.loads(data.decode('utf-8'))
        try:
            l: list = crdb.get_chat_record(user_id=myuuid, last_chat_record_id=0, limit=20, conversation_id=int(conversation_id))
        except Exception as e:
            l: list = []
            print(e)
        for cr in l:
            data_json['messages'][-1]['content'] = cr.msgContent + '\n' + data_json['messages'][-1]['content']
        data = json.dumps(data_json).encode('utf-8')

        
        # 记录用户使用的token数量到数据库
        # 优化token用量
        # summary可能不需要存库和在客户端展示
    else:
        conversation_id = 0

    # 开发环境需要走本地代理服务器才能访问到openai API
    if os.environ.get('DEBUG_MODE') != None:
        response = requests.post(api_url, headers=headers, data=data, params=params, stream=True, proxies=PROXIES)
    else:
        response = requests.post(api_url, headers=headers, data=data, params=params, stream=True)
    
    # 队列是线程安全的，所以利用它拼接流式的聊天记录
    completion_text_queue = Queue()
    
    def generate():
        # chunk可能包含多个用换行分割的json。然后再用'data:'分割
        buffer = b''
        for chunk in response.iter_content(chunk_size=1024):
            buffer += chunk
            while b'\n' in buffer:
                line, buffer = buffer.split(b'\n', 1)
                if b'data:' in line:
                    data = line.decode('utf-8').split('data:')[1].strip()
                    if data == '[DONE]':
                        completion_text_queue.put('[DONE]')
                        break
                    j = json.loads(data)
                    delta = j.get('choices')[0].get('delta') if j.get('choices') else None
                    if delta is not None and delta.get('content') is not None:
                        completion_text_queue.put(delta.get('content'))
                        # print(delta.get('content'))
                    elif delta is not None and delta.get('finish_reason') is not None and delta.get('finish_reason') == 'stop':
                        logging.debug('finish_reason: stop')
                        completion_text_queue.put("[DONE]")
            yield chunk

    rsp = Response(generate(), headers=dict(response.headers))

    def fn_thread(completion_text_queue: Queue, username: str):
        completion_text: str = ''
        while True:
            c = completion_text_queue.get()
            if c == '[DONE]':
                break
            else:
                completion_text += c
        myuuid: str = userDB.get_user_by_username(username).uuid
        cr = ChatRecord(msgFrom=userDB.get_user_by_username('Jasmine').uuid, msgTo=myuuid, msgCreateTime=int(time.time()), msgContent=completion_text, msgType=1, conversation_id=conversation_id)
        crdb.insert_chat_record(cr)

    
    thread = threading.Thread(target=fn_thread, args=(completion_text_queue, username))
    thread.start()
    return rsp

def num_tokens_from_messages(messages, model="gpt-3.5-turbo-0301"):
  """Returns the number of tokens used by a list of messages."""
  try:
      encoding = tiktoken.encoding_for_model(model)
  except KeyError:
      encoding = tiktoken.get_encoding("cl100k_base")
  if model == "gpt-3.5-turbo-0301":  # note: future models may deviate from this
      num_tokens = 0
      for message in messages:
          num_tokens += 4  # every message follows <im_start>{role/name}\n{content}<im_end>\n
          for key, value in message.items():
              num_tokens += len(encoding.encode(value))
              if key == "name":  # if there's a name, the role is omitted
                  num_tokens += -1  # role is always required and always 1 token
      num_tokens += 2  # every reply is primed with <im_start>assistant
      return num_tokens
  else:
      raise NotImplementedError(f"""num_tokens_from_messages() is not presently implemented for model {model}.
  See https://github.com/openai/openai-python/blob/main/chatml.md for information on how messages are converted to tokens.""")

def get_openai_apikey() -> dict:
    '''
    用户登录成功后，返回openai的API key给客户端
    '''
    if os.environ.get('OPENAI_API_KEY') == None:
        return {}
    else:
        return {
            "apiKey": encrypt(os.environ['OPENAI_API_KEY']),
            "baseUrl": OPENAI_PROXY_BASEURL['dev'] if os.environ.get('DEBUG_MODE') != None else OPENAI_PROXY_BASEURL['prod']
            }

def encrypt(text):
    key = '0123456789abcdef' # 密钥，必须为16、24或32字节
    cipher = AES.new(key.encode(), AES.MODE_ECB)
    text = text.encode('utf-8')
    # 补齐16字节的整数倍
    text += b" " * (16 - len(text) % 16)
    ciphertext = cipher.encrypt(text)
    # 转为 base64 编码
    return base64.b64encode(ciphertext).decode()

@app.route('/api/user/ch', methods = ['POST'])
def chat_history():
    if not request.headers.get('X-access-token'):
        return make_response('access-token missing', 500)
    data_json: dict = request.get_json()
    username: str = data_json.get('username')
    if username is None or username == '':
        return make_response('username missing', 500)
    u: User = userDB.get_user_by_username(username)
    if u is None:
        return make_response('user not exist', 500)
    if u.access_token != request.headers['X-access-token']:
        return make_response('access-token wrong', 500)
    if u.access_token_expire_at < int(time.time()):
        return make_response(jsonify({"errcode":50007,"errmsg":"access_token expired"}), 401)
    try:
        last_id: int = data_json.get('last_id', 0)
        if last_id < 0:
            return make_response('last_id error', 500)
    except Exception as e:
        return make_response('last_id missing', 500)
    
    conversation_id = data_json.get('conversation_id')
    if conversation_id is None or conversation_id == '':
        conversation_id = 0

    r: list = []
    for cr in crdb.get_chat_record(u.uuid, last_id, limit=20, conversation_id=int(conversation_id)):
        r.append({
            'pk_chat_record': cr.pk_chat_record,
            'msgFrom': userDB.get_user_by_uuid(cr.msgFrom).user_name,
            'msgFromUUID': cr.msgFrom,
            # 'msgTo': cr.msgTo,
            'msgCreateTime': cr.msgCreateTime,
            'msgContent': cr.msgContent,
            # 'msgStatus': cr.msgStatus,
            # 'msgType': cr.msgType,
            # 'msgSource': cr.msgSource,
            # 'msgDest': cr.msgDest
            'conversation_id': cr.conversation_id
        })
    return make_response(jsonify(r), 200)

@app.route('/api/user/cs', methods = ['GET','POST','PUT','DELETE'])
def conversation_crud():
    if not request.headers.get('X-access-token'):
        return make_response('access-token missing', 500)
    if request.method == 'POST' or request.method == 'PUT':
        data: dict = request.get_json()
        username: str = data.get('username')
    else:
        username: str = request.args.get('username')
    if username is None or username == '':
        return make_response('username missing', 500)
    u: User = userDB.get_user_by_username(username)
    if u is None:
        return make_response('user not exist', 500)
    if u.access_token != request.headers['X-access-token']:
        return make_response('access-token wrong', 500)
    if u.access_token_expire_at < int(time.time()):
        return make_response(jsonify({"errcode":50007,"errmsg":"access_token expired"}), 401)

    conversationDB = ConversationDB()
    if request.method == 'GET':
        back_data: list = []
        try:
            r: list = conversationDB.get_conversation_list(u.uuid)
            for i in r:
                j: Conversation = i
                back_data.append({
                    'pk_conversation': j.pk_conversation,
                    'conversation_name': j.conversation_name,
                    # 'conversation_create_time': j.conversation_create_time
                })
        except Exception as e:
            print(e)
            conversationDB.close()
            return make_response('get conversation list failed', 500)
        
        rsp = make_response(jsonify(back_data), 200)
    elif request.method == 'POST':
        c = Conversation(uuid=u.uuid, conversation_create_time=int(time.time()))
        conversation_id = conversationDB.create_conversation(c)
        conversationDB.close()
        rsp = make_response(jsonify({"pk_conversation": int(conversation_id)}), 200)
    elif request.method == 'PUT':
        conversation_id: int = data.get('conversation_id')
        conversation_name: str = data.get('conversation_name')
        if conversation_id is None or conversation_id == '':
            conversationDB.close()
            return make_response('conversation_id missing', 500)
        if conversation_name is None or conversation_name == '':
            conversationDB.close()
            return make_response('conversation_name missing', 500)
        conversationDB.update_conversation_name(conversation_id, conversation_name)
        rsp = make_response(jsonify({"pk_conversation": int(conversation_id)}), 200)
    elif request.method == 'DELETE':
        conversation_id: int = request.args.get('conversation_id')
        if conversation_id is None or conversation_id == '':
            conversationDB.close()
            return make_response('conversation_id missing', 500)
        r: Conversation = conversationDB.get_a_conversation(conversation_id)
        if r is None or r.uuid != u.uuid:
            conversationDB.close()
            return make_response('conversation not exist', 500)
        if conversationDB.delete_conversation(conversation_id):
            rsp = make_response(jsonify({"pk_conversation": int(conversation_id)}), 200)
            conversationDB.close()
        else:
            rsp = make_response('delete conversation failed', 500)
    else:
        rsp = make_response('method not allowed', 500)

    conversationDB.close()
    return rsp

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=9000)
