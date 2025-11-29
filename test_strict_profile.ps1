# test_strict_profile.ps1

function Get-Sha256Hash($string) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    $hashString = [BitConverter]::ToString($hashBytes) -replace '-'
    return $hashString.ToLower()
}

$mac = "00:1A:79:00:00:02" # New Random MAC 2
$macLower = $mac.ToLower()

# Calculate device_id using LOWERCASE MAC (Trying this again)
$deviceId = Get-Sha256Hash ($macLower + "MAG322")
$deviceId2 = $deviceId
Write-Host "Device ID: $deviceId"

# Common Headers
$ua = "Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)"
$xua = "Model: MAG322; Link: WiFi"
$referer = "http://mag.4k365.xyz/stalker_portal/c/"
$origin = "http://mag.4k365.xyz"

# ==========================================
# 1. HANDSHAKE
# ==========================================
Write-Host "`n1. Performing Handshake..."

# URL: Token is empty for handshake
$handshakeUrl = "http://mag.4k365.xyz/portal.php?type=stb&action=handshake&token=&prehash=&device_id=$deviceId&device_id2=$deviceId2&mac=$macLower&JsHttpRequest=1-xml"

# Cookie: mac, stb_lang, timezone
$handshakeCookie = "mac=$macLower; stb_lang=en; timezone=Europe/Kiev"

# Strict Header Order for API:
# ...
$response = curl.exe -s -v `
    -H "User-Agent: $ua" `
    -H "X-User-Agent: $xua" `
    -H "Accept: */*" `
    -H "Accept-Encoding: gzip, deflate" `
    -H "Accept-Language: en,en-US;q=0.9" `
    -H "Referer: $referer" `
    -H "Origin: $origin" `
    -H "Connection: Keep-Alive" `
    -H "Cookie: $handshakeCookie" `
    -H "X-Requested-With: XMLHttpRequest" `
    $handshakeUrl

Write-Host "Handshake Response: $response"

if ($response -match '"token":"([^"]+)"') {
    $token = $matches[1]
    Write-Host "Token: $token"
} else {
    Write-Host "Failed to get token"
    exit
}

# ==========================================
# 2. GET PROFILE
# ==========================================
Write-Host "`n2. Calling get_profile..."

# URL: Try adding token to URL as well.
$profileUrl = "http://mag.4k365.xyz/portal.php?type=stb&action=get_profile&token=$token&mac=$macLower&JsHttpRequest=1-xml&device_id=$deviceId&device_id2=$deviceId2"

# Cookie: mac, stb_lang, timezone, token
$apiCookie = "mac=$macLower; stb_lang=en; timezone=Europe/Kiev; token=$token"

$response = curl.exe -s -v `
    -H "User-Agent: $ua" `
    -H "X-User-Agent: $xua" `
    -H "Accept: */*" `
    -H "Accept-Encoding: gzip, deflate" `
    -H "Accept-Language: en,en-US;q=0.9" `
    -H "Referer: $referer" `
    -H "Origin: $origin" `
    -H "Connection: Keep-Alive" `
    -H "Cookie: $apiCookie" `
    -H "X-Requested-With: XMLHttpRequest" `
    $profileUrl

Write-Host "Get Profile Response: $response"

# ==========================================
# 3. CREATE LINK
# ==========================================
Write-Host "`n3. Calling create_link..."

$streamId = "534" # ARD FHD
$cmd = "ffmpeg http://mag.4k365.xyz:80/play/live.php?mac=$mac&stream=$streamId&extension=ts"
$encodedCmd = [uri]::EscapeDataString($cmd)

# URL: NO TOKEN in URL for API calls
$createLinkUrl = "http://mag.4k365.xyz/portal.php?type=itv&action=create_link&mac=$macLower&cmd=$encodedCmd&JsHttpRequest=1-xml&device_id=$deviceId&device_id2=$deviceId2&device_mac=$macLower&auth_second_step=0"


# Cookie: Same as get_profile
$response = curl.exe -s -v `
    -H "User-Agent: $ua" `
    -H "X-User-Agent: $xua" `
    -H "Accept: */*" `
    -H "Accept-Encoding: gzip, deflate" `
    -H "Accept-Language: en,en-US;q=0.9" `
    -H "Referer: $referer" `
    -H "Origin: $origin" `
    -H "Connection: Keep-Alive" `
    -H "Cookie: $apiCookie" `
    -H "X-Requested-With: XMLHttpRequest" `
    $createLinkUrl

Write-Host "Create Link Response: $response"

if ($response -match '"cmd":"([^"]+)"') {
    $playUrl = $matches[1]
    Write-Host "Play URL: $playUrl"
    
    # Extract play_token if present in the URL (it usually is part of the cmd response)
    # But wait, the response is usually JSON with "cmd" containing the URL.
    # The URL might look like: http://mag.4k365.xyz/play/live.php?...&play_token=...
    
    # Let's try to extract play_token from the response text if possible, or just use the URL provided.
    # The user said: "play_token must be in both: the query string and the Cookie header"
    
    # If the server returns a URL with play_token, we need to parse it.
} else {
    Write-Host "Failed to get play URL"
}
