<#  Get-IPGeoLoc.ps1
           .SYNOPSIS 
           (Version 1.1)
           Lookup all users for the specified IPs with MaxMind Geolocation with local databases.
           Additionally, if a user is a STAFF member also from ipinfo.io website.
           Returns GeoLocation Information 

           .DESCRIPTION
           Returns GeoLocation Information from MaxMind Local Databases for the specified IP(s)
    
           .SETUP
             Step 0: Create folders
               new-item -Type directory c:\GeoLocate
               new-item -Type directory c:\GeoLocate\DLLs
               new-item -Type directory c:\GeoLocate\DBs

             Step 1: Download Following Packages and UNZIP them 
               1: https://www.nuget.org/packages/MaxMind.Db/	
               2: https://www.nuget.org/packages/MaxMind.GeoIP2/
               3: https://www.nuget.org/packages/Newtonsoft.Json/

             Step 2: Copy DLLs from UNZIPPED packages to DLL directory
               1: .\maxmind.db.2.4.0\lib\net45\MaxMind.Db.dll -> c:\GeoLocate\DLLs
               2: .\maxmind.geoip2.3.0.0\lib\net45\MaxMind.GeoIP2.dll -> c:\GeoLocate\DLLs
               3: .\newtonsoft.json.12.0.1\lib\net45\Newtonsoft.Json.dll -> c:\GeoLocate\DLLs
 
             Step 3: Download Databases from FREE GeoLite API
               https://dev.maxmind.com/geoip/geoip2/geolite2/#MaxMind_APIs
               Put all extracted DBs (mmdb files) in c:\GeoLocate\DBs
               Currently: City, County and ASN.

           .PARAMETER InputPath
           Specifies the path to the CSV-based input file.

           .PARAMETER OutputPath
           Specifies the name and path for the CSV-based output file. By default, 
           the output filename is the "GEO-" prepended to the supplied inputfile

           .INPUTS
           The name of a CSV File containing:
               IP addresses (Property Name / Heading) is ip.
               UserName (Property Name / Heading) is Username.

           .OUTPUTS
       
            Example of the response format is 
            ip       : 107.77.227.18
            hostname : mobile-107-77-227-18.mobile.att.net
            city     : Los Angeles
            region   : California
            country  : United States
            loc      : Location [ AccuracyRadius=500, Latitude=34.0116, Longitude=-118.3411, MetroCode=803,
                       TimeZone=America/Los_Angeles]
            ASNorg   : AT&T Mobility LLC
            ASNnum   : 20057

           .EXAMPLE
           C:\PS> .\Get-IPGeoLoc.ps1 107.77.227.18
            Returns the Geolocation of the specified IP to the terminal

           .EXAMPLE
           C:\PS> .\Get-IPGeoLocation.ps1 -inputfile IPs.csv
           Returns the Geolocation of the IPs specified in IPs.csv and writes them to GEO-IPs.csv
           (The default output appends "GEO-" to the front of the input fileName)

           .EXAMPLE
           C:\PS> .\Get-IPGeoLocation.ps1 -inputfile IPs.csv -outputPath out-IPs.csv
           Returns the Geolocation of the IPs specified in IPs.csv and writes them to out-IPs.csv
           
           .EXAMPLE
           C:\PS> .\Get-IPGeoLocation.ps1 -inputfile IPs.csv -merge
           Copies all of the input columns from the file specified in inputfile and adds columns to the end of each row with the 
           geolocation information using column names of "geo-ip","geo-city","geo-region","geo-country","geo-loc"

           .VERSION HISTORY
           1.0 Initial Release
 #>


param(
    [parameter(Position=0)][string]$ip="0.0.0.0",
    [string]$inputfile,
    [string]$inputUser="",
    [string]$outfile,
    [string]$ipcol="IP ADDRESS",
    [switch]$merge=$false      
    )

# MaxMind Setup - START
<# Load Local #>
#Paths
$GeoIpDbPath = 'c:\GeoLocate\DBs\'
$GeoIpDllPath = 'c:\GeoLocate\DLLs\'

# DLLs
$GeoIpLibrary = $GeoIpDllPath + 'MaxMind.GeoIP2.dll'
$GeoIpDbLibrary = $GeoIpDllPath + 'MaxMind.Db.dll'
$GeoIpNewtonJson = $GeoIpDllPath + 'Newtonsoft.Json.dll'

# Databases
$GeoIpAsnDb = $GeoIpDbPath + 'GeoLite2-ASN.mmdb'
$GeoIpCountryDb = $GeoIpDbPath + 'GeoLite2-Country.mmdb'
$GeoIpCityDb = $GeoIpDbPath + 'GeoLite2-City.mmdb'

[System.Reflection.Assembly]::LoadFile($GeoIpLibrary) | out-null
[System.Reflection.Assembly]::LoadFile($GeoIpDbLibrary) | out-null
[System.Reflection.Assembly]::LoadFile($GeoIpNewtonJson) | out-null

$asnReader = [MaxMind.GeoIP2.DatabaseReader]::new($GeoIpAsnDb)
$countryReader = [MaxMind.GeoIP2.DatabaseReader]::new($GeoIpCountryDb)
$cityReader = [MaxMind.GeoIP2.DatabaseReader]::new($GeoIpCityDb)

<# JSon assembly redirect Workaround because of static linking in MaxMind DLLs #>
$jsonAssembly = [reflection.assembly]::LoadFrom($GeoIpNewtonJson)
$onAssemblyResolve = [System.ResolveEventHandler] {
  param($sender, $e)
  if ($e.Name -eq "Newtonsoft.Json, Version=11.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed") { return $jsonAssembly }
  foreach($a in [System.AppDomain]::CurrentDomain.GetAssemblies()){
    if($a.FullName -eq $e.Name) { return $a } else { return $null }}
  return $null
}
[System.AppDomain]::CurrentDomain.add_AssemblyResolve($onAssemblyResolve)
# MaxMind Setup - END


<# Script Functions #>

# MaxMind Check
function LookupUserMaxMind {
  param( [String]$LUIP)
  # $LUIP = Lookup IP
  $resultCity = $cityReader.city($LUIP)
  $resultCountry = $countryReader.Country($LUIP)
  $resultASN = $asnReader.Asn($LUIP)
  # write-host "Lookup IP: $LUIP" #*DEBUG*
  $DNSHostName = $LUIP
  try {$DNSHostName = [System.Net.Dns]::gethostentry($LUIP)}
  catch{} # If no hostname result - hide error output and use IP Address
  $MMResult = [PSCustomObject]@{
    ip       = $ip
    hostname = $DNSHostName.HostName
    city     = $resultCity.City
    region   = $resultCity.MostSpecificSubdivision
    country  = $resultCountry.Country
    loc      = $resultCity.location
    ASNorg   = $resultASN.AutonomousSystemOrganization
    ASNnum   = $resultASN.AutonomousSystemNumber
  }
  return $MMResult
}

<# Script Start #>

#   Terminal Output for a single IP
#     The check on this if it no longer matches its default value of "0.0.0.0"
if ($ip -ne "0.0.0.0" -and @($ip).length -ne 0 -and $ip -ne "" -and $ip -ne $null) {
  write-host " == MaxMind Result == "
  LookupUserMaxMind $ip
} else {
  # File Output for a list of IPs
  if ($inputfile.length -eq 0) {
    write-host "-inputfile is required when not specifying a single IP address on the command line"
    exit
  } else {
    if (-not (Test-Path $inputfile)) {
      Write-Host "-inputfile specified does not exist."
      exit
    } 
  }

  if ($outfile.Length -eq 0) {
    $outfile =  (Split-Path $inputfile) +"\GEO-" + (Split-Path $inputfile -leaf)
  }
  Write-Host "** Script Setup **"
  Write-Host "`tInput coming from: $inputfile"
  Write-Host "`t  Output going to: $outfile"
  Write-Host "`t      Column Name: $ipcol"
  $iplist = Import-Csv -path $inputfile
  $totalEntries = @($iplist).count
  $currEntryNum = 0
  if ($merge) {
    foreach ($line in $iplist) {
      $currEntryNum++
      if ( $currEntryNum%20 -eq 0) {
        $I = ($currEntryNum / $totalEntries) * 100
        Write-Progress -Activity "Operation in Progress" -Status "[ $currEntryNum / $totalEntries ] $I% Complete" -PercentComplete $I;
      }
      if ($currEntryNum -eq $totalEntries) {Write-Progress -Completed $true}
      $ip = $line.$ipcol
      # Write-host ("Getting Geolocation Information for "+$ip) # *DEBUG*
      $response  = LookupUserMaxMind $ip 
      $line | select *, @{l="geo-ip";e={$response.ip}},
                        @{l="geo-city";e={$response.city}},
                        @{l="geo-region";e={$response.region}},
                        @{l="geo-country";e={$response.country}},
                        @{l="geo-loc";e={$response.loc}} |
            Export-Csv -Path $outfile -NoTypeInformation -Append
      }
    } else {
    foreach ($line in $iplist) {
      $ip = $line.$ipcol
      Write-Debug ("Getting Geolocation Information for "+$ip)
      $response  = LookupUserMaxMind $ip 
      $response | select ip, hostname, city, region, country, loc | Export-Csv -Path $outfile -NoTypeInformation -Append -NoClobber
    }
  }
}