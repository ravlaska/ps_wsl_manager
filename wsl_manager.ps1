# Forcing the admin rights
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
# [console]::WindowHeight = 25;[console]::WindowWidth = 105
# [console]::BufferHeight = 25;[console]::BufferWidth = 105
# [console]::Title = "WSL Creator";[Console]::CursorVisible = $false
# [console]::WindowHeight = 25;[console]::WindowWidth = 105

# Installing / Updating WSL
function WSL-Update {
    Clear-Host
    "Installing / Updating the WSL with Ubuntu..."
    wsl --update
    Start-Sleep -Seconds 3
}
# Checking if WSL & Distros are installed
function WSL-Checker {
    wsl --version | out-null
    $global:is_wsl_installed = $LastExitCode
    wsl -l -v | out-null
    $global:is_any_distro = $LastExitCode
}

function Script-Creator($NEW_USER) {
@"
#!/bin/bash
useradd -m -G sudo -s /bin/bash $NEW_USER
passwd '$NEW_USER'
echo -e '[user]\ndefault'"=$NEW_USER" > /etc/wsl.conf
# echo 'default=$NEW_USER' >> /etc/wsl.conf
"@ | Out-File -FilePath "temp_script.sh"
}

# Checking the WSL & Distros
WSL-Checker
if ($is_wsl_installed -ne 0){
    while($true){
        Clear-Host
        Write-Host "You do not have the WSL installed."
        $doinstallwsl = Read-Host "Do you want to install / update the WSL? (y/n)"
        if ($doinstallwsl -eq 'y'){
            WSL-Update
            break
        }
        if ($doinstallwsl -eq 'n'){
            Write-Host "You need to have the WSL installed to continue. Quitting the script..."
            Start-Sleep -Seconds 2
            exit
        }
        else {
            Write-Host "Please provide valid parameter!"
            Start-Sleep -Seconds 2
        }
    }
}
# Checking the WSL & Distros
if ($is_wsl_installed -eq '0'){
    # Main loop
    while($true){
        WSL-Checker
        Clear-Host
        # Printing WSL version
        wsl -v | Select-Object -First 1
        Write-Host "`n"

        if ($is_any_distro -eq '0'){
            Write-Host "You have these distros installed:"
            wsl -l -v
            Write-Host "`n"
        }
        else {
            Write-Host "You do not have any distros installed right now."
            Write-Host "`n"
        }
        # Printing proper menu's and returning option selected
        Write-Host "Available options:"
        Write-Host "0. Update the WSL"
        Write-Host "1. Install first-default WSL distro"
        Write-Host "2. Install another WSL distro"
        Write-Host "3. Clone WSL distro"
        Write-Host "4. Remove specified WSL"
        Write-Host "5. Select the default distro"
        Write-Host "Q - Quit"
        $menu = Read-Host "Choose an option"

        # Updating the WSL
        if ($menu -eq '0'){
            Write-Host "Updating the WSL..."
            WSL-Update
        }
        # Installing default image
        if ($menu -eq '1') {
            if ($is_any_distro -ne '0'){
                Clear-Host
                wsl --list --online
                $image_to_install = Read-Host "`nProvide the name of the image to install"
                wsl --install -d $image_to_install
                Start-Sleep -Seconds 3
            }
            if ($is_any_distro -eq '0'){
                Write-Host "`nYou cannot install another default image."
                Start-Sleep -Seconds 2
            }
        }
        # Installing another images
        if ($menu -eq '2') {
            # Loop with image options
            while($true){
                Clear-Host
                Write-Host "The default image to use is Ubuntu [Jammy].`nYou can also provide link to another WSL image."
                $image_menu = Read-Host "Default image (d) / Custom image link (l)"
                # Default Ubuntu
                if ($image_menu -eq 'd'){
                    $image_url = 'https://cloud-images.ubuntu.com/wsl/jammy/current/ubuntu-jammy-wsl-amd64-wsl.rootfs.tar.gz'
                    break
                }
                # Custom image
                if ($image_menu -eq 'l'){
                    $image_url = Read-Host "Paste the link to the WSL image (*.tar.gz)"
                    break
                }
                # Option check
                else {
                    Write-Host "`nPlease choose the proper option!"
                    Start-Sleep -Seconds 2
                }
            }
            # Importing the image to WSL
            Clear-Host
            Write-Host "Downloading the WSL image..."
            Start-BitsTransfer -Source $image_url -Destination wsl_image.tar.gz
            $name = Read-Host "Choose name of the new distro"
            $path = Read-Host "Choose path to install the $name distro (for example: C:\ubuntu-distro)"
            Write-Host "Importing the image..."
            wsl --import $name "$path" wsl_image.tar.gz
            rm wsl_image.tar.gz
            Write-Host "`n`nConfiguring default account in the $name distro: "
            $NEW_USER = Read-Host "Provide username"
            Script-Creator $NEW_USER # Create and run script for username configuration
            $handle_script = Get-Content -Raw ./temp_script.sh
            wsl -d $name bash -c ($handle_script -replace '"', '\"')
            Write-Host "Username $NEW_USER configured and set as default user. Restarting $name WSL. . ."
            wsl --terminate $name
            rm "temp_script.sh"
            Start-Sleep -Seconds 2
        }
        if ($menu -eq '3'){
            if ($is_any_distro -eq '0'){
                $to_clone = Read-Host "`nSelect the distro to clone (provide a name)"
                $clone_name = Read-Host "Provide name of the new, cloned distro"
                $clone_path = Read-Host "Choose path to install the $clone_name distro"
                Write-Host "Exporting the $to_clone image..."
                wsl --export $to_clone image_to_clone.tar
                Write-Host "Importing the $to_clone image as $clone_name..."
                wsl --import $clone_name "$clone_path" image_to_clone.tar
                rm image_to_clone.tar
                Start-Sleep -Seconds 3
            }
            if ($is_any_distro -ne '0'){
                Write-Host "`nYou do not have any distros installed."
                Start-Sleep -Seconds 2
            }
        }
        if ($menu -eq '4'){
            if ($is_any_distro -eq '0'){
                $to_remove = Read-Host "`nSelect the distro to remove (provide a name)"
                wsl --unregister $to_remove
                Start-Sleep -Seconds 3
            }
            if ($is_any_distro -ne '0'){
                Write-Host "`nYou do not have any distros installed."
                Start-Sleep -Seconds 2
            }
        }
        if ($menu -eq '5'){
            if ($is_any_distro -eq '0'){
                $def_distro = Read-Host "`nSelect the default distro to set"
                wsl --setdefault $def_distro
                Start-Sleep -Seconds 3
            }
            if ($is_any_distro -ne '0'){
                Write-Host "`nYou do not have any distros installed."
                Start-Sleep -Seconds 2
            }
        }
        if ($menu -eq 'q'){
            Write-Host "`nSee you :)"
            Start-Sleep -Seconds 1
            Clear-Host
            exit
        }
        if ($menu -notin @('0', '1', '2', '3', '4', '5', 'q')) {
            Write-Host "`nPlease select valid option!"
            Start-Sleep -Seconds 2
        }
    }
}
