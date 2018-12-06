REQUIRES PoSh (PowerShell) 5.0+ ( http://aka.ms/wmf5download )

# MMPoSh
Maxmind GeoLite Powershell Implementation
I wrote this in a 2-3 hours with minimal testing based on a rewrite of our code for IPINFO so YMMV : )

.SYNOPSIS 
(Version 1.0)
Lookup all users for the specified IPs with MaxMind Geolocation with local databases.
Returns GeoLocation Information 

.DESCRIPTION
Returns GeoLocation Information from MaxMind Local Databases for the specified IP(s)

.SETUP
Step 0: Create folders (powershell commands)
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
