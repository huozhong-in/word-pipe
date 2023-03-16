import requests
word = "stationary"
url = f"https://www.dicts.cn/dict/dict/dict!searchhtml3.asp?id={word}"

r = requests.get(url=url, allow_redirects=True)

print(r.content)

