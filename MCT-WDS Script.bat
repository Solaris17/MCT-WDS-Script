@echo off
SET build=1.3
title MCT + WDS update tool (BETA) v%BUILD%

:: Lets set our variables, always set them before work blocks.
:: These are the public GVLK keys (https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys)
:: We use these to push to the MCT so it downloads the correct ISO for us to manipulate. It wont activate anything, we just use this so the MCT calls the correct ISO for us instead of hardlinking, which breaks a lot.
set homekey=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99
set entkey=NPPR9-FWDCX-D2C8J-H872K-2YT43

:checkPrivileges
:: Check for Admin by accessing protected stuff. This calls net(#).exe and can stall if we don't kill it later.
NET FILE 1>nul 2>&1 2>nul 2>&1
if '%errorlevel%' == '0' ( goto ask) else ( goto getPrivileges ) 

:getPrivileges
:: Write vbs in temp to call batch as admin.
if '%1'=='ELEV' (shift & goto ask)                               
for /f "delims=: tokens=*" %%A in ('findstr /b ::- "%~f0"') do @echo(%%A
setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs" 
echo UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs" 
"%temp%\OEgetPrivileges.vbs" 
exit /B

:ask
echo.
echo Hello, we are going to download the MCT.
echo.
echo This only works on Windows 10/11 and maybe 8? and Server 2012+
echo.
echo After we are going to mount and pull the boot wim and the install esd.
echo.
echo Then we are going to list the editions we can get and convert to wim for WDS.
echo.
echo Exit or press anykey to begin.
echo.
pause
echo.

:start
cls
echo.
echo Awesome, Which MCT would you like to download?
echo.
echo This will get saved in c:\mct I will work in this directory then delete everything during cleanup.
echo.
echo 1 = Windows 11
echo.
echo 2 = Windows 10
set choice=
echo.
set /p choice=
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto win11
if '%choice%'=='2' goto win10
goto choicewarn

:win11
set ver=Win11
cls
echo.
echo Perfect, Making the directory and downloading the MCT (Windows 11).
echo.
mkdir c:\mct >nul 2>&1
:: If the MCT version changes just change the link I tried making the link a variable but traditional bits admin get hella mad about that.
:: Source: https://www.microsoft.com/software-download/windows11
bitsadmin /transfer MCT /download /priority FOREGROUND https://software-static.download.prss.microsoft.com/dbazure/988969d5-f34g-4e03-ac9d-1f9786c66749/mediacreationtool.exe "c:\mct\mct.exe" >nul 2>&1
echo Done!
echo.
echo What version do you want to work with?
echo.
echo 1 = Home/Pro/Edu
echo.
echo 2 = Enterprise
echo.
set /p choice=
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto mcthome
if '%choice%'=='2' goto mctent
goto choicewarn


:win10
set ver=Win10
cls
echo.
echo Perfect, Making the directory and downloading the MCT (Windows 10).
echo.
mkdir c:\mct >nul 2>&1
:: If the MCT version changes just change the link I tried making the link a variable but traditional bits admin get hella mad about that.
:: Source: https://www.microsoft.com/en-us/software-download/windows10
bitsadmin /transfer MCT /download /priority FOREGROUND https://download.microsoft.com/download/9/e/a/9eac306f-d134-4609-9c58-35d1638c2363/MediaCreationTool22H2.exe "c:\mct\mct.exe" >nul 2>&1
echo Done!
echo.
echo What version do you want to work with?
echo.
echo 1 = Home/Pro/Edu
echo.
echo 2 = Enterprise
echo.
set /p choice=
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto mcthome
if '%choice%'=='2' goto mctent
goto choicewarn

:mcthome
cls
echo.
echo Alright, you want Home/Pro/Edu lets do stuff.
echo.
echo I am going to call MCT, I will cover as many flags as I can.
echo.
echo For Home use this key when asked. (I already copied it to your clipboard.)
echo.
echo %homekey%|clip
echo %homekey%
echo.
echo Make sure to select "ISO" (Don't rename it, leave it 'Windows')
echo.
echo Save it in "C:\mct" with the MCT executable (I created this for you already).
echo.
echo Then click "Finish"
echo.
echo This can take a long time, the tool is downloading the ISO.
echo.
call "c:\mct\mct.exe" /Eula Accept /Retail /MediaArch x64 /Download /MediaEdition Professional /Action CreateMedia
cls
echo.
echo Thanks now I'm going to mount it.
echo.
explorer "c:\mct\Windows.iso"
echo What is the drive letter? (Dont put dots just the letter e,d,f etc. It is not case sensitive.)
echo.
set /p dltr=""
echo.
echo Thanks, I'm doing some file copies.
echo.
echo f | xcopy "%dltr%:\sources\boot.wim" "c:\mct\boot.wim" /y >nul 2>&1
echo f | xcopy "%dltr%:\sources\install.esd" "c:\mct\install.esd" /y >nul 2>&1
powershell -Command "& {Dismount-DiskImage -ImagePath "c:\mct\Windows.iso"}" >nul 2>&1
echo I dismounted the ISO for you, now its time to convert.
echo.
echo This will list the versions in this esd. Please choose only one for now.
echo.
pause
echo.
dism /Get-WimInfo /WimFile:c:\mct\install.esd
echo.
echo Please enter the "Index Number" of the image you want me to pull out.
echo.
set /p indexnum=""
echo.
echo Now tell me the version name. Like was it Home, Pro etc?
echo.
set /p indexname=""
echo.
echo Word im going to begin ripping that.
echo.
dism /export-image /SourceImageFile:c:\mct\install.esd /SourceIndex:%indexnum% /DestinationImageFile:"c:\mct\%ver%-%indexname%".wim /Compress:max /CheckIntegrity
echo.
cls
echo.
echo All done!
echo.
echo I'm going to start cleaning these files up for you.
echo.
DEL "c:\mct\install.esd" >nul 2>&1
DEL "c:\mct\Windows.iso" >nul 2>&1
DEL "c:\mct\mct.exe" >nul 2>&1
echo Done!
echo.
pause
goto done

:mctent
cls
echo.
echo Alright, you want Enterprise lets do stuff.
echo.
echo I am going to call MCT, I will cover as many flags as I can.
echo.
echo For Enterprise use this key when asked. (I already copied it to your clipboard.)
echo.
echo %entkey%|clip
echo %entkey%
echo.
echo Make sure to select "ISO" (Don't rename it, leave it 'Windows')
echo.
echo Save it in "C:\mct" with the MCT executable (I created this for you already).
echo.
echo Then click "Finish"
echo.
echo This can take a long time, the tool is downloading the ISO.
echo.
call "c:\mct\mct.exe" /Eula Accept /Retail /MediaArch x64 /Download /MediaEdition Enterprise /Action CreateMedia
cls
echo.
echo Thanks now I'm going to mount it.
echo.
explorer "c:\mct\Windows.iso"
echo What is the drive letter? (Dont put dots just the letter e,d,f etc. It is not case sensitive.)
echo.
set /p dltr=""
echo.
echo Thanks, I'm doing some file copies.
echo.
echo f | xcopy "%dltr%:\sources\boot.wim" "c:\mct\boot.wim" /y >nul 2>&1
echo f | xcopy "%dltr%:\sources\install.esd" "c:\mct\install.esd" /y >nul 2>&1
powershell -Command "& {Dismount-DiskImage -ImagePath "c:\mct\Windows.iso"}" >nul 2>&1
echo I dismounted the ISO for you, now its time to convert.
echo.
echo This will list the versions in this esd. Please choose only one for now.
echo.
pause
echo.
dism /Get-WimInfo /WimFile:c:\mct\install.esd
echo.
echo Please enter the "Index Number" of the image you want me to pull out.
echo.
set /p indexnum=""
echo.
echo Now tell me the version name. Like was it Home, Pro etc?
echo.
set /p indexname=""
echo.
echo Word im going to begin ripping that.
echo.
dism /export-image /SourceImageFile:c:\mct\install.esd /SourceIndex:%indexnum% /DestinationImageFile:"c:\mct\%ver%-%indexname%".wim /Compress:max /CheckIntegrity
echo.
cls
echo.
echo All done!
echo.
echo I'm going to start cleaning these files up for you.
echo.
DEL "c:\mct\install.esd" >nul 2>&1
DEL "c:\mct\Windows.iso" >nul 2>&1
DEL "c:\mct\mct.exe" >nul 2>&1
echo Done!
echo.
pause
goto done

:done
cls
echo.
echo Want to go again?
echo.
echo 1 = No
echo.
echo 2 = Yes
set choice=
echo.
set /p choice=
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto cleanup
if '%choice%'=='2' goto start
goto choicewarn

:cleanup
cls
echo.
echo Do you want me to delete the left over files you would normally use for WDS?
echo.
echo This will remove the directory.
echo.
echo 1 = No
echo.
echo 2 = Yes
set choice=
echo.
set /p choice=
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto exit
if '%choice%'=='2' goto end
goto choicewarn

:choicewarn
:: Key trap for selecting something out of scope.
cls
echo "Invalid Selection Please Try again..."
echo.
pause
goto done


:end
cls
echo Cleaning up.
rmdir /s /q c:\mct >nul 2>&1
echo.
echo bye!
echo.
pause
exit

:exit
cls
echo.
echo Now just import your wims into WDS!
echo.
echo bye!
echo.
exit