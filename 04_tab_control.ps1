#==========================================================================
# 04_tab_control.ps1 - TAB CONTROL Y HERRAMIENTAS
# MODIFICADO RNX v2:
#  - Bloque LANZADORES: quitar QFIL y USB DRIVERS -> queda solo ODIN3 + HxD
#  - Agregar bloque AUTOMATIZACION Y ENTREGAS (traido desde 05_tab_adb.ps1)
#    con RESET RAPIDO ENTREGA + INSTALAR APKs
#==========================================================================

#==========================================================================
# [A] FUNCION COMPARTIDA - Show-ExtractProgress
#==========================================================================
function Show-ExtractProgress($filename) {
    $win = New-Object Windows.Forms.Form
    $win.Text = "Extrayendo..."; $win.ClientSize = New-Object System.Drawing.Size(500,170)
    $win.BackColor = [System.Drawing.Color]::FromArgb(18,18,18)
    $win.FormBorderStyle = "FixedDialog"; $win.StartPosition = "CenterScreen"
    $win.ControlBox = $false; $win.TopMost = $true

    $lbTitle = New-Object Windows.Forms.Label; $lbTitle.Text = "EXTRAYENDO FIRMWARE"
    $lbTitle.Location = New-Object System.Drawing.Point(16,14); $lbTitle.Size = New-Object System.Drawing.Size(468,20)
    $lbTitle.ForeColor = [System.Drawing.Color]::Lime
    $lbTitle.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $win.Controls.Add($lbTitle)

    $lbFile = New-Object Windows.Forms.Label; $lbFile.Text = $filename
    $lbFile.Location = New-Object System.Drawing.Point(16,38); $lbFile.Size = New-Object System.Drawing.Size(468,18)
    $lbFile.ForeColor = [System.Drawing.Color]::LightGray
    $lbFile.Font = New-Object System.Drawing.Font("Consolas",8); $win.Controls.Add($lbFile)

    $bar = New-Object Windows.Forms.ProgressBar
    $bar.Location = New-Object System.Drawing.Point(16,66); $bar.Size = New-Object System.Drawing.Size(468,24)
    $bar.Style = "Continuous"; $bar.Minimum = 0; $bar.Maximum = 100; $bar.Value = 0
    $win.Controls.Add($bar)

    $lbPct = New-Object Windows.Forms.Label; $lbPct.Text = "0%"
    $lbPct.Location = New-Object System.Drawing.Point(16,100); $lbPct.Size = New-Object System.Drawing.Size(468,18)
    $lbPct.ForeColor = [System.Drawing.Color]::Cyan
    $lbPct.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $lbPct.TextAlign = "MiddleCenter"; $win.Controls.Add($lbPct)

    $lbStatus = New-Object Windows.Forms.Label; $lbStatus.Text = "Iniciando..."
    $lbStatus.Location = New-Object System.Drawing.Point(16,124); $lbStatus.Size = New-Object System.Drawing.Size(468,18)
    $lbStatus.ForeColor = [System.Drawing.Color]::FromArgb(90,90,90)
    $lbStatus.Font = New-Object System.Drawing.Font("Consolas",7.5); $win.Controls.Add($lbStatus)

    $win.Show(); [System.Windows.Forms.Application]::DoEvents()
    return @{ Win=$win; Bar=$bar; LblFile=$lbFile; LblPct=$lbPct; LblStatus=$lbStatus }
}

#==========================================================================
# [B] TAB CONTROL - Layout
# MODIFICADO: grpC1 LANZADORES ahora solo tiene 2 botones (ODIN3 + HxD)
#             grpC4 AUTOMATIZACION Y ENTREGAS agregado (2 botones)
#==========================================================================

$CX=6; $CGAP=8; $CLOGX=436
$CBTW=195; $CBTH=56; $CPX=14; $CPY=20; $CGX=8; $CGY=8
$CGW=422; $CLOGW=$CGW

# Alturas:
# C1 = 1 fila (2 btn solo: ODIN3 + HxD)
# C2 = 2 filas (4 btn: diagnostico ADB)
# C3 = 3 filas (6 btn: sistema/PC)
# C4 = 1 fila (2 btn: automatizacion - NUEVO)
$CGH1 = $CPY + 1*($CBTH+$CGY) - $CGY + 14   # 1 fila
$CGH2 = $CPY + 2*($CBTH+$CGY) - $CGY + 14   # 2 filas
$CGH3 = $CPY + 3*($CBTH+$CGY) - $CGY + 14   # 3 filas
$CGH4 = $CPY + 1*($CBTH+$CGY) - $CGY + 14   # 1 fila

$CY1=6
$CY2=$CY1+$CGH1+$CGAP
$CY3=$CY2+$CGH2+$CGAP
$CY4=$CY3+$CGH3+$CGAP

$grpC1 = New-GBox $tabCtrl "LANZADORES"              $CX $CY1 $CGW $CGH1 "Yellow"
$grpC2 = New-GBox $tabCtrl "DIAGNOSTICO ADB"         $CX $CY2 $CGW $CGH2 "Cyan"
$grpC3 = New-GBox $tabCtrl "SISTEMA / PC"            $CX $CY3 $CGW $CGH3 "Orange"
$grpC4 = New-GBox $tabCtrl "AUTOMATIZACION Y ENTREGAS" $CX $CY4 $CGW $CGH4 "Magenta"

# LANZADORES: solo 2 botones (QFIL y USB DRIVERS eliminados)
$CL1=@("ODIN3","HxD HEX EDITOR")
$CL2=@("TEST PANTALLA","INFO BATERIA","ALMACENAMIENTO","APPS INSTALADAS")
$CL3=@("ADMIN TAREAS","ADMIN DISPOSITIVOS","DESACTIVAR DEFENDER","REINICIAR ADB","MONITOR PC","LIMPIEZA TEMP PC")
# AUTOMATIZACION (traido desde tab ADB)
$CL4=@("RESET RAPIDO ENTREGA","INSTALAR APKs")

$btnsC1=Place-Grid $grpC1 $CL1 "Yellow"  2 $CBTW $CBTH $CPX $CPY $CGX $CGY
$btnsC2=Place-Grid $grpC2 $CL2 "Cyan"    2 $CBTW $CBTH $CPX $CPY $CGX $CGY
$btnsC3=Place-Grid $grpC3 $CL3 "Orange"  2 $CBTW $CBTH $CPX $CPY $CGX $CGY
$btnsC4=Place-Grid $grpC4 $CL4 "Magenta" 2 $CBTW $CBTH $CPX $CPY $CGX $CGY

# Colores AUTOMATIZACION
$btnsC4[0].Text = "RESET RAPIDO ENTREGA"
$btnsC4[0].ForeColor = [System.Drawing.Color]::FromArgb(220,60,220)
$btnsC4[0].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(220,60,220)
$btnsC4[0].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

$btnsC4[1].Text = "INSTALAR APKs"
$btnsC4[1].ForeColor = [System.Drawing.Color]::FromArgb(180,80,255)
$btnsC4[1].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(180,80,255)
$btnsC4[1].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# Log columna derecha
$CLOGY=6; $CLOGH=616

$Global:logCtrl = New-Object Windows.Forms.TextBox
$Global:logCtrl.Multiline    = $true
$Global:logCtrl.Location     = New-Object System.Drawing.Point($CLOGX,$CLOGY)
$Global:logCtrl.Size         = New-Object System.Drawing.Size($CLOGW,$CLOGH)
$Global:logCtrl.BackColor    = "Black"
$Global:logCtrl.ForeColor    = [System.Drawing.Color]::FromArgb(255,220,50)
$Global:logCtrl.BorderStyle  = "FixedSingle"
$Global:logCtrl.ScrollBars   = "Vertical"
$Global:logCtrl.Font         = New-Object System.Drawing.Font("Consolas",8.5)
$Global:logCtrl.ReadOnly     = $true
$tabCtrl.Controls.Add($Global:logCtrl)

$ctxCtrl     = New-Object System.Windows.Forms.ContextMenuStrip
$mnuClearCtrl= $ctxCtrl.Items.Add("Limpiar Log")
$mnuClearCtrl.Font      = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$mnuClearCtrl.ForeColor = [System.Drawing.Color]::OrangeRed
$mnuClearCtrl.Add_Click({ $Global:logCtrl.Clear() })
$Global:logCtrl.ContextMenuStrip = $ctxCtrl

function CtrlLog($msg) {
    if (-not $Global:logCtrl) { return }
    $ts = Get-Date -Format "HH:mm:ss"
    $Global:logCtrl.AppendText("[$ts] $msg`r`n")
    $Global:logCtrl.SelectionStart = $Global:logCtrl.TextLength
    $Global:logCtrl.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

#==========================================================================
# [C] HANDLERS - BLOQUE C1: LANZADORES (2 botones solamente)
#==========================================================================

# ---- C1[0]: ODIN3 ----
$btnsC1[0].Add_Click({
    $btn=$btnsC1[0]; $btn.Enabled=$false; $btn.Text="BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== ODIN3 LAUNCHER ==="
    try {
        $zipPath = Join-Path $script:TOOLS_DIR "Odin3.zip"
        if (-not (Test-Path $zipPath)) {
            CtrlLog "[!] No se encontro Odin3.zip en: $($script:TOOLS_DIR)"
            CtrlLog "[~] Coloca Odin3.zip (con Odin3.exe y Odin3.ini dentro) en tools\"
            [System.Windows.Forms.MessageBox]::Show("No se encontro Odin3.zip`n`nColoca Odin3.zip en:`n$($script:TOOLS_DIR)","Odin no encontrado","OK","Warning") | Out-Null
        } else {
            CtrlLog "[+] Odin3.zip encontrado"
            $tempDir = Join-Path $env:TEMP ("Odin_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $tempDir | Out-Null
            Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
            CtrlLog "[+] ZIP extraido OK"
            $odinExeItem = Get-ChildItem -Path $tempDir -Recurse -Filter "Odin3.exe" | Select-Object -First 1
            if (-not $odinExeItem) { $odinExeItem = Get-ChildItem -Path $tempDir -Recurse -Filter "Odin*.exe" | Select-Object -First 1 }
            if (-not $odinExeItem) { Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue; throw "No se encontro Odin3.exe en el ZIP" }
            $iniPath = Join-Path $odinExeItem.Directory.FullName "Odin3.ini"
            if (-not (Test-Path $iniPath)) {
                Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue
                CtrlLog "[!] Odin3.ini no encontrado junto al exe"
                [System.Windows.Forms.MessageBox]::Show("Odin3.ini no encontrado en el ZIP","Odin3.ini faltante","OK","Warning") | Out-Null
            } else {
                CtrlLog "[+] Odin3.ini OK"
                $odinProc = Start-Process -FilePath $odinExeItem.FullName -WorkingDirectory $odinExeItem.Directory.FullName -Verb RunAs -PassThru
                $pid2 = if ($odinProc) { $odinProc.Id } else { 0 }
                CtrlLog "[OK] Odin3 abierto$(if($pid2){' (PID: '+$pid2+')'} else {' (UAC)'})"
                $null = Start-Job -ScriptBlock {
                    param($procId,$dirPath)
                    if ($procId -gt 0) { try { $p=Get-Process -Id $procId -EA SilentlyContinue; if($p){$p.WaitForExit(600000)} } catch {} }
                    else { $s=Get-Date; while(((Get-Date)-$s).TotalSeconds -lt 300){ Start-Sleep 10; if(-not(Get-Process -Name "Odin*" -EA SilentlyContinue)){break} } }
                    Start-Sleep 5; try { Remove-Item -Path $dirPath -Recurse -Force -EA SilentlyContinue } catch {}
                } -ArgumentList $pid2,$tempDir
            }
        }
    } catch { CtrlLog "[!] Error: $_" }
    $btn.Enabled=$true; $btn.Text="ODIN3"
})

# ---- C1[1]: HxD HEX EDITOR ----
$btnsC1[1].Add_Click({
    $btn=$btnsC1[1]; $btn.Enabled=$false; $btn.Text="BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== HxD HEX EDITOR ==="
    $hxd = $null
    foreach ($c in @(
        (Join-Path $script:TOOLS_DIR "HxD.exe"),
        (Join-Path $script:TOOLS_DIR "hxd\HxD.exe"),
        "$env:ProgramFiles\HxD\HxD.exe",
        "${env:ProgramFiles(x86)}\HxD\HxD.exe"
    )) { if (Test-Path $c -EA SilentlyContinue) { $hxd=$c; break } }
    if (-not $hxd) { try { $hxd=$(try{(Get-Command "HxD.exe" -EA SilentlyContinue).Source}catch{""}) } catch {} }
    if ($hxd) {
        CtrlLog "[+] HxD: $hxd"
        try { Start-Process $hxd; CtrlLog "[OK] HxD abierto" } catch { CtrlLog "[!] Error: $_" }
    } else {
        CtrlLog "[!] HxD no encontrado"
        $resp=[System.Windows.Forms.MessageBox]::Show("HxD no encontrado.`nAbrir pagina de descarga?","HxD","YesNo","Information")
        if ($resp -eq "Yes") { Start-Process "https://mh-nexus.de/en/hxd/"; CtrlLog "[~] Pagina abierta" }
    }
    $btn.Enabled=$true; $btn.Text="HxD HEX EDITOR"
})

# NOTA: QFIL (C1[2]) y USB DRIVERS (C1[3]) ELIMINADOS del bloque LANZADORES
# per instrucciones del usuario. El bloque queda con solo 2 botones.

#==========================================================================
# [D] HANDLERS - BLOQUE C2: DIAGNOSTICO ADB (sin cambios)
#==========================================================================

# ---- C2[0]: TEST PANTALLA ----
$btnsC2[0].Add_Click({
    $btn=$btnsC2[0]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== TEST PANTALLA ==="
    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="TEST PANTALLA"; return }
    function CtS($cmd) { $r=& adb shell $cmd 2>$null; if($r -is [array]){return ($r -join " ").Trim()}; return "$r".Trim() }
    $res=$( CtS "wm size" ); $dens=$(CtS "wm density"); $bright=$(CtS "settings get system screen_brightness")
    $brightM=$(CtS "settings get system screen_brightness_mode"); $timeout=$(CtS "settings get system screen_off_timeout")
    $ptrLoc=$(CtS "settings get system pointer_location")
    CtrlLog "[+] Resolucion : $res"; CtrlLog "[+] Densidad   : $dens"
    CtrlLog "[+] Brillo     : $bright/255 $(if($brightM -eq '1'){'(AUTO)'}else{'(MANUAL)'})"
    $toSec = try { [int]($timeout)/1000 } catch { "?" }
    CtrlLog "[+] Timeout    : ${toSec}s"; CtrlLog "[+] Pointer Loc: $(if($ptrLoc -eq '1'){'ACTIVO'}else{'INACTIVO'})"
    $btn.Enabled=$true; $btn.Text="TEST PANTALLA"
})

# ---- C2[1]: INFO BATERIA ----
$btnsC2[1].Add_Click({
    $btn=$btnsC2[1]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== INFO BATERIA ==="
    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="INFO BATERIA"; return }
    $dump = (& adb shell "dumpsys battery" 2>$null) -join "`n"
    function ParseBat($key) { if ($dump -match "(?m)$key[:\s]+(.+)") { return $Matches[1].Trim() }; return "?" }
    $nivel=$( ParseBat "level" ); $status=$(ParseBat "status"); $health=$(ParseBat "health")
    $temp=$( ParseBat "temperature" ); $volt=$(ParseBat "voltage")
    $statusStr=switch($status){"2"{"CARGANDO"}"3"{"DESCARGANDO"}"4"{"NO CARGA"}"5"{"LLENA"}default{"Estado $status"}}
    $healthStr=switch($health){"2"{"BUENA"}"3"{"SOBRECALENTAMIENTO"}"4"{"MUERTA"}"5"{"SOBREVOLTAJE"}default{"Estado $health"}}
    $tempC = try { [math]::Round([double]$temp/10,1) } catch { "?" }
    $voltV = try { [math]::Round([double]$volt/1000,2) } catch { "?" }
    CtrlLog "[+] Nivel       : $nivel%"; CtrlLog "[+] Estado      : $statusStr"
    CtrlLog "[+] Salud       : $healthStr"; CtrlLog "[+] Temperatura : $tempC C"; CtrlLog "[+] Voltaje     : $voltV V"
    $btn.Enabled=$true; $btn.Text="INFO BATERIA"
})

# ---- C2[2]: ALMACENAMIENTO ----
$btnsC2[2].Add_Click({
    $btn=$btnsC2[2]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== ALMACENAMIENTO ==="
    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="ALMACENAMIENTO"; return }
    $dfRaw = (& adb shell "df -h 2>/dev/null" 2>$null)
    $memRaw= (& adb shell "cat /proc/meminfo 2>/dev/null" 2>$null) -join "`n"
    function GetMemMB($key) { if ($memRaw -match "(?m)$key[\:\s]+(\d+)") { return [math]::Round([int]$Matches[1]/1024,0) }; return 0 }
    $memTotal=$(GetMemMB "MemTotal"); $memFree=$(GetMemMB "MemFree"); $memAvail=$(GetMemMB "MemAvailable")
    $_avail=if($memAvail -gt 0){$memAvail}else{$memFree}; $memUsed=$memTotal-$_avail
    $memPct=if($memTotal -gt 0){[math]::Round($memUsed/$memTotal*100,0)}else{0}
    CtrlLog "[+] RAM Total : $memTotal MB"; CtrlLog "[+] RAM Usada : $memUsed MB ($memPct%)"
    $relevantes=@("/data","/system","/vendor","/sdcard","/storage/emulated")
    if ($dfRaw) {
        foreach ($line in $dfRaw) {
            $l="$line".Trim(); if(-not $l -or $l -match "^Filesystem|^Size"){continue}
            $mostrar=$false; foreach($r in $relevantes){if($l -match [regex]::Escape($r)){$mostrar=$true;break}}
            if(-not $mostrar){continue}
            $parts=$l -split "\s+"
            if($parts.Count -ge 6){ CtrlLog "[+] $($parts[-1]) | $($parts[2]) / $($parts[1]) ($($parts[-2]))" }
        }
    }
    $btn.Enabled=$true; $btn.Text="ALMACENAMIENTO"
})

# ---- C2[3]: APPS INSTALADAS ----
$btnsC2[3].Add_Click({
    $btn=$btnsC2[3]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== APPS INSTALADAS ==="
    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="APPS INSTALADAS"; return }
    $pkgUser  =(& adb shell "pm list packages -3" 2>$null) | Where-Object { $_ -match "package:" }
    $pkgSystem=(& adb shell "pm list packages -s" 2>$null) | Where-Object { $_ -match "package:" }
    $pkgDis   =(& adb shell "pm list packages -d" 2>$null) | Where-Object { $_ -match "package:" }
    CtrlLog "[+] Apps usuario : $($pkgUser.Count)"; CtrlLog "[+] Apps sistema : $($pkgSystem.Count)"
    CtrlLog "[+] Desactivadas : $($pkgDis.Count)"; CtrlLog "[+] TOTAL: $($pkgUser.Count+$pkgSystem.Count)"
    $btn.Enabled=$true; $btn.Text="APPS INSTALADAS"
})

#==========================================================================
# [E] HANDLERS - BLOQUE C3: SISTEMA / PC (sin cambios)
#==========================================================================

# ---- C3[0]: ADMIN TAREAS ----
$btnsC3[0].Add_Click({
    CtrlLog ""; CtrlLog "=== ADMIN TAREAS ==="
    try { Start-Process "taskmgr"; CtrlLog "[OK] Administrador de tareas abierto" }
    catch { CtrlLog "[!] Error: $_" }
})

# ---- C3[1]: ADMIN DISPOSITIVOS ----
$btnsC3[1].Add_Click({
    $btn=$btnsC3[1]; $btn.Enabled=$false; $btn.Text="ABRIENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== ADMIN DISPOSITIVOS ==="
    try { Start-Process "devmgmt.msc"; CtrlLog "[OK] Administrador de dispositivos abierto" }
    catch { CtrlLog "[!] No se pudo abrir devmgmt.msc: $_" }
    CtrlLog "[~] Dispositivos con error (WMI):"
    try {
        $devErr = Get-WmiObject Win32_PnPEntity -EA SilentlyContinue |
            Where-Object { $_.ConfigManagerErrorCode -ne 0 } |
            Select-Object Name,ConfigManagerErrorCode
        if ($devErr) { foreach ($d in $devErr) { CtrlLog " [ERR $($d.ConfigManagerErrorCode)] $($d.Name)" } }
        else { CtrlLog " [OK] No hay dispositivos con error" }
    } catch { CtrlLog " [~] WMI no disponible: $_" }
    $btn.Enabled=$true; $btn.Text="ADMIN DISPOSITIVOS"
})

# ---- C3[2]: DESACTIVAR DEFENDER ----
$btnsC3[2].Add_Click({
    $btn=$btnsC3[2]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== WINDOWS DEFENDER ==="
    try {
        $status=Get-MpComputerStatus -EA Stop
        CtrlLog "[+] Proteccion RT: $(if($status.RealTimeProtectionEnabled){'ACTIVA'}else{'INACTIVA'})"
    } catch { CtrlLog "[~] Get-MpComputerStatus no disponible" }
    try { Start-Process "windowsdefender://threatsettings"; CtrlLog "[OK] Panel Defender abierto" }
    catch { try { Start-Process "ms-settings:windowsdefender" } catch { CtrlLog "[!] Error: $_" } }
    CtrlLog "[i] Desactivar: Proteccion en tiempo real -> OFF"
    $btn.Enabled=$true; $btn.Text="DESACTIVAR DEFENDER"
})

# ---- C3[3]: REINICIAR ADB ----
$btnsC3[3].Add_Click({
    $btn=$btnsC3[3]; $btn.Enabled=$false; $btn.Text="REINICIANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== REINICIAR ADB ==="
    $adbProcs=Get-Process -Name "adb" -EA SilentlyContinue
    if ($adbProcs) { foreach ($p in $adbProcs) { try { $p.Kill(); CtrlLog " [OK] adb.exe PID $($p.Id) terminado" } catch {} } }
    else { CtrlLog " [OK] No habia adb.exe activo" }
    Start-Sleep -Milliseconds 500; [System.Windows.Forms.Application]::DoEvents()
    $ks=(& adb kill-server 2>&1) -join ""; CtrlLog "[~] kill-server: $($ks.Trim())"
    Start-Sleep -Milliseconds 300
    $ss=(& adb start-server 2>&1) -join ""; CtrlLog "[~] start-server: $($ss.Trim())"
    Start-Sleep -Milliseconds 800; [System.Windows.Forms.Application]::DoEvents()
    $devs=(& adb devices 2>$null) | Where-Object { $_ -notmatch "^List|^$" }
    if ($devs) { foreach ($d in $devs) { if($d.Trim()){CtrlLog " -> $($d.Trim())"} } }
    else { CtrlLog " (ninguno conectado)" }
    CtrlLog "[OK] ADB reiniciado"
    $btn.Enabled=$true; $btn.Text="REINICIAR ADB"
})

# ---- C3[4]: MONITOR PC ----
$btnsC3[4].Add_Click({
    $btn=$btnsC3[4]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== MONITOR PC ==="
    $cpu = (Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1)
    $ram = (Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue)
    $os  = (Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue)
    if ($cpu) { CtrlLog "[+] CPU: $($cpu.Name.Trim())" }
    if ($ram) { CtrlLog "[+] RAM Total: $([math]::Round($ram.TotalPhysicalMemory/1GB,1)) GB" }
    if ($os)  {
        $ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB,1)
        CtrlLog "[+] RAM Usada : $ramUsed GB"
        CtrlLog "[+] OS: $($os.Caption) $($os.Version)"
    }
    # Discos
    Get-PSDrive -PSProvider FileSystem -EA SilentlyContinue | Where-Object { $_.Used } | ForEach-Object {
        $total = [math]::Round(($_.Used + $_.Free)/1GB, 1)
        $usedG = [math]::Round($_.Used/1GB, 1)
        $pct   = if($total -gt 0){[math]::Round($usedG/$total*100,0)}else{0}
        CtrlLog "[+] Disco $($_.Name): $usedG/$total GB ($pct% usado)"
    }
    $btn.Enabled=$true; $btn.Text="MONITOR PC"
})

# ---- C3[5]: LIMPIEZA TEMP PC ----
$btnsC3[5].Add_Click({
    $btn=$btnsC3[5]; $btn.Enabled=$false; $btn.Text="LIMPIANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== LIMPIEZA TEMP PC ==="
    $paths = @($env:TEMP, "$env:SystemRoot\Temp", "$env:LOCALAPPDATA\Temp")
    $totalDel = 0
    foreach ($p in $paths) {
        if (-not (Test-Path $p)) { continue }
        CtrlLog "[~] Limpiando: $p"
        $files = Get-ChildItem $p -Recurse -Force -EA SilentlyContinue
        foreach ($f in $files) {
            try { Remove-Item $f.FullName -Force -Recurse -EA SilentlyContinue; $totalDel++ } catch {}
        }
    }
    CtrlLog "[OK] Limpieza completada: $totalDel elementos eliminados"
    $btn.Enabled=$true; $btn.Text="LIMPIEZA TEMP PC"
})

#==========================================================================
# [F] HANDLERS - BLOQUE C4: AUTOMATIZACION Y ENTREGAS
#     (Movido desde 05_tab_adb.ps1 - grpA4 original)
#==========================================================================

# ---- C4[0]: RESET RAPIDO ENTREGA ----
$btnsC4[0].Add_Click({
    $btn=$btnsC4[0]; $btn.Enabled=$false; $btn.Text="EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== RESET RAPIDO ENTREGA ==="
    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="RESET RAPIDO ENTREGA"; return }

    $confirm=[System.Windows.Forms.MessageBox]::Show(
        "Esta accion realizara un RESET DE FABRICA del dispositivo conectado.`n`nContinuar?",
        "RESET RAPIDO ENTREGA","YesNo","Warning")
    if ($confirm -ne "Yes") { CtrlLog "[~] Cancelado."; $btn.Enabled=$true; $btn.Text="RESET RAPIDO ENTREGA"; return }

    CtrlLog "[~] Paso 1: Desactivando FRP guard..."
    & adb shell "content insert --uri content://settings/secure --bind name:s:user_setup_complete --bind value:s:1" 2>$null | Out-Null
    & adb shell "content insert --uri content://settings/global --bind name:s:device_provisioned --bind value:s:1" 2>$null | Out-Null
    CtrlLog "[+] FRP guard desactivado"

    CtrlLog "[~] Paso 2: Limpiando cuentas Google..."
    & adb shell "pm clear com.google.android.gms" 2>$null | Out-Null
    & adb shell "pm clear com.google.android.gsf" 2>$null | Out-Null
    CtrlLog "[+] Cuentas Google limpiadas"

    CtrlLog "[~] Paso 3: Factory reset via ADB..."
    & adb shell "am broadcast -a android.intent.action.MASTER_CLEAR" 2>$null | Out-Null
    CtrlLog "[OK] Reset iniciado - el equipo se reiniciara solo"
    CtrlLog "[~] Tiempo estimado: 2-5 minutos"

    $btn.Enabled=$true; $btn.Text="RESET RAPIDO ENTREGA"
})

# ---- C4[1]: INSTALAR APKs ----
$btnsC4[1].Add_Click({
    $btn=$btnsC4[1]; $btn.Enabled=$false; $btn.Text="SELECCIONANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== INSTALAR APKs ==="
    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="INSTALAR APKs"; return }

    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter    = "APK Files (*.apk)|*.apk|Todos|*.*"
    $fd.Title     = "Selecciona APKs a instalar (CTRL para seleccionar multiples)"
    $fd.Multiselect = $true
    if ($fd.ShowDialog() -ne "OK") { CtrlLog "[~] Cancelado."; $btn.Enabled=$true; $btn.Text="INSTALAR APKs"; return }

    $apks = $fd.FileNames
    CtrlLog "[+] APKs seleccionados: $($apks.Count)"
    $ok=0; $fail=0

    foreach ($apk in $apks) {
        $name=[System.IO.Path]::GetFileName($apk)
        CtrlLog "[~] Instalando: $name"
        $btn.Text="INSTALANDO $ok/$($apks.Count)..."
        [System.Windows.Forms.Application]::DoEvents()
        $res = (& adb install -r "$apk" 2>&1) -join ""
        if ($res -match "Success") {
            CtrlLog " [OK] $name instalado"
            $ok++
        } else {
            CtrlLog " [!] Fallo: $name"
            CtrlLog "     -> $($res.Trim())"
            $fail++
        }
    }
    CtrlLog ""; CtrlLog "[+] Instalados: $ok / $($apks.Count) | Fallidos: $fail"
    $btn.Enabled=$true; $btn.Text="INSTALAR APKs"
})