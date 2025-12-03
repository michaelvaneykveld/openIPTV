# MAG322 Profile Configuration - EXACT MATCH
$mac = "00:1A:79:CB:9A:23"
$streamId = "1091502" # TR| BEIN SPORTS 5 FHD

# Calculate device_id = sha256(mac + "MAG322")
$deviceIdInput = "${mac}MAG322"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($deviceIdInput)
$hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
$deviceId = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })
$deviceId2 = $deviceId

Write-Host "Generated device_id: $deviceId"

# Headers for API
$apiUa = "Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)"
$apiXUa = "Model: MAG322; Link: WiFi"
$apiReferer = "http://mag.4k365.xyz/stalker_portal/c/"
$apiOrigin = "http://mag.4k365.xyz"
$apiCookie = "mac=$mac; stb_lang=en; timezone=Europe/Kiev"

# 1. HANDSHAKE
Write-Host "1. Performing Handshake..."
$handshakeUrl = "http://mag.4k365.xyz/portal.php?type=stb&action=handshake&token=&prehash=&device_id=$deviceId&device_id2=$deviceId2&mac=$mac&JsHttpRequest=1-xml"

$response = curl.exe -v `
    -H "User-Agent: $apiUa" `
    -H "X-User-Agent: $apiXUa" `
    -H "X-Requested-With: XMLHttpRequest" `
    -H "Accept: */*" `
    -H "Cache-Control: no-cache" `
    -H "Referer: $apiReferer" `
    -H "Origin: $apiOrigin" `
    -H "Connection: Keep-Alive" `
    -H "Accept-Encoding: gzip, deflate" `
    -H "Accept-Language: en,en-US;q=0.9,ru;q=0.8" `
    -H "Cookie: $apiCookie" `
    $handshakeUrl

Write-Host "Handshake Response: $response"

if ($response -match '"token":"([^"]+)"') {
    $token = $matches[1]
    Write-Host "Got NEW Token: $token"
    
    # Update cookie with new token for subsequent API calls? 
    # User instructions didn't include token in API cookie, but usually it's needed for authenticated calls like create_link.
    # I will try WITHOUT token in cookie for create_link first, as per instructions.
    
    # 2. GET_PROFILE TESTS
    
    # Test A: Token in Cookie ONLY (No token in URL)
    Write-Host "2A. Calling get_profile (Token in Cookie ONLY)..."
    $getProfileUrlA = "http://mag.4k365.xyz/portal.php?type=stb&action=get_profile&mac=$mac&JsHttpRequest=1-xml&device_id=$deviceId&device_id2=$deviceId2"
    $apiCookieWithToken = "mac=$mac; stb_lang=en; timezone=Europe/Kiev; token=$token"
    
    try {
        $responseA = curl.exe -v `
            -H "User-Agent: $apiUa" `
            -H "X-User-Agent: $apiXUa" `
            -H "X-Requested-With: XMLHttpRequest" `
            -H "Accept: */*" `
            -H "Cache-Control: no-cache" `
            -H "Referer: $apiReferer" `
            -H "Origin: $apiOrigin" `
            -H "Connection: Keep-Alive" `
            -H "Accept-Encoding: gzip, deflate" `
            -H "Accept-Language: en,en-US;q=0.9,ru;q=0.8" `
            -H "Cookie: $apiCookieWithToken" `
            $getProfileUrlA
        Write-Host "Response A: $responseA"
    } catch {
        Write-Host "Test A Failed"
    }

    # Test B: Token in URL ONLY (No token in Cookie)
    Write-Host "2B. Calling get_profile (Token in URL ONLY)..."
    $getProfileUrlB = "http://mag.4k365.xyz/portal.php?type=stb&action=get_profile&token=$token&mac=$mac&JsHttpRequest=1-xml&device_id=$deviceId&device_id2=$deviceId2"
    $apiCookieNoToken = "mac=$mac; stb_lang=en; timezone=Europe/Kiev"

    try {
        $responseB = curl.exe -v `
            -H "User-Agent: $apiUa" `
            -H "X-User-Agent: $apiXUa" `
            -H "X-Requested-With: XMLHttpRequest" `
            -H "Accept: */*" `
            -H "Cache-Control: no-cache" `
            -H "Referer: $apiReferer" `
            -H "Origin: $apiOrigin" `
            -H "Connection: Keep-Alive" `
            -H "Accept-Encoding: gzip, deflate" `
            -H "Accept-Language: en,en-US;q=0.9,ru;q=0.8" `
            -H "Cookie: $apiCookieNoToken" `
            $getProfileUrlB
        Write-Host "Response B: $responseB"
    } catch {
        Write-Host "Test B Failed"
    }

    # Test C: Token in Authorization Header ONLY
    Write-Host "2C. Calling get_profile (Token in Auth Header ONLY)..."
    $getProfileUrlC = "http://mag.4k365.xyz/portal.php?type=stb&action=get_profile&mac=$mac&JsHttpRequest=1-xml&device_id=$deviceId&device_id2=$deviceId2"
    
    try {
        $responseC = curl.exe -v `
            -H "User-Agent: $apiUa" `
            -H "X-User-Agent: $apiXUa" `
            -H "X-Requested-With: XMLHttpRequest" `
            -H "Accept: */*" `
            -H "Cache-Control: no-cache" `
            -H "Referer: $apiReferer" `
            -H "Origin: $apiOrigin" `
            -H "Connection: Keep-Alive" `
            -H "Accept-Encoding: gzip, deflate" `
            -H "Accept-Language: en,en-US;q=0.9,ru;q=0.8" `
            -H "Cookie: $apiCookieNoToken" `
            -H "Authorization: Bearer $token" `
            $getProfileUrlC
        Write-Host "Response C: $responseC"
    } catch {
        Write-Host "Test C Failed"
    }
        
    Write-Host "Create Link Response: $response"

    if ($response -match 'play_token=([^"&]+)') {
        $playToken = $matches[1]
        Write-Host "Got play_token: $playToken"
        
        # 3. PLAYBACK
        Write-Host "3. Calling Playback..."
        
        # Playback Headers - EXACT MATCH
        # Cookie MUST include token and play_token
        $playbackCookie = "mac=$mac; stb_lang=en; timezone=Europe/Kiev; token=$token; play_token=$playToken"
        
        $playUrl = "http://mag.4k365.xyz/play/live.php?mac=$mac&stream=$streamId&extension=ts&play_token=$playToken"
        Write-Host "Calling play URL: $playUrl"
        
        curl.exe -v `
            -H "User-Agent: $apiUa" `
            -H "X-User-Agent: $apiXUa" `
            -H "Accept: */*" `
            -H "Connection: Keep-Alive" `
            -H "Accept-Encoding: identity" `
            -H "Cookie: $playbackCookie" `
            $playUrl
    } else {
        Write-Host "Failed to extract play_token"
    }

} else {
    Write-Host "Failed to extract token from handshake"
}