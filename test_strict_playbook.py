import requests
import hashlib
import json
import sys
import time
from collections import OrderedDict
import http.client as http_client

# Enable low-level debug logging to verify exact header order
http_client.HTTPConnection.debuglevel = 1

# --- CONFIGURATION ---
MAC = "00:1A:79:CB:9A:23" # UPPERCASE
STB_TYPE = "MAG322"
TIMEZONE = "Europe/London"
BASE_URL = "http://mag.4k365.xyz/portal.php"

# --- DEVICE ID CALCULATION ---
# Rule: SHA256(MAC_UPPER + "MAG322")
def get_device_id(mac, model):
    s = mac + model
    return hashlib.sha256(s.encode('utf-8')).hexdigest()

DEVICE_ID = get_device_id(MAC, STB_TYPE)
DEVICE_ID2 = DEVICE_ID

print(f"MAC: {MAC}")
print(f"Device ID: {DEVICE_ID}")

# --- SESSION SETUP ---
session = requests.Session()
session.headers.clear() # We will manually construct headers for every request

def get_headers(step, token=None):
    """
    Constructs headers with strict ordering matching the successful curl command.
    """
    h = OrderedDict()
    # 1. User-Agent (Always first in curl)
    h['User-Agent'] = "Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)"
    
    # 2. X-User-Agent
    h['X-User-Agent'] = "Model: MAG322; Link: WiFi"
    
    # 3. Referer
    h['Referer'] = "http://mag.4k365.xyz/stalker_portal/c/"
    
    # 4. Accept
    h['Accept'] = "*/*"
    
    # 5. Connection
    h['Connection'] = "Keep-Alive"
    
    # 6. Cookie
    cookie_str = f"mac={MAC}; stb_lang=en; timezone={TIMEZONE}"
    if token:
        cookie_str += f"; token={token}"
    h['Cookie'] = cookie_str
    
    # 7. Authorization (Only for post-handshake)
    if step != "handshake" and token:
        h['Authorization'] = f"Bearer {token}"
        
    return h

# --- EXECUTION FLOW ---

try:
    # 1. HANDSHAKE
    print("\n--- 1. HANDSHAKE ---")
    params = {
        'type': 'stb',
        'action': 'handshake',
        'token': '',
        'prehash': '',
        'device_id': DEVICE_ID,
        'device_id2': DEVICE_ID2,
        'mac': MAC,
        'JsHttpRequest': '1-xml'
    }
    
    # Handshake Headers: NO Authorization
    headers = get_headers("handshake")
    
    # Send Request
    resp = session.get(BASE_URL, params=params, headers=headers, timeout=10)
    
    print(f"Status: {resp.status_code}")
    if resp.status_code != 200:
        print(f"Handshake Failed: {resp.text}")
        sys.exit(1)
        
    data = resp.json()
    token = data.get('js', {}).get('token')
    
    if not token:
        print("No token received!")
        sys.exit(1)
        
    print(f"Token Received: {token}")
    
    # 2. SLEEP (Mimic processing time / avoid rapid-fire trigger)
    print("\nSleeping 2 seconds...")
    time.sleep(2)
    
    # 3. GET PROFILE
    print("\n--- 2. GET PROFILE ---")
    params = {
        'type': 'stb',
        'action': 'get_profile',
        'token': token,
        'mac': MAC,
        'device_id': DEVICE_ID,
        'device_id2': DEVICE_ID2,
        'JsHttpRequest': '1-xml'
    }
    
    # Profile Headers: WITH Authorization
    headers = get_headers("profile", token=token)
    
    # Send Request (Reusing session/connection)
    resp = session.get(BASE_URL, params=params, headers=headers, timeout=10)
    
    print(f"Status: {resp.status_code}")
    print(f"Response: {resp.text[:500]}...") # Print first 500 chars

except requests.exceptions.ConnectionError as e:
    print("\n!!! CONNECTION ERROR !!!")
    print(f"Details: {e}")
    print("Likely Cause: IP Ban / Firewall Block.")
    print("Recommendation: WAIT 15 MINUTES before retrying.")
    sys.exit(1)
except Exception as e:
    print(f"\nUnexpected Error: {e}")
    sys.exit(1)
