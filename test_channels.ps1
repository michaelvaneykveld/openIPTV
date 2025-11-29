$token = "34B228E04C0C8BA1B5BE1BEE668D2249"
$mac = "00:1a:79:cb:9a:23"

$url = "http://mag.4k365.xyz/portal.php?type=itv&action=get_all_channels&token=$token&mac=$mac"

Write-Host "Fetching channels..."
curl.exe -v -H "User-Agent: Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) InfomirBrowser/3.0 StbApp/0.23" -H "Referer: http://mag.4k365.xyz/stalker_portal/c/" -H "Cookie: mac=$mac; stb_lang=en; timezone=UTC; token=$token" -H "Authorization: Bearer $token" -H "X-User-Agent: Model:MAG254; Link:Ethernet" $url