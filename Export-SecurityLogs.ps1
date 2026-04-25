# ============================================
# Export-SecurityLogs.ps1
# Exports Windows Security Event logs to CSV
# for Power BI analysis
# Author: Muzan Abbas
# ============================================

# Output path
$outputPath = "C:\Users\Admin\Desktop\SecurityLogs.csv"

Write-Host "Extracting Security Event Logs..." -ForegroundColor Cyan

# Extract Event ID 4625 (Failed Logon)
$failedLogons = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4625
} -ErrorAction SilentlyContinue | ForEach-Object {
    $xml = [xml]$_.ToXml()
    $data = $xml.Event.EventData.Data
    
    [PSCustomObject]@{
        TimeCreated     = $_.TimeCreated
        EventID         = $_.Id
        EventType       = "Failed Logon"
        TargetAccount   = ($data | Where-Object {$_.Name -eq 'TargetUserName'}).'#text'
        WorkstationName = ($data | Where-Object {$_.Name -eq 'WorkstationName'}).'#text'
        IPAddress       = ($data | Where-Object {$_.Name -eq 'IpAddress'}).'#text'
        LogonType       = ($data | Where-Object {$_.Name -eq 'LogonType'}).'#text'
        FailureReason   = ($data | Where-Object {$_.Name -eq 'FailureReason'}).'#text'
    }
}

# Extract Event ID 4740 (Account Lockout)
$lockouts = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4740
} -ErrorAction SilentlyContinue | ForEach-Object {
    $xml = [xml]$_.ToXml()
    $data = $xml.Event.EventData.Data
    
    [PSCustomObject]@{
        TimeCreated     = $_.TimeCreated
        EventID         = $_.Id
        EventType       = "Account Lockout"
        TargetAccount   = ($data | Where-Object {$_.Name -eq 'TargetUserName'}).'#text'
        WorkstationName = ($data | Where-Object {$_.Name -eq 'CallerComputerName'}).'#text'
        IPAddress       = "N/A"
        LogonType       = "N/A"
        FailureReason   = "Account Locked Out"
    }
}

# Extract Event ID 4624 (Successful Logon)
$successLogons = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4624
} -MaxEvents 50 -ErrorAction SilentlyContinue | ForEach-Object {
    $xml = [xml]$_.ToXml()
    $data = $xml.Event.EventData.Data
    
    [PSCustomObject]@{
        TimeCreated     = $_.TimeCreated
        EventID         = $_.Id
        EventType       = "Successful Logon"
        TargetAccount   = ($data | Where-Object {$_.Name -eq 'TargetUserName'}).'#text'
        WorkstationName = ($data | Where-Object {$_.Name -eq 'WorkstationName'}).'#text'
        IPAddress       = ($data | Where-Object {$_.Name -eq 'IpAddress'}).'#text'
        LogonType       = ($data | Where-Object {$_.Name -eq 'LogonType'}).'#text'
        FailureReason   = "N/A"
    }
}

# Combine all events
$allEvents = @()
if ($failedLogons) { $allEvents += $failedLogons }
if ($lockouts)     { $allEvents += $lockouts }
if ($successLogons){ $allEvents += $successLogons }

# Sort by time
$allEvents = $allEvents | Sort-Object TimeCreated

# Export to CSV
$allEvents | Export-Csv -Path $outputPath -NoTypeInformation

Write-Host "Export complete." -ForegroundColor Green
Write-Host "Total events exported: $($allEvents.Count)" -ForegroundColor Green
Write-Host "  Failed Logons (4625): $(($allEvents | Where-Object {$_.EventID -eq 4625}).Count)" -ForegroundColor Red
Write-Host "  Account Lockouts (4740): $(($allEvents | Where-Object {$_.EventID -eq 4740}).Count)" -ForegroundColor Magenta
Write-Host "  Successful Logons (4624): $(($allEvents | Where-Object {$_.EventID -eq 4624}).Count)" -ForegroundColor Green
Write-Host "`nFile saved to: $outputPath" -ForegroundColor Cyan