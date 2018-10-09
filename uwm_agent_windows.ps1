# POWERSHELL AGENT FOR UWEBMONITOR.COM

$id = $args[0]
$token = $args[1]
$uptime = [int]((get-date)-[system.management.managementdatetimeconverter]::todatetime((get-wmiobject -class win32_operatingsystem).Lastbootuptime)).TotalSeconds

$cpu = Get-WmiObject win32_processor
$CPU = $cpu.LoadPercentage
#$CPU = [math]::round((((Get-Counter '\Processor(_Total)\% Processor Time').countersamples).CookedValue),2)
$os = Get-Ciminstance Win32_OperatingSystem
$mem_used = 100-[math]::Round(($os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,2)
$mem_total_gb = [int]($os.TotalVisibleMemorySize/1mb)
$mem_used_gb = $mem_total_gb-[math]::Round($os.FreePhysicalMemory/1mb,2)

#$id = "Windows 10"
#$token = "e25419d20c5912bbf41999955c1ceee5fe5d4edd"
$data = ""

$data = $data+"{"
$data = $data+"""internal_id"":""$id"","
$data = $data+ """internal_token"":""$token"","
$data = $data+ """internal_hostOS"":""$os"","
$data = $data+ """internal_agentinfo_version"":0.01,"
$data = $data+ """cpu_perc"":$CPU,"
$data = $data+ """mem_total_gb"":$mem_total_gb,"
$data = $data+ """mem_used_gb"":$mem_used_gb,"
$data = $data+ """mem_used"":$mem_used,"


$array = Get-WmiObject –class win32_volume | select Name,capacity,freespace
for ($i=0; $i -lt $array.length; $i++) {
    $unit = $array[$i].Name
    if ($unit -like '*:*') {
        $unit = $unit -replace ":", ''
        $unit = $unit -replace "\\", ''
        $capacidad = $array[$i].capacity
        $espacio_libre = $array[$i].freespace
#        echo $espacio_libre
#        echo $capacidad
        if (($espacio_libre -eq 0) -Or ($capacidad -eq 0)) {
            $usado_unidad = 100            
        } else {
            $usado_unidad = 100-[math]::round(((($espacio_libre*100)/$capacidad)),2)
        }
        $data = $data+ """filesystem_$unit"":$usado_unidad,"
    }
}


$array = Get-WmiObject –class Win32_Service  | select Caption,Started
for ($i=0; $i -lt $array.length; $i++) {
    $service_name = $array[$i].Caption
    $service_state = $array[$i].Started
    $service_state_output = "false"
    if ($service_state) { $service_state_output = "true" }   
    $data = $data+ """service_$service_name"":$service_state_output,"
}


$data = $data+ """uptime"": $uptime"
$data = $data+ "}"
#$data = get-content -encoding utf8 $data 
echo $data



[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$uri = "https://www.uwebmonitor.com/site/api/api.php"
$api = Invoke-WebRequest -UseBasicParsing -uri $uri -Method POST -Body $data
echo $api.StatusCode
echo $api.Content