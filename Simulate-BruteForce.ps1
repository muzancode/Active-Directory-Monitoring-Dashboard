# ============================================
# Simulate-BruteForce.ps1
# Simulates failed login attempts to generate
# Windows Security Event logs (Event ID 4625)
# Author: Muzan Abbas
# ============================================

Import-Module ActiveDirectory

# Get all users from AD
$users = Get-ADUser -Filter * -SearchBase "OU=Staff,DC=muzan,DC=local" | Select-Object -ExpandProperty SamAccountName

# Add some fake attacker-style usernames too
$attackTargets = $users + @("admin", "administrator", "root", "guest", "test", "service", "backup")

# Number of attempts per target
$attemptsPerUser = 10

Write-Host "Starting brute force simulation..." -ForegroundColor Red
Write-Host "Targeting $($attackTargets.Count) accounts with $attemptsPerUser attempts each" -ForegroundColor Red
Write-Host "Total attempts: $($attackTargets.Count * $attemptsPerUser)" -ForegroundColor Red
Write-Host ""

$totalAttempts = 0
$lockedAccounts = @()

foreach ($target in $attackTargets) {
    Write-Host "Attacking: $target" -ForegroundColor Yellow
    
    for ($i = 1; $i -le $attemptsPerUser; $i++) {

        try {
            $null = & net use \\DC01\IPC$ /user:muzan.local\$target "WrongPassword123" 2>&1
            & net use \\DC01\IPC$ /delete 2>&1 | Out-Null
        } catch { }

        $totalAttempts++
        Start-Sleep -Milliseconds 200
        Write-Host "  Attempt $i/$attemptsPerUser for $target" -ForegroundColor DarkRed
    }

    # Check if account got locked
    try {
        $userObj = Get-ADUser $target -Properties LockedOut -ErrorAction SilentlyContinue
        if ($userObj -and $userObj.LockedOut) {
            $lockedAccounts += $target
            Write-Host "  ACCOUNT LOCKED: $target" -ForegroundColor Magenta
        }
    } catch { }
}

Write-Host "`nSimulation complete." -ForegroundColor Cyan
Write-Host "Total failed attempts generated: $totalAttempts" -ForegroundColor Cyan
Write-Host "Accounts locked out: $($lockedAccounts.Count)" -ForegroundColor Cyan
if ($lockedAccounts.Count -gt 0) {
    Write-Host "Locked accounts: $($lockedAccounts -join ', ')" -ForegroundColor Magenta
}