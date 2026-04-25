# ============================================
# Create-Groups.ps1
# Creates department security groups and assigns users
# Author: Muzan Abbas
# ============================================

Import-Module ActiveDirectory

$ouPath = "OU=Staff,DC=muzan,DC=local"

# Define groups
$groups = @("IT-Team", "Finance-Team", "HR-Team", "Operations-Team", "Marketing-Team", "Security-Team")

# Create groups
foreach ($group in $groups) {
    try {
        New-ADGroup `
            -Name $group `
            -GroupScope Global `
            -GroupCategory Security `
            -Path $ouPath `
            -Description "Security group for $group department"
        
        Write-Host "Created group: $group" -ForegroundColor Green
    } catch {
        Write-Host "Group $group already exists — skipping" -ForegroundColor Yellow
    }
}

# Assign users to groups based on Department attribute
$users = Get-ADUser -Filter * -SearchBase $ouPath -Properties Department

foreach ($user in $users) {
    $dept = $user.Department
    $groupName = "$dept-Team"
    
    if ($groups -contains $groupName) {
        try {
            Add-ADGroupMember -Identity $groupName -Members $user.SamAccountName
            Write-Host "Added $($user.SamAccountName) to $groupName" -ForegroundColor Green
        } catch {
            Write-Host "Could not add $($user.SamAccountName) to $groupName : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nGroup assignment complete." -ForegroundColor Cyan