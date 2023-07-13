
$f={
#имя виртуальной машины
$vm=$TextBox1.Text
#путь до расшаренной папке на хранилище
$path=$TextBox2.Text
$Paths="$path\$vm"
#путь до логов
$LogPath=$TextBox3.Text
#количество бекапов в папке
$K=$TextBox5.Text

#вычисление размера виртуальной машины (минимальное свободное место в папке)
if ($ClusterCheckBox.Checked -eq "True"){
$drives=Get-ClusterNode  | Get-Clusterresource| ?{$_.ResourceType -eq 'Virtual Machine'}|Get-Vm | Where-Object {$_.Name -eq $vm}| Get-VMHardDiskDrive | Get-VHD
} else {
$drives=Get-VM $vm | Get-VMHardDiskDrive | Get-VHD
}


$MinFreeSpace=0
foreach ($n in $drives){
$size=$n.filesize/1048576
$MinFreeSpace=$MinFreeSpace+$size}
$TextBox6.Text=$MinFreeSpace                       

#установка статуса виртуальной машины, в котором она будет бекапиться
if ($CheckBox9.Checked -eq "True"){$vmoff =0}
if ($CheckBox10.Checked -eq "True"){$vmoff =1}
if ($CheckBox11.Checked -eq "True"){$vmoff =2}


# проверка существует ли виртуальная машина
if ($ClusterCheckBox.Checked -eq "True"){
$vms=Get-ClusterNode  | Get-Clusterresource| ?{$_.ResourceType -eq 'Virtual Machine'}|Get-Vm
foreach ($cn in $vms){
if ($cn.name -eq $vm){$prVM = 1}}}
else {$vms= Get-Vm
foreach ($cn in $vms){
if ($cn.name -eq $vm){$prVM = 1}}}
#если виртуальная машина не найдена, то будет показано сообщение
if ($prVM -ne 1){[System.Windows.Forms.MessageBox]::Show("Виртуальная машина с именем $vm не найдена!!!!") }
else{

# проверка существует ли папка для бекапов и тестировочный файл в ней
$isfile1 = Test-Path  $Paths
if($isfile1 -eq "True") {
  Write-host "Папка существует"
}
else {
   Write-host "Папка не существует"
   New-Item -Path $Paths -ItemType "directory"
   Write-host "Папка создана"
}

$fpath = "$Paths\testfile.txt" 
$isfile2 = Test-Path $fpath 
if($isfile2 -eq "True") {
   Write-host "Файл существует"
}
else {
   Write-host "Файл не существует"
   New-item -path $Paths -name testfile.txt -itemtype "file"
}

#вычисление нынешнего размера папки для бекапов
$FolderSize = (Get-ChildItem $Paths -recurse -Force | Measure-Object -Property Length -Sum).Sum / 1Mb
$TextBox9.Text = "$FolderSize"
#массив дней недели
$DaysofWeek  = @()
if ($CheckBox1.Checked -eq "True") {$DaysofWeek += "Monday"}
if ($CheckBox2.Checked -eq "True") {$DaysofWeek += "Tuesday"}
if ($CheckBox3.Checked -eq "True") {$DaysofWeek += "Wednesday"}
if ($CheckBox4.Checked -eq "True") {$DaysofWeek += "Thursday"}
if ($CheckBox5.Checked -eq "True") {$DaysofWeek += "Friday"}
if ($CheckBox6.Checked -eq "True") {$DaysofWeek += "Saturday"}
if ($CheckBox7.Checked -eq "True") {$DaysofWeek += "Sunday"}

$TextBox10.Text = $DaysofWeek -join ","
$time = $TextBox11.Text
$WeeksInterval = $TextBox12.Text
$t = New-ScheduledTaskTrigger –Weekly –DaysOfWeek $DaysofWeek –At $time -WeeksInterval $WeeksInterval
$o = New-ScheduledTaskSettingsSet

if($CheckBox.Checked -eq "True") {$proverkaPaths= 1}else{$proverkaPaths= 0}
$vm=$TextBox1.Text
$path=$TextBox2.Text
$Paths="$path\$vm"
$LogPath=$TextBox3.Text
$MinFreeSpace=$TextBox6.Text
$NameJob="Job"+"_"+$vm
$scriptpath=$TextBox14.Text
$Jobs=Get-ScheduledTask

 Foreach ($i in $Jobs){if ($i.TaskName -eq $NameJob){write-host "Такое задание уже существует"
 [System.Windows.Forms.MessageBox]::Show("Такое задание уже существует!!! Зайдите в планировщик заданий и удалите задание $NameJob") 
 $provJ=1}}
 if ($provJ -ne 1){
 # создание задания в планировщике
if ($ClusterCheckBox.Checked -eq "True"){
    $pass=$TextBox17.Text
    $us=$TextBox15.Text
    $param = "-vm $vm -path $path -LogPath $LogPath -proverkaPaths $proverkaPaths -K $K  -MinFreeSpace  $MinFreeSpace -vmoff $vmoff -us $us -pass $pass -cluster 1"
    $TextBox10.Text=$param
    $a = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoLogo -NoProfile -File $scriptpath $param"
    Register-ScheduledTask -TaskName $NameJob -Trigger $t -Settings $o -Action $a
    $p = Get-ScheduledTask $NameJob | % Principal
    $p.RunLevel = "Highest"
    Set-ScheduledTask -TaskName $NameJob -Principal $p
    $p = Get-ScheduledTask $NameJob | % Principal
    
}

else{
    $param = "-vm $vm -path $path -LogPath $LogPath -proverkaPaths $proverkaPaths -K $K -MinFreeSpace  $MinFreeSpace  -vmoff $vmoff -cluster 0"
    $TextBox10.Text=$param
    $a = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoLogo -NoProfile -File $scriptpath $param"
    Register-ScheduledTask -TaskName $NameJob -Trigger $t -Settings $o -Action $a
    $p = Get-ScheduledTask $NameJob | % Principal
    $p.RunLevel = "Highest"
    $taskPrincipal = New-ScheduledTaskPrincipal -UserId 'Control\control' -RunLevel Highest
    Set-ScheduledTask -TaskName $NameJob -User $taskPrincipal.UserID -Password 'Pf,jlfqrf5'
}
}}}






Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ='Hyper-V Backups'
$main_form.Width = 600
$main_form.Height = 600
$main_form.AutoSize = $true

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "Виртуальная машина:"
$Label1.Location  = New-Object System.Drawing.Point(0,10)
$Label1.AutoSize = $true
$main_form.Controls.Add($Label1)

$Label2 = New-Object System.Windows.Forms.Label
$Label2.Text = "Путь для бэкапов:"
$Label2.Location  = New-Object System.Drawing.Point(0,40)
$Label2.AutoSize = $true
$main_form.Controls.Add($Label2)

$Label3 = New-Object System.Windows.Forms.Label
$Label3.Text = "Путь для логов:"
$Label3.Location  = New-Object System.Drawing.Point(0,70)
$Label3.AutoSize = $true
$main_form.Controls.Add($Label3)

$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Size = New-Object System.Drawing.Size(200,10)
$TextBox1.Location  = New-Object System.Drawing.Point(400,10)
#$TextBox1.Text 
$main_form.Controls.Add($TextBox1)

$TextBox2 = New-Object System.Windows.Forms.TextBox
$TextBox2.Size = New-Object System.Drawing.Size(200,10)
$TextBox2.Location  = New-Object System.Drawing.Point(400,40)
$TextBox2.Text = '\\VMbackup\VM_Backup'
$main_form.Controls.Add($TextBox2)

$TextBox3 = New-Object System.Windows.Forms.TextBox
$TextBox3.Size = New-Object System.Drawing.Size(200,10)
$TextBox3.Location  = New-Object System.Drawing.Point(400,70)
$TextBox3.Text = '\\VMbackup\VM_Backup'
$main_form.Controls.Add($TextBox3)

$Label4 = New-Object System.Windows.Forms.Label
$Label4.Text = "Проверка свободного места в папке для бэкапов:"
$Label4.Location  = New-Object System.Drawing.Point(0,100)
$Label4.AutoSize = $true
$main_form.Controls.Add($Label4)

$Label5 = New-Object System.Windows.Forms.Label
$Label5.Text = "Хранить количество бекапов"
$Label5.Location  = New-Object System.Drawing.Point(0,130)
$Label5.AutoSize = $true
$main_form.Controls.Add($Label5)


$TextBox5 = New-Object System.Windows.Forms.TextBox
$TextBox5.Size = New-Object System.Drawing.Size(200,10)
$TextBox5.Location  = New-Object System.Drawing.Point(400,130)
$TextBox5.Text = '4'
$main_form.Controls.Add($TextBox5)

$Label6 = New-Object System.Windows.Forms.Label
$Label6.Text = "Необходимое свободное место для одного бекапа:"
$Label6.Location  = New-Object System.Drawing.Point(0,160)
$Label6.AutoSize = $true
$main_form.Controls.Add($Label6)


$TextBox6 = New-Object System.Windows.Forms.TextBox
$TextBox6.Size = New-Object System.Drawing.Size(200,10)
$TextBox6.Location  = New-Object System.Drawing.Point(400,160)
$TextBox6.Text = '1024'
$main_form.Controls.Add($TextBox6)


$Label9 = New-Object System.Windows.Forms.Label
$Label9.Text = "Нынешний размер папки бекапов виртуальной машины (MB)"
$Label9.Location  = New-Object System.Drawing.Point(0,220)
$Label9.AutoSize = $true
$main_form.Controls.Add($Label9)


$TextBox9 = New-Object System.Windows.Forms.TextBox
$TextBox9.Size = New-Object System.Drawing.Size(200,10)
$TextBox9.Location  = New-Object System.Drawing.Point(400,220)
$TextBox9.Text = '1024'
$main_form.Controls.Add($TextBox9)

$button1 = New-Object System.Windows.Forms.Button
$button1.Text = 'Создать задание'
$button1.Size = New-Object System.Drawing.Size(200,30)
$button1.Location = New-Object System.Drawing.Point(0,360)
$button1.add_Click($f)
$main_form.Controls.Add($button1)


$TextBox10 = New-Object System.Windows.Forms.TextBox
$TextBox10.Size = New-Object System.Drawing.Size(150,10)
$TextBox10.Location  = New-Object System.Drawing.Point(420,360)
$TextBox10.Text = ''
$main_form.Controls.Add($TextBox10)

$CheckBox = New-Object System.Windows.Forms.CheckBox
$CheckBox.Text = ''
$CheckBox.AutoSize = $true
$CheckBox.Checked = $true
$CheckBox.Location  = New-Object System.Drawing.Point(300,100)
$main_form.Controls.Add($CheckBox)

$CheckBox1 = New-Object System.Windows.Forms.CheckBox
$CheckBox1.Text = 'Понедельник'
$CheckBox1.AutoSize = $true
$CheckBox1.Checked = $false
$CheckBox1.Location  = New-Object System.Drawing.Point(0,270)
$main_form.Controls.Add($CheckBox1)

$CheckBox2 = New-Object System.Windows.Forms.CheckBox
$CheckBox2.Text = 'Вторник'
$CheckBox2.AutoSize = $true
$CheckBox2.Checked = $false
$CheckBox2.Location  = New-Object System.Drawing.Point(0,290)
$main_form.Controls.Add($CheckBox2)

$CheckBox3 = New-Object System.Windows.Forms.CheckBox
$CheckBox3.Text = 'Среда'
$CheckBox3.AutoSize = $true
$CheckBox3.Checked = $false
$CheckBox3.Location  = New-Object System.Drawing.Point(100,270)
$main_form.Controls.Add($CheckBox3)

$CheckBox4 = New-Object System.Windows.Forms.CheckBox
$CheckBox4.Text = 'Четверг'
$CheckBox4.AutoSize = $true
$CheckBox4.Checked = $false
$CheckBox4.Location  = New-Object System.Drawing.Point(100,290)
$main_form.Controls.Add($CheckBox4)

$CheckBox5 = New-Object System.Windows.Forms.CheckBox
$CheckBox5.Text = 'Пятница'
$CheckBox5.AutoSize = $true
$CheckBox5.Checked = $false
$CheckBox5.Location  = New-Object System.Drawing.Point(200,270)
$main_form.Controls.Add($CheckBox5)

$CheckBox6 = New-Object System.Windows.Forms.CheckBox
$CheckBox6.Text = 'Суббота'
$CheckBox6.AutoSize = $true
$CheckBox6.Checked = $false
$CheckBox6.Location  = New-Object System.Drawing.Point(200,290)
$main_form.Controls.Add($CheckBox6)

$CheckBox7 = New-Object System.Windows.Forms.CheckBox
$CheckBox7.Text = 'Воскресенье'
$CheckBox7.AutoSize = $true
$CheckBox7.Checked = $false
$CheckBox7.Location  = New-Object System.Drawing.Point(300,270)
$main_form.Controls.Add($CheckBox7)

$Label10 = New-Object System.Windows.Forms.Label
$Label10.Text = "Время (ЧЧ:ММ)"
$Label10.Location  = New-Object System.Drawing.Point(400,270)
$Label10.AutoSize = $true
$main_form.Controls.Add($Label10)

$TextBox11 = New-Object System.Windows.Forms.TextBox
$TextBox11.Size = New-Object System.Drawing.Size(100,10)
$TextBox11.Location  = New-Object System.Drawing.Point(500,270)
$TextBox11.Text = '13:30'
$main_form.Controls.Add($TextBox11)


$Label12 = New-Object System.Windows.Forms.Label
$Label12.Text = "Недельный интервал:"
$Label12.Location  = New-Object System.Drawing.Point(370,295)
$Label12.AutoSize = $true
$main_form.Controls.Add($Label12)

$TextBox12 = New-Object System.Windows.Forms.TextBox
$TextBox12.Size = New-Object System.Drawing.Size(100,10)
$TextBox12.Location  = New-Object System.Drawing.Point(500,295)
$TextBox12.Text = '4'
$main_form.Controls.Add($TextBox12)

$ClusterCheckBox = New-Object System.Windows.Forms.CheckBox
$ClusterCheckBox.Text = 'Кластер'
$ClusterCheckBox.AutoSize = $true
$ClusterCheckBox.Checked = $false
$ClusterCheckBox.Location  = New-Object System.Drawing.Point(0,450)
$main_form.Controls.Add($ClusterCheckBox)


$Label14 = New-Object System.Windows.Forms.Label
$Label14.Text = "В каком состоянии экспортировать виртуальную машину"
$Label14.Location  = New-Object System.Drawing.Point(0,315)
$Label14.AutoSize = $true
$main_form.Controls.Add($Label14)

$CheckBox9 = New-Object System.Windows.Forms.CheckBox
$CheckBox9.Text = 'Выключенное'
$CheckBox9.AutoSize = $true
$CheckBox9.Checked = $true
$CheckBox9.Location  = New-Object System.Drawing.Point(0,340)
$main_form.Controls.Add($CheckBox9)

$CheckBox10 = New-Object System.Windows.Forms.CheckBox
$CheckBox10.Text = 'Сохраненное'
$CheckBox10.AutoSize = $true
$CheckBox10.Checked = $false
$CheckBox10.Location  = New-Object System.Drawing.Point(150,340)
$main_form.Controls.Add($CheckBox10)

$CheckBox11 = New-Object System.Windows.Forms.CheckBox
$CheckBox11.Text = 'Работающая'
$CheckBox11.AutoSize = $true
$CheckBox11.Checked = $false
$CheckBox11.Location  = New-Object System.Drawing.Point(300,340)
$main_form.Controls.Add($CheckBox11)

$Label15 = New-Object System.Windows.Forms.Label
$Label15.Text = "Путь к скриптам:"
$Label15.Location  = New-Object System.Drawing.Point(0,560)
$Label15.AutoSize = $true
$main_form.Controls.Add($Label14)

$TextBox14 = New-Object System.Windows.Forms.TextBox
$TextBox14.Size = New-Object System.Drawing.Size(500,10)
$TextBox14.Location  = New-Object System.Drawing.Point(120,560)
$TextBox14.Text = "\\dchost-01\ps\f.ps1"
$main_form.Controls.Add($TextBox14)

$Label16 = New-Object System.Windows.Forms.Label
$Label16.Text = "Пользователь"
$Label16.Location  = New-Object System.Drawing.Point(0,470)
$Label16.AutoSize = $true
$main_form.Controls.Add($Label16)

$TextBox15 = New-Object System.Windows.Forms.TextBox
$TextBox15.Size = New-Object System.Drawing.Size(100,10)
$TextBox15.Location  = New-Object System.Drawing.Point(100,470)
$TextBox15.Text = 'control'
$main_form.Controls.Add($TextBox15)

$Label17 = New-Object System.Windows.Forms.Label
$Label17.Text = "Пароль"
$Label17.Location  = New-Object System.Drawing.Point(0,500)
$Label17.AutoSize = $true
$main_form.Controls.Add($Label17)

$TextBox17 = New-Object System.Windows.Forms.TextBox
$TextBox17.Size = New-Object System.Drawing.Size(100,10)
$TextBox17.Location  = New-Object System.Drawing.Point(100,500)
$TextBox17.Text = '"Pf,jlfqrf5"'
$main_form.Controls.Add($TextBox17)

$main_form.ShowDialog()



