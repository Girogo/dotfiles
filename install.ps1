# Main script
function Main {
  $isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

  # Check if running as admin
  if (!$isAdmin)
  {
      Write-Host "You need admin privileges"; -ForegroundColor Red
      return;
  }

  SetExecutionPolicy
  InstallNerdFonts
  InstallChocolatey
  InstallGit
  InstallLazyGit
  InstallOhMyPosh
  InstallPoshGit
  InstallTerminalIcons
  InstallPSReadLine
  InstallZ
  InstallPSFzf
  CreatePowershellProfile
  
  Write-Host "Process completed" -ForegroundColor Green
}

# Set Execution policy to RemoteSigned
function SetExecutionPolicy {
  Write-Host "Setting ExecutionPolicy to RemoteSigned" -ForegroundColor Cyan
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser | Out-Null
}

# Install NerdFonts
function InstallNerdFonts {
  $currentProgram = "Nerd Fonts"
  Write-Host "Installing Nerd Fonts..." -ForegroundColor Cyan
  try
  {
    Set-ExecutionPolicy Bypass -Scope Process -Force | Out-Null
    Invoke-Expression ((New-Object System.Net.WebClient)).DownloadString('https://raw.githubusercontent.com/Girogo/dotfiles/main/fonts/Nerd%20Fonts%20Installer/install.ps1')
    Write-Host "Nerd fonts installed correctly" -ForegroundColor Green
  }
  catch
  {
    if (-not (PromptContinue($currentProgram))) { exit }
  }
}

# Install chocolatey
function InstallChocolatey {
  $currentProgram = "chocolatey"
  Write-Host "Installing chocolatey CLI..." -ForegroundColor Cyan

  try {
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installed correctly" -ForegroundColor Green
  }
  catch 
  {
    if (-not (PromptContinue($currentProgram))) { exit }
  }
}

# Install git
function InstallGit {

  Write-Host "Starting git setup process..." -ForegroundColor Cyan
  $gitCommand = Get-Command git -ErrorAction SilentlyContinue
  $isGitInstalled = $null -ne $gitCommand

  if (-not ($isGitInstalled))
  {
    Write-Host "Downloading git..." -ForegroundColor Cyan
    
    $url = "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe"
    $Temp = $env:TEMP
    $installerFilePath = "$Temp\gitinstaller.exe"

    Invoke-WebRequest -Uri $url -OutFile "$installerFilePath"

    Write-Host "Starting git setup..." -ForegroundColor Cyan
    & $installerFilePath | Out-Null

    Write-Host "Updating git..." -ForegroundColor Cyan
    git update-git-for-windows # TODO: Test on new environment without existing git path variable
    Write-Host "Git setup ended." -ForegroundColor Cyan
    Remove-Item -Path $installerFilePath -Force
  }
  else
  {
    Write-Host "Git already installed!" -ForegroundColor Cyan
  }
}

# Install lazygit
function InstallLazyGit {
  $currentProgram = "lazygit"
  Write-Host "Installing 'lazygit'...'" -ForegroundColor Cyan
  try
  {
    choco install lazygit -y | Out-Null
    Write-Host "lazygit installed correctly" -ForegroundColor Green
  }
  catch 
  {
    if (-not (PromptContinue($currentProgram))) { exit }
  }
}

# Install oh-my-posh
function InstallOhMyPosh{
  
  $currentProgram = "oh-my-posh"
  Write-Host "Installing oh-my-posh..." -ForegroundColor Cyan
  try
  {
    choco install oh-my-posh -y | Out-Null
    Write-Host "Oh-my-posh installed correctly" -ForegroundColor Green
  }
  catch 
  {
    if (-not (PromptContinue($currentProgram))) { exit }
  }
}

# Install Terminal-Icons
function InstallTerminalIcons {
  Write-Host "Installing module 'Terminal-Icons'..." -ForegroundColor Cyan
  Install-Module -Name Terminal-Icons -Repository PSGallery
}

function InstallPoshGit {
  Write-Host "Installing module 'Posh-git'..." -ForegroundColor Cyan
  Install-Module posh-git -Scope CurrentUser -Force
}

# Install PSReadLine
function InstallPSReadLine {
  Write-Host "Installing module 'PSReadLine'..." -ForegroundColor Cyan
  Install-Module PSReadLine -Force
}

 # Install Z
function InstallZ {
  Write-Host "Installing module 'Z'..." -ForegroundColor Cyan
  Install-Module z -AllowClobber
}

# Install PSFzf
function InstallPSFzf {
  $currentProgram = "PSFzf"
  Write-Host "Installing 'PSFzf'...'" -ForegroundColor Cyan
  try
  {
    choco install fzf -y | Out-Null
    Write-Host "PSFzf installed correctly" -ForegroundColor Green
  }
  catch 
  {
    if (-not (PromptContinue($currentProgram))) { exit }
  }
}

# Create Powershell Profile
function CreatePowershellProfile {
  Write-Host "Creating Powershell profile..." -ForegroundColor Cyan
  $profileExists = Test-Path $PROFILE

  if ($profileExists){
    $validResponse = $false
    
    do{
      Write-Host "Powershell profile already exists. Do you want to override it? [y/n]" -ForegroundColor Yellow
      $response = Read-Host
      $response = $response.ToLower()

      $validResponse = $response -eq 'y' -or $response -eq 'n'

      if (-not $validResponse){
        Write-Host "Select a valid response" -ForegroundColor Red
      }

    }while(-not $validResponse)
    
    if ($response -eq 'n')
    {
      return
    }
  }

  $url = "https://raw.githubusercontent.com/Girogo/dotfiles/main/pwsh/user_profile.ps1"
  $profileContent = (Invoke-WebRequest -Uri $url).Content
  $profileContent > $PROFILE
  Write-Host "Powershell profile created." -ForegroundColor Cyan
}

# Asks to continue or abort the process
function PromptContinue($programName) {
  Write-Host "Something went wrong while trying to install $programName." -ForegroundColor Red
  Write-Host $_ -ForegroundColor Red
  do {
      Write-Host "Do you want to continue with the process? [y/n]" -ForegroundColor Yellow
      $response = Read-Host
      $response = $response.ToLower()
  } while ($response -ne 'y' -and $response -ne 'n')

  return $response.Equals("y")
}

# Execute script
Main