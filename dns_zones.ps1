<# RiiConnect24 DNS-Server https://github.com/RiiConnect24/DNS-Server
PowerShell script updates dns_zones-hosts.txt file from dns_zones.json file.
Generates two files to replace: https://raw.githubusercontent.com/RiiConnect24/DNS-Server/master/dns_zones-hosts.txt
First uses IP address in json file. Second uses domains in json file and looks up IP addresses from RC24 DNS server.
#>

# Set variables.
$date = Get-Date -Format "yyyy-MMMM-dd"
$header = "! Title: RiiConnect24/Wiimmfi List for Users of AdGuard Home and Pi-Hole`n! Version: $date"
$DNSjson = "https://raw.githubusercontent.com/RiiConnect24/DNS-Server/master/dns_zones.json"
$new_converted = "dns_zones-hosts.txt"
$new_verified = "dns_zones-hosts(verified).txt"
$RC24DNS = "164.132.44.106"

# Converts json format to array.
$dns_zones = (New-Object System.Net.WebClient).DownloadString($DNSjson) | ConvertFrom-Json

# Recreates hosts file from latest json file.
Out-File $new_converted -InputObject $header 
Out-File $new_converted -Append -InputObject "! Converted from https://raw.githubusercontent.com/RiiConnect24/DNS-Server/master/dns_zones.json"
$dns_zones | ForEach-Object {
    $_.value, $_.name -join ' ' | Out-File $new_converted -Append
}

# Verifies DNS records
Out-File $new_verified -InputObject $header
Out-File $new_verified -Append -InputObject "! Verified DNS lookup from RiiConnect24 DNS server $RC24DNS"
$dns_zones | ForEach-Object {
    $VerifiedIP = Resolve-DnsName -Name $_.name -DnsOnly -Server $RC24DNS
    if ($VerifiedIP.IP4Address -eq $null) {
        Write-Host "RiiConnect24 DNS server $RC24DNS does not have an IP address for", $_.name -ForegroundColor Red
        $TestIP = Resolve-DnsName -Name $_.name -DnsOnly -Server 1.1.1.1
        if ($TestIP.IP4Address -eq $null) { Write-Host "CloudFlare DNS server 1.1.1.1 confirms domain is unknown." }
        else { Write-Host "CloudFlare DNS server 1.1.1.1 reports IP address as", $TestIP.IP4Address -join ' ' }
    }
    else { $VerifiedIP.IP4Address, $_.name -join ' ' | Out-File $new_verified -Append }
}
