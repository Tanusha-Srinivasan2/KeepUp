Get-ChildItem -Path "c:\KeepUpFInalVersion\KeepUp\keep_up_hackathon\keep_up_app\lib" -Recurse -Filter *.dart | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'http://10\.0\.2\.2:8080') {
        $newContent = $content -replace 'http://10\.0\.2\.2:8080', 'https://colours-attraction-emission-length.trycloudflare.com'
        Set-Content $_.FullName -Value $newContent -NoNewline
        Write-Host "Updated: $($_.FullName)"
    }
}
