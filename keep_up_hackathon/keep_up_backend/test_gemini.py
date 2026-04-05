import requests, json

url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyB1-A41SUWAryBDMBYzi1NV-NEjzg_nfL8"
headers = {"Content-Type": "application/json"}
data = {
    "contents": [{"parts": [{"text": "Give me the latest news on technology today. Output JSON with headline and sourceUrl."}]}],
    "tools": [{"googleSearch": {}}]
}
r = requests.post(url, headers=headers, json=data)
print(json.dumps(r.json(), indent=2))
