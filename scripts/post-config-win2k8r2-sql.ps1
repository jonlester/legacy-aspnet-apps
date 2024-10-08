function DownloadAndExpand
{
    param
    (
        [string]$AppName
    )

    Invoke-WebRequest "https://github.com/jonlester/legacy-aspnet-apps/releases/download/dummy-release/$AppName.zip" -OutFile "$AppName.zip"
    Expand-Archive -Path "$AppName.zip" -DestinationPath "C:\Apps\$AppName"
    ((Get-Content -path C:\Apps\$AppName\web.config -Raw) -replace '<sqlServerName>.appmig.local',$env:computername) | Set-Content -Path C:\Apps\$AppName\web.config
   
    Write-Output "Downloaded the $AppName web app" 
}

#first update the tls level for this session, this is needed because 2008r2 defaults to TLS1.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#update the execution policy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

#install chocolatey to do some of the heavy lifting
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

#upgrade dot net (4.5.2)
choco install dotnetinstaller

#upgrade powershell (5.1)
choco install powershell -Force 

#create user for the service account
net user AppsSvcAcct password1234! /ADD
c:\Windows\Microsoft.NET\Framework\v2.0.50727\aspnet_regiis.exe -ga ${env:computername}\AppsSvcAcct

#install databases
mkdir c:\Databases
SQLCMD -E -S ${env:computername} -Q "CREATE LOGIN [${env:computername}\AppsSvcAcct] FROM WINDOWS"

Invoke-WebRequest "https://github.com/jonlester/legacy-aspnet-apps/releases/download/dummy-release/TimeTracker.bak" -OutFile "c:\databases\timetracker.bak"
SQLCMD -E -S ${env:computername} -Q "RESTORE DATABASE [TimeTracker] FROM DISK='C:\Databases\timetracker.bak' WITH MOVE 'tempname' TO 'C:\Databases\timetracker.mdf', MOVE 'TimeTracker_Log' TO 'C:\Databases\timetracker_log.ldf'"

Invoke-WebRequest "https://github.com/jonlester/legacy-aspnet-apps/releases/download/dummy-release/Classifieds.bak" -OutFile "c:\databases\Classifieds.bak"
SQLCMD -E -S ${env:computername} -Q "RESTORE DATABASE [Classifieds] FROM DISK='C:\Databases\Classifieds.bak' WITH MOVE 'Database' TO 'C:\Databases\classifieds.mdf', MOVE 'Database_log' TO 'C:\Databases\classifieds_log.ldf'"

Invoke-WebRequest "https://github.com/jonlester/legacy-aspnet-apps/releases/download/dummy-release/Jobs.bak" -OutFile "c:\databases\Jobs.bak"
SQLCMD -E -S ${env:computername} -Q "RESTORE DATABASE [Jobs] FROM DISK='C:\Databases\Jobs.bak' WITH MOVE 'EmptyDatabase' TO 'C:\Databases\jobs.mdf', MOVE 'EmptyDatabase_log' TO 'C:\Databases\jobs_log.ldf'"

SQLCMD -E -S ${env:computername} -Q "USE timetracker; CREATE USER [${env:computername}\AppsSvcAcct]; EXEC sp_addrolemember 'db_owner', '${env:computername}\AppsSvcAcct'"
SQLCMD -E -S ${env:computername} -Q "USE classifieds; CREATE USER [${env:computername}\AppsSvcAcct]; EXEC sp_addrolemember 'db_owner', 'APP${env:computername}\AppsSvcAcct'"
SQLCMD -E -S ${env:computername} -Q "USE jobs; CREATE USER [${env:computername}\AppsSvcAcct]; EXEC sp_addrolemember 'db_owner', '${env:computername}\AppsSvcAcct'"

SQLCMD -E -S ${env:computername} -Q "USE timetracker; EXEC sp_addrolemember 'db_owner', '${env:computername}\AppsSvcAcct'"
SQLCMD -E -S ${env:computername} -Q "USE classifieds; CREATE USER [${env:computername}\AppsSvcAcct]; EXEC sp_addrolemember 'db_owner', 'APP${env:computername}\AppsSvcAcct'"
SQLCMD -E -S ${env:computername} -Q "USE jobs; CREATE USER [${env:computername}\AppsSvcAcct]; EXEC sp_addrolemember 'db_owner', '${env:computername}\AppsSvcAcct'"


#ensure web server feature is enabled
Add-WindowsFeature -Name Web-Server -IncludeAllSubFeature

#install the "old" web apps from the app migration workshop
c:\windows\system32\inetsrv\appcmd delete site "Default Web Site"

DownloadAndExpand -AppName "TimeTracker"
c:\windows\system32\inetsrv\APPCMD add apppool /name:"TimeTrackerAppPool" /managedPipelineMode:"Integrated"
c:\windows\system32\inetsrv\APPCMD add site /name:TimeTracker /id:1 /bindings:http://${env:computername}:8083 /physicalPath:C:\Apps\TimeTracker
c:\windows\system32\inetsrv\APPCMD set site TimeTracker "/[path='/'].applicationPool:TimeTrackerAppPool"

DownloadAndExpand -AppName "Classifieds"
c:\windows\system32\inetsrv\APPCMD add apppool /name:"ClassifiedsAppPool" /managedPipelineMode:"Classic"
c:\windows\system32\inetsrv\APPCMD add site /name:Classifieds /id:2 /bindings:http://${env:computername}:8081 /physicalPath:C:\Apps\Classifieds
c:\windows\system32\inetsrv\APPCMD set site Classifieds "/[path='/'].applicationPool:ClassifiedsAppPool"

DownloadAndExpand -AppName "Jobs"
c:\windows\system32\inetsrv\APPCMD add apppool /name:"JobsAppPool" /managedPipelineMode:"Integrated"
c:\windows\system32\inetsrv\APPCMD add site /name:Jobs /id:3 /bindings:http://${env:computername}.com:8082 /physicalPath:C:\Apps\Jobs
c:\windows\system32\inetsrv\APPCMD set site Jobs "/[path='/'].applicationPool:JobsAppPool"

c:\windows\system32\inetsrv\appcmd set config /section:applicationPools "/[name='TimeTrackerAppPool'].processModel.identityType:SpecificUser" "/[name='TimeTrackerAppPool'].processModel.userName:${env:computername}\AppsSvcAcct" "/[name='TimeTrackerAppPool'].processModel.password:password1234!"
c:\windows\system32\inetsrv\appcmd set config /section:applicationPools "/[name='ClassifiedsAppPool'].processModel.identityType:SpecificUser" "/[name='ClassifiedsAppPool'].processModel.userName:${env:computername}\AppsSvcAcct" "/[name='ClassifiedsAppPool'].processModel.password:password1234!"
c:\windows\system32\inetsrv\appcmd set config /section:applicationPools "/[name='JobsAppPool'].processModel.identityType:SpecificUser" "/[name='JobsAppPool'].processModel.userName:${env:computername}\AppsSvcAcct" "/[name='JobsAppPool'].processModel.password:password1234!"

#finally reboot
Restart-Computer -Force
