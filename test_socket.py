import socket
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

def send_raw_request(path, headers):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((HOST, PORT))
    
    # Construct request exactly like curl
    req = f"GET {path} HTTP/1.1\r\n"
    req += f"Host: {HOST}\r\n"
    for k, v in headers.items():
        req += f"{k}: {v}\r\n"
    req += "\r\n"
    
    print(f"--- Sending ---\n{req}")
    s.sendall(req.encode())
    
    resp = b""
    # Read loop (simplified, assumes server closes or we get enough)
    # Since we don't send Connection: keep-alive (or server ignores it), 
    # we might rely on content-length or timeout.
    # For this test, we just read a bit.
    
    s.settimeout(5)
    try:
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            resp += chunk
            if b"\r\n0\r\n\r\n" in chunk: # Chunked encoding end
                break
            if b"}" in chunk and b"{" in chunk: # JSON end (hacky)
                pass
    except socket.timeout:
        pass
        
    s.close()
    return resp.decode(errors='ignore')

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
path = f"/portal.php?{params}"

headers = {
    'Accept': '*/*',
    'User-Agent': 'Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)',
    'X-User-Agent': 'Model: MAG322; Link: WiFi',
    'Referer': 'http://mag.4k365.xyz/stalker_portal/c/',
    'Cookie': f'mac={MAC}; stb_lang=en; timezone=Europe/London'
}

resp = send_raw_request(path, headers)
print(f"Response:\n{resp}")

if "200 OK" not in resp:
    print("Handshake failed")
    exit(1)

# Extract token (hacky parsing)
try:
    json_str = resp.split("\r\n\r\n")[1]
    # Handle chunked encoding artifacts if present (hex size lines)
    # Simple regex or just find the JSON
    start = json_str.find('{')
    end = json_str.rfind('}') + 1
    json_str = json_str[start:end]
    
    data = json.loads(json_str)
    token = data['js']['token']
    print(f"Token: {token}")
except Exception as e:
    print(f"Token parsing error: {e}")
    exit(1)

print("Sleeping for 10 seconds (testing timing hypothesis)...")
time.sleep(10)

# 2. Get Profile
print("\n2. Get Profile...")
params = urllib.parse.urlencode({
    'type': 'stb',
    'action': 'get_profile',
    'token': token,
    'mac': MAC,
    'device_id': DEVICE_ID,
    'device_id2': DEVICE_ID2,
    'JsHttpRequest': '1-xml'
})
path = f"/portal.php?{params}"

headers = {
    'Accept': '*/*',
    'User-Agent': 'Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)',
    'X-User-Agent': 'Model: MAG322; Link: WiFi',
    'Referer': 'http://mag.4k365.xyz/stalker_portal/c/',
    'Cookie': f'mac={MAC}; stb_lang=en; timezone=Europe/London; token={token}',
    'Authorization': f'Bearer {token}'
}

resp = send_raw_request(path, headers)
print(f"Response:\n{resp}")
