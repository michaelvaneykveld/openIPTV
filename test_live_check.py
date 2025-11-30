import requests

# Try to get the live stream URL from the API to see if it's different
url = "http://fastream.xyz:8080/player_api.php?username=chemaritotv&password=su29x1&action=get_live_streams"
try:
    r = requests.get(url)
    if r.status_code == 200:
        data = r.json()
        if len(data) > 0:
            print("Sample Live Stream Entry:")
            print(data[0])
            stream_id = data[0]['stream_id']
            print(f"\nTesting Live Stream ID: {stream_id}")
            live_url = f"http://fastream.xyz:8080/live/chemaritotv/su29x1/{stream_id}.ts"
            print(f"URL: {live_url}")
            
            r_live = requests.get(live_url, stream=True)
            print(f"Live Stream Status: {r_live.status_code}")
    else:
        print("Failed to get live streams")
except Exception as e:
    print(e)
