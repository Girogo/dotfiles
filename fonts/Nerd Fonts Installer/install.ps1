function GetNerdFonts {
    $url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/bin/scripts/lib/fonts.json"
    $fontsJson = (Invoke-WebRequest -Uri $url).Content | ConvertFrom-Json
    $fontNames = $fontsJson.fonts | ForEach-Object { $_.folderName }

    return $fontNames
}

function DownloadAndInstallFont {
    param(
        [Parameter(Mandatory=$true)]
        [string]$fontName
    )
    $url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/{0}.zip" -f $fontName
    $LocalAppData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)
    $DestinationFolder = Join-Path -Path $LocalAppData -ChildPath "Microsoft\Windows\Fonts\$fontName"
    $Temp = $env:TEMP

    # Create the destination folder if it doesn't exist
    if (-not (Test-Path $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
    }

    try {
            Write-Host "Downloading $fontName..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $url -OutFile "$Temp\$fontName.zip"

            Write-Host "Extracting $fontName..." -ForegroundColor DarkCyan
            Expand-Archive -Path "$Temp\$fontName.zip" -DestinationPath $DestinationFolder -Force

            $fontFiles = Get-ChildItem -Path $DestinationFolder -Include '*.ttf', '*.otf' -Recurse
            $fileCount = $fontFiles.Count
            $counter = 1
            foreach ($file in $fontFiles) {
                $fontFilePath = $file.FullName
                $fontFileName = $file.Name
                
                # Register the font for the current user by adding it to the registry
                $fontsRegPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
                $null = Set-ItemProperty -Path $fontsRegPath -Name $fontFileName -Value $fontFilePath
                Write-Host "-Installed ($counter/$fileCount)" -ForegroundColor White
                Start-Sleep -Milliseconds 100
                $counter++
            }
            Remove-Item -Path "$Temp\$fontName.zip" -Force
    } catch {
        Write-Error "An error occurred: $_"
    }
}

$fonts = GetNerdFonts

if ($fonts.Count -lt 1){
    Write-Host "Unable to retrieve fonts from source." -ForegroundColor Red
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Nerd Fonts Installer'
$form.Size = New-Object System.Drawing.Size(300,360)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,280)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Install'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,280)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Select the fonts to be installed'
$form.Controls.Add($label)


$CheckListBox = New-Object System.Windows.Forms.CheckedListBox
$CheckListBox.Location = New-Object System.Drawing.Point(10,40)
$CheckListBox.Size = New-Object System.Drawing.Size(260,220) 
$CheckListBox.CheckOnClick = $true

[void]$CheckListBox.Items.Add("Select all")

foreach ($font in GetNerdFonts) {
    [void]$CheckListBox.Items.Add($font)
}

# Handle the ItemCheck event to select or deselect all items
$CheckListBox.add_ItemCheck({
    param($eventSender, $e)
    if ($e.Index -eq 0) { # Check if the "Select all" checkbox is toggled
        $isChecked = $e.NewValue -eq [System.Windows.Forms.CheckState]::Checked
        for ($i = 1; $i -lt $eventSender.Items.Count; $i++) {
            $eventSender.SetItemChecked($i, $isChecked)
        }
    }
})

$form.Controls.Add($CheckListBox)
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    foreach ($checkbox in $CheckListBox.CheckedItems) {
        if($checkbox -ne 'Select All'){
            DownloadAndInstallFont $checkbox
        }
        
    }
}
$form.Dispose()