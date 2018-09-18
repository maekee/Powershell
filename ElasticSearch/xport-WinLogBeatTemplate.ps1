Function Export-WinLogBeatTemplate{
    param (
        $winlogbeatpath = "C:\Elastic\Winlogbeat\winlogbeat.exe",
        $winlogbeatversion = "6.4.0",
        $OutFile = "C:\Temp\winlogbeat.template.json"
    )

    #https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-template.html
    .\winlogbeat.exe export template --es.version $($winlogbeatversion) | Out-File $($OutFile) -Encoding UTF8
}
