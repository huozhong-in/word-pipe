import json
import threading
import time
import hashlib
import random
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
    g)
from flask_sse import sse
from stardict import *
from config import *
from io import BytesIO
from PIL import Image
from user import User,UserDB
from flask_cors import CORS


app = Flask(__name__)
CORS(app)
app.config["REDIS_URL"] = REDIS_URL
@sse.after_request
def add_header(response):
    response.headers['X-Accel-Buffering'] = 'no'
    # response.headers['Cache-Control'] = 'no-cache'
    # response.headers['Connection'] = 'keep-alive'
    response.headers['Content-Type'] = 'text/event-stream'
    return response
app.register_blueprint(sse, url_prefix=SSE_SERVER_PATH, headers={'X-Accel-Buffering': 'no'})
## for SSE nginx configuration https://serverfault.com/questions/801628/for-server-sent-events-sse-what-nginx-proxy-configuration-is-appropriate

## load json
vocab_file = Path(Path(__file__).parent.absolute() / 'db/vocab.json')
vocab = set()
with vocab_file.open() as f:
    data: dict = json.load(f)
print(data.keys())
vocab = set(data['JUNIOR']).union(set(data['SENIOR'])).union(set(data['IELTS'])).union(set(data['TOEFL'])).union(set(data['GRE'])).union(set(data['TOEIC']))
print(f'total: {len(vocab)} words.')

## marisa-trie for prefix search
trie = marisa_trie.Trie(vocab, order=marisa_trie.LABEL_ORDER)

# parse wordroot.txt
wordroot_file = Path(Path(__file__).parent.absolute() / 'db/wordroot.txt')
with wordroot_file.open() as f:
    wordroot= json.load(f)
print(f"wordroot.txt including {len(wordroot.keys())} roots.")
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

@app.teardown_appcontext
def shutdown_session(exception=None):
    # 请求上下文结束时自动释放 session
    # g.session.close()
    userDB.session.close()

@app.before_request
def before_request():
    # 请求开始时将连接和 session 绑定到请求上下文
    g.db = userDB.engine.connect()
    g.session = userDB.session

@app.after_request
def after_request(response):
    # 请求结束时断开连接
    g.db.close()
    return response


def generate_time_based_client_id(prefix='client_'):
    current_time = time.time()
    raw_client_id = f"{prefix}{current_time}".encode('utf-8')
    hashed_client_id = hashlib.sha256(raw_client_id).hexdigest()
    return hashed_client_id

@app.route('/api/test', methods = ['GET'])
def test() -> Response:    
    # import re
    # input_str = 'This is a long-time example with hyphenated-words, including some non-alpha character...'
    # exp = r'\b[a-zA-Z]+(?:-[a-zA-Z]+)*\b'
    # matches = re.finditer(exp, input_str)

    # for match in matches:
    #     word = match.group(0)
    #     start_index = match.start()
    #     end_index = match.end()
    #     print(f'Found "{word}" at position {start_index}-{end_index}')
    random_user_name = f"test{random.randint(0, 1000)}"
    user = userDB.create_user_by_username(user_name=random_user_name, password='test117')
    
    return make_response(jsonify(user.uuid), 200)

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
    
    tic = time.perf_counter()

    global trie    
    r = trie.keys(k)[0:20]
    result = dict()
    result["result"] = list(r)
    x = list()
    x.append(result)
    print(f"prefix_search() result: {x}")

    toc = time.perf_counter()
    print(f"[Processed in {toc - tic:0.4f} seconds]")
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
    
    tic = time.perf_counter()
    sd = StarDict(Path(Path(__file__).parent.absolute() / 'db/stardict.db'), False)
    r: dict = sd.query(k)
    sd.close()
    x = list()
    x.append(r)
    toc = time.perf_counter()
    print(f"point_search() word: {k}")
    print(f"[Processed in {toc - tic:0.4f} seconds]")
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
    print(f"match_words() word: {k}")
    print(f"[Processed in {toc - tic:0.4f} seconds]")
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
    print(f"query_batch() word: {r}")
    print(f"[Processed in {toc - tic:0.4f} seconds]")
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
    sse_url = url_for('sse.stream', channel=SSE_MSG_CHANNEL, _external=False)
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
    back_data['userId'] = "Jarvis"
    back_data['type'] = 1
    r.append(message)
    back_data['dataList'] = r
    sse.publish(id=id, data=back_data, type=SSE_MSG_EVENTTYPE, channel=SSE_MSG_CHANNEL)
    return jsonify({"success": True, "message": f"Server response:{message}"})

@app.route('/api/chat', methods = ['POST'])
def chat():
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
        user: str = data.get('userId')
        message: str = data.get('message')
    except:
        return make_response('JSON data required', 500)
    
    tic = time.perf_counter()
    if message.startswith('/word '):
        
        back_data: json = {}
        back_data = get_root_by_word(message)
        def publish_func1():
            id = generate_time_based_client_id(prefix=user)
            print("chat() publish id:", id)
            time.sleep(1)  # 延迟一秒
            with app.app_context():
                sse.publish(id=id, data=back_data, type=SSE_MSG_EVENTTYPE, channel=SSE_MSG_CHANNEL)

        thread = threading.Thread(target=publish_func1)
        thread.start()

    elif message.startswith('/root '):
        root: str = message.split('/root ')[1]
        back_data: json = {}
        dataList = wordroot[root]['example']
        back_data['userId'] = "Jarvis"
        back_data['type'] = 102
        back_data['dataList'] = [{root: dataList}]
        def publish_func2():
            id = generate_time_based_client_id(prefix=user)
            print("chat() publish id:", id)
            time.sleep(1)  # 延迟一秒
            with app.app_context():
                sse.publish(id=id, data=back_data, type=SSE_MSG_EVENTTYPE, channel=SSE_MSG_CHANNEL)
         
        thread = threading.Thread(target=publish_func2)
        thread.start()

    elif message.startswith('/help '):
        pass

    toc = time.perf_counter()
    print(f"[Processed in {toc - tic:0.4f} seconds]")

    return make_response('', 204)


def get_root_by_word(message: str) -> json:
    '''
    根据单词查找词根词缀

    print(word2root['tactful']) # 输出 ["-ful1","tact, tang, ting, tig"]
    TODO example里单词可能有大写或带空格的情况，如"-ite2"
    '''
    
    message = message.split('/word ')[1]
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
    back_data['userId'] = "Jarvis"
    back_data['type'] = 101
    back_data['dataList'] = dataList
    print(back_data)
    return back_data


@app.route('/api/avatar/Javris')
def get_image():
    # 读取图片数据
    img = Image.open(Path(Path(__file__).parent.absolute() / 'assets/avatar-Jarvis.jpg'))
    img_byte_arr = BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr.seek(0)
    # 发送图像数据
    return send_file(img_byte_arr, mimetype='image/jpeg')

@app.route('/api/user/signup', methods = ['POST'])
def signup():
    '''
    用户注册
    '''
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        data: dict = request.get_json()
        username: str = data.get('username')
        password: str = data.get('password')
    except:
        return make_response('JSON data required', 500)
    if username == None or password == None:
        return make_response('Please provide username and password', 500)
    user: User = userDB.get_user_by_username(username)
    if user != None:
        return make_response('User already exists', 500)
    user = UserDB.create_user_by_username(user_name=username, password=password)
    if user == None:
        return make_response('User create failed', 500)
    return make_response('', 204)

@app.route('/api/user/signin', methods = ['POST'])
def signin():
    '''
    用户登录
    '''
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        data: dict = request.get_json()
        username: str = data.get('username')
        password: str = data.get('password')
    except:
        return make_response('JSON data required', 500)
    if username == None or password == None:
        return make_response('Please provide username and password', 500)
    r: bool = userDB.check_password(username, password)
    if r == False:
        return make_response('Username Or Password is incorrect', 500)
    return make_response('', 204)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=9000)
