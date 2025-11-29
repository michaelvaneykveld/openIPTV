import hashlib

mac = "00:1A:79:CB:9A:23"
model = "MAG322"
s = mac + model
hash = hashlib.sha256(s.encode()).hexdigest()
print(f"String: {s}")
print(f"Hash: {hash}")
