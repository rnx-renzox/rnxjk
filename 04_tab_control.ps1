#==========================================================================
# 04_tab_control.ps1  -  TAB CONTROL Y HERRAMIENTAS
# Reemplaza 04_tab_samsung.ps1
# Contiene:
#   [A] Show-ExtractProgress  (funcion compartida, usada por 06_tab_generales)
#   [B] Tab CONTROL layout  (3 grupos: Lanzadores / Diagnostico / Sistema-PC)
#   [C] Handlers de todos los botones del tab Control
#==========================================================================

#==========================================================================
# [A] FUNCION COMPARTIDA  -  Show-ExtractProgress
#     Usada por 06_tab_generales.ps1 (Extraer Firmware)
#==========================================================================
function Show-ExtractProgress($filename) {
    $win = New-Object Windows.Forms.Form
    $win.Text = "Extrayendo..."; $win.ClientSize = New-Object System.Drawing.Size(500,170)
    $win.BackColor = [System.Drawing.Color]::FromArgb(18,18,18)
    $win.FormBorderStyle = "FixedDialog"; $win.StartPosition = "CenterScreen"
    $win.ControlBox = $false; $win.TopMost = $true

    $lbTitle = New-Object Windows.Forms.Label
    $lbTitle.Text = "EXTRAYENDO FIRMWARE"
    $lbTitle.Location = New-Object System.Drawing.Point(16,14)
    $lbTitle.Size = New-Object System.Drawing.Size(468,20)
    $lbTitle.ForeColor = [System.Drawing.Color]::Lime
    $lbTitle.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $win.Controls.Add($lbTitle)

    $lbFile = New-Object Windows.Forms.Label
    $lbFile.Text = $filename
    $lbFile.Location = New-Object System.Drawing.Point(16,38)
    $lbFile.Size = New-Object System.Drawing.Size(468,18)
    $lbFile.ForeColor = [System.Drawing.Color]::LightGray
    $lbFile.Font = New-Object System.Drawing.Font("Consolas",8)
    $win.Controls.Add($lbFile)

    $bar = New-Object Windows.Forms.ProgressBar
    $bar.Location = New-Object System.Drawing.Point(16,66)
    $bar.Size = New-Object System.Drawing.Size(468,24)
    $bar.Style = "Continuous"; $bar.Minimum = 0; $bar.Maximum = 100; $bar.Value = 0
    $win.Controls.Add($bar)

    $lbPct = New-Object Windows.Forms.Label
    $lbPct.Text = "0%"
    $lbPct.Location = New-Object System.Drawing.Point(16,100)
    $lbPct.Size = New-Object System.Drawing.Size(468,18)
    $lbPct.ForeColor = [System.Drawing.Color]::Cyan
    $lbPct.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $lbPct.TextAlign = "MiddleCenter"
    $win.Controls.Add($lbPct)

    $lbStatus = New-Object Windows.Forms.Label
    $lbStatus.Text = "Iniciando..."
    $lbStatus.Location = New-Object System.Drawing.Point(16,124)
    $lbStatus.Size = New-Object System.Drawing.Size(468,18)
    $lbStatus.ForeColor = [System.Drawing.Color]::FromArgb(90,90,90)
    $lbStatus.Font = New-Object System.Drawing.Font("Consolas",7.5)
    $win.Controls.Add($lbStatus)

    $win.Show(); [System.Windows.Forms.Application]::DoEvents()
    return @{ Win=$win; Bar=$bar; LblFile=$lbFile; LblPct=$lbPct; LblStatus=$lbStatus }
}

#==========================================================================
# [B] TAB CONTROL - Layout identico al resto de tabs
#     BTW=195 BTH=56 LOGX=436 GW=422  (mismas metricas que ADB y Generales)
#     3 grupos: C1=Lanzadores(Yellow) C2=Diagnostico(Cyan) C3=Sistema-PC(Orange)
#==========================================================================
# tabCtrl already created in 03_heimdall.ps1 with name "CONTROL Y HERRAMIENTAS"
# (tabOdin is an alias pointing to tabCtrl for compatibility)

$CX=6; $CGAP=8; $CLOGX=436
$CBTW=195; $CBTH=56; $CPX=14; $CPY=20; $CGX=8; $CGY=8
$CGW=422; $CLOGW=$CGW

# Alturas: C1=2 filas(4 btn), C2=2 filas(4 btn), C3=2 filas(4 btn)
$CGH1 = $CPY + 2*($CBTH+$CGY) - $CGY + 14
$CGH2 = $CPY + 2*($CBTH+$CGY) - $CGY + 14
$CGH3 = $CPY + 3*($CBTH+$CGY) - $CGY + 14   # 3 filas (6 botones)

$CY1=6
$CY2=$CY1+$CGH1+$CGAP
$CY3=$CY2+$CGH2+$CGAP

$grpC1 = New-GBox $tabCtrl "LANZADORES"          $CX $CY1 $CGW $CGH1 "Yellow"
$grpC2 = New-GBox $tabCtrl "DIAGNOSTICO ADB"     $CX $CY2 $CGW $CGH2 "Cyan"
$grpC3 = New-GBox $tabCtrl "SISTEMA / PC"        $CX $CY3 $CGW $CGH3 "Orange"

$CL1=@("ODIN3","HxD HEX EDITOR","QFIL","USB DRIVERS")
$CL2=@("TEST PANTALLA","INFO BATERIA","ALMACENAMIENTO","APPS INSTALADAS")
$CL3=@("ADMIN TAREAS","ADMIN DISPOSITIVOS","DESACTIVAR DEFENDER","REINICIAR ADB","MONITOR PC","LIMPIEZA TEMP PC")

$btnsC1=Place-Grid $grpC1 $CL1 "Yellow" 2 $CBTW $CBTH $CPX $CPY $CGX $CGY
$btnsC2=Place-Grid $grpC2 $CL2 "Cyan"   2 $CBTW $CBTH $CPX $CPY $CGX $CGY
$btnsC3=Place-Grid $grpC3 $CL3 "Orange" 2 $CBTW $CBTH $CPX $CPY $CGX $CGY

# Log columna derecha
$CLOGY=6; $CLOGH=616
$Global:logCtrl           = New-Object Windows.Forms.TextBox
$Global:logCtrl.Multiline = $true
$Global:logCtrl.Location  = New-Object System.Drawing.Point($CLOGX,$CLOGY)
$Global:logCtrl.Size      = New-Object System.Drawing.Size($CLOGW,$CLOGH)
$Global:logCtrl.BackColor = "Black"
$Global:logCtrl.ForeColor = [System.Drawing.Color]::FromArgb(255,220,50)
$Global:logCtrl.BorderStyle = "FixedSingle"
$Global:logCtrl.ScrollBars  = "Vertical"
$Global:logCtrl.Font        = New-Object System.Drawing.Font("Consolas",8.5)
$Global:logCtrl.ReadOnly    = $true
$tabCtrl.Controls.Add($Global:logCtrl)

$ctxCtrl = New-Object System.Windows.Forms.ContextMenuStrip
$mnuClearCtrl = $ctxCtrl.Items.Add("Limpiar Log")
$mnuClearCtrl.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
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
# [C] HANDLERS - BLOQUE C1: LANZADORES (amarillo)
#==========================================================================

# ---- C1[0]: ODIN3 ----
$btnsC1[0].Add_Click({
    $btn=$btnsC1[0]; $btn.Enabled=$false; $btn.Text="BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== ODIN3 LAUNCHER ==="
    try {
        $zipPath = Join-Path $script:TOOLS_DIR "Odin3.zip"
        if (-not (Test-Path $zipPath)) {
            CtrlLog "[!] No se encontro Odin3.zip en: $($script:TOOLS_DIR)"
            CtrlLog "[~] Coloca Odin3.zip (con Odin3.exe y Odin3.ini dentro) en tools\"
            [System.Windows.Forms.MessageBox]::Show(
                "No se encontro Odin3.zip`n`nColoca Odin3.zip en:`n$($script:TOOLS_DIR)`n`nEl ZIP debe contener Odin3.exe y Odin3.ini",
                "Odin no encontrado","OK","Warning") | Out-Null
        } else {
            CtrlLog "[+] Odin3.zip encontrado en tools\"
            CtrlLog "[~] Extrayendo a carpeta temporal limpia..."
            $tempDir = Join-Path $env:TEMP ("Odin_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $tempDir | Out-Null
            Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
            CtrlLog "[+] ZIP extraido OK"

            # Buscar ejecutable
            $odinExeItem = Get-ChildItem -Path $tempDir -Recurse -Filter "Odin3.exe" | Select-Object -First 1
            if (-not $odinExeItem) {
                $odinExeItem = Get-ChildItem -Path $tempDir -Recurse -Filter "Odin*.exe" | Select-Object -First 1
            }
            if (-not $odinExeItem) {
                Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue
                throw "No se encontro Odin3.exe en el ZIP"
            }
            CtrlLog "[+] Ejecutable: $($odinExeItem.Name)"

            # Verificar Odin3.ini en la misma carpeta del exe (debe venir en el ZIP)
            $iniPath = Join-Path $odinExeItem.Directory.FullName "Odin3.ini"
            if (-not (Test-Path $iniPath)) {
                Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue
                CtrlLog "[!] Odin3.ini no encontrado junto al exe"
                CtrlLog "[~] El ZIP debe contener Odin3.exe Y Odin3.ini en la misma carpeta"
                [System.Windows.Forms.MessageBox]::Show(
                    "Odin3.ini no encontrado en el ZIP`n`nEl archivo Odin3.zip debe contener:`n  - Odin3.exe`n  - Odin3.ini`n`nAgrega Odin3.ini al ZIP junto al exe",
                    "Odin3.ini faltante","OK","Warning") | Out-Null
            } else {
                CtrlLog "[+] Odin3.ini encontrado OK"
                CtrlLog "[~] Lanzando Odin3 desde su carpeta..."
                $odinProc = Start-Process `
                    -FilePath $odinExeItem.FullName `
                    -WorkingDirectory $odinExeItem.Directory.FullName `
                    -Verb RunAs `
                    -PassThru
                $pid2 = if ($odinProc) { $odinProc.Id } else { 0 }
                CtrlLog "[OK] Odin3 abierto$(if($pid2){' (PID: '+$pid2+')'} else {' (UAC elevado)'})"
                # Autolimpieza cuando Odin se cierre
                $null = Start-Job -ScriptBlock {
                    param($procId, $dirPath)
                    if ($procId -gt 0) {
                        try { $p=Get-Process -Id $procId -EA SilentlyContinue; if($p){$p.WaitForExit(600000)} } catch {}
                    } else {
                        $s=Get-Date
                        while(((Get-Date)-$s).TotalSeconds -lt 300) {
                            Start-Sleep 10
                            if (-not (Get-Process -Name "Odin*" -EA SilentlyContinue)) { break }
                        }
                    }
                    Start-Sleep 5
                    try { Remove-Item -Path $dirPath -Recurse -Force -EA SilentlyContinue } catch {}
                } -ArgumentList $pid2, $tempDir
            }
        }
    } catch {
        CtrlLog "[!] Error: $_"
    }
    $btn.Enabled=$true; $btn.Text="ODIN3"
})

# ---- C1[1]: HxD HEX EDITOR ----
$btnsC1[1].Add_Click({
    $btn=$btnsC1[1]; $btn.Enabled=$false; $btn.Text="BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== HxD HEX EDITOR ==="

    $hxd = $null
    foreach ($c in @(
        (Join-Path $script:TOOLS_DIR "HxD.exe"),
        (Join-Path $script:TOOLS_DIR "hxd\HxD.exe"),
        "$env:ProgramFiles\HxD\HxD.exe",
        "${env:ProgramFiles(x86)}\HxD\HxD.exe",
        "$env:LOCALAPPDATA\Programs\HxD\HxD.exe"
    )) { if (Test-Path $c -EA SilentlyContinue) { $hxd=$c; break } }

    if (-not $hxd) {
        try {
            $hxd = $(try{(Get-Command "HxD.exe" -EA SilentlyContinue).Source}catch{""})
        } catch {}
    }

    if ($hxd) {
        CtrlLog "[+] HxD encontrado: $hxd"
        try { Start-Process $hxd; CtrlLog "[OK] HxD abierto" }
        catch { CtrlLog "[!] Error: $_" }
    } else {
        CtrlLog "[!] HxD no encontrado en tools\ ni en Program Files"
        CtrlLog "[~] Opciones:"
        CtrlLog "    1. Coloca HxD.exe en tools\"
        CtrlLog "    2. Instala desde: https://mh-nexus.de/en/hxd/"
        $resp = [System.Windows.Forms.MessageBox]::Show(
            "HxD no encontrado.`n`nAbrir pagina de descarga oficial?",
            "HxD no encontrado","YesNo","Information")
        if ($resp -eq "Yes") {
            Start-Process "https://mh-nexus.de/en/hxd/"
            CtrlLog "[~] Pagina de descarga abierta en el navegador"
        }
    }
    $btn.Enabled=$true; $btn.Text="HxD HEX EDITOR"
})

# ---- C1[2]: QFIL ----
$btnsC1[2].Add_Click({
    $btn=$btnsC1[2]; $btn.Enabled=$false; $btn.Text="BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== QFIL LAUNCHER ==="

    $qfil = $null

    # 1. tools\
    foreach ($c in @((Join-Path $script:TOOLS_DIR "QFIL.exe"),(Join-Path $script:TOOLS_DIR "qfil\QFIL.exe"))) {
        if (Test-Path $c -EA SilentlyContinue) { $qfil=$c; break }
    }

    # 2. Program Files
    if (-not $qfil) {
        $pfTry = @(
            "$env:ProgramFiles\Qualcomm\QFIL\QFIL.exe",
            "$env:ProgramFiles\QFIL\QFIL.exe",
            "$env:ProgramFiles\Qualcomm Flash Image Loader\QFIL.exe",
            "${env:ProgramFiles(x86)}\Qualcomm\QFIL\QFIL.exe",
            "${env:ProgramFiles(x86)}\QFIL\QFIL.exe"
        )
        foreach ($c in $pfTry) { if (Test-Path $c -EA SilentlyContinue) { $qfil=$c; break } }
    }

    # 3. PATH
    if (-not $qfil) {
        try { $qf2=(Get-Command "QFIL.exe" -EA SilentlyContinue); if($qf2){$qfil=$qf2.Source} } catch {}
    }

    # 4. Busqueda recursiva en Program Files
    if (-not $qfil) {
        CtrlLog "[~] Buscando QFIL.exe en el sistema..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            foreach ($sp in @("$env:ProgramFiles","${env:ProgramFiles(x86)}")) {
                if ($qfil) { break }
                $fnd = Get-ChildItem $sp -Recurse -Filter "QFIL.exe" -EA SilentlyContinue | Select-Object -First 1
                if ($fnd) { $qfil = $fnd.FullName }
            }
        } catch {}
    }

    if ($qfil) {
        CtrlLog "[+] QFIL encontrado: $qfil"
        try {
            Start-Process -FilePath $qfil -WorkingDirectory (Split-Path $qfil) -Verb RunAs
            CtrlLog "[OK] QFIL abierto"
            CtrlLog "[i] QFIL = Qualcomm Flash Image Loader"
            CtrlLog "[i] Usa EDL mode (Vol- al conectar USB) para dispositivos Qualcomm"
        } catch {
            CtrlLog "[~] RunAs fallo - abriendo sin elevacion..."
            try { Start-Process $qfil; CtrlLog "[OK] QFIL abierto" }
            catch { CtrlLog "[!] Error: $_" }
        }
    } else {
        CtrlLog "[!] QFIL.exe no encontrado en el sistema"
        CtrlLog "[~] Opciones:"
        CtrlLog "    1. Instala Qualcomm USB Driver Package (incluye QFIL)"
        CtrlLog "    2. Coloca QFIL.exe en: $($script:TOOLS_DIR)"
        CtrlLog "    3. O instala QPST (Qualcomm Product Support Tools)"
        $resp = [System.Windows.Forms.MessageBox]::Show(
            "QFIL.exe no encontrado.`n`nColoca QFIL.exe en tools`\`n`nAbrir pagina de descarga?",
            "QFIL no encontrado","YesNo","Information")
        if ($resp -eq "Yes") { Start-Process "https://qfil.download/"; CtrlLog "[~] Pagina abierta" }
    }

    $btn.Enabled=$true; $btn.Text="QFIL"
})

# ---- C# ---- C1[3]: USB DRIVERS (dropdown: Samsung / MTK / Qualcomm) ----
$btnsC1[3].Add_Click({
    $btn=$btnsC1[3]; $btn.Enabled=$false; $btn.Text="ABRIENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== USB DRIVERS ==="

    # Drivers con sus URLs oficiales verificadas (estables, actualizadas 2024-2025)
    $drivers = @(
        @{
            Name    = "Samsung USB Drivers  (oficial Samsung Developers)"
            URL     = "https://developer.samsung.com/mobile/android-usb-driver.html"
            Version = "v1.7.60.0  (soporte Android 14+)"
            Note    = "Para todos los dispositivos Samsung Galaxy"
        },
        @{
            Name    = "MediaTek VCOM Drivers  (oficial MTK)"
            URL     = "https://spflashtools.com/windows/mtk-driver"
            Version = "MTK VCOM USB Drivers"
            Note    = "Para dispositivos con chipset MediaTek (Helio, Dimensity)"
        },
        @{
            Name    = "Qualcomm HS-USB Drivers  (oficial Qualcomm)"
            URL     = "https://developer.qualcomm.com/software/usb-driver"
            Version = "Qualcomm USB Driver for Windows"
            Note    = "Para dispositivos Snapdragon en modo EDL/DIAG/ADB"
        },
        @{
            Name    = "ADB/Fastboot Universal Drivers  (Google)"
            URL     = "https://dl.google.com/android/repository/usb_driver_r13-windows.zip"
            Version = "Google USB Driver r13  (universal ADB)"
            Note    = "Driver universal ADB para todos los fabricantes"
        }
    )

    # Mini form de seleccion
    $frmUsb = New-Object System.Windows.Forms.Form
    $frmUsb.Text="USB DRIVERS - RNX TOOL PRO"; $frmUsb.ClientSize=New-Object System.Drawing.Size(580,340)
    $frmUsb.BackColor=[System.Drawing.Color]::FromArgb(16,16,22)
    $frmUsb.FormBorderStyle="FixedDialog"; $frmUsb.StartPosition="CenterScreen"; $frmUsb.TopMost=$true

    $lbHdr2=New-Object Windows.Forms.Label; $lbHdr2.Text="  SELECCIONA EL DRIVER A DESCARGAR"
    $lbHdr2.Location=New-Object System.Drawing.Point(0,0); $lbHdr2.Size=New-Object System.Drawing.Size(580,32)
    $lbHdr2.BackColor=[System.Drawing.Color]::FromArgb(255,150,0); $lbHdr2.ForeColor=[System.Drawing.Color]::White
    $lbHdr2.Font=New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lbHdr2.TextAlign="MiddleLeft"; $frmUsb.Controls.Add($lbHdr2)

    $yD=40
    foreach ($i in 0..($drivers.Count-1)) {
        $drv = $drivers[$i]
        $pnl=New-Object Windows.Forms.Panel; $pnl.Location=New-Object System.Drawing.Point(12,$yD)
        $pnl.Size=New-Object System.Drawing.Size(556,58); $pnl.BackColor=[System.Drawing.Color]::FromArgb(24,24,34)
        $pnl.BorderStyle="FixedSingle"; $frmUsb.Controls.Add($pnl)

        $lName=New-Object Windows.Forms.Label; $lName.Text=$drv.Name
        $lName.Location=New-Object System.Drawing.Point(8,6); $lName.Size=New-Object System.Drawing.Size(440,18)
        $lName.ForeColor=[System.Drawing.Color]::White
        $lName.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $pnl.Controls.Add($lName)

        $lNote=New-Object Windows.Forms.Label; $lNote.Text=$drv.Note
        $lNote.Location=New-Object System.Drawing.Point(8,26); $lNote.Size=New-Object System.Drawing.Size(440,14)
        $lNote.ForeColor=[System.Drawing.Color]::FromArgb(130,130,150)
        $lNote.Font=New-Object System.Drawing.Font("Segoe UI",7.5); $pnl.Controls.Add($lNote)

        $lVer=New-Object Windows.Forms.Label; $lVer.Text=$drv.Version
        $lVer.Location=New-Object System.Drawing.Point(8,42); $lVer.Size=New-Object System.Drawing.Size(440,14)
        $lVer.ForeColor=[System.Drawing.Color]::FromArgb(80,160,255)
        $lVer.Font=New-Object System.Drawing.Font("Consolas",7.5); $pnl.Controls.Add($lVer)

        $btnD=New-Object Windows.Forms.Button; $btnD.Text="DESCARGAR"
        $btnD.Location=New-Object System.Drawing.Point(454,12); $btnD.Size=New-Object System.Drawing.Size(94,34)
        $btnD.FlatStyle="Flat"; $btnD.ForeColor=[System.Drawing.Color]::FromArgb(255,150,0)
        $btnD.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(255,150,0)
        $btnD.BackColor=[System.Drawing.Color]::FromArgb(35,28,15)
        $btnD.Font=New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
        $btnD.Tag = $drv.URL
        $btnD.Add_Click({
            $url=$this.Tag
            try { Start-Process $url; CtrlLog "[OK] Abriendo: $url" }
            catch { CtrlLog "[!] Error abriendo navegador: $_" }
        })
        $pnl.Controls.Add($btnD)

        $yD += 66
    }

    $btnCl3=New-Object Windows.Forms.Button; $btnCl3.Text="CERRAR"
    $btnCl3.Location=New-Object System.Drawing.Point(210,302); $btnCl3.Size=New-Object System.Drawing.Size(160,30)
    $btnCl3.FlatStyle="Flat"; $btnCl3.ForeColor=[System.Drawing.Color]::Gray
    $btnCl3.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(70,70,70)
    $btnCl3.BackColor=[System.Drawing.Color]::FromArgb(25,25,35)
    $btnCl3.Font=New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $btnCl3.Add_Click({ $frmUsb.Close() }); $frmUsb.Controls.Add($btnCl3)
    $frmUsb.ShowDialog() | Out-Null

    $btn.Enabled=$true; $btn.Text="USB DRIVERS"
})
# ---- C2[0]: TEST PANTALLA ----
$btnsC2[0].Add_Click({
    $btn=$btnsC2[0]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== TEST PANTALLA ==="

    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="TEST PANTALLA"; return }

    function CtS($cmd) {
        $r = & adb shell $cmd 2>$null
        if ($r -is [array]) { return ($r -join " ").Trim() }
        return "$r".Trim()
    }

    $res     = CtS "wm size"
    $dens    = CtS "wm density"
    $bright  = CtS "settings get system screen_brightness"
    $brightM = CtS "settings get system screen_brightness_mode"
    $timeout = CtS "settings get system screen_off_timeout"
    $ptrLoc  = CtS "settings get system pointer_location"

    CtrlLog "[+] Resolucion    : $res"
    CtrlLog "[+] Densidad DPI  : $dens"
    CtrlLog "[+] Brillo        : $bright / 255 $(if($brightM -eq '1'){'(AUTO)'}else{'(MANUAL)'})"
    $toSec = try { [int]($timeout)/1000 } catch { "?" }
    CtrlLog "[+] Timeout pantalla: ${toSec}s"
    CtrlLog "[+] Pointer Location: $(if($ptrLoc -eq '1'){'ACTIVO'}else{'INACTIVO'})"
    CtrlLog ""

    $frmTest = New-Object System.Windows.Forms.Form
    $frmTest.Text="TEST PANTALLA - RNX TOOL PRO"; $frmTest.ClientSize=New-Object System.Drawing.Size(360,280)
    $frmTest.BackColor=[System.Drawing.Color]::FromArgb(20,20,20); $frmTest.FormBorderStyle="FixedDialog"
    $frmTest.StartPosition="CenterScreen"; $frmTest.TopMost=$true

    function AddLbl($txt,$y,$clr="LightGray",$bold=$false) {
        $l=New-Object Windows.Forms.Label; $l.Text=$txt
        $l.Location=New-Object System.Drawing.Point(14,$y); $l.Size=New-Object System.Drawing.Size(332,18)
        $l.ForeColor=[System.Drawing.Color]::$clr
        $l.Font=New-Object System.Drawing.Font("Consolas",8,$(if($bold){[System.Drawing.FontStyle]::Bold}else{[System.Drawing.FontStyle]::Regular}))
        $frmTest.Controls.Add($l)
    }
    function AddBtn($txt,$x,$y,$w,$clr,$action) {
        $b=New-Object Windows.Forms.Button; $b.Text=$txt
        $b.Location=New-Object System.Drawing.Point($x,$y); $b.Size=New-Object System.Drawing.Size($w,34)
        $b.FlatStyle="Flat"; $b.ForeColor=[System.Drawing.Color]::$clr
        $b.FlatAppearance.BorderColor=[System.Drawing.Color]::$clr
        $b.BackColor=[System.Drawing.Color]::FromArgb(30,30,30)
        $b.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
        $b.Add_Click($action); $frmTest.Controls.Add($b)
    }
    AddLbl "INFORMACION DE PANTALLA" 12 "Cyan" $true
    AddLbl $res    34 "White"
    AddLbl $dens   52 "White"
    AddLbl "Brillo: $bright/255  $(if($brightM -eq '1'){'AUTO'}else{'MANUAL'})" 70 "White"
    AddLbl "Timeout: ${toSec}s" 88 "White"
    AddLbl "Pointer Location: $(if($ptrLoc -eq '1'){'ACTIVO (rojo)'}else{'INACTIVO'})" 106 "White"

    AddLbl "ACCIONES RAPIDAS" 136 "Cyan" $true
    AddBtn "TOGGLE POINTER LOC" 14 158 160 "Yellow" {
        $cur=(& adb shell "settings get system pointer_location" 2>$null).Trim()
        $new=if($cur -eq "1"){"0"}else{"1"}
        & adb shell "settings put system pointer_location $new" 2>$null | Out-Null
        CtrlLog "[OK] Pointer Location -> $(if($new -eq '1'){'ACTIVO'}else{'INACTIVO'})"
    }
    AddBtn "BRILLO MAXIMO" 182 158 152 "Lime" {
        & adb shell "settings put system screen_brightness 255" 2>$null | Out-Null
        & adb shell "settings put system screen_brightness_mode 0" 2>$null | Out-Null
        CtrlLog "[OK] Brillo al maximo (255), modo manual"
    }
    AddBtn "BRILLO AUTO" 14 200 160 "Cyan" {
        & adb shell "settings put system screen_brightness_mode 1" 2>$null | Out-Null
        CtrlLog "[OK] Brillo automatico activado"
    }
    AddBtn "TIMEOUT 10 MIN" 182 200 152 "Orange" {
        & adb shell "settings put system screen_off_timeout 600000" 2>$null | Out-Null
        CtrlLog "[OK] Timeout pantalla -> 10 minutos"
    }
    AddBtn "CERRAR" 110 242 140 "Gray" { $frmTest.Close() }
    $frmTest.ShowDialog() | Out-Null

    $btn.Enabled=$true; $btn.Text="TEST PANTALLA"
})

# ---- C2[1]: INFO BATERIA ----
$btnsC2[1].Add_Click({
    $btn=$btnsC2[1]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== INFO BATERIA ==="

    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="INFO BATERIA"; return }

    function BatS($cmd) {
        $r = & adb shell $cmd 2>$null
        if ($r -is [array]) { return ($r -join " ").Trim() }
        return "$r".Trim()
    }

    # Dumpsys battery
    $dump = (& adb shell "dumpsys battery" 2>$null) -join "`n"
    function ParseBat($key) {
        if ($dump -match "(?m)$key[:\s]+(.+)") { return $Matches[1].Trim() }
        return "?"
    }

    $nivel   = ParseBat "level"
    $status  = ParseBat "status"     # 1=unknown 2=charging 3=discharging 4=not charging 5=full
    $health  = ParseBat "health"     # 1=unknown 2=good 3=overheat 4=dead 5=overvoltage 6=failure 7=cold
    $temp    = ParseBat "temperature"
    $volt    = ParseBat "voltage"
    $techno  = ParseBat "technology"
    $plugged = ParseBat "plugged"

    $statusStr = switch ($status) {
        "2" { "CARGANDO" } "3" { "DESCARGANDO" } "4" { "NO CARGA" } "5" { "LLENA" } default { "Estado $status" }
    }
    $healthStr = switch ($health) {
        "2" { "BUENA" } "3" { "SOBRECALENTAMIENTO" } "4" { "MUERTA" }
        "5" { "SOBREVOLTAJE" } "7" { "FRIA" } default { "Estado $health" }
    }
    $tempC = try { [math]::Round([double]$temp/10,1) } catch { "?" }
    $voltV = try { [math]::Round([double]$volt/1000,2) } catch { "?" }
    $plugStr = switch ($plugged) { "1"{"USB"} "2"{"AC/Pared"} "4"{"Wireless"} default{"No"} }

    CtrlLog "[+] Nivel        : $nivel%"
    CtrlLog "[+] Estado       : $statusStr  (Cargador: $plugStr)"
    CtrlLog "[+] Salud        : $healthStr"
    $tempAlert = if ($tempC -ne "?" -and [double]$tempC -gt 40) { " [ALERTA: >40 grados C]" } else { "" }
    CtrlLog "[+] Temperatura  : $tempC C$tempAlert"
    CtrlLog "[+] Voltaje      : $voltV V"
    CtrlLog "[+] Tecnologia   : $techno"

    # Capacidad via sysfs
    CtrlLog ""
    CtrlLog "[~] Leyendo capacidad via sysfs..."
    $batPath = "/sys/class/power_supply/battery"
    $altPaths = @("/sys/class/power_supply/Battery", "/sys/class/power_supply/bms", "/sys/class/power_supply/qpnp-qg")

    function ReadSysfs($path) {
        $r = & adb shell "cat $path 2>/dev/null" 2>$null
        if ($r) { $v=("$r").Trim(); if ($v -match "^\d") { return $v } }
        return $null
    }

    $capNow  = ReadSysfs "$batPath/charge_now"
    $capFull = ReadSysfs "$batPath/charge_full"
    $capDes  = ReadSysfs "$batPath/charge_full_design"
    $curNow  = ReadSysfs "$batPath/current_now"
    $cyclos  = ReadSysfs "$batPath/cycle_count"

    # Fallback: charge en uAh en vez de uA
    if (-not $capNow)  { $capNow  = ReadSysfs "$batPath/charge_counter" }
    if (-not $capFull) {
        foreach ($ap in $altPaths) {
            $capFull = ReadSysfs "$ap/charge_full"
            if ($capFull) { $batPath=$ap; break }
        }
    }

    if ($capNow -and $capFull) {
        $mAhNow  = try { [math]::Round([double]$capNow/1000,0)  } catch { "?" }
        $mAhFull = try { [math]::Round([double]$capFull/1000,0) } catch { "?" }
        $mAhDes  = if ($capDes) { try { [math]::Round([double]$capDes/1000,0) } catch { "?" } } else { "?" }
        CtrlLog "[+] Capacidad actual : $mAhNow mAh"
        CtrlLog "[+] Capacidad full   : $mAhFull mAh"
        CtrlLog "[+] Capacidad diseno : $mAhDes mAh"
        if ($mAhFull -ne "?" -and $mAhDes -ne "?") {
            $salud = try { [math]::Round(([double]$mAhFull/[double]$mAhDes)*100,1) } catch { "?" }
            $saludLabel = if ($salud -ne "?") {
                if    ($salud -ge 85) { "BUENA ($salud%)" }
                elseif($salud -ge 70) { "ACEPTABLE ($salud%)" }
                elseif($salud -ge 50) { "DEGRADADA ($salud%)" }
                else                  { "CRITICA ($salud%)" }
            } else { "?" }
            CtrlLog "[+] Salud real       : $saludLabel"
        }
    } else {
        CtrlLog "[~] Datos sysfs no disponibles en este dispositivo"
    }

    if ($cyclos) { CtrlLog "[+] Ciclos de carga  : $cyclos" }
    if ($curNow) {
        $mA = try { [math]::Round([math]::Abs([double]$curNow)/1000,0) } catch { "?" }
        $dir = if ([double]$curNow -gt 0) { "descargando" } else { "cargando" }
        CtrlLog "[+] Corriente actual : $mA mA ($dir)"
    }

    if ($tempAlert) {
        CtrlLog ""
        CtrlLog "[ALERTA] Temperatura elevada: $tempC C"
        CtrlLog "         Temperatura normal: 20-40 C durante carga"
        CtrlLog "         Detener carga si supera 45 C continuamente"
    }

    $btn.Enabled=$true; $btn.Text="INFO BATERIA"
})

# ---- C2[2]: ALMACENAMIENTO ----
$btnsC2[2].Add_Click({
    $btn=$btnsC2[2]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== ALMACENAMIENTO ==="
    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="ALMACENAMIENTO"; return }

    CtrlLog "[~] Recopilando datos..."
    [System.Windows.Forms.Application]::DoEvents()

    # ---- Recopilar datos ----
    $dfRaw  = (& adb shell "df -h 2>/dev/null" 2>$null)
    $memRaw = (& adb shell "cat /proc/meminfo 2>/dev/null" 2>$null) -join "`n"
    function GetMemMB($key) {
        if ($memRaw -match "(?m)$key[\:\s]+(\d+)") { return [math]::Round([int]$Matches[1]/1024,0) }
        return 0
    }
    $memTotal = GetMemMB "MemTotal"; $memFree = GetMemMB "MemFree"; $memAvail = GetMemMB "MemAvailable"
    $_avail   = if ($memAvail -gt 0) { $memAvail } else { $memFree }
    $memUsed  = $memTotal - $_avail
    $memPct   = if ($memTotal -gt 0) { [math]::Round($memUsed/$memTotal*100,0) } else { 0 }

    # Parse particiones relevantes
    $relevantes = @("/data","/system","/vendor","/cache","/sdcard","/storage/emulated","/product","/odm")
    $partRows = @()
    if ($dfRaw) {
        foreach ($line in $dfRaw) {
            $l = "$line".Trim(); if (-not $l) { continue }
            if ($l -match "^Filesystem|^Size") { continue }
            $mostrar = $false
            foreach ($r in $relevantes) { if ($l -match [regex]::Escape($r)) { $mostrar=$true; break } }
            if (-not $mostrar) { continue }
            # Parse: Filesystem Size Used Avail Use% MountedOn
            $parts = $l -split "\s+"
            if ($parts.Count -ge 6) {
                $pct = if ($parts[-2] -match "(\d+)%") { [int]$Matches[1] } else { 0 }
                $partRows += @{Mount=$parts[-1]; Size=$parts[1]; Used=$parts[2]; Avail=$parts[3]; Pct=$pct}
            }
        }
    }

    CtrlLog "[+] Datos listos. Abriendo panel visual..."
    $btn.Enabled=$true; $btn.Text="ALMACENAMIENTO"

    # ---- Mini UI visual ----
    $frmSt = New-Object System.Windows.Forms.Form
    $frmSt.Text="ALMACENAMIENTO - RNX TOOL PRO"
    $frmSt.ClientSize = New-Object System.Drawing.Size(620, 500)
    $frmSt.BackColor  = [System.Drawing.Color]::FromArgb(15,15,20)
    $frmSt.FormBorderStyle="FixedDialog"; $frmSt.StartPosition="CenterScreen"; $frmSt.TopMost=$true

    # Titulo
    $lbT=New-Object Windows.Forms.Label; $lbT.Text="  ALMACENAMIENTO Y MEMORIA"
    $lbT.Location=New-Object System.Drawing.Point(0,0); $lbT.Size=New-Object System.Drawing.Size(620,32)
    $lbT.BackColor=[System.Drawing.Color]::FromArgb(0,140,255); $lbT.ForeColor=[System.Drawing.Color]::White
    $lbT.Font=New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $lbT.TextAlign="MiddleLeft"; $frmSt.Controls.Add($lbT)

    $y = 42

    # --- Funcion helper: dibujar barra de uso ---
    function Draw-StorageBar($parent, $label, $usedPct, $usedStr, $totalStr, $yPos, $clrFill) {
        $BAR_W=580; $BAR_H=28; $X=18

        $lbName=New-Object Windows.Forms.Label; $lbName.Text=$label
        $lbName.Location=New-Object System.Drawing.Point($X,$yPos); $lbName.Size=New-Object System.Drawing.Size(200,16)
        $lbName.ForeColor=[System.Drawing.Color]::FromArgb(180,180,200)
        $lbName.Font=New-Object System.Drawing.Font("Segoe UI",8)
        $parent.Controls.Add($lbName)

        $lbVal=New-Object Windows.Forms.Label
        $lbVal.Text="$usedStr usados de $totalStr  ($usedPct%)"
        $lbVal.Location=New-Object System.Drawing.Point(220,$yPos); $lbVal.Size=New-Object System.Drawing.Size(380,16)
        $lbVal.ForeColor=[System.Drawing.Color]::FromArgb(140,140,160)
        $lbVal.Font=New-Object System.Drawing.Font("Segoe UI",7.5); $lbVal.TextAlign="MiddleRight"
        $parent.Controls.Add($lbVal)

        # Barra de fondo
        $pnlBg=New-Object Windows.Forms.Panel; $pnlBg.Location=New-Object System.Drawing.Point($X,($yPos+18))
        $pnlBg.Size=New-Object System.Drawing.Size($BAR_W,$BAR_H)
        $pnlBg.BackColor=[System.Drawing.Color]::FromArgb(35,35,45); $parent.Controls.Add($pnlBg)

        # Barra rellena
        $fillW = [math]::Max(4,[int]($BAR_W * $usedPct / 100))
        $pnlFill=New-Object Windows.Forms.Panel; $pnlFill.Location=New-Object System.Drawing.Point(0,0)
        $pnlFill.Size=New-Object System.Drawing.Size($fillW,$BAR_H)
        $pnlFill.BackColor=$clrFill; $pnlBg.Controls.Add($pnlFill)

        # % label centrado en la barra
        $lbPct2=New-Object Windows.Forms.Label; $lbPct2.Text="$usedPct%"
        $lbPct2.Location=New-Object System.Drawing.Point(0,0); $lbPct2.Size=New-Object System.Drawing.Size($BAR_W,$BAR_H)
        $lbPct2.ForeColor=[System.Drawing.Color]::White
        $lbPct2.Font=New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
        $lbPct2.TextAlign="MiddleCenter"; $pnlBg.Controls.Add($lbPct2)

        return $yPos + $BAR_H + 22
    }

    # ---- RAM ----
    $lbRamHdr=New-Object Windows.Forms.Label; $lbRamHdr.Text="  MEMORIA RAM"
    $lbRamHdr.Location=New-Object System.Drawing.Point(0,$y); $lbRamHdr.Size=New-Object System.Drawing.Size(620,22)
    $lbRamHdr.BackColor=[System.Drawing.Color]::FromArgb(30,30,45); $lbRamHdr.ForeColor=[System.Drawing.Color]::Cyan
    $lbRamHdr.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $lbRamHdr.TextAlign="MiddleLeft"; $frmSt.Controls.Add($lbRamHdr)
    $y += 24

    $ramClr = if ($memPct -ge 85) { [System.Drawing.Color]::FromArgb(220,60,60) }
              elseif ($memPct -ge 65) { [System.Drawing.Color]::FromArgb(220,150,0) }
              else { [System.Drawing.Color]::FromArgb(0,180,100) }
    $y = Draw-StorageBar $frmSt "RAM" $memPct "${memUsed} MB" "${memTotal} MB" $y $ramClr
    $y += 6

    # ---- PARTICIONES ----
    $lbPartHdr=New-Object Windows.Forms.Label; $lbPartHdr.Text="  PARTICIONES ANDROID"
    $lbPartHdr.Location=New-Object System.Drawing.Point(0,$y); $lbPartHdr.Size=New-Object System.Drawing.Size(620,22)
    $lbPartHdr.BackColor=[System.Drawing.Color]::FromArgb(30,30,45); $lbPartHdr.ForeColor=[System.Drawing.Color]::FromArgb(255,200,0)
    $lbPartHdr.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $lbPartHdr.TextAlign="MiddleLeft"; $frmSt.Controls.Add($lbPartHdr)
    $y += 24

    if ($partRows.Count -eq 0) {
        $lbNoPart=New-Object Windows.Forms.Label; $lbNoPart.Text="  No se pudieron leer particiones (df -h)"
        $lbNoPart.Location=New-Object System.Drawing.Point(18,$y); $lbNoPart.Size=New-Object System.Drawing.Size(580,20)
        $lbNoPart.ForeColor=[System.Drawing.Color]::Gray
        $lbNoPart.Font=New-Object System.Drawing.Font("Segoe UI",8); $frmSt.Controls.Add($lbNoPart)
        $y += 24
    } else {
        foreach ($row in $partRows) {
            if ($y -gt 440) { break }
            $pct = $row.Pct
            $clr = if ($pct -ge 90) { [System.Drawing.Color]::FromArgb(220,60,60) }
                   elseif ($pct -ge 75) { [System.Drawing.Color]::FromArgb(220,150,0) }
                   else { [System.Drawing.Color]::FromArgb(0,150,220) }
            $lbl = $row.Mount
            if ($lbl.Length -gt 22) { $lbl = "..." + $lbl.Substring($lbl.Length-19) }
            $y = Draw-StorageBar $frmSt $lbl $pct $row.Used $row.Size $y $clr
        }
    }

    # Boton cerrar
    $btnCl=New-Object Windows.Forms.Button; $btnCl.Text="CERRAR"
    $btnCl.Location=New-Object System.Drawing.Point(230,460); $btnCl.Size=New-Object System.Drawing.Size(160,32)
    $btnCl.FlatStyle="Flat"; $btnCl.ForeColor=[System.Drawing.Color]::LightGray
    $btnCl.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(80,80,80)
    $btnCl.BackColor=[System.Drawing.Color]::FromArgb(30,30,40)
    $btnCl.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnCl.Add_Click({ $frmSt.Close() }); $frmSt.Controls.Add($btnCl)

    $frmSt.ShowDialog() | Out-Null
})

# ---- C2[3]: APPS INSTALADAS ----
$btnsC2[3].Add_Click({
    $btn=$btnsC2[3]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== APPS INSTALADAS ==="

    if (-not (Check-ADB)) { CtrlLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="APPS INSTALADAS"; return }

    CtrlLog "[~] Contando paquetes..."
    $pkgUser   = (& adb shell "pm list packages -3"  2>$null) | Where-Object { $_ -match "package:" }
    $pkgSystem = (& adb shell "pm list packages -s"  2>$null) | Where-Object { $_ -match "package:" }
    $pkgDis    = (& adb shell "pm list packages -d"  2>$null) | Where-Object { $_ -match "package:" }

    $cU = $pkgUser.Count; $cS = $pkgSystem.Count; $cD = $pkgDis.Count
    CtrlLog "[+] Apps usuario    : $cU"
    CtrlLog "[+] Apps sistema    : $cS"
    CtrlLog "[+] Desactivadas    : $cD"
    CtrlLog "[+] TOTAL           : $($cU+$cS)"
    CtrlLog ""

    $frmApps = New-Object System.Windows.Forms.Form
    $frmApps.Text="APPS INSTALADAS - RNX TOOL PRO"
    $frmApps.ClientSize=New-Object System.Drawing.Size(480,360)
    $frmApps.BackColor=[System.Drawing.Color]::FromArgb(20,20,20)
    $frmApps.FormBorderStyle="FixedDialog"; $frmApps.StartPosition="CenterScreen"
    $frmApps.TopMost=$true

    $lbInfo=New-Object Windows.Forms.Label
    $lbInfo.Text="Usuario: $cU  |  Sistema: $cS  |  Desactivadas: $cD  |  TOTAL: $($cU+$cS)"
    $lbInfo.Location=New-Object System.Drawing.Point(14,10); $lbInfo.Size=New-Object System.Drawing.Size(452,18)
    $lbInfo.ForeColor=[System.Drawing.Color]::Cyan
    $lbInfo.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmApps.Controls.Add($lbInfo)

    function MakeAppBtn($txt,$x,$y,$clr,$data,$tipoPm) {
        $b=New-Object Windows.Forms.Button; $b.Text=$txt
        $b.Location=New-Object System.Drawing.Point($x,$y); $b.Size=New-Object System.Drawing.Size(218,30)
        $b.FlatStyle="Flat"; $b.ForeColor=[System.Drawing.Color]::$clr
        $b.FlatAppearance.BorderColor=[System.Drawing.Color]::$clr
        $b.BackColor=[System.Drawing.Color]::FromArgb(30,30,30)
        $b.Font=New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
        $b.Tag=@{data=$data;tipo=$tipoPm}
        $b.Add_Click({
            $pkgs=$this.Tag.data; $tipo=$this.Tag.tipo
            $txt2=New-Object System.Windows.Forms.Form
            $txt2.Text="Lista de paquetes ($tipo)"; $txt2.ClientSize=New-Object System.Drawing.Size(560,480)
            $txt2.BackColor=[System.Drawing.Color]::FromArgb(15,15,15); $txt2.StartPosition="CenterScreen"
            $txt2.TopMost=$true; $txt2.Owner=$frmApps
            $tb=New-Object Windows.Forms.TextBox; $tb.Multiline=$true; $tb.ReadOnly=$true; $tb.ScrollBars="Vertical"
            $tb.Location=New-Object System.Drawing.Point(8,8); $tb.Size=New-Object System.Drawing.Size(544,428)
            $tb.BackColor=[System.Drawing.Color]::FromArgb(15,15,15); $tb.ForeColor=[System.Drawing.Color]::Lime
            $tb.Font=New-Object System.Drawing.Font("Consolas",8)
            $sb=[System.Text.StringBuilder]::new()
            $i=0
            foreach ($p in $pkgs) {
                $i++; $name=$p -replace "^package:",""; $sb.AppendLine("[$i] $name") | Out-Null
                if ($tipo -eq "USUARIO") {
                    $sb.AppendLine("     Desinstalar : adb shell pm uninstall $name") | Out-Null
                } elseif ($tipo -eq "SISTEMA") {
                    $sb.AppendLine("     Desactivar  : adb shell pm disable-user $name") | Out-Null
                }
            }
            $tb.Text=$sb.ToString(); $txt2.Controls.Add($tb); $txt2.ShowDialog() | Out-Null
        })
        $frmApps.Controls.Add($b)
    }

    MakeAppBtn "LISTAR USUARIO ($cU)"    14  40 "Lime"   $pkgUser   "USUARIO"
    MakeAppBtn "LISTAR SISTEMA ($cS)"   248  40 "Cyan"   $pkgSystem "SISTEMA"
    MakeAppBtn "LISTAR DESACTIVADAS ($cD)" 14 78 "Orange" $pkgDis "DESACTIVADA"

    $btnClose2=New-Object Windows.Forms.Button; $btnClose2.Text="CERRAR"
    $btnClose2.Location=New-Object System.Drawing.Point(164,112); $btnClose2.Size=New-Object System.Drawing.Size(152,34)
    $btnClose2.FlatStyle="Flat"; $btnClose2.ForeColor=[System.Drawing.Color]::Gray
    $btnClose2.FlatAppearance.BorderColor=[System.Drawing.Color]::Gray
    $btnClose2.BackColor=[System.Drawing.Color]::FromArgb(30,30,30)
    $btnClose2.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnClose2.Add_Click({ $frmApps.Close() }); $frmApps.Controls.Add($btnClose2)
    $frmApps.ShowDialog() | Out-Null

    $btn.Enabled=$true; $btn.Text="APPS INSTALADAS"
})

#==========================================================================
# BLOQUE C3: SISTEMA / PC (naranja)
#==========================================================================

# ---- C3[1]: ADMIN DISPOSITIVOS ----
$btnsC3[1].Add_Click({
    $btn=$btnsC3[1]; $btn.Enabled=$false; $btn.Text="ABRIENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== ADMIN DISPOSITIVOS ==="

    # Abrir devmgmt.msc
    try { Start-Process "devmgmt.msc"; CtrlLog "[OK] Administrador de dispositivos abierto" }
    catch { CtrlLog "[!] No se pudo abrir devmgmt.msc: $_" }

    # Listar dispositivos con error via WMI
    CtrlLog ""
    CtrlLog "[~] Dispositivos con error (WMI):"
    try {
        $devErr = Get-WmiObject Win32_PnPEntity -EA SilentlyContinue |
                  Where-Object { $_.ConfigManagerErrorCode -ne 0 } |
                  Select-Object Name,ConfigManagerErrorCode,Description
        if ($devErr) {
            $codeMsg = @{
                1="No configurado correctamente"; 2="Memoria/recurso insuficiente"
                3="Driver danado"; 10="No puede iniciar"; 12="No tiene suficientes recursos libres"
                14="Requiere reinicio"; 18="Reinstalar drivers"; 22="Desactivado"
                28="Driver no instalado"; 43="Windows detecto problema"
            }
            foreach ($d in $devErr) {
                $code=$d.ConfigManagerErrorCode
                $msg=if($codeMsg.ContainsKey([int]$code)){$codeMsg[[int]$code]}else{"Codigo $code"}
                CtrlLog "  [ERR $code] $($d.Name)"
                CtrlLog "             -> $msg"
            }
            CtrlLog "[+] Total con error: $($devErr.Count)"
        } else { CtrlLog "  [OK] No hay dispositivos con error" }
    } catch { CtrlLog "  [~] WMI no disponible: $_" }

    # Detectar dispositivos Android/ADB
    CtrlLog ""
    CtrlLog "[~] Dispositivos Android/ADB presentes:"
    try {
        $android = Get-WmiObject Win32_PnPEntity -EA SilentlyContinue |
                   Where-Object { $_.Name -imatch "android|adb|composite adb|google usb|samsung mobile" }
        if ($android) {
            foreach ($d in $android) { CtrlLog "  [ADB] $($d.Name)  Estado: $($d.Status)" }
        } else { CtrlLog "  (ninguno detectado via WMI - puede ser normal)" }
    } catch { CtrlLog "  [~] No se pudo consultar WMI" }

    $btn.Enabled=$true; $btn.Text="ADMIN DISPOSITIVOS"
})

# ---- C3[2]: DESACTIVAR DEFENDER ----
$btnsC3[2].Add_Click({
    $btn=$btnsC3[2]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== WINDOWS DEFENDER ==="

    # Leer estado actual
    try {
        $status = Get-MpComputerStatus -EA Stop
        CtrlLog "[+] Proteccion en tiempo real : $(if($status.RealTimeProtectionEnabled){'ACTIVA'}else{'INACTIVA'})"
        CtrlLog "[+] Antimalware activado      : $(if($status.AntispywareEnabled){'SI'}else{'NO'})"
        CtrlLog "[+] AntiVirus activado        : $(if($status.AntivirusEnabled){'SI'}else{'NO'})"
        CtrlLog "[+] Servicio activo           : $(if($status.AMServiceEnabled){'SI'}else{'NO'})"
        CtrlLog "[+] Definiciones             : $($status.AntispywareSignatureVersion)"
        CtrlLog ""
        if ($status.RealTimeProtectionEnabled) {
            CtrlLog "[~] Proteccion en tiempo real ACTIVA"
            CtrlLog "[~] Abriendo panel de amenazas para desactivar..."
        } else {
            CtrlLog "[~] Proteccion en tiempo real ya INACTIVA"
        }
    } catch {
        CtrlLog "[~] Get-MpComputerStatus no disponible: $_"
        CtrlLog "[~] Abriendo panel de Defender directamente..."
    }

    # Abrir panel exacto de Defender
    try {
        Start-Process "windowsdefender://threatsettings"
        CtrlLog "[OK] Panel de Defender abierto (windowsdefender://threatsettings)"
    } catch {
        try { Start-Process "ms-settings:windowsdefender"; CtrlLog "[OK] Configuracion de seguridad abierta" }
        catch { CtrlLog "[!] No se pudo abrir Defender: $_" }
    }
    CtrlLog ""
    CtrlLog "[i] En el panel de Windows Security:"
    CtrlLog "    Proteccion contra virus y amenazas"
    CtrlLog "    -> Configuracion de proteccion"
    CtrlLog "    -> Proteccion en tiempo real: DESACTIVAR"
    CtrlLog ""
    CtrlLog "[i] TIP: Agrega exclusion de carpeta RNX TOOL para evitar"
    CtrlLog "         que Defender bloquee adb.exe (falso positivo comun)"

    $btn.Enabled=$true; $btn.Text="DESACTIVAR DEFENDER"
})

# ---- C3[3]: REINICIAR ADB ----
$btnsC3[3].Add_Click({
    $btn=$btnsC3[3]; $btn.Enabled=$false; $btn.Text="REINICIANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""
    CtrlLog "=== REINICIAR ADB ==="

    # Matar procesos adb.exe huerfanos
    CtrlLog "[~] Buscando procesos adb.exe activos..."
    $adbProcs = Get-Process -Name "adb" -EA SilentlyContinue
    if ($adbProcs) {
        foreach ($p in $adbProcs) {
            try { $p.Kill(); CtrlLog "  [OK] Matado adb.exe (PID: $($p.Id))" }
            catch { CtrlLog "  [~] No se pudo matar PID $($p.Id): $_" }
        }
    } else { CtrlLog "  [OK] No habia procesos adb.exe activos" }

    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.Application]::DoEvents()

    # kill-server + start-server
    CtrlLog "[~] adb kill-server..."
    $ks = (& adb kill-server 2>&1) -join ""
    CtrlLog "  -> $($ks.Trim())"
    Start-Sleep -Milliseconds 300

    CtrlLog "[~] adb start-server..."
    $ss = (& adb start-server 2>&1) -join ""
    CtrlLog "  -> $($ss.Trim())"
    Start-Sleep -Milliseconds 800
    [System.Windows.Forms.Application]::DoEvents()

    # Listar dispositivos
    CtrlLog ""
    CtrlLog "[~] Dispositivos post-reinicio:"
    $devs = (& adb devices 2>$null) | Where-Object { $_ -notmatch "^List|^$" }
    if ($devs) {
        $count=0
        foreach ($d in $devs) {
            $d2=$d.Trim()
            if (-not $d2) { continue }
            CtrlLog "  -> $d2"; $count++
        }
        CtrlLog "[+] $count dispositivo(s) detectado(s)"
    } else { CtrlLog "  (ninguno conectado)" }

    CtrlLog "[OK] ADB reiniciado correctamente"
    $btn.Enabled=$true; $btn.Text="REINICIAR ADB"
})

# ---- C3[4]: MONITOR PC ----
$btnsC3[4].Add_Click({
    $btn=$btnsC3[4]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== MONITOR PC ==="
    CtrlLog "[~] Recopilando informacion del sistema..."
    [System.Windows.Forms.Application]::DoEvents()

    # Recopilar todo antes de mostrar UI
    $osObj    = Get-WmiObject Win32_OperatingSystem   -EA SilentlyContinue
    $cpuObj   = Get-WmiObject Win32_Processor         -EA SilentlyContinue | Select-Object -First 1
    $dimsObj  = Get-WmiObject Win32_PhysicalMemory    -EA SilentlyContinue
    $diskObjs = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -EA SilentlyContinue
    $gpuObjs  = Get-WmiObject Win32_VideoController   -EA SilentlyContinue
    $top5     = Get-Process -EA SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 5

    $osName = if ($osObj) { $osObj.Caption } else { "Desconocido" }
    $osBits = if ($osObj) { $osObj.OSArchitecture } else { "" }
    $upStr  = if ($osObj) {
        $up = (Get-Date) - $osObj.ConvertToDateTime($osObj.LastBootUpTime)
        "{0}d {1}h {2}m" -f [int]$up.TotalDays,[int]($up.TotalHours%24),[int]($up.Minutes)
    } else { "?" }

    $cpuName   = if ($cpuObj) { $cpuObj.Name.Trim() } else { "?" }
    $cpuCores  = if ($cpuObj) { $cpuObj.NumberOfCores } else { "?" }
    $cpuThread = if ($cpuObj) { $cpuObj.NumberOfLogicalProcessors } else { "?" }
    $cpuGHz    = if ($cpuObj) { [math]::Round($cpuObj.MaxClockSpeed/1000,2) } else { "?" }
    $cpuLoad   = if ($cpuObj) { ($cpuObj | Measure-Object -Property LoadPercentage -Average).Average } else { 0 }

    $ramTotalMB= if ($osObj) { [math]::Round($osObj.TotalVisibleMemorySize/1KB,0) } else { 0 }
    $ramFreeMB = if ($osObj) { [math]::Round($osObj.FreePhysicalMemory/1KB,0)     } else { 0 }
    $ramUsedMB = $ramTotalMB - $ramFreeMB
    $ramPct    = if ($ramTotalMB -gt 0) { [math]::Round($ramUsedMB/$ramTotalMB*100,0) } else { 0 }
    $dimCount  = if ($dimsObj) { @($dimsObj).Count } else { 0 }
    $dimSpeed  = if ($dimsObj -and @($dimsObj).Count -gt 0) { (@($dimsObj))[0].Speed } else { "?" }

    CtrlLog "[+] Datos listos. Abriendo monitor..."
    $btn.Enabled=$true; $btn.Text="MONITOR PC"

    # ---- Mini UI visual ----
    $frmMon = New-Object System.Windows.Forms.Form
    $frmMon.Text="MONITOR PC - RNX TOOL PRO"; $frmMon.ClientSize=New-Object System.Drawing.Size(640,580)
    $frmMon.BackColor=[System.Drawing.Color]::FromArgb(12,14,20)
    $frmMon.FormBorderStyle="FixedDialog"; $frmMon.StartPosition="CenterScreen"; $frmMon.TopMost=$true

    # Header
    $lbHdr=New-Object Windows.Forms.Label; $lbHdr.Text="  MONITOR DEL SISTEMA"
    $lbHdr.Location=New-Object System.Drawing.Point(0,0); $lbHdr.Size=New-Object System.Drawing.Size(640,34)
    $lbHdr.BackColor=[System.Drawing.Color]::FromArgb(255,100,0); $lbHdr.ForeColor=[System.Drawing.Color]::White
    $lbHdr.Font=New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $lbHdr.TextAlign="MiddleLeft"; $frmMon.Controls.Add($lbHdr)

    $y=42

    function Mon-SectionHdr($parent,$title,$clr,$yPos) {
        $l=New-Object Windows.Forms.Label; $l.Text="  $title"
        $l.Location=New-Object System.Drawing.Point(0,$yPos); $l.Size=New-Object System.Drawing.Size(640,22)
        $l.BackColor=[System.Drawing.Color]::FromArgb(25,25,35); $l.ForeColor=$clr
        $l.Font=New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
        $l.TextAlign="MiddleLeft"; $parent.Controls.Add($l); return $yPos+24
    }
    function Mon-Row($parent,$label,$value,$yPos,$valClr="LightGray") {
        $lL=New-Object Windows.Forms.Label; $lL.Text=$label
        $lL.Location=New-Object System.Drawing.Point(20,$yPos); $lL.Size=New-Object System.Drawing.Size(130,18)
        $lL.ForeColor=[System.Drawing.Color]::FromArgb(100,100,120)
        $lL.Font=New-Object System.Drawing.Font("Segoe UI",8); $parent.Controls.Add($lL)
        $lV=New-Object Windows.Forms.Label; $lV.Text=$value
        $lV.Location=New-Object System.Drawing.Point(155,$yPos); $lV.Size=New-Object System.Drawing.Size(470,18)
        $lV.ForeColor=[System.Drawing.Color]::$valClr
        $lV.Font=New-Object System.Drawing.Font("Consolas",8); $parent.Controls.Add($lV)
        return $yPos+20
    }
    function Mon-Bar($parent,$pct,$yPos,$clrFill,$label2) {
        $BAR_W=600; $BAR_H=20
        $pnlBg=New-Object Windows.Forms.Panel; $pnlBg.Location=New-Object System.Drawing.Point(20,$yPos)
        $pnlBg.Size=New-Object System.Drawing.Size($BAR_W,$BAR_H); $pnlBg.BackColor=[System.Drawing.Color]::FromArgb(35,35,50)
        $parent.Controls.Add($pnlBg)
        $fw=[math]::Max(4,[int]($BAR_W*$pct/100))
        $pF=New-Object Windows.Forms.Panel; $pF.Location=New-Object System.Drawing.Point(0,0)
        $pF.Size=New-Object System.Drawing.Size($fw,$BAR_H); $pF.BackColor=$clrFill; $pnlBg.Controls.Add($pF)
        $lp=New-Object Windows.Forms.Label; $lp.Text="$label2"
        $lp.Location=New-Object System.Drawing.Point(0,0); $lp.Size=New-Object System.Drawing.Size($BAR_W,$BAR_H)
        $lp.ForeColor=[System.Drawing.Color]::White
        $lp.Font=New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
        $lp.TextAlign="MiddleCenter"; $pnlBg.Controls.Add($lp)
        return $yPos+$BAR_H+4
    }

    # OS
    $y = Mon-SectionHdr $frmMon "SISTEMA OPERATIVO" ([System.Drawing.Color]::FromArgb(100,180,255)) $y
    $y = Mon-Row $frmMon "OS" "$osName  ($osBits)" $y "White"
    $y = Mon-Row $frmMon "Uptime" $upStr $y "Cyan"
    $y += 6

    # CPU
    $y = Mon-SectionHdr $frmMon "PROCESADOR" ([System.Drawing.Color]::FromArgb(255,160,0)) $y
    $y = Mon-Row $frmMon "Modelo" $cpuName $y "White"
    $y = Mon-Row $frmMon "Nucleos" "$cpuCores fisicos / $cpuThread logicos  |  $cpuGHz GHz max" $y "LightGray"
    $cpuClr = if ($cpuLoad -ge 85) { [System.Drawing.Color]::FromArgb(220,60,60) }
               elseif ($cpuLoad -ge 60) { [System.Drawing.Color]::FromArgb(220,150,0) }
               else { [System.Drawing.Color]::FromArgb(0,200,100) }
    $y = Mon-Bar $frmMon $cpuLoad $y $cpuClr "CPU  $cpuLoad%"
    $y += 6

    # RAM
    $y = Mon-SectionHdr $frmMon "MEMORIA RAM" ([System.Drawing.Color]::FromArgb(100,220,180)) $y
    $ramGB = [math]::Round($ramTotalMB/1024,1); $ramUsedGB=[math]::Round($ramUsedMB/1024,1); $ramFreeGB=[math]::Round($ramFreeMB/1024,1)
    $y = Mon-Row $frmMon "Total" "$ramGB GB  |  Usada: $ramUsedGB GB  |  Libre: $ramFreeGB GB" $y "White"
    if ($dimCount -gt 0) { $y = Mon-Row $frmMon "Modulos" "$dimCount DIMM(s)  @  $dimSpeed MHz" $y "LightGray" }
    $ramClr2 = if ($ramPct -ge 85) { [System.Drawing.Color]::FromArgb(220,60,60) }
                elseif ($ramPct -ge 65) { [System.Drawing.Color]::FromArgb(220,150,0) }
                else { [System.Drawing.Color]::FromArgb(0,180,220) }
    $y = Mon-Bar $frmMon $ramPct $y $ramClr2 "RAM  $ramPct%  ($ramUsedGB GB / $ramGB GB)"
    $y += 6

    # Discos
    $y = Mon-SectionHdr $frmMon "ALMACENAMIENTO" ([System.Drawing.Color]::FromArgb(200,100,255)) $y
    if ($diskObjs) {
        foreach ($d in $diskObjs) {
            if ($y -gt 470) { break }
            $szGB=[math]::Round($d.Size/1GB,1); $fGB=[math]::Round($d.FreeSpace/1GB,1); $uGB=[math]::Round($szGB-$fGB,1)
            $dp=if($szGB-gt 0){[math]::Round($uGB/$szGB*100,0)}else{0}
            $dClr=if($dp-ge 90){[System.Drawing.Color]::FromArgb(220,60,60)}elseif($dp-ge 70){[System.Drawing.Color]::FromArgb(220,150,0)}else{[System.Drawing.Color]::FromArgb(80,140,220)}
            $y = Mon-Bar $frmMon $dp $y $dClr "$($d.DeviceID)  $uGB GB / $szGB GB  ($dp%  -  $fGB GB libre)"
        }
    } else { $y = Mon-Row $frmMon "Discos" "No disponible" $y "Gray" }
    $y += 6

    # GPU
    if ($gpuObjs -and $y -lt 460) {
        $y = Mon-SectionHdr $frmMon "TARJETA GRAFICA" ([System.Drawing.Color]::FromArgb(255,80,160)) $y
        foreach ($gpu in $gpuObjs) {
            if ($y -gt 470) { break }
            $vramMB=try{[math]::Round($gpu.AdapterRAM/1MB,0)}catch{0}
            $y = Mon-Row $frmMon "GPU" "$($gpu.Name)  |  VRAM: $vramMB MB  |  Driver: $($gpu.DriverVersion)" $y "White"
        }
        $y += 4
    }

    # Top 5 procesos
    if ($top5 -and $y -lt 440) {
        $y = Mon-SectionHdr $frmMon "TOP 5 PROCESOS (CPU)" ([System.Drawing.Color]::FromArgb(255,80,80)) $y
        foreach ($p in $top5) {
            if ($y -gt 470) { break }
            $cpuS=[math]::Round($p.CPU,1); $memMB=[math]::Round($p.WorkingSet64/1MB,0)
            $y = Mon-Row $frmMon $p.ProcessName "CPU: ${cpuS}s   RAM: ${memMB} MB" $y "LightGray"
        }
    }

    # Boton cerrar
    $btnCl2=New-Object Windows.Forms.Button; $btnCl2.Text="CERRAR"
    $btnCl2.Location=New-Object System.Drawing.Point(240,542); $btnCl2.Size=New-Object System.Drawing.Size(160,32)
    $btnCl2.FlatStyle="Flat"; $btnCl2.ForeColor=[System.Drawing.Color]::LightGray
    $btnCl2.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(80,80,80)
    $btnCl2.BackColor=[System.Drawing.Color]::FromArgb(25,25,35)
    $btnCl2.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnCl2.Add_Click({ $frmMon.Close() }); $frmMon.Controls.Add($btnCl2)
    $frmMon.ShowDialog() | Out-Null
})

# ---- C3[4]: MONITOR PC (posicion 4 ahora) - ya definido arriba ----
# ---- C3[0]: ADMIN TAREAS ----
# Nota: Place-Grid crea btnsC3 en orden de CL3:
# [0]=ADMIN TAREAS [1]=ADMIN DISPOSITIVOS [2]=DESACTIVAR DEFENDER
# [3]=REINICIAR ADB [4]=MONITOR PC [5]=LIMPIEZA TEMP PC
# Los handlers de [1],[2],[3] ya existen arriba como btnsC3[0],[1],[2]
# Remapeamos: los handlers viejos [0],[1],[2],[3] siguen validos para los nuevos indices [1],[2],[3],[4]
# Solo agregamos handlers para [0]=ADMIN TAREAS y [5]=LIMPIEZA TEMP PC

$btnsC3[0].Add_Click({
    $btn=$btnsC3[0]; $btn.Enabled=$false; $btn.Text="ABRIENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== ADMINISTRADOR DE TAREAS ==="
    try {
        Start-Process "taskmgr.exe"
        CtrlLog "[OK] Administrador de tareas abierto"
        CtrlLog "[i] Tip: pestaña Rendimiento -> CPU/Memoria/Disco/Red en tiempo real"
    } catch { CtrlLog "[!] No se pudo abrir taskmgr.exe: $_" }
    $btn.Enabled=$true; $btn.Text="ADMIN TAREAS"
})

$btnsC3[5].Add_Click({
    $btn=$btnsC3[5]; $btn.Enabled=$false; $btn.Text="LIMPIANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    CtrlLog ""; CtrlLog "=== LIMPIEZA DE ARCHIVOS TEMPORALES ==="

    $paths = @(
        $env:TEMP,
        "$env:SystemRoot\Temp",
        "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
    )
    $totalDeleted = 0; $totalSize = 0

    foreach ($path in $paths) {
        if (-not (Test-Path $path)) { continue }
        $files = Get-ChildItem $path -Recurse -File -EA SilentlyContinue
        $pathSize = ($files | Measure-Object -Property Length -Sum -EA SilentlyContinue).Sum
        $pathSize = if ($pathSize) { $pathSize } else { 0 }
        $deleted  = 0
        foreach ($f in $files) {
            try { Remove-Item $f.FullName -Force -EA Stop; $deleted++ } catch {}
        }
        # Borrar carpetas vacias
        Get-ChildItem $path -Recurse -Directory -EA SilentlyContinue |
            Sort-Object FullName -Descending |
            ForEach-Object { try { Remove-Item $_.FullName -Force -EA SilentlyContinue } catch {} }
        $sizeMB = [math]::Round($pathSize/1MB,1)
        CtrlLog "  [OK] $path -> $deleted archivos eliminados ($sizeMB MB)"
        $totalDeleted += $deleted; $totalSize += $pathSize
    }

    $totalMB = [math]::Round($totalSize/1MB,1)
    CtrlLog ""
    CtrlLog "[+] Total: $totalDeleted archivos eliminados"
    CtrlLog "[+] Espacio recuperado: $totalMB MB aprox."
    CtrlLog "[OK] Limpieza completada"
    $btn.Enabled=$true; $btn.Text="LIMPIEZA TEMP PC"
})