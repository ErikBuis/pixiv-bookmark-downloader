# See README.md for documentation, rationale, and troubleshooting.

uvsh

$USER_ID = (Get-Content "$PSScriptRoot\pixiv_user_id.txt" -Raw).Trim()
$URL = "https://www.pixiv.net/en/users/$USER_ID/bookmarks/artworks"

gallery-dl --config "$PSScriptRoot\gallery-dl.conf" $URL
