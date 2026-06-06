$historyDir = "$env:APPDATA\Code\User\History"
if (Test-Path $historyDir) {
    Get-ChildItem -Path $historyDir -Recurse -File | Select-String -Pattern 'class UserHomeTab' -List | Select-Object Path
} else {
    Write-Output "History dir not found"
}
