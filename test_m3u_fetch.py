import requests

url = "http://fastream.xyz:8080/get.php?username=chemaritotv&password=su29x1&type=m3u&output=ts"

try:
    print(f"Fetching M3U from: {url}")
    response = requests.get(url, timeout=10)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("First 500 bytes:")
        print(response.text[:500])
    else:
        print("Failed to fetch M3U")
except Exception as e:
    print(f"Error: {e}")
