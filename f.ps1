param($vm, $path, $LogPath, $proverkaPaths, $K, $vmoff, $ClusterNodes, $us, [string]$pass, $cluster)
$VmName=$vm
$date=get-date -format "dd.MM.yy.HH.mm.ss"
$fullpath="$path\$vm\$date"
$Paths="$path\$vm"
$LOG="$LogPath\$vm.txt"
$MinFree=$MinFreeSpace
$MaxFolder=$MaxFolderSize
$blade= hostname


write "$(get-date -format "dd.MM.yy.HH.mm.ss") ___________________________________________________________________________________________________________________________" | out-file  $LOG -append
write "$(get-date -format "dd.MM.yy.HH.mm.ss") ___________________________________________________________________________________________________________________________" | out-file  $LOG -append

function GetFreeSpace ($Paths, $VmName, $K, $LOG){
$FolderSize = (Get-ChildItem $Paths -recurse -Force | Measure-Object -Property Length -Sum).Sum / 1Mb                   
$drives=Get-VM $VmName | Get-VMHardDiskDrive | Get-VHD
$MinFreeSpace=0
        foreach ($n in $drives){
            $size=$n.filesize/1048576
            $MinFreeSpace=$MinFreeSpace+$size
        }

write "$(get-date -format "dd.MM.yy.HH.mm.ss") папка дл€ бекапов сейчас имеет размер: $FolderSize" | out-file  $LOG -append
write "$(get-date -format "dd.MM.yy.HH.mm.ss") необходимое место дл€ бекапа: $MinFreeSpace" | out-file  $LOG -append
}


function DelOldFolders ($Paths, $R, $LOG){

   #проверка есть ли папка для бекапов
   if (-not (Test-Path -Path $Paths)) {
    throw "$Paths not found"
}
   #количество подпапок в папке
   $foldersCount= Get-ChildItem $Paths | Measure-Object | %{$_.Count}
   write "количество бекапов  - $foldersCount !!!!!!!!!!!!!!!!!!!!!!!!"
   #если количество подпапок меньше чем необходимое количество бекапов то выоходим из цикла - удалять ничего не надо
   if($foldersCount -le $R){
       write "количество бекапов мало - $foldersCount - выходим!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
       return
   }
   else{
  # пока количество папок не равно необходимому количеству бекапов 
   While ($foldersCount -ne $R){
    #список папок
    $folders = dir $Paths
    write "colpap $foldersCount"
    #переменная для хранения даты
    $datetime = get-date
     #находим папку с самой старой датой
     foreach ($p in $folders ){
            if ($datetime -gt $p.LastWriteTime){
                $datetime= $p.LastWriteTime
                Write $datetime
            }
            
     }
     #ищем самую старую папку и удаляем
    
     foreach ($s in $folders ){
                if ($datetime -eq $s.LastWriteTime){
                    cd $Paths
                    Write "Удаляю $s   дата $datetime ___________________________________"
                    Write "Удаляю $s   дата $datetime ___________________________________" | out-file  $LOG -append
                    rm $s -recurse
                }
            }
     #обновляем значение переменной - количество подпапок      
     $foldersCount= Get-ChildItem $Paths | Measure-Object | %{$_.Count}
     } 
}
   }

function SetVMStatus ($vmoff, $vm, $LOG){
        $vmstate= get-vm $vm

        if ($vmoff -eq 0){
                    if ($vmstate.state -eq "running"){
                    write "$(get-date -format "dd.MM.yy.HH.mm.ss") завершаем работу $vm" | out-file $LOG -append
	                Stop-VM $vm -ErrorAction Stop}
                    else {write "$(get-date -format "dd.MM.yy.HH.mm.ss") $vm была выключена ранее" | out-file $LOG -append}
        }
        if ($vmoff -eq 1){
                if ($vmstate.state -eq "Running"){
                write "$(get-date -format "dd.MM.yy.HH.mm.ss") —охран€ем  $vm" | out-file $LOG -append
	            Stop-VM $vm -Save -ErrorAction Stop}
                else {write "$(get-date -format "dd.MM.yy.HH.mm.ss") $vm была выключена ранее" | out-file $LOG -append}
        }
        if ($vmoff -eq 2){
                if ($vmstate.state -eq "Running"){
                write "$(get-date -format "dd.MM.yy.HH.mm.ss") будем экспортировать работающую  $vm" | out-file $LOG -append}
                else {write "$(get-date -format "dd.MM.yy.HH.mm.ss") $vm" | out-file $LOG -append}
        }
}

function ExportVM ($vm, $fullpath, $LOG){
       $starttime=get-date
       $vmstate= get-vm $vm
       $to='it-eventss@mail.ru'
       $from='it-eventss@mail.ru'
       $mailserver='mail.ru'
       write "$(get-date -format "dd.MM.yy.HH.mm.ss") пытаемс€ экспортировать $vm в $fullpath" | out-file $LOG -append
	   Export-VM -Name $vm -Path $fullpath -ErrorAction Stop
       $endtime=get-date
       $duration= [math]::Round(($endtime - $starttime).TotalMinutes, 2)
       write "$(get-date -format "dd.MM.yy.HH.mm.ss") ¬озобновл€ем работу $vm" | out-file $LOG -append
      #проверка бекапа
       if(Test-Path "$fullpath\$vm\Virtual Hard Disks\*.vhdx"){
           $FolderSize = [math]::Round((Get-ChildItem $fullpath\$vm -recurse -Force | Measure-Object -Property Length -Sum).Sum / 1Gb, 2)
           Send-MailMessage -From $from -To $to -Subject "$(get-date -format "dd.MM.yy.HH.mm.ss") Backup $vm OK ($duration min, $FolderSize Gb)" -Body "Backup $vm OK ($duration min), VM Size - $FolderSize Gb" ЦSmtpServer $mailserver -Encoding 'UTF8'
           write "$(get-date -format "dd.MM.yy.HH.mm.ss") 'экспорт $vm в $fullpath OK" | out-file $LOG -append
       }else{
           Send-MailMessage -From $from -To $to -Subject "$(get-date -format "dd.MM.yy.HH.mm.ss") Backup $vm ERROr" -Body "Backup $vm ERROR" ЦSmtpServer $mailserver -Encoding 'UTF8'
           write "$(get-date -format "dd.MM.yy.HH.mm.ss") 'экспорт $vm в $fullpath ERRor" | out-file $LOG -append
       }

       if ($vmstate.state -ne "Running"){Start-VM $vm -ErrorAction Stop}
}


if($cluster -eq 1){
$h= Get-ClusterNode
foreach($i in $h){
$vms=Get-ClusterNode $i.name | Get-Clusterresource| ?{$_.ResourceType -eq 'Virtual Machine'}|Get-Vm
foreach ($cn in $vms){
if ($cn.name -eq $VmName){
   write "$(get-date -format "dd.MM.yy.HH.mm.ss") ќбнаружена $VmName на $i" | out-file $LOG -append
   if ($i -eq $blade){
       write "$(get-date -format "dd.MM.yy.HH.mm.ss") $VmName располагаетс€ локально" | out-file $LOG -append
       if ($proverkaPaths= 1){
            GetFreeSpace -Paths $Paths -VmName $VmName -K $K -LOG $LOG
            DelOldFolders -Paths $Paths -R $K -LOG $LOG
       }
       
	try {
        $vmstate= get-vm $vm
        SetVMStatus -vmoff $vmoff -vm $vm -LOG $LOG 
        ExportVM -vm $vm -fullpath $fullpath -LOG $LOG
	} 
    catch {
            $path | Out-File $LOG -append
		    "$_" | Out-File $LOG -append
            Start-VM $vm
            write "$(get-date -format "dd.MM.yy.HH.mm.ss") $vm произошли ошибки!!!" | out-file $LOG -append
	}
       } 
#__________________________________________________________________________________________________________
       else {
             #сохранение функций в переменную
             $getfreespace   = ${function:GetFreeSpace}.ToString()
             $deloldfolders = ${function:DelOldFolders}.ToString()
             $setvmstatus = ${function:SetVMStatus}.ToString()
             $exportvm =  ${function:ExportVM}.ToString()
             #параметры сессиии
             $password = ConvertTo-SecureString -String "$pass" -AsPlainText -Force
             $cred= New-Object System.Management.Automation.PSCredential ("$us", $password )
             $s = New-PSSession -computerName $i -authentication CredSSP -credential $cred
             #el
             Invoke-Command -Session $s -Scriptblock {
                #переопределение переменных 
                $vm=$using:VmName            
                $blade= hostname
                $paths=$using:path
                $LogPaths=$using:LogPath
                $date=get-date -format "dd.MM.yy.HH.mm.ss"
                $fullpaths="$paths\$vm\$date"
                $Pathss="$paths\$vm" 
                $LOGs="$LogPaths\$vm.txt"
                $proverkaPathss=$using:proverkaPaths
                $K=$using:K
                $vmoffs=$using:vmoff
                
                #переопределение функций
                ${function:GetFreeSpace} = $using:getfreespace
                ${function:DelOldFolders} = $using:deloldfolders
                ${function:SetVMStatus} = $using:setvmstatus
                ${function:ExportVM} = $using:exportvm


             
                if ($proverkaPathss= 1){
                     #проверка свободного места
                     GetFreeSpace -Paths $Pathss -VmName $vm -K $K -LOG $LOGs
                     DelOldFolders -Paths $Pathss -R $K -LOG $LOGs
                }

	            try {
                    $vmstate= get-vm $vm
                    #статус виртуальной машины
                    SetVMStatus -vmoff $vmoffs -vm $vm -LOG $LOGs

                    #экспорт виртуальной машины
                    ExportVM -vm $vm -fullpath $fullpaths -LOG $LOGs


	            }
	            catch {
                    $paths | Out-File $LOGs -append
		            "$_" | Out-File $LOGs -append
                    Start-VM $vm
                    write "$(get-date -format "dd.MM.yy.HH.mm.ss") $vm произошли ошибки!!!" | out-file $LOGs -append
	     
	            }



                                  }
Remove-PSSession $s}
}}
}

}
else {

    if ($proverkaPaths= 1){
                GetFreeSpace -Paths $Paths -VmName $VmName -K $K -LOG $LOG
                DelOldFolders -Paths $Paths -R $K -LOG $LOG
           }
       
	try {
        $vmstate= get-vm $vm
        SetVMStatus -vmoff $vmoff -vm $vm -LOG $LOG 
        ExportVM -vm $vm -fullpath $fullpath -LOG $LOG
	} 
    catch {
            $path | Out-File $LOG -append
		    "$_" | Out-File $LOG -append
            Start-VM $vm
            write "$(get-date -format "dd.MM.yy.HH.mm.ss") $vm произошли ошибки!!!" | out-file $LOG -append
	}

} 


