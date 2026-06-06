$lines = Get-Content -Path "C:\Users\786 Computers\.gemini\antigravity\brain\cfcae1ea-0306-4673-82ab-5c508a718b03\.system_generated\logs\transcript.jsonl"
$count = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match "user_home_tab.dart") {
        Write-Output "--- Match at line $i ---"
        Write-Output $lines[$i].Substring(0, [math]::Min(500, $lines[$i].Length))
        $count++
        if ($count -ge 10) { break }
    }
}
