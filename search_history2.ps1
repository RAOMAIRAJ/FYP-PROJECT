$historyDir = "$env:APPDATA\Code\User\History"
if (Test-Path $historyDir) {
    Get-ChildItem -Path $historyDir -Recurse -File | Where-Object { $_.LastWriteTime -ge (Get-Date).AddHours(-24) } | Select-Object FullName, LastWriteTime | Sort-Object LastWriteTime -Descending | Select-Object -First 30
} else {
    Write-Output "History dir not found"
}
