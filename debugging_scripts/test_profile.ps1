# test_profile.ps1

function Get-Sha256Hash($string) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    $hashString = [BitConverter]::ToString($hashBytes) -replace '-'
    return $hashString.ToLower()
}

$mac = "00:1A:79:CB:9A:23"
$macLower = $mac.ToLower()

# Calculate device_id using LOWERCASE MAC
$deviceId = Get-Sha256Hash ($macLower + "MAG322")
$deviceId2 = $deviceId
Write-Host "Device ID (Lower MAC): $deviceId"

# Headers
$apiUa = "Mozilla/5.0 (QtEmbedded; U; Linux; MAG322)"
$apiXUa = "Model: MAG322; Link: WiFi"
$apiReferer = "http://mag.4k365.xyz/stalker_portal/c/"
$apiOrigin = "http://mag.4k365.xyz"

# 1. Handshake to get token
Write-Host "1. Handshake..."
# Use Lowercase MAC in URL and Cookie
$handshakeUrl = "http://mag.4k365.xyz/portal.php?type=stb&action=handshake&token=&prehash=&device_id=$deviceId&device_id2=$deviceId2&mac=$macLower&JsHttpRequest=1-xml"
$handshakeCookie = "mac=$macLower; stb_lang=en; timezone=Europe/Kiev"

$response = curl.exe -s `
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
    -H "Cookie: $handshakeCookie" `
    $handshakeUrl

Write-Host "Handshake Response: $response"

if ($response -match '"token":"([^"]+)"') {
    $token = $matches[1]
    Write-Host "Token: $token"
} else {
    Write-Host "Failed to get token"
    exit
}

# 2. Get Profile
Write-Host "2. Get Profile..."
$profileUrl = "http://mag.4k365.xyz/portal.php?type=stb&action=get_profile&mac=$macLower&JsHttpRequest=1-xml&device_id=$deviceId&device_id2=$deviceId2"
$cookie = "mac=$macLower; stb_lang=en; timezone=Europe/Kiev; token=$token"

try {
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
        -H "Cookie: $cookie" `
        -H "Authorization: Bearer $token" `
        $profileUrl
    Write-Host "Profile Response: $response"
} catch {
    Write-Host "Profile Failed"
}
