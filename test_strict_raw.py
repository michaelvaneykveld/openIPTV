import http.client
import json
import urllib.parse
import time
import hashlib

MAC = "00:1A:79:CB:9A:23"
HOST = "mag.4k365.xyz"
PORT = 80
STB_TYPE = "MAG322"

def get_device_id(mac, model):
    s = mac + model
    return hashlib.sha256(s.encode('utf-8')).hexdigest()

DEVICE_ID = get_device_id(MAC, STB_TYPE)
DEVICE_ID2 = DEVICE_ID

print(f"MAC: {MAC}")
print(f"Device ID: {DEVICE_ID}")

conn = http.client.HTTPConnection(HOST, PORT)
conn.set_debuglevel(1)

# 1. Handshake
# ...existing code...
# 1. Handshake
print("\n1. Handshake...")
params = urllib.parse.urlencode({
    'type': 'stb',
    'action': 'handshake',
    'token': '',
    'prehash': '',
    'device_id': DEVICE_ID,
    'device_id2': DEVICE_ID2,
    'mac': MAC,
    'JsHttpRequest': '1-xml'
})
url = f"/portal.php?{params}"

# Headers as a dict (insertion ordered in Python 3.7+)
# Matching curl order: Host (auto), Accept, User-Agent, X-User-Agent, Referer, Cookie
headers = {
    'Accept': "*/*",
    'User-Agent': "Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)",
    'X-User-Agent': "Model: MAG322; Link: WiFi",
    'Referer': "http://mag.4k365.xyz/stalker_portal/c/",
    'Cookie': f"mac={MAC}; stb_lang=en; timezone=Europe/London"
}

try:
    # Use low-level putrequest to skip Accept-Encoding
    conn.putrequest("GET", url, skip_host=False, skip_accept_encoding=True)
    for k, v in headers.items():
        conn.putheader(k, v)
    conn.endheaders()
    
    resp = conn.getresponse()
    print(f"Status: {resp.status}")
    body = resp.read().decode()
    print(f"Body: {body}")
    
    if resp.status != 200:
        print("Handshake failed")
        exit(1)

    data = json.loads(body)
    token = data['js']['token']
    print(f"Token: {token}")

except Exception as e:
    print(f"Handshake Error: {e}")
    exit(1)

# CLOSE CONNECTION TO MIMIC CURL
conn.close()
print("Connection closed. Sleeping...")
time.sleep(2)

# 2. Get Profile
print("\n2. Get Profile...")
# RE-OPEN CONNECTION
conn = http.client.HTTPConnection(HOST, PORT)
conn.set_debuglevel(1)

params = urllib.parse.urlencode({
    'type': 'stb',
    'action': 'get_profile',
    'token': token,
    'mac': MAC,
    'device_id': DEVICE_ID,
    'device_id2': DEVICE_ID2,
    'JsHttpRequest': '1-xml'
})
url = f"/portal.php?{params}"

# Headers matching curl: Host (auto), Accept, User-Agent, X-User-Agent, Referer, Cookie, Authorization
headers = {
    'Accept': "*/*",
    'User-Agent': "Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)",
    'X-User-Agent': "Model: MAG322; Link: WiFi",
    'Referer': "http://mag.4k365.xyz/stalker_portal/c/",
    'Cookie': f"mac={MAC}; stb_lang=en; timezone=Europe/London; token={token}",
    'Authorization': f"Bearer {token}"
}

try:
    conn.request("GET", url, headers=headers)
    resp = conn.getresponse()
    print(f"Status: {resp.status}")
    body = resp.read().decode()
    print(f"Body: {body}")

except Exception as e:
    print(f"Get Profile Error: {e}")

conn.close()