# MAG322 Profile Configuration - EXACT MATCH
$mac = "00:1A:79:CB:9A:23"
$token = "34B228E04C0C8BA1B5BE1BEE668D2249"
$streamId = "1091502" # TR| BEIN SPORTS 5 FHD

# Calculate device_id = sha256(mac + "MAG322")
$deviceIdInput = "${mac}MAG322"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($deviceIdInput)
$hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
$deviceId = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })
$deviceId2 = $deviceId

Write-Host "Generated device_id: $deviceId"

# Headers for API (create_link)
$apiUa = "Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)"
$apiXUa = "Model: MAG322; Link: WiFi"
$apiReferer = "http://mag.4k365.xyz/stalker_portal/c/"
$apiOrigin = "http://mag.4k365.xyz"
# Note: User instructions for API cookie did NOT include token, but usually it's needed. 
# I will try WITHOUT token in cookie for API first, as per instructions.
$apiCookie = "mac=$mac; stb_lang=en; timezone=Europe/Kiev" 

# Construct create_link URL with new params
$cmd = "ffmpeg http://mag.4k365.xyz:80/play/live.php?mac=$mac&stream=$streamId&extension=ts"
$encodedCmd = [uri]::EscapeDataString($cmd)
$createLinkUrl = "http://mag.4k365.xyz/portal.php?type=itv&action=create_link&token=$token&mac=$mac&cmd=$encodedCmd&JsHttpRequest=1-xml&device_id=$deviceId&device_id2=$deviceId2&device_mac=$mac&auth_second_step=0"

Write-Host "Calling create_link..."
# Using curl.exe to ensure exact header control
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
    $createLinkUrl

Write-Host "Response: $response"

if ($response -match 'play_token=([^"&]+)') {
    $playToken = $matches[1]
    Write-Host "Got play_token: $playToken"
    
    # Playback Headers - EXACT MATCH
    # NO Authorization, NO Referer, NO Origin, NO X-Requested-With
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