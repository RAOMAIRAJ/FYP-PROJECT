$lines = Get-Content -Path "C:\Users\786 Computers\.gemini\antigravity\brain\cfcae1ea-0306-4673-82ab-5c508a718b03\.system_generated\logs\transcript.jsonl"
for ($i = 9000; $i -lt 9300; $i++) {
    if ($lines[$i] -match "user_home_tab.dart" -and $lines[$i] -match "TargetContent") {
        Write-Output "Step $i has TargetContent!"
    }
}
