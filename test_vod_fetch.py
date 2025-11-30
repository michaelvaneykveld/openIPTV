import requests

urls_to_test = [
    "https://fastream.xyz:8080/movie/chemaritotv/su29x1/278669.mp4",
    "https://fastream.xyz:2083/movie/chemaritotv/su29x1/278669.mp4"
]

headers = {} # Empty headers to use default python-requests UA

for url in urls_to_test:
    print(f"\nTesting: {url}")
    try:
        response = requests.get(url, headers=headers, stream=True, timeout=5)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print("SUCCESS!")
            break
    except Exception as e:
        print(f"Error: {e}")
