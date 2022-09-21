[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$false)]
    [System.String]
    $database,
    [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$false)]
    [System.String]
    $server,
    [Parameter(Mandatory=$True, Position=2, ValueFromPipeline=$false)]
    [System.String]
    $SourceControlDirectory,
    [Parameter(Mandatory=$True, Position=3, ValueFromPipeline=$false)]
    [System.String]
    $logDirectory
)

$logName = 'SQL-Schema-Restore-'
$logFileName = $logName + (Get-Date -f yyyy-MM-dd-HH-mm) + ".log"
$logFullPath =  Join-Path $logDirectory $logFileName
$logFileLimit = (Get-Date).AddDays(-15)

if(Get-Module -ListAvailable -name dbatools)
{
    Import-Module -Name dbatools
} else 
{
    try 
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to install dbatools as it is not present on this system."
        Install-Module dbatools -Confirm $false
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - DbaTools has now been installed."
    }
    catch {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $_"
    }
}

$svr = Connect-dbaInstance -SqlInstance $server

$databaseCheck = Get-DbaDatabase -SqlInstance $svr -Database $database | Select-Object Name

if(-eq $null $databaseCheck)
{    
    New-DbaDatabase -SqlInstance $svr -Database $database
} else {
    Rename-DbaDatabase -SqlInstance $svr -Database $database -DatabaseName $database + "_Old"
    New-DbaDatabase -SqlInstance $svr -Database $database
}

try {
    Add-Content -Path $logFullPath -Value "$(Get-Date -f "yyyy-MM-dd-HH-mm") - Attempting to delete old log files"
    Get-ChildItem -Path $logFullPath -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $logFileLimit } | Remove-Item -Force
    Add-Content -Path $logFullPath -Value "$(Get-Date -f "yyyy-MM-dd-HH-mm") - Old log files deleted"

}
catch {
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to delete old log files from '$logFullPath'. The Error was: $_"
}

if(-Not(Test-Path -Path $logFullPath -PathType Leaf))
{
    try 
    {
        $null =  New-Item -ItemType File -Path $logFullPath -Force -ErrorAction Stop
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - The log file '$logFileName' has been created"
    }
    catch 
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to log file in '$logFullPath'. The Error was: $_"
    }
}

$SourceControlDirectory = $SourceControlDirectory + '\'
$tablePath = $SourceControlDirectory + 'Tables'
$storedProcedurePath = $SourceControlDirectory + 'StoredProcedures'
$viewPath = $SourceControlDirectory + 'Views'

if(-Not(Test-Path -Path $tablePath -PathType Leaf))
{
    break
}
if(-Not(Test-Path -Path $viewPath -PathType Leaf))
{
    break
}
if(-Not(Test-Path -Path $storedProcedurePath -PathType Leaf))
{
    break
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - The log file '$logFileName' has been created"
$tables = get-childitem $tablePath –Filter *.sql | sort-object Name
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $_"

foreach ($table in $tables) 
{
    try {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - The log file '$logFileName' has been created"        
        Invoke-DbaQuery –SqlInstance $svr –File $table.FullName –Database $database
    } catch 
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $_"
    }
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - The log file '$logFileName' has been created"
$views = get-childitem $viewPath –Filter *.sql | sort-object Name
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $_"

foreach ($view in $views) 
{
    try {

        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - The log file '$logFileName' has been created"
        Invoke-DbaQuery –SqlInstance $svr –File $view.FullName –Database $database
    } catch
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $_"
    }
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - The log file '$logFileName' has been created"
$storedProcedures = get-childitem $storedProcedurePath –Filter *.sql | sort-object Name
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $_"

foreach ($storedProcedure in $storedProcedures) 
{
    try {         

        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore Stored Procedure"
        Invoke-DbaQuery –SqlInstance $svr –File $storedProcedure.FullName –Database $database

    } catch
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $_"
    }
}