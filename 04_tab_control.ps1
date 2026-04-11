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
$grpC2 = New-GBox $tabCtrl "ARCHIVOS / FIRMWARE"  $CX $CY2 $CGW $CGH2 "Red"
$grpC3 = New-GBox $tabCtrl "SISTEMA / PC"        $CX $CY3 $CGW $CGH3 "Orange"

$CL1=@("ODIN3","HxD HEX EDITOR","QFIL","USB DRIVERS")
$CL2=@("ORGANIZAR FIRMWARE","RENOMBRAR ARCHIVOS","EXTRAER FIRMWARE","VERIFICAR CHECKSUM")
$CL3=@("ADMIN TAREAS","ADMIN DISPOSITIVOS","DESACTIVAR DEFENDER","REINICIAR ADB","MONITOR PC","LIMPIEZA TEMP PC")

$btnsC1=Place-Grid $grpC1 $CL1 "Yellow" 2 $CBTW $CBTH $CPX $CPY $CGX $CGY
$btnsC2=Place-Grid $grpC2 $CL2 "Red"     2 $CBTW $CBTH $CPX $CPY $CGX $CGY
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
# BLOQUE C2 - ARCHIVOS / FIRMWARE
#==========================================================================

# ---- [0] ORGANIZAR FIRMWARE ----
$btnsC2[0].Add_Click({
    $btn = $btnsC2[0]; $btn.Enabled=$false; $btn.Text="ORGANIZANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        CtrlLog ""
        CtrlLog "=============================================="
        CtrlLog "  ORGANIZAR FIRMWARE - RNX TOOL PRO v2"
        CtrlLog "=============================================="
        CtrlLog "[~] Selecciona la carpeta con los firmwares..."

        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        $fb.Description = "Selecciona carpeta con firmwares"
        if ($fb.ShowDialog() -ne "OK") { CtrlLog "[~] Cancelado."; return }

        $source = $fb.SelectedPath
        $dest   = Join-Path $source "Organizados"
        New-Item $dest -ItemType Directory -Force | Out-Null
        CtrlLog "[+] Carpeta origen : $source"
        CtrlLog "[+] Carpeta destino: $dest"
        CtrlLog ""

        # ---- FILTRO DE VINCULACION A CELULARES ----
        # Solo se mueven archivos cuyo nombre contenga referencia a dispositivo movil
        $vinculacionPattern = "imei|sn|serial|sm-|xt\d|redmi|poco|xiaomi|miui|samsung|galaxy|motorola|moto|oppo|vivo|realme|tecno|itel|huawei|honor|oneplus|pixel|iphone|nokia|lg |htc|sony|xperia|\d{15}"

        # Cargar TODOS los archivos relevantes (firmware + partes NV/EFS)
        $allFiles = Get-ChildItem $source -Recurse -File |
                    Where-Object { $_.FullName -notlike "*\Organizados\*" }

        # Extensiones de firmware movil estandar
        $fwExts = "zip|rar|tgz|gz|7z|img|tar|md5|ffu|qcn|bin|lz4|ext4|erofs|sparse"

        $files = $allFiles | Where-Object { $_.Extension -imatch "\.($fwExts)$" }

        if ($files.Count -eq 0) { CtrlLog "[!] No se encontraron archivos de firmware."; return }
        CtrlLog "[+] $($files.Count) archivos candidatos."
        CtrlLog ""

        $movidos = 0; $duplicados = 0; $omitidos = 0
        $procesados = [System.Collections.Generic.HashSet[string]]::new()

        # ================================================================
        # FASE 1: GRUPOS ESPECIALES - NV/EFS con correlacion horaria (+-5 min)
        # ================================================================
        CtrlLog "[FASE 1] Detectando grupos NV/EFS por correlacion horaria..."

        # Mapear archivos NV/EFS por nombre base
        $nvNames  = @("nvram","nvdata","protect1","protect2","efs","sec_efs","nvcfg","nvbk")
        $nvFiles  = $allFiles | Where-Object {
            $b = $_.BaseName.ToLower() -replace "\..*",""
            $nvNames | Where-Object { $b -match $_ }
        }

        # Agrupar por ventana de tiempo de 5 minutos
        $grupos = @{}
        foreach ($nf in $nvFiles) {
            $slot = [math]::Floor(($nf.LastWriteTime - [datetime]"2000-01-01").TotalMinutes / 5)
            $key  = "NV_$slot"
            if (-not $grupos[$key]) { $grupos[$key] = [System.Collections.Generic.List[object]]::new() }
            $grupos[$key].Add($nf)
        }

        foreach ($key in $grupos.Keys) {
            $grp = $grupos[$key]
            if ($grp.Count -lt 2) { continue }  # necesita al menos nvram+nvdata

            $nombres   = $grp | ForEach-Object { $_.BaseName.ToLower() -replace "\..*","" }
            $tieneNv   = ($nombres | Where-Object { $_ -match "nvram|nvdata" }).Count -ge 1
            if (-not $tieneNv) { continue }

            $tieneEfs  = ($nombres | Where-Object { $_ -match "^efs$|sec_efs" }).Count -ge 1
            $tieneProt = ($nombres | Where-Object { $_ -match "protect1|protect2" }).Count -ge 1

            $ts = $grp[0].LastWriteTime.ToString("yyyyMMdd_HHmm")
            $carpetaNombre = if ($tieneEfs) {
                "EFS_Full_Backup_$ts"
            } elseif ($tieneProt) {
                "NV_Protect_Backup_$ts"
            } else {
                "NV_Backup_$ts"
            }

            $destGrupo = Join-Path $dest $carpetaNombre
            New-Item $destGrupo -ItemType Directory -Force | Out-Null
            CtrlLog "  [GRUPO] $carpetaNombre ($($grp.Count) archivos)"

            foreach ($gf in $grp) {
                if ($procesados.Contains($gf.FullName)) { continue }
                $tgt = Join-Path $destGrupo $gf.Name
                if (Test-Path $tgt) {
                    $b2=$gf.BaseName; $e2=$gf.Extension; $v=2
                    do { $tgt = Join-Path $destGrupo "${b2}_v${v}${e2}"; $v++ } while (Test-Path $tgt)
                    $duplicados++
                }
                Move-Item $gf.FullName $tgt -Force
                $procesados.Add($gf.FullName) | Out-Null
                CtrlLog "    -> $($gf.Name)"
                $movidos++
            }
            [System.Windows.Forms.Application]::DoEvents()
        }

        # ================================================================
        # FASE 2: ARCHIVOS ESPECIALES (.ffu, .qcn)
        # ================================================================
        CtrlLog ""
        CtrlLog "[FASE 2] Detectando .ffu y .qcn..."

        foreach ($file in ($files | Where-Object { -not $procesados.Contains($_.FullName) })) {
            $ext = $file.Extension.ToLower()
            $destEsp = $null

            if ($ext -eq ".ffu") { $destEsp = Join-Path $dest "EMC_Firmware" }
            elseif ($ext -eq ".qcn") { $destEsp = Join-Path $dest "QCN_File" }

            if ($destEsp) {
                New-Item $destEsp -ItemType Directory -Force | Out-Null
                $tgt = Join-Path $destEsp $file.Name
                if (Test-Path $tgt) {
                    $b2=$file.BaseName; $e2=$file.Extension; $v=2
                    do { $tgt = Join-Path $destEsp "${b2}_v${v}${e2}"; $v++ } while (Test-Path $tgt)
                    $duplicados++
                }
                Move-Item $file.FullName $tgt -Force
                $procesados.Add($file.FullName) | Out-Null
                CtrlLog "  [$(($ext).ToUpper() -replace '.')] $($file.Name) -> $(Split-Path $destEsp -Leaf)"
                $movidos++
            }
        }

        # ================================================================
        # FASE 3: FIRMWARE GENERAL - con filtro de vinculacion
        # ================================================================
        CtrlLog ""
        CtrlLog "[FASE 3] Organizando firmware por marca/modelo..."

        foreach ($file in ($files | Where-Object { -not $procesados.Contains($_.FullName) })) {
            $name = $file.Name.ToLower()

            # Filtro de vinculacion: si no hay match a dispositivo movil, skip
            if ($name -notmatch $vinculacionPattern) {
                CtrlLog "  [SKIP] $($file.Name) - sin referencia a dispositivo movil"
                $omitidos++
                $procesados.Add($file.FullName) | Out-Null
                continue
            }

            # Deteccion de marca
            if     ($name -match "miui|redmi|poco|xiaomi|_rn\d|_mi\d|_poco")  { $brand = "Xiaomi" }
            elseif ($name -match "sm-|samsung|galaxy")                          { $brand = "Samsung" }
            elseif ($name -match "xt\d|moto|motorola")                        { $brand = "Motorola" }
            elseif ($name -match "oppo")                                         { $brand = "Oppo" }
            elseif ($name -match "vivo")                                     { $brand = "Vivo" }
            elseif ($name -match "realme")                                       { $brand = "Realme" }
            elseif ($name -match "tecno|camon|spark")                            { $brand = "Tecno" }
            elseif ($name -match "itel")                                     { $brand = "Itel" }
            elseif ($name -match "huawei|honor")                                 { $brand = "Huawei" }
            elseif ($name -match "oneplus")                                      { $brand = "OnePlus" }
            elseif ($name -match "pixel")                                        { $brand = "Google" }
            elseif ($name -match "iphone")                                       { $brand = "Apple" }
            elseif ($name -match "nokia")                                    { $brand = "Nokia" }
            elseif ($name -match "lg")                                       { $brand = "LG" }
            elseif ($name -match "htc")                                      { $brand = "HTC" }
            elseif ($name -match "sony|xperia")                                  { $brand = "Sony" }
            else                                                                  { $brand = "Otros" }

            # Deteccion de modelo (heuristica ampliada)
            $modelo = ""
            if     ($name -match "(sm-[a-z0-9]{4,8})")    { $modelo = $Matches[1].ToUpper() }
            elseif ($name -match "(xt\d{3,5}[a-z]?)")     { $modelo = $Matches[1].ToUpper() }
            elseif ($name -match "miui_([a-z0-9_]+?)_v")  { $modelo = ($Matches[1] -replace "_"," ").Trim() }
            elseif ($name -match "_(rn\d+[a-z]?)[_\.]")   { $modelo = "Redmi Note $($Matches[1] -replace 'rn','')" }
            elseif ($name -match "_(m\d+[a-z]?)[_\.]")    { $modelo = $Matches[1].ToUpper() }
            elseif ($name -match "_(cph\d+)[_\.]")        { $modelo = $Matches[1].ToUpper() }
            elseif ($name -match "_(v\d{4}[a-z]?)[_\.]")  { $modelo = $Matches[1].ToUpper() }
            elseif ($name -match "(pixel[ _]\d[a-z ]*)")   { $modelo = ($Matches[1] -replace "[ _]"," ").Trim() }

            $destPath = if ($modelo) {
                Join-Path $dest (Join-Path $brand $modelo)
            } else {
                Join-Path $dest $brand
            }
            New-Item $destPath -ItemType Directory -Force | Out-Null

            $target = Join-Path $destPath $file.Name
            if (Test-Path $target) {
                $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                $ext2 = $file.Extension; $v = 2
                do { $target = Join-Path $destPath "${base}_v${v}${ext2}"; $v++ } while (Test-Path $target)
                $duplicados++
                CtrlLog "  [DUP] $($file.Name) -> $([System.IO.Path]::GetFileName($target))"
            }

            Move-Item $file.FullName $target -Force
            $procesados.Add($file.FullName) | Out-Null
            $rel = "$brand$(if($modelo){`"/$modelo`"})"
            CtrlLog "  [OK] $($file.Name) -> $rel"
            $movidos++
            [System.Windows.Forms.Application]::DoEvents()
        }

        CtrlLog ""
        CtrlLog "=============================================="
        CtrlLog "  RESUMEN ORGANIZAR FIRMWARE"
        CtrlLog "=============================================="
        CtrlLog "  Movidos     : $movidos"
        CtrlLog "  Duplicados  : $duplicados (renombrados _v2, _v3...)"
        CtrlLog "  Omitidos    : $omitidos (sin vinculacion a celular)"
        CtrlLog "  Destino     : $dest"
        CtrlLog "=============================================="

        $abrir = [System.Windows.Forms.MessageBox]::Show(
            "Firmware organizado.`n`nMovidos  : $movidos`nOmitidos : $omitidos`n`nAbrir carpeta destino?",
            "LISTO", "YesNo", "Information")
        if ($abrir -eq "Yes") { Start-Process explorer.exe $dest }

    } catch { CtrlLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="ORGANIZAR FIRMWARE" }
})

# ---- [1] RENOMBRAR ARCHIVOS ----
$btnsC2[1].Add_Click({
    $btn = $btnsC2[1]; $btn.Enabled=$false; $btn.Text="RENOMBRANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        CtrlLog ""
        CtrlLog "=============================================="
        CtrlLog "  RENOMBRAR ARCHIVOS - RNX TOOL PRO"
        CtrlLog "=============================================="
        CtrlLog "[~] Selecciona carpeta con archivos a renombrar..."

        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        $fb.Description = "Selecciona carpeta para renombrar archivos"
        if ($fb.ShowDialog() -ne "OK") { CtrlLog "[~] Cancelado."; return }

        $files = Get-ChildItem $fb.SelectedPath -File
        if ($files.Count -eq 0) { CtrlLog "[!] No hay archivos en la carpeta."; return }
        CtrlLog "[+] $($files.Count) archivos encontrados."
        CtrlLog ""

        $renombrados = 0; $sin_cambios = 0

        foreach ($file in $files) {
            $nuevo = $file.Name
            # Reglas de limpieza
            $nuevo = $nuevo.ToLower()
            $nuevo = $nuevo -replace "\s+", "_"          # espacios -> _
            $nuevo = $nuevo -replace "[\(\)\[\]\{\}]", "" # quitar parentesis/corchetes
            $nuevo = $nuevo -replace "[áéíóúàèìòùâêîôû]", { $args[0].Value -replace "á","a" -replace "é","e" -replace "í","i" -replace "ó","o" -replace "ú","u" }
            $nuevo = $nuevo -replace "[^a-z0-9_\.\-]", "" # solo alfanumericos, _, ., -
            $nuevo = $nuevo -replace "_{2,}", "_"          # dobles _ -> uno solo
            $nuevo = $nuevo.Trim("_")

            if ($nuevo -eq $file.Name) { $sin_cambios++; continue }

            $target = Join-Path $file.DirectoryName $nuevo
            # Evitar colision
            if (Test-Path $target) {
                $base = [System.IO.Path]::GetFileNameWithoutExtension($nuevo)
                $ext  = [System.IO.Path]::GetExtension($nuevo)
                $v = 2
                do { $target = Join-Path $file.DirectoryName "${base}_v${v}${ext}"; $v++ } while (Test-Path $target)
                $nuevo = [System.IO.Path]::GetFileName($target)
            }

            Rename-Item $file.FullName $target
            CtrlLog "  [OK] $($file.Name)"
            CtrlLog "       -> $nuevo"
            $renombrados++
            [System.Windows.Forms.Application]::DoEvents()
        }

        CtrlLog ""
        CtrlLog "  Renombrados : $renombrados"
        CtrlLog "  Sin cambios : $sin_cambios"
        CtrlLog "=============================================="

    } catch { CtrlLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="RENOMBRAR ARCHIVOS" }
})

# ---- [2] EXTRAER FIRMWARE ----
$btnsC2[2].Add_Click({
    $btn = $btnsC2[2]; $btn.Enabled=$false; $btn.Text="EXTRAYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        CtrlLog ""
        CtrlLog "=============================================="
        CtrlLog "  EXTRAER FIRMWARE - RNX TOOL PRO v2"
        CtrlLog "=============================================="

        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "Firmware (*.zip;*.rar;*.7z;*.tgz;*.tar;*.gz;*.tar.md5;*.md5)|*.zip;*.rar;*.7z;*.tgz;*.tar;*.gz;*.md5|Todos|*.*"
        $fd.Title  = "Selecciona archivo de firmware a extraer"
        if ($fd.ShowDialog() -ne "OK") { CtrlLog "[~] Cancelado."; return }

        $archPath = $fd.FileName
        $archName = [System.IO.Path]::GetFileName($archPath)
        $archSz   = [math]::Round((Get-Item $archPath).Length / 1MB, 2)
        $ext      = [System.IO.Path]::GetExtension($archPath).ToLower()
        $base     = [System.IO.Path]::GetFileNameWithoutExtension($archPath) -replace "\.tar$",""

        $dest = Join-Path ([System.IO.Path]::GetDirectoryName($archPath)) ($base + "_extraido")
        New-Item $dest -ItemType Directory -Force | Out-Null

        CtrlLog "[+] Archivo : $archName ($archSz MB)"
        CtrlLog "[+] Destino : $dest"
        CtrlLog "[~] Preparando extraccion..."

        # Buscar 7z
        $7z = $null
        foreach ($c in @(
            (Join-Path $script:TOOLS_DIR "7z.exe"),
            "C:\Program Files\7-Zip\7z.exe",
            "C:\Program Files (x86)\7-Zip\7z.exe"
        )) { if (Test-Path $c) { $7z = $c; break } }

        $isTar   = ($ext -match "\.(tar|md5|tgz|gz)$") -or ($archPath -imatch "\.tar\.md5$")
        $isZip   = ($ext -eq ".zip")
        $is7zRar = ($ext -match "\.(7z|rar)$")

        # ---- Ventana de progreso ----
        $ui = Show-ExtractProgress $archName
        $ui.LblStatus.Text = "Iniciando..."; [System.Windows.Forms.Application]::DoEvents()

        try {
            if ($isZip -and -not $7z) {
                # ZIP nativo con progreso por entrada
                $ui.LblStatus.Text = "Extrayendo ZIP (nativo)..."
                $ui.Bar.Value = 5; [System.Windows.Forms.Application]::DoEvents()
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $zip   = [System.IO.Compression.ZipFile]::OpenRead($archPath)
                $total = $zip.Entries.Count; $done = 0
                foreach ($entry in $zip.Entries) {
                    $outPath = [System.IO.Path]::Combine($dest, $entry.FullName)
                    $outDir  = [System.IO.Path]::GetDirectoryName($outPath)
                    if (-not (Test-Path $outDir)) { New-Item $outDir -ItemType Directory -Force | Out-Null }
                    if (-not $entry.FullName.EndsWith("/")) {
                        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $outPath, $true)
                    }
                    $done++
                    $pct = [int](($done / $total) * 95) + 4
                    $ui.Bar.Value   = [Math]::Min($pct, 98)
                    $ui.LblPct.Text = "$pct%"
                    $ui.LblFile.Text = $entry.Name
                    $ui.LblStatus.Text = "[$done/$total] $($entry.Name)"
                    if ($done % 4 -eq 0) { [System.Windows.Forms.Application]::DoEvents() }
                }
                $zip.Dispose()
                $ui.Bar.Value = 100; $ui.LblPct.Text = "100%"
                [System.Windows.Forms.Application]::DoEvents()
                CtrlLog "[OK] ZIP extraido (PowerShell nativo)"

            } elseif ($7z) {
                # 7z con progreso via archivo de log temporal (evita freeze total de UI)
                $ui.LblStatus.Text = "Extrayendo con 7z ($ext)..."
                $ui.Bar.Value = 5; [System.Windows.Forms.Application]::DoEvents()

                $logFile = [System.IO.Path]::GetTempFileName()
                try {
                    # Lanzar 7z redirigiendo TODO a archivo de log (sin pipes que bloquean)
                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName    = $7z
                    $psi.Arguments   = "x `"$archPath`" `"-o$dest`" -y -bsp1 -bso1 -bse1"
                    $psi.UseShellExecute        = $false
                    $psi.RedirectStandardOutput = $false
                    $psi.RedirectStandardError  = $false
                    $psi.CreateNoWindow         = $true
                    # Redirigir stdout al archivo via cmd /c
                    $psi.FileName  = "cmd.exe"
                    $psi.Arguments = "/c `"`"$7z`" x `"$archPath`" `"-o$dest`" -y -bsp1 -bso1 -bse1 > `"$logFile`" 2>&1`""

                    $proc = [System.Diagnostics.Process]::Start($psi)
                    $lastPos = 0
                    while (-not $proc.HasExited) {
                        Start-Sleep -Milliseconds 120
                        [System.Windows.Forms.Application]::DoEvents()
                        # Leer lineas nuevas del log
                        try {
                            $fs = [System.IO.File]::Open($logFile, [System.IO.FileMode]::Open,
                                  [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                            $fs.Seek($lastPos, [System.IO.SeekOrigin]::Begin) | Out-Null
                            $sr = New-Object System.IO.StreamReader($fs)
                            $chunk = $sr.ReadToEnd()
                            $lastPos = $fs.Position
                            $sr.Dispose(); $fs.Dispose()
                            foreach ($l in ($chunk -split "`n")) {
                                $l = $l.Trim()
                                if ($l -match "(\d+)%") {
                                    $pct = [int]$Matches[1]
                                    $ui.Bar.Value   = [Math]::Min(5 + [int]($pct * 0.93), 98)
                                    $ui.LblPct.Text = "$pct%"
                                }
                                if ($l -match "\- (.+)$") {
                                    $ui.LblFile.Text   = $Matches[1].Trim()
                                    $ui.LblStatus.Text = $Matches[1].Trim()
                                }
                            }
                        } catch {}
                    }
                    $proc.WaitForExit()
                    $ui.Bar.Value = 100; $ui.LblPct.Text = "100%"
                    [System.Windows.Forms.Application]::DoEvents()

                    if ($proc.ExitCode -ne 0) { CtrlLog "[!] 7z salio con codigo $($proc.ExitCode)" }
                    else { CtrlLog "[OK] Extraccion completada con 7z" }
                } finally {
                    try { Remove-Item $logFile -Force -EA SilentlyContinue } catch {}
                }

                # Manejo TAR interno (tgz / tar.md5)
                if ($isTar) {
                    $innerTar = Get-ChildItem $dest -Recurse -File |
                                Where-Object { $_.Extension -imatch "\.(tar)$" } | Select-Object -First 1
                    if ($innerTar) {
                        CtrlLog "[~] TAR interno: $($innerTar.Name) - extrayendo imgs/..."
                        $ui.LblStatus.Text = "TAR interno: $($innerTar.Name)"
                        $ui.Bar.Value = 50; [System.Windows.Forms.Application]::DoEvents()
                        $destInner = Join-Path $dest "imgs"
                        New-Item $destInner -ItemType Directory -Force | Out-Null
                        & $7z x "$($innerTar.FullName)" "-o$destInner" -y 2>&1 | Out-Null
                        $ui.Bar.Value = 100; $ui.LblPct.Text = "100%"
                        [System.Windows.Forms.Application]::DoEvents()
                        CtrlLog "[OK] TAR interno extraido en: imgs/"
                    }
                }

            } else {
                # Fallback: tar nativo
                $ui.LblStatus.Text = "Extrayendo con tar nativo..."
                $ui.Bar.Value = 10; [System.Windows.Forms.Application]::DoEvents()
                if (Get-Command tar -ErrorAction SilentlyContinue) {
                    & tar -xf "$archPath" -C "$dest" 2>&1 | Out-Null
                    $ui.Bar.Value = 100; $ui.LblPct.Text = "100%"
                    [System.Windows.Forms.Application]::DoEvents()
                    CtrlLog "[OK] Extraido con tar nativo"
                } else {
                    CtrlLog "[!] No se encontro 7z.exe ni tar."
                    CtrlLog "[~] Coloca 7z.exe en .\tools\ o instala 7-Zip"
                    return
                }
            }
        } finally {
            Start-Sleep -Milliseconds 400
            if ($ui -and $ui.Win -and -not $ui.Win.IsDisposed) {
                try { $ui.Win.Close() } catch {}
            }
        }

        $archivos = (Get-ChildItem $dest -Recurse -File).Count
        CtrlLog ""
        CtrlLog "  Archivos extraidos : $archivos"
        CtrlLog "  Carpeta            : $dest"
        CtrlLog "=============================================="

        $abrir = [System.Windows.Forms.MessageBox]::Show(
            "Extraccion completada.`n$archivos archivos.`n`nAbrir carpeta?",
            "EXTRAIDO", "YesNo", "Information")
        if ($abrir -eq "Yes") { Start-Process explorer.exe $dest }

    } catch { CtrlLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="EXTRAER FIRMWARE" }
})
# ---- [3] VERIFICAR CHECKSUM ----
$btnsC2[3].Add_Click({
    $btn = $btnsC2[3]; $btn.Enabled=$false; $btn.Text="CALCULANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        CtrlLog ""
        CtrlLog "=============================================="
        CtrlLog "  VERIFICAR CHECKSUM - RNX TOOL PRO"
        CtrlLog "=============================================="

        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "Todos los archivos|*.*"
        $fd.Title  = "Selecciona archivo para verificar checksum"
        if ($fd.ShowDialog() -ne "OK") { CtrlLog "[~] Cancelado."; return }

        $archPath = $fd.FileName
        $archName = [System.IO.Path]::GetFileName($archPath)
        $archSz   = [math]::Round((Get-Item $archPath).Length / 1MB, 2)

        CtrlLog "[+] Archivo : $archName ($archSz MB)"
        CtrlLog "[~] Calculando MD5..."
        $md5  = (Get-FileHash $archPath -Algorithm MD5).Hash
        CtrlLog "[~] Calculando SHA256..."
        $sha256 = (Get-FileHash $archPath -Algorithm SHA256).Hash
        CtrlLog "[~] Calculando SHA1..."
        $sha1 = (Get-FileHash $archPath -Algorithm SHA1).Hash

        CtrlLog ""
        CtrlLog "  MD5    : $md5"
        CtrlLog "  SHA1   : $sha1"
        CtrlLog "  SHA256 : $sha256"
        CtrlLog ""

        # Opcion de comparacion
        Add-Type -AssemblyName Microsoft.VisualBasic
        $esperado = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Pega el hash esperado para comparar (opcional):`n(MD5, SHA1 o SHA256 - deja vacio para saltar)",
            "COMPARAR HASH", "")

        if ($esperado -and $esperado.Trim() -ne "") {
            $esperado = $esperado.Trim().ToUpper()
            $coincide = ($esperado -eq $md5) -or ($esperado -eq $sha1) -or ($esperado -eq $sha256)
            if ($coincide) {
                CtrlLog "  VERIFICACION : [OK] HASH CORRECTO - Archivo integro"
                [System.Windows.Forms.MessageBox]::Show(
                    "HASH VERIFICADO`n`nEl archivo es integro y coincide con el hash esperado.",
                    "OK", "OK", "Information") | Out-Null
            } else {
                CtrlLog "  VERIFICACION : [ERROR] HASH NO COINCIDE - Archivo puede estar corrupto"
                [System.Windows.Forms.MessageBox]::Show(
                    "HASH NO COINCIDE`n`nEl archivo puede estar corrupto o es incorrecto.`n`nEsperado: $esperado`nMD5: $md5",
                    "ERROR", "OK", "Warning") | Out-Null
            }
        }

        # Guardar log de checksum
        $logPath = Join-Path ([System.IO.Path]::GetDirectoryName($archPath)) "$archName.checksum.txt"
        @(
            "Archivo : $archName",
            "Tamaño  : $archSz MB",
            "Fecha   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
            "",
            "MD5    : $md5",
            "SHA1   : $sha1",
            "SHA256 : $sha256"
        ) | Out-File $logPath -Encoding UTF8
        CtrlLog "  Log guardado : $([System.IO.Path]::GetFileName($logPath))"
        CtrlLog "=============================================="

    } catch { CtrlLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="VERIFICAR CHECKSUM" }
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