import requests
import hashlib
import json
import sys
import time
from collections import OrderedDict
import http.client as http_client

# Enable low-level debug logging
http_client.HTTPConnection.debuglevel = 1

# Configuration
MAC = "00:1A:79:CB:9A:23"
MAC_LOWER = MAC.lower()
SERIAL = "HD0001234567" # Example Serial
STB_TYPE = "MAG322"
IMAGE_VERSION = "218"
VER = "2.20.05"
NUM_BANKS = "2"
TIMEZONE = "Europe/London"

# Calculate Device ID
def get_device_id(mac, model):
    s = mac + model
    return hashlib.sha256(s.encode('utf-8')).hexdigest()

# Use UPPERCASE MAC for Device ID hash as per successful PS test
DEVICE_ID = get_device_id(MAC, STB_TYPE) 
DEVICE_ID2 = DEVICE_ID # Revert to same ID

print(f"MAC: {MAC}")
print(f"Device ID: {DEVICE_ID}")
print(f"Device ID 2: {DEVICE_ID2}")

# Session Setup
session = requests.Session()
# Clear default headers to avoid interference
session.headers.clear()

def get_headers(cookie_value, token=None):
    # Match the successful curl headers EXACTLY
    h = OrderedDict()
    h['User-Agent'] = "Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)"
    h['X-User-Agent'] = "Model: MAG322; Link: WiFi"
    h['Referer'] = "http://mag.4k365.xyz/stalker_portal/c/"
    h['Accept'] = "*/*"
    h['Connection'] = "close" # Try closing connection to mimic separate curl calls
    h['Accept-Encoding'] = None # Remove Accept-Encoding
    h['Cookie'] = cookie_value
    if token:
        h['Authorization'] = f"Bearer {token}"
    return h

def construct_cookie(token=None):
    # Try UPPERCASE MAC in Cookie as per successful PS test
    c = f"mac={MAC}; stb_lang=en; timezone={TIMEZONE}"
    if token:
        c += f"; token={token}"
    return c

# 1. HANDSHAKE
print("\n1. Performing Handshake...")
handshake_url = "http://mag.4k365.xyz/portal.php"
handshake_params = {
    'type': 'stb',
    'action': 'handshake',
    'token': '',
    'prehash': '',
    'device_id': DEVICE_ID,
    'device_id2': DEVICE_ID2,
    'mac': MAC, # Try UPPERCASE MAC in URL
    'JsHttpRequest': '1-xml'
}

# Manually set cookie for this request
headers = get_headers(construct_cookie())

try:
    # We use a prepared request to ensure we can inspect/control things if needed, 
    # but session.get is usually fine.
    # Note: requests might re-order headers. 
    
    resp = session.get(handshake_url, params=handshake_params, headers=headers, timeout=10)
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text}")
    
    if resp.status_code != 200:
        print("Handshake failed.")
        sys.exit(1)
        
    data = resp.json()
    token = data.get('js', {}).get('token')
    
    if not token:
        print("No token found in handshake.")
        sys.exit(1)
        
    print(f"Token: {token}")
    
    # Check for prehash/random
    random_seed = data.get('js', {}).get('random')
    prehash = data.get('js', {}).get('prehash')
    if random_seed:
        print(f"Found random: {random_seed}")
    if prehash:
        print(f"Found prehash: {prehash}")

except Exception as e:
    print(f"Handshake Error: {e}")
    sys.exit(1)

print("Sleeping for 2 seconds to mimic real device...")
time.sleep(2)

# 2. GET PROFILE
print("\n2. Calling get_profile (Persistent Connection)...")

profile_params = {
    'type': 'stb',
    'action': 'get_profile',
    'token': token, # Added token to URL
    'mac': MAC, # UPPERCASE
    'device_id': DEVICE_ID,
    'device_id2': DEVICE_ID2,
    'JsHttpRequest': '1-xml'
}
# Removed sn, stb_type, image_version, ver, num_banks

# Update Cookie with Token AND Add Authorization Header
headers = get_headers(construct_cookie(token), token=token)

try:
    resp = session.get(handshake_url, params=profile_params, headers=headers, timeout=10)
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text}")

except Exception as e:
    print(f"Get Profile Error: {e}")

# 3. CREATE LINK
print("\n3. Calling create_link (Persistent Connection)...")
stream_id = "534"
cmd = f"ffmpeg http://mag.4k365.xyz:80/play/live.php?mac={MAC}&stream={stream_id}&extension=ts"

create_link_params = {
    'type': 'itv',
    'action': 'create_link',
    'mac': MAC, # UPPERCASE
    'cmd': cmd,
    'JsHttpRequest': '1-xml',
    'device_id': DEVICE_ID,
    'device_id2': DEVICE_ID2,
    'device_mac': MAC, # UPPERCASE
    'auth_second_step': '0'
}

headers = get_headers(construct_cookie(token), token=token)

try:
    resp = session.get(handshake_url, params=create_link_params, headers=headers, timeout=10)
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text}")
    
    data = resp.json()
    play_url = data.get('js', {}).get('cmd')
    if play_url:
        print(f"Play URL: {play_url}")
    else:
        print("No play URL found.")

except Exception as e:
    print(f"Create Link Error: {e}")