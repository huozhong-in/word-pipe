import json
import time
from pathlib import Path
# import ahocorasick
# import werkzeug
import marisa_trie
from flask import Flask, Response, jsonify, make_response, request
from flask_cors import CORS, cross_origin
from stardict import *

app = Flask(__name__)
cors = CORS(app, resource={
    r"/*":{
        "origins":"*"
    }
})
## load json
vocab_file = Path(Path(__file__).parent.absolute() / 'db/vocab.json')
vocab = set()
with vocab_file.open() as f:
    data: dict = json.load(f)
# print(data.keys())
vocab = set(data['SENIOR']).union(set(data['IELTS']))
print('word number:', len(vocab))

## marisa-trie for prefix search
trie = marisa_trie.Trie(vocab, order=marisa_trie.LABEL_ORDER) # todo: 放入中文解释，放入使用频率（倒序）

## pyahocorasick for wild-search
# A = ahocorasick.Automaton()
# for idx, word in enumerate(vocab):
#     A.add_word(word, (idx, word))
# A.make_automaton()


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
    print(x)

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
    print(f"Processed in {toc - tic:0.4f} seconds")
    return make_response(jsonify(r), 200)

@app.route('/favicon.ico')
def favicon():
    r = make_response("data:;base64,iVBORw0KGgo=", 200)
    r.mimetype = "image/x-icon"
    return r

if __name__ == '__main__':
    app.run(debug=True, host='127.0.0.1', port=80)
