# Introduction

This script uses [dbatools](https://dbatools.io/) to backup database objects from a SQL Server Database to a directory of your choosing. This script is used internally to backup our databases for GitHub.

The server & database are both user defined parameters.

## Accepted Parameters 

| Parameter | Data Type  | Mandatory |
|---|---|---|
| database | string | Yes |
| server | string | Yes |
| SourceControlDirectory | string | Yes |
| logDirectory | string | Yes |

## Getting Started

1. Clone the code to your local workstation.
2. Navigate to the directory where the script has been cloned
3. Execute the script passing in the required parameters.

### Executing the script

`.\SQL-Schema-Backup.ps1 -database 'YourDatabase' -server 'YourServer' -SourceControlDirectory 'C:\Temp\' -logDirectory 'C:\Temp\Logs'`