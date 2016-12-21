<#
Account lockout detection and notification for active directory.
.Description
This script creates monitors active directory for account lockout events and notifies an email address when an event occurs.
.How to use
You'll need to modify the 'Declare email' section to match your environment.
.Optional
Modify the write to log file section to control where the lockout event is exported to.
.Created by
Nathan Studebaker
#>

#Declare location of script. Output file will be created
$location = "C:\support\scripts"

#Declare email
$To = "recipient@mydomain.com"
$From = "myserver@mydomain.com"
$Body = "Quote:Keep your friends close, but your enemies closer. Account lockout event detected."
$Sub = "Account Lockout Event"
$CredUser = "myuser"
$CredPass = "mypassword" | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.Pscredential -Argumentlist $CredUser,$CredPass
$Attachments = "$location\LockedEvents.csv"
$SmtpServer = "smtp.mailserver.com"
$Port = "25" #Should be port 25 or 587 depending on the setup

#Checks for locked out accounts, event id 4625
#Checks the last 1 hours and if found, sends email
$events = Get-WinEvent -FilterHashtable @{logname='security';id=4625;StartTime=(get-date).AddHours(-1.0)} | Select-Object -Property "TimeCreated", 
@{label='TargetUserName';expression={$_.properties[5].value}}, 
@{label='TargetDomainName';expression={$_.properties[6].value}}

#Convert events to a number using measure object and select object
$eventcount = $events | Measure-Object | Select-Object -Property Count

#If more than one lockout is found, send email
If ($eventcount.count -ge 1) {
#Write to logfile
$events | Export-Csv $location\LockedEvents.csv -Append
#Send email alert
Send-MailMessage -To $To -From $From -Body $Body -Subject $Sub -Credential $Credentials -SmtpServer $smtpServer -Port $Port -Attachments $Attachments
}

Exit