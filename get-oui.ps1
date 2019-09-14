# Retooled variant of Darren Robinson's original OUI grabber
# Includes the vendor addressing metadata as well.
# Includes a colon formatting of the vendor OUI too.
# Original:  https://gist.github.com/darrenjrobinson/9d98a2ef9c52561198c90a0dabb61a32
# Get MAC Vendor List http://standards-oui.ieee.org/oui/oui.txt

$uri = "http://standards-oui.ieee.org/oui/oui.txt"
$output = "C:\data\oui_vendors.txt"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod -Uri $uri -Method GET -OutFile $output

[array]$vendors = @()

if (test-path -Path $output) {
    $vendorlist = Get-Content -Path $output 
    if ($vendorlist.Length -gt 15300) {
        # Loop over each line in the vendor file
        foreach ($vendor in $vendorlist) {
            if ($vendor.Trim().length -eq 0){
                # (Re)initialize our variables if we're reading a blank line from between the data.  Seems as good a time as any.
                $arrVDetails = $null 
                $vendorDetails = [PSCustomObject]@{    
                    ouiVendor = $null
                    ouiBase16 = $null
                    ouiHex    = $null
                    ouiColon = $null
                    ouiAddress = $null
                    ouiCity = $null
                    ouiCountry = $null
                }
            }elseif(($vendor -match "(hex)") -or ($vendor -match "(base 16)")) {
                # If we're looking at a line with octet values, load up the MAC Address variables
                $arrVDetails = $vendor.Split("`t")
                $vendorDetails.ouiVendor = $arrVDetails[2]
                if ($vendor -match "(hex)") { 
                    $vendorDetails.ouiHex = ($arrVDetails[0].Split(" "))[0].trim()
                    # Also generate a colon formatted version while we're here, as its so commonly used.
                    $vendorDetails.ouiColon = (($arrVDetails[0].Split(" "))[0] -replace "-",":").trim()
                }
                if ($vendor -match "(base 16)") { 
                    $vendorDetails.ouiBase16 = ($arrVDetails[0].Split(" "))[0].trim()
                }
            }else{
                # These are the "other" lines that contain vendor address metadata.  Lets get them into a field too.
                # First verify we have all the basic vendor data, if we do then we'll start loading up address information.
                if ($vendorDetails.ouiHex -and $vendorDetails.ouiBase16 -and $vendorDetails.ouiVendor) {
                    # First will be the Address line, next time through should be the City and last line should be the country                    
                    if(!$vendorDetails.ouiAddress){
                        $vendorDetails.ouiAddress = $vendor.Trim()
                    }elseif(!$vendorDetails.ouiCity){
                        $vendorDetails.ouiCity = $vendor.Trim()
                    }else{
                        $vendorDetails.ouiCountry = $vendor.Trim()
                    }
                    # If we have all the address data, we're ready to load all our data points into a detailed pscustomobject and add it to our growing array of vendors
                    if($vendorDetails.ouiAddress -and $vendorDetails.ouiCity -and $vendorDetails.ouiCountry){
                        $vendorDetails
                        $vendors += $vendorDetails
                    }
                }
            }
        }
    }
}

# I prefer csv's but you can uncomment the xml output if you prefer, or additionally want, that data formatting.
#$vendors | Export-Clixml -Path "C:\temp\MAC Address\Vendors.xml"
$vendors | Select-Object ouivendor,ouibase16,ouihex,ouiColon,ouiaddress,ouicity,ouicountry -Unique | Export-csv "F:\data\oui_Vendors.csv" -Append -NoTypeInformation

<#
Sample Objects 

ouiVendor  : Hewlett Packard
ouiBase16  : B499BA
ouiHex     : B4-99-BA
ouiColon   : B4:99:BA
ouiAddress : 11445 Compaq Center Drive
ouiCity    : Houston    77070
ouiCountry : US

ouiVendor  : D-Link Corporation
ouiBase16  : 0050BA
ouiHex     : 00-50-BA
ouiColon   : 00:50:BA
ouiAddress : 2F, NO. 233L-2, PAO-CHIAO RD.
ouiCity    : TAIPEI    0000
ouiCountry : TW

ouiVendor  : Cisco Systems, Inc
ouiBase16  : 501CBF
ouiHex     : 50-1C-BF
ouiColon   : 50:1C:BF
ouiAddress : 170 West Tasman Drive
ouiCity    : San Jose  CA  95134
ouiCountry : US

ouiVendor  : KYOCERA Display Corporation
ouiBase16  : 34A843
ouiHex     : 34-A8-43
ouiColon   : 34:A8:43
ouiAddress : 5-7-18 Higashinippori
ouiCity    : Arakawa-ku  Tokyo  116-0014
ouiCountry : JP
#>
