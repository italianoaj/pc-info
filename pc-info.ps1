Clear-Host
$Date=Get-Date
Write-Host "---------- Anthony's PC Info Script ----------"
Write-Host "Generated: "$Date
Write-Host

#OS Info
$OS = Get-WmiObject -Class win32_OperatingSystem

$OS_Name = $OS.Caption
$OS_InstallD8 = $OS.ConvertToDateTime($OS.InstallDate)
$OS_LastBoot = $OS.ConvertToDateTime($OS.LastBootUpTime)
$OS_Architecture = $OS.OSArchitecture
$OS_SystemDrive = $OS.SystemDrive
$OS_WINDIR = $OS.WindowsDirectory
$OS_BuildNum = $OS.BuildNumber
$OS_SerialNum = $OS.SerialNumber
$OS_Version = $OS.Version
$OS_Manufac = $OS.Manufacturer

Write-Host "---------- OS INFO ----------"
Write-Host "Installed Operating System: "$OS_Name
Write-Host "OS Version: "$OS_Version
Write-Host "OS Build Number: "$OS_BuildNum
Write-Host "OS Serial Number: "$OS_SerialNum
Write-Host "OS installation date: "$OS_InstallD8
Write-Host "Last boot time: "$OS_LastBoot
Write-Host "OS Architecture: "$OS_Architecture
Write-Host "OS is installed on drive: "$OS_SystemDrive
Write-Host "Location of OS Directory: "$OS_WINDIR
Write-Host "OS Manufacturer: "$OS_Manufac
Write-Host

#Computer System
$CS = Get-WmiObject -Class win32_ComputerSystem

$CS_Name = $CS.Name
$CS_Owner = $CS.PrimaryOwnerName
$uptime = (get-date) - (gcim Win32_OperatingSystem).LastBootUpTime

Write-Host "---------- SYS INFO ----------"
Write-Host "System Name: "$CS_Name
Write-Host "System Owner: "$CS_Owner
Write-Host "System Uptime: " -NoNewline
if($uptime.Days -ge 7){
    Write-Host $uptime.Days" Days, "$uptime.Hours" Hours, "$uptime.Minutes" Minutes, "$uptime.Seconds" Seconds" -ForegroundColor Red
}else{
    Write-Host $uptime.Days" Days, "$uptime.Hours" Hours, "$uptime.Minutes" Minutes, "$uptime.Seconds" Seconds" -ForegroundColor Green
}
Write-Host

#CPU
$CPU = Get-WmiObject -Class Win32_Processor

$CPU_Name = $CPU.Name
$CPU_Manufac = $CPU.Manufacturer
$CPU_MaxClockSpeed = $CPU.MaxClockSpeed / 1000
$CPU_Used = (Get-WmiObject Win32_Processor).LoadPercentage
$Objects = Get-WmiObject -Query "SELECT * FROM Win32_PerfFormattedData_Counters_ThermalZoneInformation" -Namespace "root/CIMV2"
$CPU_CTemp
foreach ($Obj in $Objects) {
    $HiPrec = $Obj.HighPrecisionTemperature
    $CPU_CTemp = [math]::round($HiPrec / 100.0, 1)
}
$CPU_FTemp = [math]::round(($CPU_CTemp*(9/5))+32)

Write-Host "---------- CPU INFO ----------"
Write-Host "CPU Name: "$CPU_Name
Write-Host "CPU Manufacturer: "$CPU_Manufac
Write-Host "Max CPU Clock Speed: "$CPU_MaxClockSpeed
Write-Host "Current CPU Usage: " -NoNewline
if($CPU_Used -gt 85){
    Write-Host $CPU_used"%" -ForegroundColor Red
}else{
    Write-Host $CPU_used"%" -ForegroundColor Green
}
Write-Host "CPU Temp: " -NoNewline
if ($CPU_CTemp -gt 70){
    Write-Host $CPU_CTemp"C/"$CPU_FTemp"F" -ForegroundColor Red
}else{
    Write-Host $CPU_CTemp"C/"$CPU_FTemp"F" -ForegroundColor Green
}
Write-Host

#RAM
$RAM = Get-WmiObject -Query "SELECT TotalVisibleMemorySize, FreePhysicalMemory FROM win32_OperatingSystem"

$usedRAM = [math]::Round(($RAM.TotalVisibleMemorySize - $RAM.FreePhysicalMemory)/1MB, 2)
$freeRAM = [math]::Round($RAM.FreePhysicalMemory/1MB, 2)
$totalRAM = [math]::Round($RAM.TotalVisibleMemorySize/1MB, 2)

Write-Host "---------- RAM INFO ----------"
Write-Host "Total PC RAM is: "$totalRAM"GB"
Write-Host "Free RAM is: "$freeRAM"GB"
Write-Host "Used RAM is: " -NoNewline
if (($usedRAM/$totalRAM) -gt 0.85){
    Write-Host $usedRAM"GB" -ForegroundColor Red
}else{
    Write-Host $usedRAM"GB" -ForegroundColor Green
}
Write-Host

#Battery 
$Battery = Get-WmiObject -Class Win32_Battery

$Battery_Name = $Battery.Name
$Battery_Life = $Battery.EstimatedChargeRemaining
$Battery_Status = $Battery.Status

Write-Host "---------- BATTERY INFO -----------"
Write-Host "Battery Name: "$Battery_Name
Write-Host "Battery Status: " -NoNewLine
if ($Battery_Status -eq "OK"){
    Write-Host $Battery_Status -ForegroundColor Green
}else{
    Write-Host $Battery_Status -ForegroundColor Red
}
Write-Host "Battery Life: " -NoNewLine
if ($Battery_Life -gt 25){
    Write-Host $Battery_Life"%" -ForegroundColor Green
}else{
    Write-Host $Battery_Life"%" -ForegroundColor Red
}
Write-Host

#Drives

Write-Host "---------- Drive Information ----------"
#Write-Host "Local Drive Table"
try{
    Get-PSDrive -PSProvider FileSystem | format-table -property Name,Root,@{n="Used (GB)";e={[math]::Round($_.Used/1GB,1)}},@{n="Free (GB)";e={[math]::Round($_.Free/1GB,1)}}
} catch {
	Write-Host "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
}
#Write-Host "Shared Drives:"
#$sharedDrives = Get-WmiObject win32_share
#Write-Host $sharedDrives
Write-Host

#Printers
Write-Host "---------- Printer Information ----------"
Write-Host "Installed Printers:"
try {
	if ($isLinux) {
		# TODO
        Write-Host "Linux"
	} else {
		$ComputerName = $(hostname)
		Get-WMIObject -Class Win32_Printer -ComputerName $ComputerName | Format-Table
	}
} catch {
	Write-Host "Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
}

#Network
Write-Host "----------Network Information ----------"
$hosts = "amazon.com,bing.com,cnn.com,dropbox.com,github.com,google.com,youtube.com"
Write-Host "Pinging hosts: "$hosts
try {
	Write-Host "Ping latency is" -noNewline
	$hostsArray = $hosts.Split(",")
	$t = $hostsArray | ForEach-Object {
		(New-Object Net.NetworkInformation.Ping).SendPingAsync($_, 250)
	}
	[Threading.Tasks.Task]::WaitAll($t)
	[int]$min = 9999999
	[int]$max = [int]$avg = [int]$successCount = [int]$lossCount = 0
	foreach($ping in $t.Result) {
		if ($ping.Status -eq "Success") {
			[int]$latency = $ping.RoundtripTime
			if ($latency -lt $min) { $min = $Latency }
			if ($latency -gt $max) { $max = $Latency }
			$avg += $latency
			$successCount++
		} else {
			$lossCount++
		}
	}
    if($successCount -eq 0){
        $avg = 0
    }else{
        $avg /= $successCount
    }
    if($successCount -gt $lossCount){
	    Write-Host " $($avg)ms average ($($min)ms...$($max)ms, $lossCount loss)" -ForegroundColor Green
    }else{
        Write-Host " $($avg)ms average ($($min)ms...$($max)ms, $lossCount loss)" -ForegroundColor Red
    }
} catch {
	"Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
}
Write-Host

#BIOS
$Bios = Get-WmiObject -Class Win32_Bios

$bName = $Bios.Name
$bVer = $Bios.BIOSVersion
$bStatus = $Bios.Status
$bRelDate = $Bios.ReleaseDate
$bMan = $Bios.Manufacturer

Write-Host "---------- BIOS INFO ----------"
Write-Host "BIOS: "$bName
Write-Host "Version: "$bVer
Write-Host "Manufacturer: "$bMan
Write-Host "Release Date: "$bRelDate
Write-Host "Status: " -NoNewline
if ($bStatus -eq "OK"){
    Write-Host $bStatus -ForegroundColor Green
}else{
    Write-Host $bStatus -ForegroundColor Red
}
Write-Host

#Services
$Response = Read-Host "Would you like to view running services? (Y/n)"
if($Response -ne "n"){
    $services = Get-ServiceWrite-Host "---------- Running Services ----------"
    foreach($service in $services){
        Write-Host $service
    }
    Write-Host
}




