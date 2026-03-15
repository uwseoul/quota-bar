import urllib.request
import json

api_key = input("Enter your API Key: ")
platform = "https://api.z.ai"
url = f"{platform}/api/monitor/usage/quota/limit"
headers = {"Authorization": f"Bearer {api_key}"}

req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print(f"Status: {response.getcode()}")
        print(json.dumps(json.loads(response.read()), indent=2))
except Exception as e:
    print(f"Error: {e}")
