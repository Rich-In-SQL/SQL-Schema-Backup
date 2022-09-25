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

Function Test-FileEmpty {

    Param ([Parameter(Mandatory = $true)][string]$file)
  
    if ((Test-Path -LiteralPath $file) -and !((Get-Content -LiteralPath $file -Raw) -match '\S')) {return $true} else {return $false}
  
  }

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

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to connect to $server."
$svr = Connect-dbaInstance -SqlInstance $server

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Checking existance of $database."
$databaseCheck = Get-DbaDatabase -SqlInstance $svr -Database $database | Select-Object Name

if(!$databaseCheck)
{    
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Creating a new instance of $database."
    New-DbaDatabase -SqlInstance $svr -Database $database
} else {

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Dropping $database."
    Remove-DbaDatabase -SqlInstance $svr -Database $database -Confirm:$false

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Creating a new instance of $database."
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

Write-Host -Message "$(Get-Date -f yyyy-MM-dd-HH-mm) - Script starting" -ForegroundColor Gray
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Script starting" 

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
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Added trailing slash to $SourceControlDirectory"

$tablePath = $SourceControlDirectory + 'Tables'
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Set Constraint Path $tablePath"

$storedProcedurePath = $SourceControlDirectory + 'StoredProcedures'
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Set Constraint Path $storedProcedurePath"

$viewPath = $SourceControlDirectory + 'Views'
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Set Constraint Path $viewPath"

$constraintPath = $SourceControlDirectory + 'Constraints'
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Set Constraint Path $constraintPath"

if(-Not(Test-Path -Path $tablePath))
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $tablePath does not exist ending"
    break
}
if(-Not(Test-Path -Path $viewPath))
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $viewPath does not exist ending"
    break
}
if(-Not(Test-Path -Path $storedProcedurePath))
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $storedProcedurePath does not exist ending"
    break
}
if(-Not(Test-Path -Path $constraintPath))
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $constraintPath does not exist ending"
    break
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get table files"

$total = get-childitem $tablePath –Filter *.sql | Measure-Object | ForEach-Object{$_.Count}  

if($total -ne 0)
{
    $tables = get-childitem $tablePath –Filter *.sql | sort-object Name

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to get table files. The Error was: $_"

    foreach ($table in $tables) 
    {
        if((([IO.File]::ReadAllText($table)) -match '\S') -eq $True)
        {
            try {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore $table"        
                Invoke-DbaQuery –SqlInstance $svr –File $table.FullName –Database $database
            } catch 
            {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Restoring $table failed. The Error was: $_"
            }
        } else {
            Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $table is empty, no need to restore."
        }
    }
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get View Files"

$total = get-childitem $viewPath –Filter *.sql | Measure-Object | ForEach-Object{$_.Count} 

if($total -ne 0)
{
    $views = get-childitem $viewPath –Filter *.sql | sort-object Name

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to get view files. The Error was: $_"

    foreach ($view in $views) 
    {
        if((([IO.File]::ReadAllText($view)) -match '\S') -eq $True)
        {
            try {

                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore $view"
                Invoke-DbaQuery –SqlInstance $svr –File $view.FullName –Database $database

            } catch
            {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to restore $view. The Error was: $_"
            }
        }
        else {
            Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $view is empty, no need to restore."
        }
    }
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get Stored Procedure Files"

$total = get-childitem $storedProcedurePath –Filter *.sql | Measure-Object | ForEach-Object{$_.Count} 

if($total -ne 0)
{
    $storedProcedures = get-childitem $storedProcedurePath –Filter *.sql | sort-object Name

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to get Stored Procedure Files. The Error was: $_"

    foreach ($storedProcedure in $storedProcedures) 
    {
        if((([IO.File]::ReadAllText($storedProcedure)) -match '\S') -eq $True)
        {
            try {         

                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore Stored Procedure $storedProcedure"
                Invoke-DbaQuery –SqlInstance $svr –File $storedProcedure.FullName –Database $database

            } catch
            {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to restore Stored Procedure $storedProcedure. The Error was: $_"
            }
        }
        else {
            Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $storedProcedure is empty, no need to restore."
        }
    }
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get constraint files"

$total = get-childitem $constraintPath –Filter *.sql | Measure-Object | ForEach-Object{$_.Count} 

if($total -ne 0)
{
    $constraints = get-childitem $constraintPath –Filter *.sql | sort-object Name

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to get constraint files. The Error was: $_"

    foreach ($constraint in $constraints) 
    {
        if((([IO.File]::ReadAllText($constraint)) -match '\S') -eq $True)
        {
            try {         

                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore Constraints from $constraint"
                Invoke-DbaQuery –SqlInstance $svr –File $constraint.FullName –Database $database

            } catch
            {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to restore constraint $constraint. The Error was: $_"
            }
        }
        else {
            Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $constraint is empty, no need to restore."
        }
    }
}