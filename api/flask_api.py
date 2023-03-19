import json
import time
import hashlib
from pathlib import Path
# import ahocorasick
# import werkzeug
import marisa_trie
from flask import Flask, Response, jsonify, make_response, request, render_template, url_for
from flask_cors import CORS #, cross_origin
from flask_sse import sse
from stardict import *
from config import *

app = Flask(__name__)
cors = CORS(app, resource={
    r"/*":{
        "origins":"*"
    }
})
app.config["REDIS_URL"] = REDIS_URL
app.register_blueprint(sse, url_prefix=SSE_SERVER_PATH)

## load json
vocab_file = Path(Path(__file__).parent.absolute() / 'db/vocab.json')
vocab = set()
with vocab_file.open() as f:
    data: dict = json.load(f)
# print(data.keys())
vocab = set(data['JUNIOR']).union(set(data['SENIOR'])).union(set(data['IELTS']))
print(f'JUNIOR + SENIOR + IELTS, total: {len(vocab)} words.')

## marisa-trie for prefix search
trie = marisa_trie.Trie(vocab, order=marisa_trie.LABEL_ORDER)

## pyahocorasick for wild-search
# A = ahocorasick.Automaton()
# for idx, word in enumerate(vocab):
#     A.add_word(word, (idx, word))
# A.make_automaton()

# parse wordroot.txt
wordroot_file = Path(Path(__file__).parent.absolute() / 'db/wordroot.txt')
with wordroot_file.open() as f:
    wordroot= json.load(f)
print(f"wordroot.txt including {len(wordroot.keys())} roots.")
word2root = {}
for key, value in wordroot.items():
    if 'example' in value:
        for word in value['example']:
            if word in word2root:
                word2root[word].append(key)
            else:
                word2root[word] = [key]



def generate_time_based_client_id(prefix='client_'):
    current_time = time.time()
    # 使用当前时间创建一个唯一的ClientID
    raw_client_id = f"{prefix}{current_time}".encode('utf-8')
    # 使用hashlib生成一个唯一的ClientID
    hashed_client_id = hashlib.sha256(raw_client_id).hexdigest()
    return hashed_client_id

@app.route('/test', methods = ['GET'])
def test() -> Response:
    # response.headers.add("Access-Control-Allow-Origin", "*")
    # response.headers.add("Access-Control-Allow-Credentials", "true")
    # response.headers.add("Access-Control-Allow-Headers", "*")
    # response.headers.add("Access-Control-Allow-Methods", "*")
    
    # import re
    # input_str = 'This is a long-time example with hyphenated-words, including some non-alpha character...'
    # exp = r'\b[a-zA-Z]+(?:-[a-zA-Z]+)*\b'
    # matches = re.finditer(exp, input_str)

    # for match in matches:
    #     word = match.group(0)
    #     start_index = match.start()
    #     end_index = match.end()
    #     print(f'Found "{word}" at position {start_index}-{end_index}')
    # 创建新的数据结构
    
    return make_response(jsonify(get_root_by_word('tactful')), 200)

@app.route('/s', methods = ['GET'])
def search() -> Response:
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
    print(f"search() result: {x}")

    toc = time.perf_counter()
    print(f"[Processed in {toc - tic:0.4f} seconds]")
    return make_response(jsonify(x), 200)

# @app.route('/ws', methods = ['GET'])
# def wild_search():
#     global A
#     pattern = '*count*'
#     results = A.keys("bl??k", "?", ahocorasick.MATCH_AT_LEAST_PREFIX)
#     # print(list(results))
#     return make_response(jsonify({"a":list(results)}), 200)

@app.route('/p', methods = ['GET'])
def point_search():
    '''
    查询单词的意思：

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

@app.route('/m', methods = ['GET'])
def match_words():
    if not request.args.get('k'):
        return make_response(jsonify({}), 200)
    k: str = request.args.get('k')
    if k == '':
        return make_response(jsonify({}), 200)
    tic = time.perf_counter()
    sd = StarDict(Path(Path(__file__).parent.absolute() / 'db/stardict.db'), False)
    r: list = sd.match(word=k, limit=10, strip=True)
    sd.close()
    toc = time.perf_counter()
    print(f"match_words() word: {k}")
    print(f"[Processed in {toc - tic:0.4f} seconds]")
    return make_response(jsonify(r), 200)

@app.route('/favicon.ico')
def favicon():
    r = make_response("data:;base64,iVBORw0KGgo=", 200)
    r.mimetype = "image/x-icon"
    return r

@app.route('/user/reconnect')
def user_reconnect():
    if not request.args.get('userId') or not request.args.get('lastEventId'):
        return make_response(jsonify({}), 200)
    userId: str = request.args.get('userId')
    lastEventId: str = request.args.get('lastEventId')
    if userId == '' or lastEventId=='':
        return make_response(jsonify({}), 200)
    print("/user/reconnect")
    return 1

@app.route('/sse-test.html')
def sse_test():
    sse_url = url_for('sse.stream', channel=SSE_MSG_CHANNEL, _external=False)
    return render_template('sse-test.html', sse_url=sse_url)

@app.route('/pub-test', methods = ['POST'])
def publish_test():
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        data: dict = request.get_json()
        message: str = data.get('message')
    except:
        return make_response('JSON data required', 500)
    
    id: str = generate_time_based_client_id()
    back_data: dict = dict()
    back_data['user'] = "Jarvis"
    back_data['type'] = "get_word_root"
    back_data['data'] = [message]
    sse.publish(id=id, data=back_data, type=SSE_MSG_TYPE, channel=SSE_MSG_CHANNEL)
    return jsonify({"success": True, "message": f"Server response:{message}"})

@app.route('/chat', methods = ['POST'])
def chat():
    '''
    通过对话的方式，将用户查询的字符串拆分成单个单词，分别查找词根词缀。

    - 有可能命中多个词根词缀
    - 单词是动词的话只有原型，需要先查lemma得到原型
    - 给出相同词根的其他单词，按频次倒序，只出现在选定范围（四六雅思）内的词
    '''
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        data: dict = request.get_json()
        user: str = data.get('user')
        message: str = data.get('message')
    except:
        return make_response('JSON data required', 500)
    tic = time.perf_counter()
    if message.startswith('/word '):
        message = message.split('/word ')[1]
        r: list = list()
        import re
        # message= 'This is a long-time example with hyphenated-words, including some non-alpha character...'
        exp = r'\b[a-zA-Z]+(?:-[a-zA-Z]+)*\b'
        matches = re.finditer(exp, message)
        for match in matches:
            word = match.group(0)
            t: list = get_root_by_word(word)
            if len(t) != 0:
                r.extend(t)
                # for t1 in t:
                #     r.append(wordroot[t1])

        back_data: dict = dict()
        back_data['user'] = "Jarvis"
        back_data['type'] = "get_word_root"
        back_data['data'] = r
     
        id: str = generate_time_based_client_id(prefix=user)
        print("chat() pushlish id:", id)
        sse.publish(id=id, data=back_data, type=SSE_MSG_TYPE, channel=SSE_MSG_CHANNEL)
    elif message.startswith('/help '):
        pass

    toc = time.perf_counter()
    print(f"[Processed in {toc - tic:0.4f} seconds]")

    return make_response(list(), 200)

def get_root_by_word(word:str) -> list:
    # TODO example里单词可能有大写或带空格的情况，如"-ite2"

    # print(word2root['tactful']) # 输出 ["-ful1","tact, tang, ting, tig"]
    return list(word2root.get(word)) if word2root.get(word) != None else list()


if __name__ == '__main__':
    app.run(debug=True, host='127.0.0.1', port=5000)
