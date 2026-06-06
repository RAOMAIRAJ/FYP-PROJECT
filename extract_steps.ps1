$lines = Get-Content -Path "C:\Users\786 Computers\.gemini\antigravity\brain\cfcae1ea-0306-4673-82ab-5c508a718b03\.system_generated\logs\transcript.jsonl"
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '"step_index":90') {
        if ($lines[$i] -match "MODEL") {
            Write-Output "Step $i"
            Write-Output $lines[$i].Substring(0, [math]::Min(800, $lines[$i].Length))
        }
    }
}
