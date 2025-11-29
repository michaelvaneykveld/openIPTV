import subprocess
import json
import re
import time

MAC = "00:1A:79:CB:9A:23"
MAC_ENCODED = "00%3A1A%3A79%3ACB%3A9A%3A23"
DEVICE_ID = "3e80bb247dc36e64a1fb0d61736baf8a7068c6d9373f34c3044dc81fb46bbea6"
DEVICE_ID2 = DEVICE_ID

print("1. Handshake (curl)...")
cmd = [
    "curl", "-s",
    f"http://mag.4k365.xyz/portal.php?type=stb&action=handshake&token=&prehash=&device_id={DEVICE_ID}&device_id2={DEVICE_ID2}&mac={MAC_ENCODED}&JsHttpRequest=1-xml",
    "-H", "User-Agent: Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)",
    "-H", "X-User-Agent: Model: MAG322; Link: WiFi",
    "-H", "Referer: http://mag.4k365.xyz/stalker_portal/c/",
    "-H", f"Cookie: mac={MAC}; stb_lang=en; timezone=Europe/London"
]

result = subprocess.run(cmd, capture_output=True, text=True)
print(f"Output: {result.stdout}")

try:
    data = json.loads(result.stdout)
    token = data['js']['token']
    print(f"Token: {token}")
except:
    print("Failed to parse token")
    exit(1)

print("Sleeping...")
time.sleep(2)

print("2. Get Profile (curl)...")
cmd = [
    "curl", "-v",
    f"http://mag.4k365.xyz/portal.php?type=stb&action=get_profile&token={token}&mac={MAC_ENCODED}&device_id={DEVICE_ID}&device_id2={DEVICE_ID2}&JsHttpRequest=1-xml",
    "-H", "User-Agent: Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)",
    "-H", "X-User-Agent: Model: MAG322; Link: WiFi",
    "-H", "Referer: http://mag.4k365.xyz/stalker_portal/c/",
    "-H", f"Cookie: mac={MAC}; stb_lang=en; timezone=Europe/London; token={token}",
    "-H", f"Authorization: Bearer {token}"
]

result = subprocess.run(cmd, capture_output=True, text=True)
print(f"Output: {result.stdout}")
print(f"Stderr: {result.stderr}")
