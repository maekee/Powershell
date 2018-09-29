#This script generates 10000 documents with swedish names and random error codes.

$Uri = "http://localhost:9200"

1..10000 | Foreach {
    $JsonBody = @{
        "@timestamp" = "{0:yyyy-MM-ddTHH:mm:ss.fffZ}" -f (Get-Date).AddHours(-2)
        "Name" = "Micke","Kalle","Peter","Jonas","Nina","Fredrik","Gunnar","Ingvar","Christian","Davor","Pia","Niklas","Sara","Lena","Lilian","Mika","Olof" | Get-Random
        "errorcode" = Get-Random -Minimum 10000 -Maximum 100000
        "Message" = "Dont do that"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri "$Uri/magicindex/_doc" -Method Post -Body $JsonBody -ContentType 'application/json' -UseBasicParsing #indexes (creates) a document
}
