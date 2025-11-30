import http.client
import urllib.parse
import json
import time
import sys

# ==========================================
# CONFIGURATION - USER MUST FILL THIS IN
# ==========================================
HOST = "fastream.xyz"
PORT = 8080
USERNAME = "chemaritotv"
PASSWORD = "su29x1"
# Optional: Specific stream ID to test (if known). If None, will try to find one from live streams.
TEST_STREAM_ID = "278669" 
TEST_STREAM_EXT = "mp4" # ts or m3u8
# ==========================================

def log(msg):
    print(f"[DIAGNOSTIC] {msg}")

def print_response(resp, body_preview_len=500):
    print(f"  Status: {resp.status} {resp.reason}")
    print("  Response Headers:")
    for k, v in resp.getheaders():
        print(f"    {k}: {v}")
    
    body = resp.read()
    try:
        decoded = body.decode('utf-8', errors='replace')
        print(f"  Body Preview: {decoded[:body_preview_len]}...")
        return decoded
    except:
        print(f"  Body: <binary data> ({len(body)} bytes)")
        return body

def run_diagnostic():
    print(f"Starting diagnostic for {HOST}...")
    
    # 1. AUTHENTICATION (To get cookies and verify creds)
    log("Step 1: Authentication (player_api.php)")
    
    conn = http.client.HTTPConnection(HOST, PORT)
    # conn.set_debuglevel(1) # Uncomment for raw HTTP debug
    
    params = urllib.parse.urlencode({
        'username': USERNAME,
        'password': PASSWORD
    })
    auth_path = f"/player_api.php?{params}"
    
    # Headers mimicking IPTV Smarters Pro
    headers = {
        'User-Agent': 'IPTV Smarters Pro',
        'Accept': '*/*',
        'Connection': 'keep-alive'
    }
    
    try:
        conn.request("GET", auth_path, headers=headers)
        resp = conn.getresponse()
        body = print_response(resp)
        
        if resp.status != 200:
            log("Authentication failed. Check credentials.")
            return

        # Parse cookies
        cookies = []
        headers_list = resp.getheaders()
        for k, v in headers_list:
            if k.lower() == 'set-cookie':
                # Simple parser, takes everything before first ;
                cookie_part = v.split(';')[0]
                cookies.append(cookie_part)
        
        cookie_header_val = "; ".join(cookies)
        log(f"Captured Cookies: {cookie_header_val}")
        
        try:
            data = json.loads(body)
            user_info = data.get('user_info', {})
            auth_status = user_info.get('auth', 0)
            if auth_status != 1:
                log("API returned auth=0. Credentials rejected by API logic.")
                return
            log("Authentication successful.")
        except json.JSONDecodeError:
            log("Could not parse JSON response.")
            return

    except Exception as e:
        log(f"Connection error during auth: {e}")
        return
    finally:
        conn.close()

    # 2. FIND A STREAM TO TEST
    stream_id = TEST_STREAM_ID
    if not stream_id:
        log("Step 2: Finding a live stream to test...")
        conn = http.client.HTTPConnection(HOST, PORT)
        live_path = f"/player_api.php?{params}&action=get_live_streams"
        
        try:
            conn.request("GET", live_path, headers=headers)
            resp = conn.getresponse()
            body = resp.read().decode('utf-8', errors='replace')
            
            if resp.status == 200:
                try:
                    streams = json.loads(body)
                    if streams and len(streams) > 0:
                        stream_id = streams[0].get('stream_id')
                        log(f"Found stream ID: {stream_id} ({streams[0].get('name')})")
                    else:
                        log("No live streams found.")
                        return
                except:
                    log("Failed to parse streams JSON.")
                    return
            else:
                log(f"Failed to get streams. Status: {resp.status}")
                return
        except Exception as e:
            log(f"Error getting streams: {e}")
            return
        finally:
            conn.close()

    if not stream_id:
        log("No stream ID available. Exiting.")
        return

    # 3. TEST PLAYBACK (The Critical Step)
    log(f"Step 3: Testing Playback for Stream ID {stream_id}")
    
    # Construct the stream URL path
    # Standard Xtream format: /live/username/password/stream_id.ts
    # OR /movie/username/password/stream_id.mp4
    
    base_type = "movie" if TEST_STREAM_EXT == "mp4" else "live"
    stream_path = f"/{base_type}/{USERNAME}/{PASSWORD}/{stream_id}.{TEST_STREAM_EXT}"
    
    log(f"Testing URL Path: {stream_path}")
    
    # We will try a few combinations
    
    scenarios = [
        {
            "name": "Baseline (No Cookies, Generic UA)",
            "headers": {
                'User-Agent': 'Python-urllib/3.x',
                'Accept': '*/*',
                'Connection': 'keep-alive'
            }
        },
        {
            "name": "IPTV Smarters UA + Cookies",
            "headers": {
                'User-Agent': 'IPTV Smarters Pro',
                'Accept': '*/*',
                'Connection': 'keep-alive',
                'Cookie': cookie_header_val
            }
        },
        {
            "name": "VLC UA + Cookies",
            "headers": {
                'User-Agent': 'VLC/3.0.18 LibVLC/3.0.18',
                'Accept': '*/*',
                'Connection': 'keep-alive',
                'Cookie': cookie_header_val
            }
        },
        {
            "name": "Full Mimic (Host, Referer, Cookies, UA)",
            "headers": {
                'User-Agent': 'IPTV Smarters Pro',
                'Accept': '*/*',
                'Connection': 'keep-alive',
                'Host': HOST,
                'Referer': f"http://{HOST}/",
                'Cookie': cookie_header_val
            }
        }
    ]
    
    for scenario in scenarios:
        print(f"\n--- Testing Scenario: {scenario['name']} ---")
        conn = http.client.HTTPConnection(HOST, PORT)
        # Force HTTP/1.1 (http.client does this by default, but good to know)
        
        try:
            # We use putrequest to have full control if needed, but request() is usually fine for 1.1
            # Using request() here
            conn.request("GET", stream_path, headers=scenario['headers'])
            resp = conn.getresponse()
            
            print(f"  Status: {resp.status} {resp.reason}")
            # We only read a few bytes to check if it's a video stream
            first_bytes = resp.read(100)
            print(f"  First 100 bytes: {first_bytes}")
            
            if resp.status == 200:
                print("  SUCCESS! This combination works.")
            elif resp.status == 401:
                print("  FAILED (401 Unauthorized). Check credentials or IP blocking.")
            elif resp.status == 403:
                print("  FAILED (403 Forbidden). WAF blocked this request.")
            elif resp.status == 302:
                print(f"  REDIRECT to: {resp.getheader('Location')}")
            
            resp.close()
            
        except Exception as e:
            print(f"  Error: {e}")
        finally:
            conn.close()
            time.sleep(1) # Be nice to the server

if __name__ == "__main__":
    if USERNAME == "YOUR_USERNAME":
        print("ERROR: You must edit the script and set USERNAME and PASSWORD first.")
    else:
        run_diagnostic()
