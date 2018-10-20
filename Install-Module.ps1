param(
    [Switch]$Force,

    [ValidateSet("CurrentUser","AllUser")]
    $Scope = "CurrentUser"
)

$edition = $PSVersionTable.PSEdition
if($edition -match "Core") {
    $profilePath = ~\Documents\PowerShell
} else {
    $profilePath = ~\Documents\WindowsPowerShell
}

Write-Host "Installing into $profilePath"

mkdir "$profilePath\Modules" -force | convert-path | Push-location

try {
    $ErrorActionPreference = "Stop"
    if(Test-Path Profile-master){
        Write-Error "The Profile-master folder already exists, install cannot continue."
    }
    if(Test-Path Profile){
        Write-Warning "The Profile module already exists, install will overwrite it and put the old one in Profile/old."
        Remove-Item Profile/old -Recurse -Force -ErrorAction SilentlyContinue
    }

    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest https://github.com/MarkusAmshove/Profile/archive/master.zip -OutFile Profile-master.zip
    $ProgressPreference = "Continue"
    Expand-Archive Profile-master.zip .
    $null = mkdir Profile-master\old

    if(Test-Path Profile) {
        Move-Item Profile\* Profile-master\old
        Remove-Item Profile
    }

    Rename-Item Profile-master Profile
    Remove-Item Profile-master.zip

    Move-Item Profile\profile.ps1 $profilePath -Force:$Force -ErrorAction SilentlyContinue -ErrorVariable MoveFailed
    if($MoveFailed) {
        Write-Warning "Profile.ps1 already exists. Leaving new profile in $profilePath\Profile"
    }

    if($PSVersionTable.PSEdition -ne "Core") {
        $Gallery = Get-PSRepository PSGallery
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -SourceLocation https://www.powershellgallery.com/api/v2/
        Install-Module -AllowClobber -Scope:$Scope -Name @((Get-Module Profile -ListAvailable).RequiredModules)
        Set-PSRepository -Name PSGallery -InstallationPolicy $Gallery.InstallationPolicy
    }
    if(!(Test-Path "$profilePath\Scripts")) {
        mkdir "$profilePath\Scripts"
    }
} finally {
    Pop-Location
}
