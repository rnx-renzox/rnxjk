#==========================================================================
# 07b_tab_edl.ps1  -  TAB EDL (Emergency Download Mode)
# Layout identico al resto de tabs: 2 columnas, grupos con Place-Grid
# Requiere: edl.exe en tools\
# Bloque 1 (Cyan)   : Deteccion y Particiones (4 botones)
# Bloque 2 (Orange) : Flasheo / Borrado / FRP  (6 botones)
# Bloque 3 (Magenta): Reservado / Futura impl.  (4 botones)
#==========================================================================

#==========================================================================
# TAB EDL - Layout
#==========================================================================
$tabEDL           = New-Object Windows.Forms.TabPage
$tabEDL.Text      = "EDL"
$tabEDL.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$tabs.TabPages.Add($tabEDL)

$EX=6; $EGAP=8; $ELOGX=436
$EBTW=195; $EBTH=56; $EPX=14; $EPY=20; $EGX=8; $EGY=8
$EGW=422; $ELOGW=$EGW

$EGH1 = $EPY + 2*($EBTH+$EGY) - $EGY + 14   # 4 btn = 2 filas
$EGH2 = $EPY + 3*($EBTH+$EGY) - $EGY + 14   # 6 btn = 3 filas
$EGH3 = $EPY + 2*($EBTH+$EGY) - $EGY + 14   # 4 btn = 2 filas
$EY1=6; $EY2=$EY1+$EGH1+$EGAP; $EY3=$EY2+$EGH2+$EGAP

$grpE1 = New-GBox $tabEDL "DETECCION Y PARTICIONES"   $EX $EY1 $EGW $EGH1 "Cyan"
$grpE2 = New-GBox $tabEDL "FLASHEO / BORRADO / FRP"   $EX $EY2 $EGW $EGH2 "Orange"
$grpE3 = New-GBox $tabEDL "HERRAMIENTAS AVANZADAS"    $EX $EY3 $EGW $EGH3 "Magenta"

$EL1=@("DETECTAR DISPOSITIVO","VER PARTICIONES","LOADER","DRIVERS QDL 9008")
$EL2=@("FLASHEAR PARTICION","FLASHEAR ROM COMPLETA","WIPE EFS","FRP EDL","BORRAR PARTICION","MI ACCOUNT EDL")
$EL3=@("PROXIMAMENTE","PROXIMAMENTE","PROXIMAMENTE","PROXIMAMENTE")

$btnsE1=Place-Grid $grpE1 $EL1 "Cyan"    2 $EBTW $EBTH $EPX $EPY $EGX $EGY
$btnsE2=Place-Grid $grpE2 $EL2 "Orange"  2 $EBTW $EBTH $EPX $EPY $EGX $EGY
$btnsE3=Place-Grid $grpE3 $EL3 "Magenta" 2 $EBTW $EBTH $EPX $EPY $EGX $EGY

# Log columna derecha
$ELOGY=6; $ELOGH=616
$Global:logEDL           = New-Object Windows.Forms.TextBox
$Global:logEDL.Multiline = $true
$Global:logEDL.Location  = New-Object System.Drawing.Point($ELOGX,$ELOGY)
$Global:logEDL.Size      = New-Object System.Drawing.Size($ELOGW,$ELOGH)
$Global:logEDL.BackColor = "Black"
$Global:logEDL.ForeColor = [System.Drawing.Color]::FromArgb(0,220,255)
$Global:logEDL.BorderStyle = "FixedSingle"
$Global:logEDL.ScrollBars  = "Vertical"
$Global:logEDL.Font        = New-Object System.Drawing.Font("Consolas",8.5)
$Global:logEDL.ReadOnly    = $true
$tabEDL.Controls.Add($Global:logEDL)

$ctxEDL = New-Object System.Windows.Forms.ContextMenuStrip
$mnuClrEDL = $ctxEDL.Items.Add("Limpiar Log")
$mnuClrEDL.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$mnuClrEDL.ForeColor = [System.Drawing.Color]::OrangeRed
$mnuClrEDL.Add_Click({ $Global:logEDL.Clear() })
$Global:logEDL.ContextMenuStrip = $ctxEDL

function EdlLog($msg) {
    if (-not $Global:logEDL) { return }
    $ts = Get-Date -Format "HH:mm:ss"
    $Global:logEDL.AppendText("[$ts] $msg`r`n")
    $Global:logEDL.SelectionStart = $Global:logEDL.TextLength
    $Global:logEDL.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Botones futuros desactivados visualmente
foreach ($b in $btnsE3) {
    $b.Enabled   = $false
    $b.ForeColor = [System.Drawing.Color]::FromArgb(60,60,80)
    $b.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,80)
}

# Helper: buscar edl.exe
function Get-EdlExe {
    foreach ($c in @(
        (Join-Path $script:TOOLS_DIR "edl.exe"),
        (Join-Path $script:TOOLS_DIR "edl\edl.exe"),
        "edl.exe"
    )) { if (Test-Path $c -EA SilentlyContinue) { return (Resolve-Path $c).Path } }
    return $null
}

# Helper: verificar dispositivo EDL conectado antes de operar
function Check-EdlDevice {
    $edl = Get-EdlExe
    if (-not $edl) { EdlLog "[!] edl.exe no encontrado en tools\"; return $false }
    EdlLog "[~] Verificando dispositivo EDL (9008)..."
    [System.Windows.Forms.Application]::DoEvents()
    $res = Run-Edl "getdevinfo" 8
    # Si no hay respuesta util o hay error claro -> no hay equipo
    $noDevice = (-not $res.out) -or ($res.out -imatch "no device|not found|timed out|error.*connect|failed to connect")
    $hasDevice = $res.out -imatch "cpu|chipset|serial|device|version|qualcomm|9008"
    if ($noDevice -or (-not $hasDevice -and -not $res.ok)) {
        EdlLog "[!] No se detecto equipo en modo EDL/9008"
        EdlLog "[~] Asegurate que:"
        EdlLog "    1. El equipo este en DOWNLOAD MODE 9008"
        EdlLog "    2. Drivers Qualcomm HS-USB QDLoader 9008 instalados"
        EdlLog "    3. Cable USB conectado"
        EdlLog "[~] Presiona DETECTAR DISPOSITIVO para verificar"
        return $false
    }
    EdlLog "[+] Dispositivo EDL detectado"
    return $true
}

# Helper: ejecutar edl.exe y capturar output con timeout
function Run-Edl($args2, $timeoutSec=30) {
    $edl = Get-EdlExe
    if (-not $edl) { return @{ok=$false; out="edl.exe no encontrado en tools\"} }
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName               = $edl
        $psi.Arguments              = $args2
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute        = $false
        $psi.CreateNoWindow         = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        $out = ""; $err = ""
        $waited = 0
        while (-not $p.HasExited -and $waited -lt $timeoutSec) {
            Start-Sleep -Milliseconds 200; $waited += 0.2
            [System.Windows.Forms.Application]::DoEvents()
        }
        if (-not $p.HasExited) { $p.Kill() }
        $out = $p.StandardOutput.ReadToEnd()
        $err = $p.StandardError.ReadToEnd()
        return @{ok=($p.ExitCode -eq 0); out=($out+"`n"+$err).Trim(); code=$p.ExitCode}
    } catch { return @{ok=$false; out="Error: $_"} }
}

#==========================================================================
# BLOQUE E1: DETECCION Y PARTICIONES
#==========================================================================

# ---- E1[0]: DETECTAR DISPOSITIVO ----
$btnsE1[0].Add_Click({
    $btn=$btnsE1[0]; $btn.Enabled=$false; $btn.Text="DETECTANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== DETECTAR DISPOSITIVO EDL ==="

    $edl = Get-EdlExe
    if (-not $edl) {
        EdlLog "[!] edl.exe no encontrado en tools\"
        EdlLog "[~] Coloca edl.exe en: $($script:TOOLS_DIR)"
        $btn.Enabled=$true; $btn.Text="DETECTAR DISPOSITIVO"; return
    }
    EdlLog "[+] edl.exe: $edl"
    EdlLog "[~] Buscando dispositivo en modo 9008 (QDL)..."
    EdlLog "[~] Asegurate que el equipo este en EDL/9008:"
    EdlLog "    Vol+ + Vol- al encender, o via adb reboot edl"
    EdlLog ""
    [System.Windows.Forms.Application]::DoEvents()

    $res = Run-Edl "getdevinfo" 20
    if ($res.out) {
        foreach ($l in ($res.out -split "`n")) {
            $l2=$l.Trim(); if ($l2) { EdlLog "  $l2" }
        }
    }

    # Intentar leer propiedades del dispositivo
    $resInfo = Run-Edl "printgpt" 15
    if ($resInfo.ok -or $resInfo.out -imatch "cpu|chipset|serial|imei|version") {
        EdlLog ""
        EdlLog "[+] Dispositivo detectado en modo EDL"
        $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  EDL 9008  |  Conectado"
        $Global:lblADB.Text    = "ADB         : EDL 9008"
        $Global:lblADB.ForeColor = [System.Drawing.Color]::FromArgb(255,80,0)
    } else {
        EdlLog ""
        EdlLog "[~] No se detecto dispositivo EDL activo."
        EdlLog "[~] Verifica conexion USB y modo 9008."
        EdlLog "[~] Instala drivers Qualcomm HS-USB QDLoader 9008 si es necesario."
    }
    $btn.Enabled=$true; $btn.Text="DETECTAR DISPOSITIVO"
})

# ---- E1[1]: VER PARTICIONES ----
$btnsE1[1].Add_Click({
    $btn=$btnsE1[1]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== VER PARTICIONES GPT ==="

    $edl = Get-EdlExe
    if (-not $edl) { EdlLog "[!] edl.exe no encontrado."; $btn.Enabled=$true; $btn.Text="VER PARTICIONES"; return }

    EdlLog "[~] Leyendo tabla de particiones via EDL..."
    [System.Windows.Forms.Application]::DoEvents()
    $res = Run-Edl "printgpt" 30

    if (-not $res.out) { EdlLog "[!] Sin respuesta del dispositivo."; $btn.Enabled=$true; $btn.Text="VER PARTICIONES"; return }

    # Parsear y mostrar tabla
    $parts = @()
    foreach ($l in ($res.out -split "`n")) {
        $l2=$l.Trim()
        if ($l2 -match "^\s*(\w+)\s+Offset\s+([\w]+)\s+Size\s+([\w]+)") {
            $parts += [PSCustomObject]@{Name=$Matches[1]; Offset=$Matches[2]; Size=$Matches[3]}
        } elseif ($l2) { EdlLog "  $l2" }
    }

    if ($parts.Count -gt 0) {
        EdlLog ""
        EdlLog "[+] $($parts.Count) particiones detectadas:"
        EdlLog ("  {0,-24} {1,-16} {2}" -f "NOMBRE","OFFSET","TAMANO")
        EdlLog ("  " + ("-"*55))
        $script:EDL_PARTITIONS = $parts
        foreach ($p in $parts) {
            EdlLog ("  {0,-24} {1,-16} {2}" -f $p.Name, $p.Offset, $p.Size)
        }
    } else {
        EdlLog "[~] No se pudieron parsear particiones - mostrando raw:"
        foreach ($l in ($res.out -split "`n")) { $l2=$l.Trim(); if($l2){ EdlLog "  $l2" } }
    }
    $btn.Enabled=$true; $btn.Text="VER PARTICIONES"
})

# ---- E1[2]: LOADER ----
$btnsE1[2].Add_Click({
    $btn=$btnsE1[2]; $btn.Enabled=$false; $btn.Text="CARGANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== LOADER EDL ==="

    $frmLdr = New-Object System.Windows.Forms.Form
    $frmLdr.Text="LOADER EDL - RNX TOOL PRO"; $frmLdr.ClientSize=New-Object System.Drawing.Size(520,320)
    $frmLdr.BackColor=[System.Drawing.Color]::FromArgb(14,14,22); $frmLdr.FormBorderStyle="FixedDialog"
    $frmLdr.StartPosition="CenterScreen"; $frmLdr.TopMost=$true

    $lbH=New-Object Windows.Forms.Label; $lbH.Text="  SELECCIONAR LOADER (.elf)"
    $lbH.Location=New-Object System.Drawing.Point(0,0); $lbH.Size=New-Object System.Drawing.Size(520,30)
    $lbH.BackColor=[System.Drawing.Color]::FromArgb(0,160,255); $lbH.ForeColor=[System.Drawing.Color]::White
    $lbH.Font=New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lbH.TextAlign="MiddleLeft"; $frmLdr.Controls.Add($lbH)

    # Opcion 1: Local
    $rbLocal=New-Object Windows.Forms.RadioButton; $rbLocal.Text="Usar archivo local (.elf)"
    $rbLocal.Location=New-Object System.Drawing.Point(20,44); $rbLocal.Size=New-Object System.Drawing.Size(480,22)
    $rbLocal.ForeColor=[System.Drawing.Color]::Cyan; $rbLocal.Checked=$true
    $rbLocal.Font=New-Object System.Drawing.Font("Segoe UI",9); $frmLdr.Controls.Add($rbLocal)

    $btnBrowse=New-Object Windows.Forms.Button; $btnBrowse.Text="EXPLORAR .elf"
    $btnBrowse.Location=New-Object System.Drawing.Point(20,70); $btnBrowse.Size=New-Object System.Drawing.Size(140,28)
    $btnBrowse.FlatStyle="Flat"; $btnBrowse.ForeColor=[System.Drawing.Color]::Cyan
    $btnBrowse.FlatAppearance.BorderColor=[System.Drawing.Color]::Cyan
    $btnBrowse.BackColor=[System.Drawing.Color]::FromArgb(20,30,40)
    $btnBrowse.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmLdr.Controls.Add($btnBrowse)

    $lbElfPath=New-Object Windows.Forms.Label; $lbElfPath.Text="(ninguno seleccionado)"
    $lbElfPath.Location=New-Object System.Drawing.Point(168,76); $lbElfPath.Size=New-Object System.Drawing.Size(334,18)
    $lbElfPath.ForeColor=[System.Drawing.Color]::FromArgb(120,120,140)
    $lbElfPath.Font=New-Object System.Drawing.Font("Consolas",7.5); $frmLdr.Controls.Add($lbElfPath)

    $btnBrowse.Add_Click({
        $fd=New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter="Loaders EDL (*.elf;*.mbn)|*.elf;*.mbn|Todos|*.*"
        $fd.Title="Selecciona loader .elf para EDL"
        if ($fd.ShowDialog() -eq "OK") { $lbElfPath.Text=$fd.FileName; $script:EDL_ELF=$fd.FileName }
    })

    # Separador
    $sep=New-Object Windows.Forms.Label; $sep.Location=New-Object System.Drawing.Point(20,108)
    $sep.Size=New-Object System.Drawing.Size(480,1); $sep.BorderStyle="Fixed3D"; $frmLdr.Controls.Add($sep)

    # Opcion 2: Por codename
    $rbAuto=New-Object Windows.Forms.RadioButton; $rbAuto.Text="Buscar por codename del dispositivo"
    $rbAuto.Location=New-Object System.Drawing.Point(20,116); $rbAuto.Size=New-Object System.Drawing.Size(480,22)
    $rbAuto.ForeColor=[System.Drawing.Color]::FromArgb(255,200,0)
    $rbAuto.Font=New-Object System.Drawing.Font("Segoe UI",9); $frmLdr.Controls.Add($rbAuto)

    $lbCod=New-Object Windows.Forms.Label; $lbCod.Text="Codename (ej: lavender, merlin, whyred):"
    $lbCod.Location=New-Object System.Drawing.Point(20,142); $lbCod.Size=New-Object System.Drawing.Size(480,16)
    $lbCod.ForeColor=[System.Drawing.Color]::FromArgb(140,140,160)
    $lbCod.Font=New-Object System.Drawing.Font("Segoe UI",8); $frmLdr.Controls.Add($lbCod)

    $txtCod=New-Object Windows.Forms.TextBox; $txtCod.Location=New-Object System.Drawing.Point(20,162)
    $txtCod.Size=New-Object System.Drawing.Size(300,24); $txtCod.BackColor=[System.Drawing.Color]::FromArgb(30,30,40)
    $txtCod.ForeColor=[System.Drawing.Color]::White; $txtCod.Font=New-Object System.Drawing.Font("Consolas",9)
    $frmLdr.Controls.Add($txtCod)

    $lbNote=New-Object Windows.Forms.Label
    $lbNote.Text="El loader se descargara de miui-edl-loaders repo (GitHub)"
    $lbNote.Location=New-Object System.Drawing.Point(20,190); $lbNote.Size=New-Object System.Drawing.Size(480,16)
    $lbNote.ForeColor=[System.Drawing.Color]::FromArgb(80,80,100)
    $lbNote.Font=New-Object System.Drawing.Font("Segoe UI",7.5); $frmLdr.Controls.Add($lbNote)

    # Botones
    $btnOkL=New-Object Windows.Forms.Button; $btnOkL.Text="APLICAR LOADER"
    $btnOkL.Location=New-Object System.Drawing.Point(60,250); $btnOkL.Size=New-Object System.Drawing.Size(180,34)
    $btnOkL.FlatStyle="Flat"; $btnOkL.ForeColor=[System.Drawing.Color]::Lime
    $btnOkL.FlatAppearance.BorderColor=[System.Drawing.Color]::Lime
    $btnOkL.BackColor=[System.Drawing.Color]::FromArgb(10,35,10)
    $btnOkL.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $frmLdr.Controls.Add($btnOkL)

    $btnCancelL=New-Object Windows.Forms.Button; $btnCancelL.Text="CANCELAR"
    $btnCancelL.Location=New-Object System.Drawing.Point(260,250); $btnCancelL.Size=New-Object System.Drawing.Size(120,34)
    $btnCancelL.FlatStyle="Flat"; $btnCancelL.ForeColor=[System.Drawing.Color]::Gray
    $btnCancelL.FlatAppearance.BorderColor=[System.Drawing.Color]::Gray
    $btnCancelL.BackColor=[System.Drawing.Color]::FromArgb(30,30,30)
    $btnCancelL.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnCancelL.Add_Click({ $frmLdr.Close() }); $frmLdr.Controls.Add($btnCancelL)

    $btnOkL.Add_Click({
        if ($rbLocal.Checked) {
            if (-not $script:EDL_ELF -or -not (Test-Path $script:EDL_ELF)) {
                [System.Windows.Forms.MessageBox]::Show("Selecciona un archivo .elf primero.","Loader","OK","Warning") | Out-Null; return
            }
            EdlLog "[+] Loader configurado (local): $($script:EDL_ELF)"
            $frmLdr.Close()
        } else {
            $cod=$txtCod.Text.Trim().ToLower()
            if (-not $cod) {
                [System.Windows.Forms.MessageBox]::Show("Ingresa el codename del dispositivo.","Codename","OK","Warning") | Out-Null; return
            }
            EdlLog "[~] Buscando loader para codename: $cod"
            $loaderDir = Join-Path $script:TOOLS_DIR "loaders"
            New-Item $loaderDir -ItemType Directory -Force | Out-Null
            $url = "https://github.com/bkerler/Loaders/raw/main/$cod/$cod.elf"
            $outElf = Join-Path $loaderDir "$cod.elf"
            if (Test-Path $outElf) {
                EdlLog "[+] Loader ya existe localmente: $outElf"
                $script:EDL_ELF = $outElf
            } else {
                EdlLog "[~] Descargando: $url"
                try {
                    $wc=New-Object System.Net.WebClient
                    $wc.Headers.Add("User-Agent","Mozilla/5.0")
                    $wc.DownloadFile($url, $outElf)
                    if (Test-Path $outElf) {
                        EdlLog "[OK] Loader descargado: $outElf"
                        $script:EDL_ELF = $outElf
                    } else { EdlLog "[!] Descarga fallida - intenta bajarlo manualmente" }
                } catch { EdlLog "[!] Error descargando: $_" }
            }
            $frmLdr.Close()
        }
    })

    $frmLdr.ShowDialog() | Out-Null
    $btn.Enabled=$true; $btn.Text="LOADER"
})

# ---- E1[3]: DRIVERS QDL 9008 ----
$btnsE1[3].Add_Click({
    $btn=$btnsE1[3]; $btn.Enabled=$false; $btn.Text="ABRIENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== DRIVERS QUALCOMM HS-USB QDLoader 9008 ==="

    $frmDrv = New-Object System.Windows.Forms.Form
    $frmDrv.Text="DRIVERS QDL 9008 - RNX TOOL PRO"; $frmDrv.ClientSize=New-Object System.Drawing.Size(560,360)
    $frmDrv.BackColor=[System.Drawing.Color]::FromArgb(14,14,22); $frmDrv.FormBorderStyle="FixedDialog"
    $frmDrv.StartPosition="CenterScreen"; $frmDrv.TopMost=$true

    $lbHD=New-Object Windows.Forms.Label; $lbHD.Text="  QUALCOMM HS-USB QDLoader 9008"
    $lbHD.Location=New-Object System.Drawing.Point(0,0); $lbHD.Size=New-Object System.Drawing.Size(560,30)
    $lbHD.BackColor=[System.Drawing.Color]::FromArgb(0,160,255); $lbHD.ForeColor=[System.Drawing.Color]::White
    $lbHD.Font=New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lbHD.TextAlign="MiddleLeft"; $frmDrv.Controls.Add($lbHD)

    $instrText = @"
COMO INSTALAR LOS DRIVERS QUALCOMM 9008

El dispositivo en modo EDL aparece como:
  "Qualcomm HS-USB QDLoader 9008"
  (con signo de exclamacion si falta el driver)

METODO 1 - ZADIG (recomendado):
  1. Descarga Zadig desde: https://zadig.akeo.ie/
  2. Abre Zadig como Administrador
  3. Selecciona: "Qualcomm HS-USB QDLoader 9008"
     (si no aparece, activa Options > List All Devices)
  4. Elige driver: libusb-win32 o WinUSB
  5. Haz clic en "Install Driver"
  6. Espera la confirmacion y listo

METODO 2 - Driver oficial Qualcomm:
  Descarga el paquete de drivers desde el boton de abajo

VERIFICACION:
  Administrador de dispositivos > Puertos (COM y LPT)
  debe mostrar: "Qualcomm HS-USB QDLoader 9008 (COM X)"
"@

    $tb=New-Object Windows.Forms.TextBox; $tb.Multiline=$true; $tb.ReadOnly=$true
    $tb.Text=$instrText; $tb.ScrollBars="Vertical"
    $tb.Location=New-Object System.Drawing.Point(14,36); $tb.Size=New-Object System.Drawing.Size(532,240)
    $tb.BackColor=[System.Drawing.Color]::FromArgb(20,20,30); $tb.ForeColor=[System.Drawing.Color]::LightGray
    $tb.Font=New-Object System.Drawing.Font("Consolas",8); $frmDrv.Controls.Add($tb)

    function MkDrvBtn($txt,$x,$w,$url,$clr) {
        $b=New-Object Windows.Forms.Button; $b.Text=$txt
        $b.Location=New-Object System.Drawing.Point($x,288); $b.Size=New-Object System.Drawing.Size($w,36)
        $b.FlatStyle="Flat"; $b.ForeColor=[System.Drawing.Color]::$clr
        $b.FlatAppearance.BorderColor=[System.Drawing.Color]::$clr
        $b.BackColor=[System.Drawing.Color]::FromArgb(22,22,32)
        $b.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
        $b.Tag=$url; $b.Add_Click({ Start-Process $this.Tag })
        $frmDrv.Controls.Add($b)
    }
    MkDrvBtn "DESCARGAR ZADIG"   14  160 "https://zadig.akeo.ie/"                      "Cyan"
    MkDrvBtn "DRIVER QUALCOMM"  182  160 "https://developer.qualcomm.com/software/usb-driver" "Orange"
    MkDrvBtn "CERRAR"           350  196 "" "Gray"
    ($frmDrv.Controls | Where-Object { $_.Text -eq "CERRAR" }) | ForEach-Object {
        $_.Add_Click({ $frmDrv.Close() })
    }
    $frmDrv.ShowDialog() | Out-Null
    EdlLog "[i] Panel de instrucciones cerrado"
    $btn.Enabled=$true; $btn.Text="DRIVERS QDL 9008"
})

#==========================================================================
# BLOQUE E2: FLASHEO / BORRADO / FRP
#==========================================================================

# ---- E2[0]: FLASHEAR PARTICION ----
$btnsE2[0].Add_Click({
    $btn=$btnsE2[0]; $btn.Enabled=$false; $btn.Text="CARGANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== FLASHEAR PARTICION EDL ==="

    $edl=Get-EdlExe
    if (-not $edl) { EdlLog "[!] edl.exe no encontrado."; $btn.Enabled=$true; $btn.Text="FLASHEAR PARTICION"; return }
    if (-not (Check-EdlDevice)) { $btn.Enabled=$true; $btn.Text="FLASHEAR PARTICION"; return }

    # Leer particiones si no estan cacheadas
    if (-not $script:EDL_PARTITIONS) {
        EdlLog "[~] Leyendo particiones primero..."
        $res = Run-Edl "printgpt" 30
        $script:EDL_PARTITIONS = @()
        foreach ($l in ($res.out -split "`n")) {
            if ($l -match "^\s*(\w+)\s+Offset") {
                $script:EDL_PARTITIONS += [PSCustomObject]@{Name=$Matches[1]}
            }
        }
    }

    # Formulario de seleccion
    $frmFl = New-Object System.Windows.Forms.Form
    $frmFl.Text="FLASHEAR PARTICION - RNX TOOL PRO"; $frmFl.ClientSize=New-Object System.Drawing.Size(560,480)
    $frmFl.BackColor=[System.Drawing.Color]::FromArgb(14,14,22); $frmFl.FormBorderStyle="FixedDialog"
    $frmFl.StartPosition="CenterScreen"; $frmFl.TopMost=$true

    $lbHF=New-Object Windows.Forms.Label; $lbHF.Text="  FLASHEAR PARTICION"
    $lbHF.Location=New-Object System.Drawing.Point(0,0); $lbHF.Size=New-Object System.Drawing.Size(560,30)
    $lbHF.BackColor=[System.Drawing.Color]::FromArgb(200,80,0); $lbHF.ForeColor=[System.Drawing.Color]::White
    $lbHF.Font=New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lbHF.TextAlign="MiddleLeft"; $frmFl.Controls.Add($lbHF)

    # Lista de particiones con checkboxes
    $clbPart=New-Object Windows.Forms.CheckedListBox
    $clbPart.Location=New-Object System.Drawing.Point(14,36); $clbPart.Size=New-Object System.Drawing.Size(250,300)
    $clbPart.BackColor=[System.Drawing.Color]::FromArgb(22,22,32); $clbPart.ForeColor=[System.Drawing.Color]::Cyan
    $clbPart.Font=New-Object System.Drawing.Font("Consolas",8.5); $clbPart.CheckOnClick=$true
    if ($script:EDL_PARTITIONS.Count -gt 0) {
        foreach ($p in $script:EDL_PARTITIONS) { $clbPart.Items.Add($p.Name) | Out-Null }
    } else {
        # Particiones comunes como fallback
        @("boot","recovery","system","vendor","userdata","cache","efs","modem",
          "persist","misc","frp","aboot","tz","rpm","sbl1") |
          ForEach-Object { $clbPart.Items.Add($_) | Out-Null }
    }
    $frmFl.Controls.Add($clbPart)

    $lbImg=New-Object Windows.Forms.Label; $lbImg.Text="Archivo imagen a flashear:"
    $lbImg.Location=New-Object System.Drawing.Point(274,36); $lbImg.Size=New-Object System.Drawing.Size(270,16)
    $lbImg.ForeColor=[System.Drawing.Color]::FromArgb(140,140,160)
    $lbImg.Font=New-Object System.Drawing.Font("Segoe UI",8); $frmFl.Controls.Add($lbImg)

    $lbImgPath=New-Object Windows.Forms.Label; $lbImgPath.Text="(ninguno)"
    $lbImgPath.Location=New-Object System.Drawing.Point(274,56); $lbImgPath.Size=New-Object System.Drawing.Size(270,30)
    $lbImgPath.ForeColor=[System.Drawing.Color]::FromArgb(80,180,255)
    $lbImgPath.Font=New-Object System.Drawing.Font("Consolas",7.5); $frmFl.Controls.Add($lbImgPath)

    $btnSelImg=New-Object Windows.Forms.Button; $btnSelImg.Text="SELECCIONAR IMAGEN"
    $btnSelImg.Location=New-Object System.Drawing.Point(274,90); $btnSelImg.Size=New-Object System.Drawing.Size(200,28)
    $btnSelImg.FlatStyle="Flat"; $btnSelImg.ForeColor=[System.Drawing.Color]::Cyan
    $btnSelImg.FlatAppearance.BorderColor=[System.Drawing.Color]::Cyan
    $btnSelImg.BackColor=[System.Drawing.Color]::FromArgb(15,30,40)
    $btnSelImg.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $script:EDL_IMG_PATH=""
    $btnSelImg.Add_Click({
        $fd=New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter="Imagenes (*.img;*.bin;*.mbn)|*.img;*.bin;*.mbn|Todos|*.*"
        if ($fd.ShowDialog() -eq "OK") { $script:EDL_IMG_PATH=$fd.FileName; $lbImgPath.Text=[System.IO.Path]::GetFileName($fd.FileName) }
    })
    $frmFl.Controls.Add($btnSelImg)

    $lbWarn=New-Object Windows.Forms.Label
    $lbWarn.Text="ADVERTENCIA: Flashear la particion incorrecta`npuede brickear el dispositivo. Verifica bien."
    $lbWarn.Location=New-Object System.Drawing.Point(274,130); $lbWarn.Size=New-Object System.Drawing.Size(270,40)
    $lbWarn.ForeColor=[System.Drawing.Color]::FromArgb(255,120,0)
    $lbWarn.Font=New-Object System.Drawing.Font("Segoe UI",7.5); $frmFl.Controls.Add($lbWarn)

    $btnFlashGo=New-Object Windows.Forms.Button; $btnFlashGo.Text="FLASHEAR"
    $btnFlashGo.Location=New-Object System.Drawing.Point(274,356); $btnFlashGo.Size=New-Object System.Drawing.Size(120,34)
    $btnFlashGo.FlatStyle="Flat"; $btnFlashGo.ForeColor=[System.Drawing.Color]::Lime
    $btnFlashGo.FlatAppearance.BorderColor=[System.Drawing.Color]::Lime
    $btnFlashGo.BackColor=[System.Drawing.Color]::FromArgb(10,35,10)
    $btnFlashGo.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnFlashGo.Add_Click({
        $selParts=@(); for($i=0;$i-lt$clbPart.Items.Count;$i++){if($clbPart.GetItemChecked($i)){$selParts+=$clbPart.Items[$i]}}
        if ($selParts.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Selecciona al menos una particion.","Aviso","OK","Warning")|Out-Null; return }
        if (-not $script:EDL_IMG_PATH -or -not (Test-Path $script:EDL_IMG_PATH)) {
            [System.Windows.Forms.MessageBox]::Show("Selecciona el archivo imagen primero.","Aviso","OK","Warning")|Out-Null; return
        }
        $conf=[System.Windows.Forms.MessageBox]::Show(
            "CONFIRMAR FLASHEO EDL`n`nParticion(es): $($selParts -join ', ')`nImagen: $(Split-Path $script:EDL_IMG_PATH -Leaf)`n`nEsta operacion sobreescribira la particion.`nContinuar?",
            "CONFIRMAR","YesNo","Warning")
        if ($conf -ne "Yes") { return }
        $frmFl.Close()
        foreach ($part in $selParts) {
            EdlLog "[~] Flasheando: $part <- $(Split-Path $script:EDL_IMG_PATH -Leaf)"
            $ldrArg = if ($script:EDL_ELF) { "--loader=`"$($script:EDL_ELF)`"" } else { "" }
            $res = Run-Edl "w $part `"$($script:EDL_IMG_PATH)`" $ldrArg" 120
            if ($res.ok) { EdlLog "[OK] $part flasheado correctamente" }
            else {
                foreach ($l in ($res.out -split "`n")) { $l2=$l.Trim(); if($l2){ EdlLog "  $l2" } }
                EdlLog "[!] Error flasheando $part"
            }
        }
        EdlLog "[+] Proceso de flasheo completado"
    })
    $frmFl.Controls.Add($btnFlashGo)

    $btnCancelFl=New-Object Windows.Forms.Button; $btnCancelFl.Text="CANCELAR"
    $btnCancelFl.Location=New-Object System.Drawing.Point(404,356); $btnCancelFl.Size=New-Object System.Drawing.Size(100,34)
    $btnCancelFl.FlatStyle="Flat"; $btnCancelFl.ForeColor=[System.Drawing.Color]::Gray
    $btnCancelFl.FlatAppearance.BorderColor=[System.Drawing.Color]::Gray
    $btnCancelFl.BackColor=[System.Drawing.Color]::FromArgb(28,28,28)
    $btnCancelFl.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnCancelFl.Add_Click({ $frmFl.Close() }); $frmFl.Controls.Add($btnCancelFl)

    $frmFl.ShowDialog() | Out-Null
    $btn.Enabled=$true; $btn.Text="FLASHEAR PARTICION"
})

# ---- E2[1]: FLASHEAR ROM COMPLETA ----
$btnsE2[1].Add_Click({
    $btn=$btnsE2[1]; $btn.Enabled=$false; $btn.Text="CARGANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== FLASHEAR ROM COMPLETA EDL ==="

    $edl=Get-EdlExe
    if (-not $edl) { EdlLog "[!] edl.exe no encontrado."; $btn.Enabled=$true; $btn.Text="FLASHEAR ROM COMPLETA"; return }
    if (-not (Check-EdlDevice)) { $btn.Enabled=$true; $btn.Text="FLASHEAR ROM COMPLETA"; return }

    $frmRom = New-Object System.Windows.Forms.Form
    $frmRom.Text="FLASHEAR ROM COMPLETA - RNX TOOL PRO"; $frmRom.ClientSize=New-Object System.Drawing.Size(580,400)
    $frmRom.BackColor=[System.Drawing.Color]::FromArgb(14,14,22); $frmRom.FormBorderStyle="FixedDialog"
    $frmRom.StartPosition="CenterScreen"; $frmRom.TopMost=$true

    $lbHR=New-Object Windows.Forms.Label; $lbHR.Text="  FLASHEAR ROM COMPLETA (rawprogram XML)"
    $lbHR.Location=New-Object System.Drawing.Point(0,0); $lbHR.Size=New-Object System.Drawing.Size(580,30)
    $lbHR.BackColor=[System.Drawing.Color]::FromArgb(180,60,0); $lbHR.ForeColor=[System.Drawing.Color]::White
    $lbHR.Font=New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lbHR.TextAlign="MiddleLeft"; $frmRom.Controls.Add($lbHR)

    function AddRomLbl($txt,$y,$clr="LightGray") {
        $l=New-Object Windows.Forms.Label; $l.Text=$txt
        $l.Location=New-Object System.Drawing.Point(14,$y); $l.Size=New-Object System.Drawing.Size(552,16)
        $l.ForeColor=[System.Drawing.Color]::$clr
        $l.Font=New-Object System.Drawing.Font("Segoe UI",8); $frmRom.Controls.Add($l)
    }
    function AddRomPath($yL,$yB,$tag) {
        $lbP=New-Object Windows.Forms.Label; $lbP.Text="(no seleccionado)"
        $lbP.Location=New-Object System.Drawing.Point(14,$yL); $lbP.Size=New-Object System.Drawing.Size(420,16)
        $lbP.ForeColor=[System.Drawing.Color]::FromArgb(80,160,255)
        $lbP.Font=New-Object System.Drawing.Font("Consolas",7.5); $frmRom.Controls.Add($lbP)
        $b=New-Object Windows.Forms.Button; $b.Text="..."
        $b.Location=New-Object System.Drawing.Point(440,$yL-2); $b.Size=New-Object System.Drawing.Size(50,22)
        $b.FlatStyle="Flat"; $b.ForeColor=[System.Drawing.Color]::Cyan
        $b.FlatAppearance.BorderColor=[System.Drawing.Color]::Cyan
        $b.BackColor=[System.Drawing.Color]::FromArgb(15,30,40)
        $b.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
        $b.Tag=@{lbl=$lbP;tag=$tag}
        $b.Add_Click({
            $info=$this.Tag
            if ($info.tag -eq "xml" -or $info.tag -eq "xml2") {
                $fd=New-Object System.Windows.Forms.OpenFileDialog
                $fd.Filter="rawprogram XML (*.xml)|*.xml|Todos|*.*"
            } else {
                $fd=New-Object System.Windows.Forms.OpenFileDialog
                $fd.Filter="patch/txt (*.xml;*.txt)|*.xml;*.txt|Todos|*.*"
            }
            if ($fd.ShowDialog() -eq "OK") {
                $info.lbl.Text=[System.IO.Path]::GetFileName($fd.FileName)
                $varName = "EDL_ROM_" + $info.tag.ToUpper()
                Set-Variable -Name $varName -Value $fd.FileName -Scope Script
            }
        })
        $frmRom.Controls.Add($b); return $lbP
    }

    AddRomLbl "rawprogram0.xml (single SIM):" 36 "Cyan"
    AddRomPath 54 54 "xml" | Out-Null
    AddRomLbl "rawprogram1.xml (dual SIM / modem B - opcional):" 80 "Cyan"
    AddRomPath 98 98 "xml2" | Out-Null
    AddRomLbl "patch0.xml o patch.txt:" 124 "Orange"
    AddRomPath 142 142 "patch" | Out-Null
    AddRomLbl "Carpeta con las imagenes .img:" 168 "LightGray"
    $lbImgDir=New-Object Windows.Forms.Label; $lbImgDir.Text="(no seleccionada)"
    $lbImgDir.Location=New-Object System.Drawing.Point(14,186); $lbImgDir.Size=New-Object System.Drawing.Size(420,16)
    $lbImgDir.ForeColor=[System.Drawing.Color]::FromArgb(80,160,255)
    $lbImgDir.Font=New-Object System.Drawing.Font("Consolas",7.5); $frmRom.Controls.Add($lbImgDir)
    $btnSelDir=New-Object Windows.Forms.Button; $btnSelDir.Text="..."
    $btnSelDir.Location=New-Object System.Drawing.Point(440,184); $btnSelDir.Size=New-Object System.Drawing.Size(50,22)
    $btnSelDir.FlatStyle="Flat"; $btnSelDir.ForeColor=[System.Drawing.Color]::LightGray
    $btnSelDir.FlatAppearance.BorderColor=[System.Drawing.Color]::LightGray
    $btnSelDir.BackColor=[System.Drawing.Color]::FromArgb(22,22,32)
    $btnSelDir.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnSelDir.Add_Click({
        $fb=New-Object System.Windows.Forms.FolderBrowserDialog
        $fb.Description="Selecciona la carpeta con las imagenes .img"
        if ($fb.ShowDialog() -eq "OK") { $script:EDL_ROM_DIR=$fb.SelectedPath; $lbImgDir.Text=$fb.SelectedPath }
    })
    $frmRom.Controls.Add($btnSelDir)

    $btnFlashRom=New-Object Windows.Forms.Button; $btnFlashRom.Text="FLASHEAR ROM"
    $btnFlashRom.Location=New-Object System.Drawing.Point(60,340); $btnFlashRom.Size=New-Object System.Drawing.Size(180,38)
    $btnFlashRom.FlatStyle="Flat"; $btnFlashRom.ForeColor=[System.Drawing.Color]::FromArgb(255,80,0)
    $btnFlashRom.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(255,80,0)
    $btnFlashRom.BackColor=[System.Drawing.Color]::FromArgb(35,15,5)
    $btnFlashRom.Font=New-Object System.Drawing.Font("Segoe UI",9.5,[System.Drawing.FontStyle]::Bold)
    $btnFlashRom.Add_Click({
        $xml1 = Get-Variable -Name "EDL_ROM_XML" -Scope Script -ValueOnly -EA SilentlyContinue
        if (-not $xml1 -or -not (Test-Path $xml1)) {
            [System.Windows.Forms.MessageBox]::Show("Selecciona el rawprogram0.xml primero.","Aviso","OK","Warning")|Out-Null; return
        }
        $conf=[System.Windows.Forms.MessageBox]::Show(
            "FLASHEAR ROM COMPLETA VIA EDL`n`nEsta operacion sobreescribira TODO el dispositivo.`nAsegurate de tener backup.`n`nContinuar?",
            "CONFIRMAR ROM FLASH","YesNo","Warning")
        if ($conf -ne "Yes") { return }
        $frmRom.Close()
        EdlLog "[~] Iniciando flasheo de ROM completa..."
        $ldrArg = if ($script:EDL_ELF) { "--loader=`"$($script:EDL_ELF)`"" } else { "" }
        $xmlArg = "--xml=`"$xml1`""
        $romDir = Get-Variable -Name "EDL_ROM_DIR" -Scope Script -ValueOnly -EA SilentlyContinue
        $dirArg = if ($romDir) { "--imgdir=`"$romDir`"" } else { "" }
        $res = Run-Edl "qfil $xmlArg $dirArg $ldrArg" 600
        foreach ($l in ($res.out -split "`n")) { $l2=$l.Trim(); if($l2){ EdlLog "  $l2" } }
        if ($res.ok) { EdlLog "[OK] ROM flasheada correctamente" }
        else { EdlLog "[!] Error durante el flasheo - revisa el log" }
    })
    $frmRom.Controls.Add($btnFlashRom)

    $btnCancelRom=New-Object Windows.Forms.Button; $btnCancelRom.Text="CANCELAR"
    $btnCancelRom.Location=New-Object System.Drawing.Point(350,340); $btnCancelRom.Size=New-Object System.Drawing.Size(120,38)
    $btnCancelRom.FlatStyle="Flat"; $btnCancelRom.ForeColor=[System.Drawing.Color]::Gray
    $btnCancelRom.FlatAppearance.BorderColor=[System.Drawing.Color]::Gray
    $btnCancelRom.BackColor=[System.Drawing.Color]::FromArgb(28,28,28)
    $btnCancelRom.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnCancelRom.Add_Click({ $frmRom.Close() }); $frmRom.Controls.Add($btnCancelRom)
    $frmRom.ShowDialog() | Out-Null
    $btn.Enabled=$true; $btn.Text="FLASHEAR ROM COMPLETA"
})

# ---- E2[2]: WIPE EFS ----
$btnsE2[2].Add_Click({
    $btn=$btnsE2[2]; $btn.Enabled=$false; $btn.Text="EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== WIPE EFS EDL ==="
    EdlLog "[!] Esta operacion borra: modemst1, modemst2, fsg, fsc"
    EdlLog "[!] El IMEI sera restaurado desde backup o dejara de funcionar"

    $edl=Get-EdlExe
    if (-not $edl) { EdlLog "[!] edl.exe no encontrado."; $btn.Enabled=$true; $btn.Text="WIPE EFS"; return }
    if (-not (Check-EdlDevice)) { $btn.Enabled=$true; $btn.Text="WIPE EFS"; return }

    $conf=[System.Windows.Forms.MessageBox]::Show(
        "WIPE EFS VIA EDL`n`nSe borraran las particiones:`n  - modemst1`n  - modemst2`n  - fsg`n  - fsc`n`nAntes se hara un BACKUP de cada particion.`n`nEsta operacion puede afectar el IMEI.`n`nCONFIRMAS?",
        "WIPE EFS EDL","YesNo","Warning")
    if ($conf -ne "Yes") { EdlLog "[~] Cancelado."; $btn.Enabled=$true; $btn.Text="WIPE EFS"; return }

    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $bakDir = Join-Path (Join-Path $script:SCRIPT_ROOT "BACKUPS") "EFS_EDL\$stamp"
    New-Item $bakDir -ItemType Directory -Force | Out-Null
    EdlLog "[+] Backup dir: $bakDir"

    $efsParts = @("modemst1","modemst2","fsg","fsc")
    $ldrArg   = if ($script:EDL_ELF) { "--loader=`"$($script:EDL_ELF)`"" } else { "" }

    foreach ($part in $efsParts) {
        $bakFile = Join-Path $bakDir "$part.img"
        EdlLog "[~] Backup: $part -> $bakFile"
        $resR = Run-Edl "r $part `"$bakFile`" $ldrArg" 60
        if (Test-Path $bakFile) { EdlLog "[+] Backup $part OK ($([math]::Round((Get-Item $bakFile).Length/1KB,1)) KB)" }
        else { EdlLog "[~] No se pudo backup $part - continuando..." }
    }

    EdlLog ""
    EdlLog "[~] Ejecutando wipe..."
    foreach ($part in $efsParts) {
        EdlLog "[~] Borrando: $part"
        $resE = Run-Edl "e $part $ldrArg" 30
        if ($resE.ok) { EdlLog "[OK] $part borrado" }
        else { EdlLog "[~] ${part}: $($resE.out)" }
    }

    EdlLog ""
    EdlLog "[OK] WIPE EFS completado"
    EdlLog "[~] Backup guardado en: $bakDir"
    EdlLog "[~] Reinicia el dispositivo para que el modem regenere las particiones"
    $btn.Enabled=$true; $btn.Text="WIPE EFS"
})

# ---- E2[3]: FRP EDL ----
$btnsE2[3].Add_Click({
    $btn=$btnsE2[3]; $btn.Enabled=$false; $btn.Text="EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== FRP RESET VIA EDL ==="

    $edl=Get-EdlExe
    if (-not $edl) { EdlLog "[!] edl.exe no encontrado."; $btn.Enabled=$true; $btn.Text="FRP EDL"; return }
    if (-not (Check-EdlDevice)) { $btn.Enabled=$true; $btn.Text="FRP EDL"; return }

    $conf=[System.Windows.Forms.MessageBox]::Show(
        "FRP RESET VIA EDL`n`nSe borrara la particion 'frp'.`n`nEsto desbloquea el Factory Reset Protection.`n`nConfirmas?",
        "FRP EDL","YesNo","Question")
    if ($conf -ne "Yes") { EdlLog "[~] Cancelado."; $btn.Enabled=$true; $btn.Text="FRP EDL"; return }

    $ldrArg = if ($script:EDL_ELF) { "--loader=`"$($script:EDL_ELF)`"" } else { "" }
    EdlLog "[~] Borrando particion frp..."
    $res = Run-Edl "e frp $ldrArg" 30
    if ($res.ok) {
        EdlLog "[OK] Particion frp borrada correctamente"
        EdlLog "[~] Reinicia el dispositivo"
    } else {
        EdlLog "[~] Respuesta: $($res.out)"
        # Intentar locate FRP si no se llama 'frp'
        EdlLog "[~] Intentando buscar FRP por contenido..."
        $res2 = Run-Edl "printgpt $ldrArg" 20
        foreach ($l in ($res2.out -split "`n")) {
            if ($l -imatch "frp|config") { EdlLog "  Posible FRP: $l" }
        }
        EdlLog "[~] Si la particion tiene otro nombre, usa BORRAR PARTICION"
    }
    $btn.Enabled=$true; $btn.Text="FRP EDL"
})

# ---- E2[4]: BORRAR PARTICION ESPECIFICA ----
$btnsE2[4].Add_Click({
    $btn=$btnsE2[4]; $btn.Enabled=$false; $btn.Text="CARGANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== BORRAR PARTICION EDL ==="

    $edl=Get-EdlExe
    if (-not $edl) { EdlLog "[!] edl.exe no encontrado."; $btn.Enabled=$true; $btn.Text="BORRAR PARTICION"; return }
    if (-not (Check-EdlDevice)) { $btn.Enabled=$true; $btn.Text="BORRAR PARTICION"; return }

    $frmErs = New-Object System.Windows.Forms.Form
    $frmErs.Text="BORRAR PARTICION - RNX TOOL PRO"; $frmErs.ClientSize=New-Object System.Drawing.Size(420,400)
    $frmErs.BackColor=[System.Drawing.Color]::FromArgb(14,14,22); $frmErs.FormBorderStyle="FixedDialog"
    $frmErs.StartPosition="CenterScreen"; $frmErs.TopMost=$true

    $lbHE2=New-Object Windows.Forms.Label; $lbHE2.Text="  BORRAR PARTICION"
    $lbHE2.Location=New-Object System.Drawing.Point(0,0); $lbHE2.Size=New-Object System.Drawing.Size(420,30)
    $lbHE2.BackColor=[System.Drawing.Color]::FromArgb(160,0,0); $lbHE2.ForeColor=[System.Drawing.Color]::White
    $lbHE2.Font=New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lbHE2.TextAlign="MiddleLeft"; $frmErs.Controls.Add($lbHE2)

    $clbErs=New-Object Windows.Forms.CheckedListBox
    $clbErs.Location=New-Object System.Drawing.Point(14,36); $clbErs.Size=New-Object System.Drawing.Size(392,280)
    $clbErs.BackColor=[System.Drawing.Color]::FromArgb(22,22,32); $clbErs.ForeColor=[System.Drawing.Color]::Orange
    $clbErs.Font=New-Object System.Drawing.Font("Consolas",9); $clbErs.CheckOnClick=$true
    if ($script:EDL_PARTITIONS -and $script:EDL_PARTITIONS.Count -gt 0) {
        foreach ($p in $script:EDL_PARTITIONS) { $clbErs.Items.Add($p.Name) | Out-Null }
    } else {
        @("frp","config","userdata","cache") | ForEach-Object { $clbErs.Items.Add($_) | Out-Null }
    }
    $frmErs.Controls.Add($clbErs)

    $btnEraseGo=New-Object Windows.Forms.Button; $btnEraseGo.Text="BORRAR SELECCIONADAS"
    $btnEraseGo.Location=New-Object System.Drawing.Point(14,326); $btnEraseGo.Size=New-Object System.Drawing.Size(200,34)
    $btnEraseGo.FlatStyle="Flat"; $btnEraseGo.ForeColor=[System.Drawing.Color]::FromArgb(255,60,60)
    $btnEraseGo.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(255,60,60)
    $btnEraseGo.BackColor=[System.Drawing.Color]::FromArgb(35,8,8)
    $btnEraseGo.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnEraseGo.Add_Click({
        $sel=@(); for($i=0;$i-lt$clbErs.Items.Count;$i++){if($clbErs.GetItemChecked($i)){$sel+=$clbErs.Items[$i]}}
        if ($sel.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Selecciona al menos una.","Aviso","OK","Warning")|Out-Null; return }
        $c=[System.Windows.Forms.MessageBox]::Show(
            "BORRAR: $($sel -join ', ')`n`nEsta operacion es IRREVERSIBLE.`nConfirmas?","BORRAR","YesNo","Warning")
        if ($c -ne "Yes") { return }
        $frmErs.Close()
        $ldrArg=if($script:EDL_ELF){"--loader=`"$($script:EDL_ELF)`""}else{""}
        foreach ($p in $sel) {
            EdlLog "[~] Borrando: $p"
            $r=Run-Edl "e $p $ldrArg" 30
            if ($r.ok) { EdlLog "[OK] $p borrado" } else { EdlLog "[~] ${p}: $($r.out)" }
        }
        EdlLog "[+] Operacion completada"
    })
    $frmErs.Controls.Add($btnEraseGo)

    $btnCancelErs=New-Object Windows.Forms.Button; $btnCancelErs.Text="CANCELAR"
    $btnCancelErs.Location=New-Object System.Drawing.Point(226,326); $btnCancelErs.Size=New-Object System.Drawing.Size(100,34)
    $btnCancelErs.FlatStyle="Flat"; $btnCancelErs.ForeColor=[System.Drawing.Color]::Gray
    $btnCancelErs.FlatAppearance.BorderColor=[System.Drawing.Color]::Gray
    $btnCancelErs.BackColor=[System.Drawing.Color]::FromArgb(28,28,28)
    $btnCancelErs.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnCancelErs.Add_Click({ $frmErs.Close() }); $frmErs.Controls.Add($btnCancelErs)
    $frmErs.ShowDialog() | Out-Null
    $btn.Enabled=$true; $btn.Text="BORRAR PARTICION"
})

# ---- E2[5]: MI ACCOUNT EDL (flujo automatico) ----
$btnsE2[5].Add_Click({
    $btn=$btnsE2[5]; $btn.Enabled=$false; $btn.Text="ANALIZANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    EdlLog ""; EdlLog "=== MI ACCOUNT REMOVE VIA EDL ==="

    $edl=Get-EdlExe
    if (-not $edl) { EdlLog "[!] edl.exe no encontrado."; $btn.Enabled=$true; $btn.Text="MI ACCOUNT EDL"; return }
    if (-not (Check-EdlDevice)) { $btn.Enabled=$true; $btn.Text="MI ACCOUNT EDL"; return }

    EdlLog "[i] FLUJO MI ACCOUNT EDL:"
    EdlLog "    1. Detectar dispositivo y modelo"
    EdlLog "    2. Leer particiones persist y modem(s)"
    EdlLog "    3. Parchear persist + modem con herramientas de tab Generales"
    EdlLog "    4. Sobreescribir particiones parcheadas"
    EdlLog ""
    EdlLog "[~] PASO 1: Identificando dispositivo..."
    [System.Windows.Forms.Application]::DoEvents()

    $ldrArg = if ($script:EDL_ELF) { "--loader=`"$($script:EDL_ELF)`"" } else { "" }
    $resInfo = Run-Edl "getdevinfo $ldrArg" 15
    EdlLog "    $($resInfo.out -replace '`n',' ')"

    # Leer GPT para encontrar persist y modem
    EdlLog "[~] PASO 2: Buscando particiones persist y modem..."
    $resGpt = Run-Edl "printgpt $ldrArg" 20
    $persistPart=$null; $modemParts=@()
    foreach ($l in ($resGpt.out -split "`n")) {
        if ($l -imatch "^\s*(persist)\s") { $persistPart=$l.Trim().Split()[0] }
        if ($l -imatch "^\s*(modem[ab]?)\s") { $modemParts += $l.Trim().Split()[0] }
    }
    if (-not $persistPart) { $persistPart = "persist" }
    if ($modemParts.Count -eq 0) { $modemParts = @("modem") }
    EdlLog "[+] Persist    : $persistPart"
    EdlLog "[+] Modem(s)   : $($modemParts -join ', ')"
    EdlLog ""

    $stamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $wrkDir = Join-Path (Join-Path $script:SCRIPT_ROOT "BACKUPS") "MI_ACCOUNT_EDL\$stamp"
    New-Item $wrkDir -ItemType Directory -Force | Out-Null

    # Leer particiones
    EdlLog "[~] PASO 3: Leyendo particiones al PC..."
    $readParts = @($persistPart) + $modemParts
    $readFiles = @{}
    foreach ($part in $readParts) {
        $outFile = Join-Path $wrkDir "$part.img"
        EdlLog "    Leyendo: $part -> $outFile"
        $r = Run-Edl "r $part `"$outFile`" $ldrArg" 120
        if (Test-Path $outFile) {
            $sz=[math]::Round((Get-Item $outFile).Length/1MB,2)
            EdlLog "    [OK] $part ($sz MB)"
            $readFiles[$part] = $outFile
        } else { EdlLog "    [!] No se pudo leer $part" }
    }

    EdlLog ""
    EdlLog "[~] PASO 4: Abre el patcher de Mi Account (tab Generales) en las imagenes leidas:"
    foreach ($kv in $readFiles.GetEnumerator()) {
        EdlLog "    $($kv.Key): $($kv.Value)"
    }
    EdlLog ""
    EdlLog "[~] Abriendo carpeta de trabajo..."
    Start-Process explorer.exe $wrkDir

    $resp = [System.Windows.Forms.MessageBox]::Show(
        "PASO 4 MANUAL`n`nArchivos leidos en:`n$wrkDir`n`nAhora:`n  1. Usa MODEM MI ACCOUNT (tab Generales) sobre modem.img`n  2. Usa PERSIST MI ACCOUNT (tab Generales) sobre persist.img`n  3. Cuando termines el parcheo, presiona OK para sobreescribir en el dispositivo",
        "MI ACCOUNT EDL - Paso manual","OK","Information")

    EdlLog "[~] PASO 5: Sobreescribiendo particiones parcheadas..."
    foreach ($part in $readParts) {
        $patchFile = Join-Path $wrkDir "$part.img"
        if (Test-Path $patchFile) {
            EdlLog "[~] Escribiendo: $part"
            $rW = Run-Edl "w $part `"$patchFile`" $ldrArg" 120
            if ($rW.ok) { EdlLog "[OK] $part escrito" }
            else { EdlLog "[~] ${part}: $($rW.out)" }
        }
    }
    EdlLog ""
    EdlLog "[OK] Proceso Mi Account EDL completado"
    EdlLog "[~] Reinicia el dispositivo"
    $btn.Enabled=$true; $btn.Text="MI ACCOUNT EDL"
})

#==========================================================================
# BLOQUE E3: RESERVADO (4 botones vacios para futura implementacion)
#==========================================================================
# Los botones ya estan desactivados visualmente arriba (foreach $btnsE3)
# Handlers vacios para evitar errores si se hace clic
foreach ($b in $btnsE3) {
    $b.Add_Click({
        EdlLog ""
        EdlLog "[i] Boton reservado para futura implementacion"
        EdlLog "[~] Funcionalidad pendiente en proxima version de RNX TOOL PRO"
    })
}