Get-Content -Path "BZLogger.txt" -Wait -Tail 0 -Encoding UTF8 | ForEach-Object {
    if ($_ -match '\|LUA\|PRINT\|(.*?)\|PRINT\|LUA\|') {
        $msg = $Matches[1]
        Write-Host $msg
    }
    elseif ($_ -match '\|LUA\|ERROR\|(.*?)\|ERROR\|LUA\|') {
        $msg = $Matches[1]
        Write-Host $msg -ForegroundColor Red
    }
}
