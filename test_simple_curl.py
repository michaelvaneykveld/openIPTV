import subprocess
print("Google:")
subprocess.run(["curl", "-I", "http://google.com"])
print("\nPortal:")
subprocess.run(["curl", "-I", "http://mag.4k365.xyz/portal.php"])