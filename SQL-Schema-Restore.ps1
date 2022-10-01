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
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to install dbatools. The Error was: $error"
    }
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Restore was run by $env:username."
Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Restoring schema for $database to $server from $SourceControlDirectory."

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to connect to $server."
$svr = Connect-dbaInstance -SqlInstance $server

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Checking existance of $database."
$databaseCheck = Get-DbaDatabase -SqlInstance $svr -Database $database | Select-Object Name

if(!$databaseCheck)
{    
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Creating a new instance of $database."
    New-DbaDatabase -SqlInstance $svr -Database $database
} else {

    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $database already exists, Attempting to drop $database."
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
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to delete old log files from '$logFullPath'. The Error was: $error"
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
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to log file in '$logFullPath'. The Error was: $error"
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

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get table files"

if(Test-Path -LiteralPath $tablePath -PathType Container)
{
    $tableTotal = get-childitem $tablePath –Filter *.sql | Measure-Object | ForEach-Object{$_.Count}  

    if($tableTotal -ne 0)
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $tableTotal files found in $tablePath"

        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Getting a count of files from $tablePath"

        $tables = get-childitem $tablePath –Filter *.sql | sort-object Name

        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Getting a list of files from $tablePath"

        foreach ($table in $tables) 
        {            
            $tableFullName = $table.FullName

            Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Checking to make sure $tableFullName is not empty"

            if((([IO.File]::ReadAllText($table)) -match '\S') -eq $True)
            {
                try {
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore $table"        
                    Invoke-DbaQuery –SqlInstance $svr –File $table.FullName –Database $database
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Restored $table"  

                } catch 
                {
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Restoring $table failed. The Error was: $error_"
                }
            } else {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $table is empty, no need to restore."
            }
        }
    } else {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $tablePath exists, but no files were found skipping"
    }
} else {
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $tablePath doesn't exist, skipping"
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get View Files"

if(Test-Path -LiteralPath $viewPath -PathType Container)
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Getting a count of files from $viewPath"

    $viewTotal = get-childitem $viewPath –Filter *.sql | Measure-Object | ForEach-Object{$_.Count} 

    if($viewTotal -ne 0)
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $viewTotal files found in $viewPath"

        $views = get-childitem $viewPath –Filter *.sql | sort-object Name

        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) -  Attempting to get view files from $viewPath"

        foreach ($view in $views) 
        {
            $viewFullName = $view.FullName
            
            Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Checking to make sure $viewFullName is not empty"

            if((([IO.File]::ReadAllText($view)) -match '\S') -eq $True)
            {
                try {

                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore $view"
                    Invoke-DbaQuery –SqlInstance $svr –File $view.FullName –Database $database
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Restored $view"

                } catch
                {
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to restore $view. The Error was: $error"
                }
            }
            else {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $view is empty, no need to restore."
            }
        }
    } else {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $viewPath exists, but no files were found skipping"
    }
} else {
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $viewPath doesn't exist, skipping"
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get Stored Procedure Files"

if(Test-Path -LiteralPath $storedProcedurePath -PathType Container)
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Getting a count of files from $storedProcedurePath"

    $procTotal = get-childitem $storedProcedurePath –Filter *.sql | Measure-Object | ForEach-Object{$_.Count} 

    if($procTotal -ne 0)
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $procTotal files found in $storedProcedurePath"

        $storedProcedures = get-childitem $storedProcedurePath –Filter *.sql | sort-object Name

        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get Stored Procedures from $storedProcedures"

        foreach ($storedProcedure in $storedProcedures) 
        {
            $storedProcedureFullname = $storedProcedure.FullName
            
            Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Checking to make sure $storedProcedureFullname is not empty"

            if((([IO.File]::ReadAllText($storedProcedure)) -match '\S') -eq $True)
            {
                try {         

                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore Stored Procedure $storedProcedure"
                    Invoke-DbaQuery –SqlInstance $svr –File $storedProcedure.FullName –Database $database
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Restored Stored Procedure $storedProcedure"

                } catch
                {
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to restore Stored Procedure $storedProcedure. The Error was: $error"
                }
            }
            else {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $storedProcedure is empty, no need to restore."
            }
        }
    } else {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $storedProcedurePath exists, but no files were found skipping"
    }
} else {
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $storedProcedurePath doesn't exist, skipping"
}

Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get constraint files"

if(Test-Path -LiteralPath $constraintPath -PathType Container)
{
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Getting a count of files from $constraintPath"

    $constraintTotal = get-childitem $constraintPath –Filter *.sql | Measure-Object | ForEach-Object{$_.Count} 

    if($constraintTotal -ne 0)
    {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $constraintTotal files found in $constraintPath"

        $constraints = get-childitem $constraintPath –Filter *.sql | sort-object Name

        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to get constraints from $constraintPath"

        foreach ($constraint in $constraints) 
        {
            $constraintFullname = $constraint.FullName
            
            Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Checking to make sure $constraintFullname is not empty"

            if((([IO.File]::ReadAllText($constraint)) -match '\S') -eq $True)
            {
                try {         

                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Attempting to restore Constraints from $constraint"
                    Invoke-DbaQuery –SqlInstance $svr –File $constraint.FullName –Database $database
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Restored Constraints from $constraint"

                } catch
                {
                    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - Unable to restore constraint $constraint. The Error was: $error"
                }
            }
            else {
                Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $constraint is empty, no need to restore."
            }
        }
    } else {
        Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $constraintPath exists, but no files were found skipping"
    }
} else {
    Add-Content -Path $logFullPath -Value "$(Get-Date -f yyyy-MM-dd-HH-mm) - $constraintPath doesn't exist, skipping"
}

Write-Host -Message "$(Get-Date -f yyyy-MM-dd-HH-mm) - Script Finished" -ForegroundColor Green