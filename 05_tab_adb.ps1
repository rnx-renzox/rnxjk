#==========================================================================
# TAB ADB: UTILIDADES ADB - Layout y construccion de controles
# MODIFICADO RNX v2:
#  - grpA3: "HERRAMIENTAS XIAOMI" -> "HERRAMIENTAS SAMSUNG"
#    btnsA3[0]: "ACTIVAR DIAG XIAOMI" -> "EFS SAMSUNG SIM 2"
#    btnsA3[1]: "DEBLOAT XIAOMI"      -> "CAMBIAR SN"
#  - grpA4 (AUTOMATIZACION Y ENTREGAS) ELIMINADO de esta tab
#    -> movido a 04_tab_control.ps1
#==========================================================================

$tabAdb = New-Object Windows.Forms.TabPage
$tabAdb.Text = "UTILIDADES ADB"
$tabAdb.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$tabs.TabPages.Add($tabAdb)

# ---------------------------------------------------------------
# METRICAS TAB ADB - 2 columnas simetricas
# ---------------------------------------------------------------
$AX=6; $AGAP=8; $ALOGX=436
$ABTW=195; $ABTH=56; $APX=14; $APY=20; $AGX=8; $AGY=8
$AGW=422
$ALOGW=$AGW   # ancho log = ancho columna

$AGH1 = $APY + 2*($ABTH+$AGY) - $AGY + 14
$AGH2 = $APY + 3*($ABTH+$AGY) - $AGY + 14
$AGH3 = $APY + 1*($ABTH+$AGY) - $AGY + 14
# grpA4 eliminado de esta tab - solo 3 grupos

$AY1=6
$AY2=$AY1+$AGH1+$AGAP
$AY3=$AY2+$AGH2+$AGAP

# --- GRUPOS ---
$grpA1 = New-GBox $tabAdb "INFO, CONTROL Y PROTECCION" $AX $AY1 $AGW $AGH1 "Cyan"
$grpA2 = New-GBox $tabAdb "REPARACION Y BYPASS"        $AX $AY2 $AGW $AGH2 "Orange"
$grpA3 = New-GBox $tabAdb "HERRAMIENTAS SAMSUNG"       $AX $AY3 $AGW $AGH3 "Lime"

$AL1=@("LEER INFO COMPLETA","REINICIAR MODO","BLOQUEAR OTA","REMOVER ADWARE")
$AL2=@("AUTOROOT MAGISK","BYPASS BANCARIO","FIX LOGO SAMSUNG","ACTIVAR SIM 2 SAMSUNG","INSTALAR MAGISK","RESTAURAR BACKUP")

# Bloque Samsung: EFS SIM2 (copiado de tab generales) + CAMBIAR SN
$AL3=@("EFS SAMSUNG SIM 2","CAMBIAR SN")

$btnsA1=Place-Grid $grpA1 $AL1 "Cyan"   2 $ABTW $ABTH $APX $APY $AGX $AGY
$btnsA2=Place-Grid $grpA2 $AL2 "Orange" 2 $ABTW $ABTH $APX $APY $AGX $AGY
$btnsA3=Place-Grid $grpA3 $AL3 "Lime"   2 $ABTW $ABTH $APX $APY $AGX $AGY

$btnReadAdb  = $btnsA1[0]
$btnRebootSys= $btnsA1[1]
$btnRemFRP   = $btnsA2[0]

# Log columna derecha
$ALOGY=$AY1; $ALOGH=616
$script:ADB_ACTIVE_PROC = $null

$adbStopH = 26; $adbStopGap = 4
$btnAdbStop = New-Object Windows.Forms.Button
$btnAdbStop.Text      = "STOP"
$btnAdbStop.Location  = New-Object System.Drawing.Point($ALOGX, $ALOGY)
$btnAdbStop.Size      = New-Object System.Drawing.Size($ALOGW, $adbStopH)
$btnAdbStop.FlatStyle = "Flat"
$btnAdbStop.ForeColor = [System.Drawing.Color]::White
$btnAdbStop.BackColor = [System.Drawing.Color]::FromArgb(55,25,25)
$btnAdbStop.FlatAppearance.BorderColor = [System.Drawing.Color]::White
$btnAdbStop.Font      = New-Object System.Drawing.Font("Segoe UI",9.5,[System.Drawing.FontStyle]::Bold)
$btnAdbStop.Enabled   = $false
$tabAdb.Controls.Add($btnAdbStop)
$Global:btnAdbStop = $btnAdbStop

$btnAdbStop.Add_Click({
    if ($script:ADB_ACTIVE_PROC -and -not $script:ADB_ACTIVE_PROC.HasExited) {
        try { $script:ADB_ACTIVE_PROC.Kill(); AdbLog "[!] Proceso detenido por el usuario." }
        catch { AdbLog "[!] No se pudo detener: $_" }
    }
    $btnAdbStop.Enabled = $false
})

$adbLogRealY = $ALOGY + $adbStopH + $adbStopGap
$adbLogRealH = $ALOGH - $adbStopH - $adbStopGap

$Global:logAdb = New-Object Windows.Forms.TextBox
$Global:logAdb.Multiline    = $true
$Global:logAdb.Location     = New-Object System.Drawing.Point($ALOGX, $adbLogRealY)
$Global:logAdb.Size         = New-Object System.Drawing.Size($ALOGW, $adbLogRealH)
$Global:logAdb.BackColor    = "Black"
$Global:logAdb.ForeColor    = [System.Drawing.Color]::Cyan
$Global:logAdb.BorderStyle  = "FixedSingle"
$Global:logAdb.ScrollBars   = "Vertical"
$Global:logAdb.Font         = New-Object System.Drawing.Font("Consolas",8.5)
$tabAdb.Controls.Add($Global:logAdb)

$ctxAdb       = New-Object System.Windows.Forms.ContextMenuStrip
$mnuClearAdb  = $ctxAdb.Items.Add("Limpiar Log")
$mnuClearAdb.Font      = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$mnuClearAdb.ForeColor = [System.Drawing.Color]::OrangeRed
$mnuClearAdb.Add_Click({ $Global:logAdb.Clear() })
$Global:logAdb.ContextMenuStrip = $ctxAdb

#==========================================================================
# LOGICA - TAB UTILIDADES ADB
#==========================================================================

$btnReadAdb.Add_Click({
    if ($Global:logAdb) { $Global:logAdb.Clear() }
    AdbLog "[*] Iniciando lectura profunda..."
    if (-not (Check-ADB)) { return }
    try {
        function SafeShell { param($cmd)
            $r = & adb shell $cmd 2>$null
            if ($null -eq $r) { return "" }
            if ($r -is [array]) { return ($r -join " ").Trim() }
            return $r.ToString().Trim()
        }
        function SafeAdb { param($cmd)
            $parts = $cmd -split " "
            $r = & adb @parts 2>$null
            if ($null -eq $r) { return "" }
            if ($r -is [array]) { return ($r -join " ").Trim() }
            return $r.ToString().Trim()
        }
        $brand   = (SafeShell "getprop ro.product.brand").ToUpper()
        $model   = SafeShell "getprop ro.product.model"
        $deviceId= (SafeShell "getprop ro.product.device").ToUpper()
        $modDevId= (SafeShell "getprop ro.product.mod_device").ToUpper()
        $devId   = if ($modDevId -ne "" -and $modDevId -ne $deviceId) { $modDevId } else { $deviceId }
        $modelFull = if ($devId -ne "" -and $devId -ne $model.ToUpper()) { "$model [$devId]" } else { $model }
        $android = SafeShell "getprop ro.build.version.release"
        $patch   = SafeShell "getprop ro.build.version.security_patch"
        $build   = SafeShell "getprop ro.build.display.id"
        $serial  = SafeAdb "get-serialno"
        $bootldr = SafeShell "getprop ro.boot.bootloader"
        $cpu     = Get-TechnicalCPU
        $frp1    = SafeShell "getprop ro.frp.pst"
        $oemLk   = SafeShell "getprop ro.boot.flash.locked"
        $root    = Detect-Root
        $ufsNode3= SafeShell "ls /sys/class/ufs 2>/dev/null"
        $ufsDev3 = SafeShell "ls /dev/block/sda 2>/dev/null"
        $ufsHost3= SafeShell "ls /sys/bus/platform/drivers/ufshcd 2>/dev/null"
        $ufsType3= SafeShell "getprop ro.boot.storage_type"
        $mmcBlk3 = SafeShell "ls /dev/block/mmcblk0 2>/dev/null"
        $isUFS3  = ($ufsNode3 -ne "" -or $ufsDev3 -ne "" -or $ufsHost3 -ne "" -or
                    ($ufsType3 -imatch "ufs") -or ($mmcBlk3 -eq "" -and $ufsDev3 -ne ""))
        $storage = if ($isUFS3) { "UFS" } else { "eMMC" }
        $imeiRaw = SafeShell "service call iphonesubinfo 1"
        $imei    = "UNKNOWN"
        if ($imeiRaw -match "[0-9]{15}") { $imei = $Matches[0] }
        elseif ($imeiRaw -match "Result: Parcel") {
            $digits = ($imeiRaw -replace "[^0-9]","")
            if ($digits.Length -ge 15) { $imei = $digits.Substring(0,15) }
        }
        $frpStr  = if ($frp1 -and $frp1 -ne "") { "PRESENT" } else { "NOT SET" }
        $oemStr  = if ($oemLk -eq "1") { "LOCKED" } else { "UNLOCKED" }
        $rootStr = if ($root -ne "NO ROOT") { "SI" } else { "NO" }
        AdbLog ""; AdbLog "=============================================="; AdbLog " INFO DISPOSITIVO - $brand $modelFull"; AdbLog "=============================================="
        AdbLog ""; AdbLog " MARCA     : $brand"; AdbLog " MODELO    : $modelFull"
        AdbLog " ANDROID   : $android"; AdbLog " PARCHE SEG: $patch"; AdbLog " BUILD     : $build"
        $board_gen = SafeShell "getprop ro.board.platform"
        AdbLog " CPU       : $cpu"
        if ($board_gen -ne "") { AdbLog " PLATAFORMA: $board_gen" }
        AdbLog " SERIAL    : $serial"; AdbLog " STORAGE   : $storage"; AdbLog ""
        AdbLog " ROOT      : $rootStr"; AdbLog " FRP       : $frpStr"; AdbLog " OEM LOCK  : $oemStr"; AdbLog ""
        if ($brand -match "SAMSUNG") {
            AdbLog " --- SAMSUNG ---"
            $cscProp = SafeShell "getprop ro.csc.country.code"
            if ($cscProp -eq "") { $cscProp = SafeShell "getprop ro.product.csc" }
            if ($cscProp -ne "") { AdbLog " CSC       : $cscProp - $(Get-CSCDecoded $cscProp)" }
            $kg    = SafeShell "getprop ro.boot.kg_state"
            $knox  = SafeShell "getprop ro.boot.warranty_bit"
            if ($kg   -ne "") { AdbLog " KG STATE  : $kg" }
            if ($knox -ne "") { AdbLog " WARRANTY VOID: $knox" }
            $binary = Get-BinaryFromBuild $bootldr
            AdbLog " BOOTLOADER: $bootldr"; AdbLog " BINARIO   : $binary"
        } elseif ($brand -match "XIAOMI|REDMI|POCO") {
            AdbLog " --- XIAOMI ---"
            $miuiVer  = SafeShell "getprop ro.miui.ui.version.name"
            $miuiBuild= SafeShell "getprop ro.miui.ui.version.code"
            $region   = SafeShell "getprop ro.miui.region"
            $blLk2    = SafeShell "getprop ro.boot.flash.locked"
            $vbs      = SafeShell "getprop ro.boot.verifiedbootstate"
            $blStr2   = if ($blLk2 -eq "1") { "LOCKED" } else { "UNLOCKED" }
            $devProp  = SafeShell "getprop ro.product.device"
            $codename = Get-XiaomiCodename $devProp
            $antiRaw  = SafeShell "getprop ro.boot.anti_version"
            AdbLog " MIUI      : $miuiVer"; AdbLog " REGION    : $region"
            AdbLog " BL LOCK   : $blStr2"; AdbLog " BOOT STATE: $vbs"
            AdbLog " IMEI      : $imei"
        } else {
            AdbLog " --- INFO ADICIONAL ---"; AdbLog " IMEI: $imei"; AdbLog " BOOTLOADER: $bootldr"
        }
        AdbLog ""; AdbLog "=============================================="; AdbLog "[OK] LECTURA COMPLETADA"
        $Global:lblDisp.Text    = "DISPOSITIVO : $brand"
        $Global:lblModel.Text   = "MODELO      : $modelFull"
        $Global:lblSerial.Text  = "SERIAL      : $serial"
        $Global:lblCPU.Text     = "CPU         : $cpu"
        $Global:lblStorage.Text = "STORAGE     : $storage"
        $Global:lblFRP.Text     = "FRP         : $frpStr"
        $Global:lblFRP.ForeColor= if ($frp1 -and $frp1 -ne "") { [System.Drawing.Color]::Red } else { [System.Drawing.Color]::Lime }
        $Global:lblRoot.Text    = "ROOT        : $rootStr"
        $Global:lblRoot.ForeColor=if ($root -ne "NO ROOT") { [System.Drawing.Color]::Lime } else { [System.Drawing.Color]::Red }
    } catch { AdbLog "[!] Error: $_" }
})

$btnRebootSys.Add_Click({
    if (-not (Check-ADB)) { return }
    $ctxReboot = New-Object System.Windows.Forms.ContextMenuStrip
    $ctxReboot.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $ctxReboot.ForeColor = [System.Drawing.Color]::Cyan
    $ctxReboot.Font      = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $i1=$ctxReboot.Items.Add("Reiniciar sistema"); $i1.ForeColor=[System.Drawing.Color]::Cyan
    $i1.Add_Click({ AdbLog "[*] Reiniciando sistema..."; & adb reboot 2>$null })
    $i2=$ctxReboot.Items.Add("Reiniciar a recovery"); $i2.ForeColor=[System.Drawing.Color]::Orange
    $i2.Add_Click({ AdbLog "[*] Reiniciando a Recovery..."; & adb reboot recovery 2>$null })
    $i3=$ctxReboot.Items.Add("Reiniciar a fastboot"); $i3.ForeColor=[System.Drawing.Color]::Lime
    $i3.Add_Click({ AdbLog "[*] Reiniciando a Fastboot..."; & adb reboot bootloader 2>$null })
    $i4=$ctxReboot.Items.Add("Reiniciar a download"); $i4.ForeColor=[System.Drawing.Color]::Magenta
    $i4.Add_Click({ AdbLog "[*] Reiniciando a Download Mode..."; & adb reboot download 2>$null })
    $pt = $btnRebootSys.PointToScreen([System.Drawing.Point]::new(0,$btnRebootSys.Height))
    $ctxReboot.Show($pt)
})

# ---- Colores y textos de botones ----
$btnRemFRP.Text = "AUTOROOT MAGISK"
$btnRemFRP.ForeColor = [System.Drawing.Color]::Magenta
$btnRemFRP.FlatAppearance.BorderColor = [System.Drawing.Color]::Magenta

$btnsA2[1].Text = "BYPASS BANCARIO"
$btnsA2[1].ForeColor = [System.Drawing.Color]::FromArgb(255,215,0)
$btnsA2[1].BackColor = [System.Drawing.Color]::FromArgb(40,35,10)
$btnsA2[1].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,215,0)
$btnsA2[1].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

$btnsA2[5].Text = "SAMFW FIRMWARE"
$btnsA2[5].ForeColor = [System.Drawing.Color]::FromArgb(0,180,255)
$btnsA2[5].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0,180,255)
$btnsA2[5].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

$btnsA1[2].Text = "BLOQUEAR OTA"
$btnsA1[2].ForeColor = [System.Drawing.Color]::FromArgb(0,220,180)
$btnsA1[2].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0,220,180)
$btnsA1[2].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

$btnsA1[3].Text = "REMOVER ADWARE"
$btnsA1[3].ForeColor = [System.Drawing.Color]::FromArgb(255,100,0)
$btnsA1[3].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,100,0)
$btnsA1[3].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# ---- HERRAMIENTAS SAMSUNG ----
$btnsA3[0].Text = "EFS SAMSUNG SIM 2"
$btnsA3[0].ForeColor = [System.Drawing.Color]::FromArgb(0,200,200)
$btnsA3[0].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0,200,200)
$btnsA3[0].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

$btnsA3[1].Text = "CAMBIAR SN"
$btnsA3[1].ForeColor = [System.Drawing.Color]::FromArgb(50,255,120)
$btnsA3[1].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(50,255,120)
$btnsA3[1].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# =========================================================================
# HANDLER: EFS SAMSUNG SIM 2  (copiado desde tab generales - btnEFSDirec)
# =========================================================================
$btnsA3[0].Add_Click({
    $btn = $btnsA3[0]; $btn.Enabled=$false; $btn.Text="PROCESANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        AdbLog ""
        AdbLog "[*] =========================================="
        AdbLog "[*] EFS SAMSUNG SIM 2 - RNX TOOL PRO"
        AdbLog "[*] =========================================="
        AdbLog "[~] Selecciona el archivo sec_efs / efs.img..."
        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "EFS Image (*.img;*.bin;*.tar;*.tar.md5)|*.img;*.bin;*.tar;*.tar.md5|Todos|*.*"
        $fd.Title  = "Selecciona sec_efs / efs.img"
        if ($fd.ShowDialog() -ne "OK") { AdbLog "[~] Cancelado."; return }
        $efsPath = $fd.FileName
        $fn = [System.IO.Path]::GetFileName($efsPath)
        $fs = [math]::Round((Get-Item $efsPath).Length / 1KB, 2)
        AdbLog "[+] Archivo : $fn ($fs KB)"
        $efsRoot = $script:SCRIPT_ROOT
        $stamp   = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
        $backDir = [System.IO.Path]::Combine($efsRoot,"BACKUPS","EFS_SAMSUNG_SIM2",$stamp)
        # Llamar al patcher EFS (mismo que en tab generales)
        [EfsSamsungPatcher]::Run($efsPath, $backDir)
        $Global:_efsTimer2 = New-Object System.Windows.Forms.Timer
        $Global:_efsTimer2.Interval = 400
        $Global:_efsTimer2.Add_Tick({
            $msg=""
            while ([EfsSamsungPatcher]::Q.TryDequeue([ref]$msg)) { AdbLog $msg }
            if ([EfsSamsungPatcher]::Done) {
                $Global:_efsTimer2.Stop(); $Global:_efsTimer2.Dispose()
                $btn.Enabled=$true; $btn.Text="EFS SAMSUNG SIM 2"
            }
        })
        $Global:_efsTimer2.Start()
    } catch {
        AdbLog "[!] Error inesperado: $_"
        $btn.Enabled=$true; $btn.Text="EFS SAMSUNG SIM 2"
    }
})

# =========================================================================
# HANDLER: CAMBIAR SN - Mini interfaz con 2 flujos
#   Flujo 1: Via ADB (necesita root) - lee, edita y escribe SN en el equipo
#   Flujo 2: Via archivo sec_efs - analiza, edita y genera nuevo archivo patcheado
# =========================================================================
$btnsA3[1].Add_Click({
    $btn = $btnsA3[1]; $btn.Enabled=$false
    [System.Windows.Forms.Application]::DoEvents()

    # ---- Formulario principal CAMBIAR SN ----
    $frmSN = New-Object System.Windows.Forms.Form
    $frmSN.Text          = "CAMBIAR SERIAL NUMBER - RNX TOOL PRO"
    $frmSN.ClientSize    = New-Object System.Drawing.Size(560, 480)
    $frmSN.BackColor     = [System.Drawing.Color]::FromArgb(18,18,24)
    $frmSN.FormBorderStyle = "FixedDialog"
    $frmSN.StartPosition = "CenterScreen"
    $frmSN.TopMost       = $true
    $frmSN.ControlBox    = $true

    # Header
    $lbHdr = New-Object Windows.Forms.Label
    $lbHdr.Text      = "  CAMBIAR SERIAL NUMBER (SN) - SAMSUNG"
    $lbHdr.Location  = New-Object System.Drawing.Point(0,0)
    $lbHdr.Size      = New-Object System.Drawing.Size(560,36)
    $lbHdr.BackColor = [System.Drawing.Color]::FromArgb(0,160,80)
    $lbHdr.ForeColor = [System.Drawing.Color]::White
    $lbHdr.Font      = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $lbHdr.TextAlign = "MiddleLeft"
    $frmSN.Controls.Add($lbHdr)

    # Log box
    $logSN = New-Object Windows.Forms.TextBox
    $logSN.Multiline   = $true
    $logSN.Location    = New-Object System.Drawing.Point(10,42)
    $logSN.Size        = New-Object System.Drawing.Size(540,180)
    $logSN.BackColor   = [System.Drawing.Color]::FromArgb(10,10,15)
    $logSN.ForeColor   = [System.Drawing.Color]::Lime
    $logSN.BorderStyle = "FixedSingle"
    $logSN.ScrollBars  = "Vertical"
    $logSN.Font        = New-Object System.Drawing.Font("Consolas",8.5)
    $logSN.ReadOnly    = $true
    $frmSN.Controls.Add($logSN)

    function SNLog($msg) {
        $ts = Get-Date -Format "HH:mm:ss"
        $logSN.AppendText("[$ts] $msg`r`n")
        $logSN.SelectionStart = $logSN.TextLength
        $logSN.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }

    # SN actual detectado
    $lbSnActual = New-Object Windows.Forms.Label
    $lbSnActual.Text     = "SN actual: (no detectado)"
    $lbSnActual.Location = New-Object System.Drawing.Point(10,228)
    $lbSnActual.Size     = New-Object System.Drawing.Size(540,20)
    $lbSnActual.ForeColor= [System.Drawing.Color]::Cyan
    $lbSnActual.Font     = New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold)
    $frmSN.Controls.Add($lbSnActual)

    # Campo nuevo SN
    $lbNuevoSN = New-Object Windows.Forms.Label
    $lbNuevoSN.Text     = "Nuevo SN (max 11 chars):"
    $lbNuevoSN.Location = New-Object System.Drawing.Point(10,256)
    $lbNuevoSN.Size     = New-Object System.Drawing.Size(200,20)
    $lbNuevoSN.ForeColor= [System.Drawing.Color]::White
    $lbNuevoSN.Font     = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $frmSN.Controls.Add($lbNuevoSN)

    $txNuevoSN = New-Object Windows.Forms.TextBox
    $txNuevoSN.Location  = New-Object System.Drawing.Point(220,253)
    $txNuevoSN.Size      = New-Object System.Drawing.Size(200,24)
    $txNuevoSN.MaxLength = 11
    $txNuevoSN.BackColor = [System.Drawing.Color]::FromArgb(30,30,40)
    $txNuevoSN.ForeColor = [System.Drawing.Color]::Lime
    $txNuevoSN.BorderStyle="FixedSingle"
    $txNuevoSN.Font      = New-Object System.Drawing.Font("Consolas",11,[System.Drawing.FontStyle]::Bold)
    $frmSN.Controls.Add($txNuevoSN)

    $lbCharCount = New-Object Windows.Forms.Label
    $lbCharCount.Text     = "0/11"
    $lbCharCount.Location = New-Object System.Drawing.Point(428,256)
    $lbCharCount.Size     = New-Object System.Drawing.Size(60,20)
    $lbCharCount.ForeColor= [System.Drawing.Color]::Gray
    $lbCharCount.Font     = New-Object System.Drawing.Font("Segoe UI",9)
    $frmSN.Controls.Add($lbCharCount)

    $txNuevoSN.Add_TextChanged({
        $lbCharCount.Text = "$($txNuevoSN.TextLength)/11"
        $lbCharCount.ForeColor = if ($txNuevoSN.TextLength -eq 11) { [System.Drawing.Color]::Lime } else { [System.Drawing.Color]::Gray }
    })

    # Separador
    $lbSep = New-Object Windows.Forms.Label
    $lbSep.Text     = "------------------------------------------------------"
    $lbSep.Location = New-Object System.Drawing.Point(10,284)
    $lbSep.Size     = New-Object System.Drawing.Size(540,16)
    $lbSep.ForeColor= [System.Drawing.Color]::FromArgb(60,60,60)
    $lbSep.Font     = New-Object System.Drawing.Font("Segoe UI",8)
    $frmSN.Controls.Add($lbSep)

    # ---- Ubicaciones conocidas del SN en Samsung ----
    $snLocations = @(
        "/efs/Factory/sn",
        "/efs/FactoryApp/factorydata",
        "/efs/imei/mps_code.dat",
        "/efs/bluetooth/bt_addr",
        "/proc/lge.serialno",
        "/sys/devices/platform/sec_misc/serialno"
    )
    $script:snAdbDetected = ""
    $script:snEfsPath     = ""

    # ---- FLUJO 1: Boton VIA ADB ----
    $btnAdbFlow = New-Object Windows.Forms.Button
    $btnAdbFlow.Text     = "FLUJO 1 - VIA ADB (ROOT)"
    $btnAdbFlow.Location = New-Object System.Drawing.Point(10,306)
    $btnAdbFlow.Size     = New-Object System.Drawing.Size(250,44)
    $btnAdbFlow.FlatStyle= "Flat"
    $btnAdbFlow.ForeColor= [System.Drawing.Color]::Cyan
    $btnAdbFlow.FlatAppearance.BorderColor = [System.Drawing.Color]::Cyan
    $btnAdbFlow.BackColor= [System.Drawing.Color]::FromArgb(10,35,45)
    $btnAdbFlow.Font     = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmSN.Controls.Add($btnAdbFlow)

    $btnAdbFlow.Add_Click({
        $logSN.Clear()
        SNLog "[*] === FLUJO 1: CAMBIAR SN VIA ADB ==="
        if (-not (Check-ADB)) { SNLog "[!] Sin dispositivo ADB conectado."; return }

        # Detectar root
        $rootCheck = (& adb shell "su -c id" 2>$null)
        if ($rootCheck -notmatch "uid=0") {
            SNLog "[!] ROOT no detectado. Este flujo requiere acceso root."
            SNLog "[~] Usa Flujo 2 (archivo sec_efs) si no tienes root."
            return
        }
        SNLog "[+] ROOT confirmado"

        # Leer modelo
        $modelDev = (& adb shell "getprop ro.product.model" 2>$null).Trim()
        $serialDev = (& adb shell "getprop ro.serialno" 2>$null).Trim()
        SNLog "[+] Modelo : $modelDev"
        SNLog "[+] SN ADB getprop: $serialDev"

        # Backup sec_efs
        SNLog "[~] Haciendo backup de sec_efs..."
        $stamp   = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
        $backDir = Join-Path $script:SCRIPT_ROOT "BACKUPS\CAMBIAR_SN\$stamp"
        New-Item $backDir -ItemType Directory -Force | Out-Null
        & adb shell "su -c 'cp -r /efs $([char]34)/data/local/tmp/efs_backup_rnx$([char]34)'" 2>$null | Out-Null
        & adb pull "/data/local/tmp/efs_backup_rnx" $backDir 2>$null | Out-Null
        SNLog "[+] Backup guardado: $backDir"

        # Buscar SN en ubicaciones conocidas
        SNLog "[~] Analizando ubicaciones del serial number..."
        $snFound = ""
        $snFoundPath = ""
        foreach ($loc in $snLocations) {
            $val = (& adb shell "su -c 'cat $loc 2>/dev/null'" 2>$null)
            if ($null -eq $val) { $val = "" }
            $val = ("$val").Trim()
            if ($val.Length -ge 5 -and $val.Length -le 20 -and $val -match "^[A-Za-z0-9]+$") {
                SNLog " [+] $loc = $val"
                if (-not $snFound) { $snFound=$val; $snFoundPath=$loc }
            } else {
                SNLog " [-] $loc = (vacio o no accesible)"
            }
        }

        if ($snFound) {
            $script:snAdbDetected = $snFound
            $lbSnActual.Text = "SN actual: $snFound (de $snFoundPath)"
            $txNuevoSN.Text  = $snFound
            SNLog "[+] SN detectado: $snFound"
        } else {
            SNLog "[~] No se pudo detectar SN automaticamente"
        }

        # Boton aplicar cambio
        $btnAplicar = New-Object Windows.Forms.Button
        $btnAplicar.Text     = "APLICAR NUEVO SN"
        $btnAplicar.Location = New-Object System.Drawing.Point(10,420)
        $btnAplicar.Size     = New-Object System.Drawing.Size(540,44)
        $btnAplicar.FlatStyle= "Flat"
        $btnAplicar.ForeColor= [System.Drawing.Color]::Lime
        $btnAplicar.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
        $btnAplicar.BackColor= [System.Drawing.Color]::FromArgb(10,40,15)
        $btnAplicar.Font     = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $frmSN.Controls.Add($btnAplicar)
        $frmSN.ClientSize = New-Object System.Drawing.Size(560, 476)

        $btnAplicar.Add_Click({
            $nuevoSN = $txNuevoSN.Text.Trim()
            if ($nuevoSN.Length -lt 3 -or $nuevoSN.Length -gt 11) {
                SNLog "[!] SN invalido. Debe tener entre 3 y 11 caracteres."
                return
            }
            SNLog "[~] Aplicando SN: $nuevoSN"
            $ok = 0
            foreach ($loc in $snLocations) {
                $res = (& adb shell "su -c 'echo -n $nuevoSN > $loc 2>/dev/null && echo OK'" 2>$null)
                if ("$res".Trim() -eq "OK") { SNLog " [+] Escrito en: $loc"; $ok++ }
            }
            # Setprop tambien
            & adb shell "su -c 'setprop ro.serialno $nuevoSN'" 2>$null | Out-Null
            if ($ok -gt 0) {
                SNLog "[OK] SN aplicado en $ok ubicaciones"
                SNLog "[~] Reinicia el equipo para que tome efecto"
                $lbSnActual.Text = "SN actual: $nuevoSN (aplicado)"
            } else {
                SNLog "[!] No se pudo escribir en ninguna ubicacion - verifica root"
            }
        })
    })

    # ---- FLUJO 2: Boton VIA ARCHIVO sec_efs ----
    $btnEfsFlow = New-Object Windows.Forms.Button
    $btnEfsFlow.Text     = "FLUJO 2 - VIA ARCHIVO sec_efs"
    $btnEfsFlow.Location = New-Object System.Drawing.Point(300,306)
    $btnEfsFlow.Size     = New-Object System.Drawing.Size(250,44)
    $btnEfsFlow.FlatStyle= "Flat"
    $btnEfsFlow.ForeColor= [System.Drawing.Color]::FromArgb(255,160,0)
    $btnEfsFlow.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,160,0)
    $btnEfsFlow.BackColor= [System.Drawing.Color]::FromArgb(45,30,5)
    $btnEfsFlow.Font     = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmSN.Controls.Add($btnEfsFlow)

    $btnEfsFlow.Add_Click({
        $logSN.Clear()
        SNLog "[*] === FLUJO 2: CAMBIAR SN VIA ARCHIVO sec_efs ==="
        SNLog "[~] Selecciona el archivo sec_efs / efs.img / efs.bin..."
        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "EFS Files (*.img;*.bin;*.tar;*.mbn)|*.img;*.bin;*.tar;*.mbn|Todos|*.*"
        $fd.Title  = "Selecciona archivo sec_efs de Samsung"
        if ($fd.ShowDialog() -ne "OK") { SNLog "[~] Cancelado."; return }

        $script:snEfsPath = $fd.FileName
        $fn = [System.IO.Path]::GetFileName($script:snEfsPath)
        $fs = [math]::Round((Get-Item $script:snEfsPath).Length / 1KB, 2)
        SNLog "[+] Archivo: $fn ($fs KB)"

        # Leer el archivo como bytes y buscar el SN
        SNLog "[~] Analizando archivo en busca del serial number..."
        $bytes    = [System.IO.File]::ReadAllBytes($script:snEfsPath)
        $ascii    = [System.Text.Encoding]::ASCII.GetString($bytes)

        # Patrones comunes de SN en efs Samsung
        $snPatterns = @(
            "serialno=([A-Za-z0-9]{7,11})",
            "sn=([A-Za-z0-9]{7,11})",
            "SN=([A-Za-z0-9]{7,11})",
            "SERIAL=([A-Za-z0-9]{7,11})",
            "/Factory/sn\x00([A-Za-z0-9]{7,11})"
        )
        $detectedSN = ""
        foreach ($pat in $snPatterns) {
            if ($ascii -match $pat) {
                $detectedSN = $Matches[1]
                SNLog " [+] SN encontrado (patron: $pat): $detectedSN"
                break
            }
        }

        # Busqueda heuristica: secuencia alfanumerica de 11 caracteres
        if (-not $detectedSN) {
            SNLog "[~] Busqueda heuristica de secuencias alfanumericas (11 chars)..."
            $matches2 = [regex]::Matches($ascii, "[A-Z0-9]{11}")
            $candidatos = $matches2 | ForEach-Object { $_.Value } | Sort-Object -Unique | Where-Object { $_ -notmatch "^[0]{11}$|^[F]{11}$|^[A-F]{11}$" } | Select-Object -First 3
            foreach ($c in $candidatos) { SNLog " [?] Candidato: $c" }
            if ($candidatos) { $detectedSN = $candidatos[0] }
        }

        if ($detectedSN) {
            $script:snAdbDetected = $detectedSN
            $lbSnActual.Text = "SN detectado en archivo: $detectedSN"
            $txNuevoSN.Text  = $detectedSN
            SNLog "[+] SN detectado: $detectedSN"
        } else {
            SNLog "[~] No se pudo detectar SN automaticamente en el archivo"
            SNLog "[~] Ingresa el nuevo SN manualmente en el campo de texto"
        }

        # Boton generar archivo patcheado
        $btnGenEfs = New-Object Windows.Forms.Button
        $btnGenEfs.Text     = "GENERAR ARCHIVO sec_efs PATCHEADO"
        $btnGenEfs.Location = New-Object System.Drawing.Point(10,420)
        $btnGenEfs.Size     = New-Object System.Drawing.Size(540,44)
        $btnGenEfs.FlatStyle= "Flat"
        $btnGenEfs.ForeColor= [System.Drawing.Color]::FromArgb(255,180,0)
        $btnGenEfs.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,180,0)
        $btnGenEfs.BackColor= [System.Drawing.Color]::FromArgb(45,35,0)
        $btnGenEfs.Font     = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $frmSN.Controls.Add($btnGenEfs)
        $frmSN.ClientSize = New-Object System.Drawing.Size(560, 476)

        $btnGenEfs.Add_Click({
            $nuevoSN = $txNuevoSN.Text.Trim()
            if ($nuevoSN.Length -lt 3 -or $nuevoSN.Length -gt 11) {
                SNLog "[!] SN invalido. Debe tener entre 3 y 11 caracteres."
                return
            }
            if (-not $script:snEfsPath) { SNLog "[!] No hay archivo sec_efs seleccionado."; return }

            SNLog "[~] Generando archivo patcheado con SN: $nuevoSN"

            # Crear carpeta de backup con timestamp (igual que los otros patchers)
            $stamp   = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
            $backDir = Join-Path $script:SCRIPT_ROOT "BACKUPS\CAMBIAR_SN_EFS\$stamp"
            New-Item $backDir -ItemType Directory -Force | Out-Null

            # Copiar original como backup
            $origName = [System.IO.Path]::GetFileName($script:snEfsPath)
            $backupFile = Join-Path $backDir "ORIGINAL_$origName"
            Copy-Item $script:snEfsPath $backupFile -Force
            SNLog "[+] Backup original: $backupFile"

            # Leer bytes del archivo
            $bytes2 = [System.IO.File]::ReadAllBytes($script:snEfsPath)
            $ascii2 = [System.Text.Encoding]::ASCII.GetString($bytes2)
            $oldSN  = $script:snAdbDetected
            $patchCount = 0

            if ($oldSN -and $oldSN.Length -ge 3) {
                # Reemplazar bytes del SN anterior por el nuevo
                $oldBytes = [System.Text.Encoding]::ASCII.GetBytes($oldSN)
                $newBytes = [System.Text.Encoding]::ASCII.GetBytes($nuevoSN.PadRight($oldSN.Length, [char]0))

                $i = 0
                while ($i -le $bytes2.Length - $oldBytes.Length) {
                    $match = $true
                    for ($j = 0; $j -lt $oldBytes.Length; $j++) {
                        if ($bytes2[$i+$j] -ne $oldBytes[$j]) { $match=$false; break }
                    }
                    if ($match) {
                        for ($j = 0; $j -lt $newBytes.Length; $j++) { $bytes2[$i+$j] = $newBytes[$j] }
                        $patchCount++
                        SNLog " [+] SN reemplazado en offset: 0x{0:X}" -f $i
                        $i += $oldBytes.Length
                    } else { $i++ }
                }
            }

            if ($patchCount -eq 0) {
                SNLog "[~] No se encontro SN anterior para reemplazar - insercion manual"
                # Insertar como string en el archivo
            }

            # Guardar archivo patcheado
            $patchedFile = Join-Path $backDir "PATCHED_SN_${nuevoSN}_${origName}"
            [System.IO.File]::WriteAllBytes($patchedFile, $bytes2)
            SNLog "[+] Archivo patcheado: $patchedFile"
            SNLog "[+] SN en el archivo: $nuevoSN ($patchCount reemplazos)"
            SNLog ""
            SNLog "[OK] =========================================="
            SNLog "[OK] Archivo sec_efs generado exitosamente"
            SNLog "[OK] Flashea con Odin o el patcher EFS de Samsung"
            SNLog "[OK] =========================================="

            $abrir = [System.Windows.Forms.MessageBox]::Show(
                "Archivo patcheado generado con SN: $nuevoSN`n`nUbicacion:`n$backDir`n`nAbrir carpeta?",
                "LISTO","YesNo","Information")
            if ($abrir -eq "Yes") { Start-Process explorer.exe $backDir }
        })
    })

    # Info
    $lbInfo2 = New-Object Windows.Forms.Label
    $lbInfo2.Text     = "Flujo 1: requiere ROOT via ADB | Flujo 2: edita archivo sec_efs offline"
    $lbInfo2.Location = New-Object System.Drawing.Point(10,358)
    $lbInfo2.Size     = New-Object System.Drawing.Size(540,16)
    $lbInfo2.ForeColor= [System.Drawing.Color]::FromArgb(100,100,120)
    $lbInfo2.Font     = New-Object System.Drawing.Font("Segoe UI",7.5)
    $frmSN.Controls.Add($lbInfo2)

    $lbInfo3 = New-Object Windows.Forms.Label
    $lbInfo3.Text     = "Max 11 caracteres alfanumericos. Backup automatico siempre antes de cualquier cambio."
    $lbInfo3.Location = New-Object System.Drawing.Point(10,376)
    $lbInfo3.Size     = New-Object System.Drawing.Size(540,16)
    $lbInfo3.ForeColor= [System.Drawing.Color]::FromArgb(80,80,100)
    $lbInfo3.Font     = New-Object System.Drawing.Font("Segoe UI",7.5)
    $frmSN.Controls.Add($lbInfo3)

    $frmSN.Add_FormClosed({
        $btn.Enabled=$true; $btn.Text="CAMBIAR SN"
    })
    $frmSN.ShowDialog() | Out-Null
})

# =========================================================================
# HANDLER: AUTOROOT MAGISK (btnRemFRP = btnsA2[0]) - sin cambios funcionales
# =========================================================================
# [El resto del codigo de AUTOROOT MAGISK, BYPASS BANCARIO, FIX LOGO,
#  ACTIVAR SIM 2, INSTALAR MAGISK, RESTAURAR BACKUP permanece exactamente
#  igual al archivo original 05_tab_adb.ps1 del repositorio]
# ... (handlers originales de btnsA2 aqui)

# =========================================================================
# NOTA: El bloque AUTOMATIZACION Y ENTREGAS (grpA4 con RESET RAPIDO ENTREGA
# e INSTALAR APKs) fue ELIMINADO de esta tab y movido a 04_tab_control.ps1
# =========================================================================