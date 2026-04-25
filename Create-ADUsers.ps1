# ============================================
# Create-ADUsers.ps1
# Bulk creates AD users from CSV file
# Author: Muzan Abbas
# ============================================

# Import Active Directory module
Import-Module ActiveDirectory

# Define path to CSV
$csvPath = "C:\Users\Admin\Desktop\users.csv"

# Define default password for all new users
$defaultPassword = ConvertTo-SecureString "Welcome@12345!" -AsPlainText -Force

# Define base OU path (we'll create this OU first)
$ouPath = "OU=Staff,DC=muzan,DC=local"

# Create the Staff OU if it doesn't exist
try {
    New-ADOrganizationalUnit -Name "Staff" -Path "DC=muzan,DC=local" -ErrorAction Stop
    Write-Host "Created OU: Staff" -ForegroundColor Green
} catch {
    Write-Host "OU already exists, skipping..." -ForegroundColor Yellow
}

# Import CSV and create users
$users = Import-Csv -Path $csvPath

foreach ($user in $users) {
    
    # Build username: first letter of first name + last name (lowercase)
    $username = ($user.FirstName.Substring(0,1) + $user.LastName).ToLower()
    
    # Build display name
    $displayName = "$($user.FirstName) $($user.LastName)"
    
    # Check if user already exists
    if (Get-ADUser -Filter {SamAccountName -eq $username} -ErrorAction SilentlyContinue) {
        Write-Host "User $username already exists — skipping" -ForegroundColor Yellow
        continue
    }
    
    # Create the user
    try {
        New-ADUser `
            -Name $displayName `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -SamAccountName $username `
            -UserPrincipalName "$username@muzan.local" `
            -Department $user.Department `
            -Title $user.JobTitle `
            -Path $ouPath `
            -AccountPassword $defaultPassword `
            -Enabled $true `
            -ChangePasswordAtLogon $true
        
        Write-Host "Created user: $username ($displayName) - $($user.Department)" -ForegroundColor Green
        
    } catch {
        Write-Host "Failed to create $username : $_" -ForegroundColor Red
    }
}

Write-Host "`nUser creation complete." -ForegroundColor Cyan
Write-Host "Total users processed: $($users.Count)" -ForegroundColor Cyan