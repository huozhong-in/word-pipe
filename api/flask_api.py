import json
import time
import hashlib
from pathlib import Path
# import ahocorasick
# import werkzeug
import marisa_trie
from flask import Flask, Response, jsonify, make_response, request, render_template, url_for
from flask_cors import CORS, cross_origin
from flask_sse import sse
from stardict import *

app = Flask(__name__)
cors = CORS(app, resource={
    r"/*":{
        "origins":"*"
    }
})
app.config["REDIS_URL"] = "redis://localhost"
app.register_blueprint(sse, url_prefix='/stream')


## load json
vocab_file = Path(Path(__file__).parent.absolute() / 'db/vocab.json')
vocab = set()
with vocab_file.open() as f:
    data: dict = json.load(f)
# print(data.keys())
vocab = set(data['SENIOR']).union(set(data['IELTS']))
print(f'vocab.json including {len(vocab)} words.')

## marisa-trie for prefix search
trie = marisa_trie.Trie(vocab, order=marisa_trie.LABEL_ORDER)

## pyahocorasick for wild-search
# A = ahocorasick.Automaton()
# for idx, word in enumerate(vocab):
#     A.add_word(word, (idx, word))
# A.make_automaton()

def generate_time_based_client_id(prefix='client_'):
    current_time = time.time()
    # 使用当前时间创建一个唯一的ClientID
    raw_client_id = f"{prefix}{current_time}".encode('utf-8')
    # 使用hashlib生成一个唯一的ClientID
    hashed_client_id = hashlib.sha256(raw_client_id).hexdigest()
    return hashed_client_id

@app.route('/test', methods = ['GET'])
def test() -> Response:
    if request.method == 'GET':
        y = request.args['k']
        x: dict = {"output": y}
        # r: json = json.loads('{"output": 1}')
        # filename: str = werkzeug.utils.secure_filename("xx")
        # x['filename'] = filename
        response = jsonify(x)
        # response.headers.add("Access-Control-Allow-Origin", "*")
        # response.headers.add("Access-Control-Allow-Credentials", "true")
        # response.headers.add("Access-Control-Allow-Headers", "*")
        # response.headers.add("Access-Control-Allow-Methods", "*")
        return jsonify(x)

@app.route('/s', methods = ['GET'])
def search() -> Response:    
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
    print(f"Processed in {toc - tic:0.4f} seconds")
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
    print(f"Processed in {toc - tic:0.4f} seconds")
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
    print(f"Processed in {toc - tic:0.4f} seconds")
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

@app.route('/sse-test')
def sse_test():
    sse_url = url_for('sse.stream', channel='users.social', _external=False)
    return render_template('sse-test.html', sse_url=sse_url)

@app.route('/pub-test', methods = ['POST'])
def publish_test():
    if request.method != 'POST':
        return make_response('Please use POST method', 500)
    try:
        data = request.get_json()
        message = data.get('message')
    except:
        return make_response('JSON data required', 500)
    
    # if not request.args.get('user'):
    #     return make_response(jsonify({}), 500)
    # userId: str = data.get('user')

    id: str = generate_time_based_client_id()
    sse.publish(id=id, data={"user": "Jarvis", "message": message}, type='broadcasting', channel="users.social")
    return jsonify({"success": True, "message": f"Server response:{message}"})


if __name__ == '__main__':
    app.run(debug=True, host='127.0.0.1', port=5000)
