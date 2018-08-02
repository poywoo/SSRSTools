# SSRSTools
PowerShell functions for SQL Server Reporting Services

## Summary
The PowerShell functions in the SSRSTools/Functions folder are designed to be flexible for scripting and deployment of reports to a report server. There are dependencies between the scripts which are summarized below. The . source references will have to be modified with the correct local path. The default target Report Server Web Service endpoint is 2010 for SQL Server 2008 and above, but the parameter may be changed.

## Commands

| Function      | Description   | References    |
| ------------- | ------------- | ------------- |
| Add-RsReport  | Uploads an .rdl report file to a SQL Report Server | Create-RsWebServiceProxy |
| Create-RsWebServiceProxy | Creates a web service proxy object to the reporting services soap endpoint, with default credentials | none |
| Delete-RsReport | Deletes an .rdl report file from SQL Report Server | Create-RsWebServiceProxy |
| Get-RsReports | Lists all reports in a SQL Reporting Server folder | Create-RsWebServiceProxy |
| Sync-RsFolder | Compares and syncs a folder on SQL Report Server to a local folder | Create-RsWebServiceProxy, Add-RsReport, Delete-RsReport |

## Examples
Assume they are saved in C:\PowerShell\SSRSTools

**Example 1:** Create a web service proxy and uses it to add DailyOperationsSummary report to the Client Reports folder on report server
```
# . source
. C:\PowerShell\SSRSTools\Create-RsWebServiceProxy.ps1
. C:\PowerShell\SSRSTools\Add-RsReport.ps1

$proxy = Create-RsWebServiceProxy -ReportServerUri "http://servername:8080/ReportServer"
Add-RsReport -rdlFilePath "C:\SSRS Reports\Client Reports\DailyOperationsSummary.rdl" -RsFolder "Client Reports" -SSRSProxy $proxy

```

**Example 2:** Sync Client Reports folder on report server to local reports in C:\SSRS Reports\Client Reports
```
# . source
. C:\PowerShell\SSRSTools\Sync-RsFolder.ps1

# declare variables
$LocalFolderPath = "C:\SSRS Reports\Client Reports"
$RsFolder = "Client Reports"
$ReportServerUri = "http://servername:8080/ReportServer"

Sync-RsFolder -ReportFolderPath $LocalFolderPath -RsFolder $RsFolder -ReportServerUri $ReportServerUri
```

