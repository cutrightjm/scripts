
Get-VIServer -server bimag1vcenter
get-vm | where {$_.PowerState -eq "PoweredOn"} | select-object Name > "C:\Temp\hosts.txt"

get-content C:\Temp\hosts.txt |
    select -Skip 3 |
    set-content "temp.txt"
move "temp.txt" C:\Temp\hosts.txt -Force

$lines = get-content C:\temp\hosts.txt

foreach ($server in $lines) {
    $server = $server.Trim()
    echo "$server - working..."
    Get-VM $server | Get-AdvancedSetting | Select-Object Entity, Name, Value | Sort-Object Name | Export-CSV "C:\temp\CSV\$server.csv"
}
del "C:\Temp\hosts.txt"
