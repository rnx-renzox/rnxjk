#==========================================================================
# TAB GENERALES: UTILIDADES GENERALES - Layout y construccion de controles
# (Movido desde 04_tab_samsung.ps1 para separar logica Samsung de Generales)
#==========================================================================

#==========================================================================
$tabGen           = New-Object Windows.Forms.TabPage
$tabGen.Text      = "UTILIDADES GENERALES"
$tabGen.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$tabs.TabPages.Add($tabGen)

# ---- Metricas compartidas con ADB para coherencia visual ----
# Col izq x=6 w=422 | gap=8 | col der x=436 w=422
$GX_PAD  = 6
$GX_LOGX = 436
$GX_GW   = 422
$GX_LOGW = $GX_GW
$GX_BTW  = 195   # mismo que ADB
$GX_BTH  = 56    # mismo que ADB
$GX_PPX  = 14
$GX_PPY  = 20
$GX_GGX  = 8
$GX_GGY  = 8
$GX_GGAP = 8

# Altura de cada grupo: 2 filas de botones
$GX_GH = $GX_PPY + 2*($GX_BTH+$GX_GGY) - $GX_GGY + 14

$GX_Y1 = 6
$GX_Y2 = $GX_Y1 + $GX_GH + $GX_GGAP
$GX_Y3 = $GX_Y2 + $GX_GH + $GX_GGAP

# ---- Grupos columna izquierda ----
# G1 y G3: 2 filas (4 botones). G2: 3 filas (6 botones)
$GX_GH2 = $GX_PPY + 3*($GX_BTH+$GX_GGY) - $GX_GGY + 14   # altura para 3 filas
$GX_GH1 = $GX_GH   # G1 mantiene 2 filas
$GX_GH3 = $GX_GH   # G3 mantiene 2 filas

$GX_Y2B = $GX_Y1 + $GX_GH1 + $GX_GGAP
$GX_Y3B = $GX_Y2B + $GX_GH2 + $GX_GGAP

$grpG1 = New-GBox $tabGen "DIAGNOSTICO ADB"           $GX_PAD $GX_Y1  $GX_GW $GX_GH1 "Cyan"
$grpG2 = New-GBox $tabGen "PARCHEO DE PARTICIONES"  $GX_PAD $GX_Y2B $GX_GW $GX_GH2 "Cyan"
$grpG3 = New-GBox $tabGen "TALLER / GESTION"        $GX_PAD $GX_Y3B $GX_GW $GX_GH3 "Magenta"

$GL1=@("TEST PANTALLA","INFO BATERIA","ALMACENAMIENTO","APPS INSTALADAS")
$GL2=@("OEMINFO MDM HONOR","MODEM MI ACCOUNT","EFS SAMSUNG SIM 2","PERSIST MI ACCOUNT",
       "ACTIVAR RESET / MISC MOTOROLA","FLASH PARTICION IMG")
$GL3=@("CREAR FICHA CLIENTE","ADMIN CLIENTES","GENERAR REPORTE","ABRIR CARPETA TRABAJO")

$btnsG1=Place-Grid $grpG1 $GL1 "Cyan"    2 $GX_BTW $GX_BTH $GX_PPX $GX_PPY $GX_GGX $GX_GGY
$btnsG2=Place-Grid $grpG2 $GL2 "Cyan"    2 $GX_BTW $GX_BTH $GX_PPX $GX_PPY $GX_GGX $GX_GGY
$btnsG3=Place-Grid $grpG3 $GL3 "Magenta" 2 $GX_BTW $GX_BTH $GX_PPX $GX_PPY $GX_GGX $GX_GGY

$btnEditOem  =$btnsG2[0]
$btnEFSMod   =$btnsG2[1]
$btnEFSDirec =$btnsG2[2]
$btnPersist  =$btnsG2[3]
$btnRepairNV =$btnsG2[4]
$btnFlashPart=$btnsG2[5]

# ---- Log columna derecha - altura completa igual que ADB ----
$GX_LOGY = 6
$GX_LOGH = 616

$Global:logGen           = New-Object Windows.Forms.TextBox
$Global:logGen.Multiline = $true
$Global:logGen.Location  = New-Object System.Drawing.Point($GX_LOGX, $GX_LOGY)
$Global:logGen.Size      = New-Object System.Drawing.Size($GX_LOGW, $GX_LOGH)
$Global:logGen.BackColor = "Black"; $Global:logGen.ForeColor = "White"
$Global:logGen.BorderStyle = "FixedSingle"; $Global:logGen.ScrollBars = "Vertical"
$Global:logGen.Font      = New-Object System.Drawing.Font("Consolas",9)
$tabGen.Controls.Add($Global:logGen)
# Context menu: Limpiar Log
$ctxGen = New-Object System.Windows.Forms.ContextMenuStrip
$mnuClearGen = $ctxGen.Items.Add("Limpiar Log")
$mnuClearGen.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$mnuClearGen.ForeColor = [System.Drawing.Color]::OrangeRed
$mnuClearGen.Add_Click({ $Global:logGen.Clear() })
$Global:logGen.ContextMenuStrip = $ctxGen

# NOTA: La logica de los botones FIX LOGO SAMSUNG (btnsA2[2]) e INSTALAR MAGISK (btnsA2[4])

#==========================================================================
# LOGICA - TAB UTILIDADES GENERALES
#==========================================================================

# Ruta base del taller (clientes, trabajos, reportes)
$script:RNX_TALLER = Join-Path $script:SCRIPT_ROOT "RNXTaller"

function Ensure-TallerDirs {
    foreach ($d in @("clientes","trabajos","reportes")) {
        $p = Join-Path $script:RNX_TALLER $d
        if (-not (Test-Path $p)) { New-Item $p -ItemType Directory -Force | Out-Null }
    }
}

# Genera el proximo ID correlativo corto para sticker (ej: RNX-001, RNX-002...)
function Get-NextClienteID {
    $clientesDir = Join-Path $script:RNX_TALLER "clientes"
    if (-not (Test-Path $clientesDir)) { return "RNX-001" }
    $existing = Get-ChildItem $clientesDir -Filter "RNX-*.json" -EA SilentlyContinue |
        ForEach-Object {
            if ($_.BaseName -match "^RNX-(\d+)$") { [int]$Matches[1] }
        } | Sort-Object -Descending | Select-Object -First 1
    $next = if ($existing) { $existing + 1 } else { 1 }
    return "RNX-{0:D3}" -f $next
}

#==========================================================================
# BLOQUE G1 - DIAGNOSTICO ADB
$btnsG1[0].Add_Click({
    $btn=$btnsG1[0]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    GenLog ""
    GenLog "=== TEST PANTALLA ==="

    if (-not (Check-ADB)) { GenLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="TEST PANTALLA"; return }

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

    GenLog "[+] Resolucion    : $res"
    GenLog "[+] Densidad DPI  : $dens"
    GenLog "[+] Brillo        : $bright / 255 $(if($brightM -eq '1'){'(AUTO)'}else{'(MANUAL)'})"
    $toSec = try { [int]($timeout)/1000 } catch { "?" }
    GenLog "[+] Timeout pantalla: ${toSec}s"
    GenLog "[+] Pointer Location: $(if($ptrLoc -eq '1'){'ACTIVO'}else{'INACTIVO'})"
    GenLog ""

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
        GenLog "[OK] Pointer Location -> $(if($new -eq '1'){'ACTIVO'}else{'INACTIVO'})"
    }
    AddBtn "BRILLO MAXIMO" 182 158 152 "Lime" {
        & adb shell "settings put system screen_brightness 255" 2>$null | Out-Null
        & adb shell "settings put system screen_brightness_mode 0" 2>$null | Out-Null
        GenLog "[OK] Brillo al maximo (255), modo manual"
    }
    AddBtn "BRILLO AUTO" 14 200 160 "Cyan" {
        & adb shell "settings put system screen_brightness_mode 1" 2>$null | Out-Null
        GenLog "[OK] Brillo automatico activado"
    }
    AddBtn "TIMEOUT 10 MIN" 182 200 152 "Orange" {
        & adb shell "settings put system screen_off_timeout 600000" 2>$null | Out-Null
        GenLog "[OK] Timeout pantalla -> 10 minutos"
    }
    AddBtn "CERRAR" 110 242 140 "Gray" { $frmTest.Close() }
    $frmTest.ShowDialog() | Out-Null

    $btn.Enabled=$true; $btn.Text="TEST PANTALLA"
})

# ---- G1[1]: INFO BATERIA ----
$btnsG1[1].Add_Click({
    $btn=$btnsG1[1]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    GenLog ""
    GenLog "=== INFO BATERIA ==="

    if (-not (Check-ADB)) { GenLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="INFO BATERIA"; return }

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

    GenLog "[+] Nivel        : $nivel%"
    GenLog "[+] Estado       : $statusStr  (Cargador: $plugStr)"
    GenLog "[+] Salud        : $healthStr"
    $tempAlert = if ($tempC -ne "?" -and [double]$tempC -gt 40) { " [ALERTA: >40 grados C]" } else { "" }
    GenLog "[+] Temperatura  : $tempC C$tempAlert"
    GenLog "[+] Voltaje      : $voltV V"
    GenLog "[+] Tecnologia   : $techno"

    # Capacidad via sysfs
    GenLog ""
    GenLog "[~] Leyendo capacidad via sysfs..."
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
        GenLog "[+] Capacidad actual : $mAhNow mAh"
        GenLog "[+] Capacidad full   : $mAhFull mAh"
        GenLog "[+] Capacidad diseno : $mAhDes mAh"
        if ($mAhFull -ne "?" -and $mAhDes -ne "?") {
            $salud = try { [math]::Round(([double]$mAhFull/[double]$mAhDes)*100,1) } catch { "?" }
            $saludLabel = if ($salud -ne "?") {
                if    ($salud -ge 85) { "BUENA ($salud%)" }
                elseif($salud -ge 70) { "ACEPTABLE ($salud%)" }
                elseif($salud -ge 50) { "DEGRADADA ($salud%)" }
                else                  { "CRITICA ($salud%)" }
            } else { "?" }
            GenLog "[+] Salud real       : $saludLabel"
        }
    } else {
        GenLog "[~] Datos sysfs no disponibles en este dispositivo"
    }

    if ($cyclos) { GenLog "[+] Ciclos de carga  : $cyclos" }
    if ($curNow) {
        $mA = try { [math]::Round([math]::Abs([double]$curNow)/1000,0) } catch { "?" }
        $dir = if ([double]$curNow -gt 0) { "descargando" } else { "cargando" }
        GenLog "[+] Corriente actual : $mA mA ($dir)"
    }

    if ($tempAlert) {
        GenLog ""
        GenLog "[ALERTA] Temperatura elevada: $tempC C"
        GenLog "         Temperatura normal: 20-40 C durante carga"
        GenLog "         Detener carga si supera 45 C continuamente"
    }

    $btn.Enabled=$true; $btn.Text="INFO BATERIA"
})

# ---- G1[2]: ALMACENAMIENTO ----
$btnsG1[2].Add_Click({
    $btn=$btnsG1[2]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    GenLog ""; GenLog "=== ALMACENAMIENTO ==="
    if (-not (Check-ADB)) { GenLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="ALMACENAMIENTO"; return }

    GenLog "[~] Recopilando datos..."
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

    GenLog "[+] Datos listos. Abriendo panel visual..."
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

# ---- G1[3]: APPS INSTALADAS ----
$btnsG1[3].Add_Click({
    $btn=$btnsG1[3]; $btn.Enabled=$false; $btn.Text="LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    GenLog ""
    GenLog "=== APPS INSTALADAS ==="

    if (-not (Check-ADB)) { GenLog "[!] Sin dispositivo ADB."; $btn.Enabled=$true; $btn.Text="APPS INSTALADAS"; return }

    GenLog "[~] Contando paquetes..."
    $pkgUser   = (& adb shell "pm list packages -3"  2>$null) | Where-Object { $_ -match "package:" }
    $pkgSystem = (& adb shell "pm list packages -s"  2>$null) | Where-Object { $_ -match "package:" }
    $pkgDis    = (& adb shell "pm list packages -d"  2>$null) | Where-Object { $_ -match "package:" }

    $cU = $pkgUser.Count; $cS = $pkgSystem.Count; $cD = $pkgDis.Count
    GenLog "[+] Apps usuario    : $cU"
    GenLog "[+] Apps sistema    : $cS"
    GenLog "[+] Desactivadas    : $cD"
    GenLog "[+] TOTAL           : $($cU+$cS)"
    GenLog ""

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
# PARCHEO DE PARTICIONES - handlers existentes (sin cambios)
#==========================================================================
$btnEditOem.Add_Click({
    $fd=New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter="OEMINFO Files (*.img;*.bin)|*.img;*.bin|Todos|*.*"
    if ($fd.ShowDialog() -ne "OK") { return }
    $Global:_oemPath=$fd.FileName
    $Global:_oemRoot=$script:SCRIPT_ROOT
    $fn=[System.IO.Path]::GetFileName($Global:_oemPath)
    $fs=(Get-Item $Global:_oemPath).Length
    GenLog "`r`n[*] ===== OEMINFO MDM HONOR ====="
    GenLog "[*] Archivo : $fn ($([math]::Round($fs/1KB,2)) KB)"
    GenLog "[~] Procesando..."
    $Global:_btnOem=$btnEditOem; $Global:_btnOem.Enabled=$false; $Global:_btnOem.Text="PROCESANDO..."
    $stamp=Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
    $backDir=[System.IO.Path]::Combine($Global:_oemRoot,"BACKUPS","OEMINFO_MDM_HONOR",$stamp)
    [OemPatcher]::Run($Global:_oemPath,$backDir)
    $Global:_oemTimer=New-Object System.Windows.Forms.Timer; $Global:_oemTimer.Interval=400
    $Global:_oemTimer.Add_Tick({
        $msg=""
        while ([OemPatcher]::Q.TryDequeue([ref]$msg)) { GenLog $msg }
        if ([OemPatcher]::Done) {
            $Global:_oemTimer.Stop(); $Global:_oemTimer.Dispose()
            $Global:_btnOem.Enabled=$true; $Global:_btnOem.Text="OEMINFO MDM HONOR"
        }
    })
    $Global:_oemTimer.Start()
})

#==========================================================================
# MODEM MI ACCOUNT - edita modem.img / modem.bin
# Entra a /image y renombra todos los archivos cardapp.xxx a 00000000000
# Soporta seleccion de 1 o 2 archivos (modem_a + modem_b, tipico en Xiaomi)
#==========================================================================
$btnEFSMod.Add_Click({
    $btnEFSMod.Enabled = $false; $btnEFSMod.Text = "PROCESANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        GenLog ""
        GenLog "[*] =========================================="
        GenLog "[*] MODEM MI ACCOUNT - RNX TOOL PRO"
        GenLog "[*] Renombrar cardapp.xxx -> 00000000000"
        GenLog "[*] =========================================="
        GenLog ""
        GenLog "[~] Selecciona 1 o 2 archivos modem (modem.img / modem.bin)"
        GenLog "[~] Algunos Xiaomi traen modem_a y modem_b - selecciona ambos"
        GenLog ""
        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "Modem Image (*.img;*.bin)|*.img;*.bin|Todos|*.*"
        $fd.Title = "Selecciona modem.img / modem.bin (CTRL para seleccionar 2)"
        $fd.Multiselect = $true
        if ($fd.ShowDialog() -ne "OK") {
            GenLog "[~] Cancelado."
            return
        }
        $selectedFiles = $fd.FileNames
        if ($selectedFiles.Count -eq 0) { GenLog "[~] Sin archivos seleccionados."; return }
        if ($selectedFiles.Count -gt 2) {
            GenLog "[!] Maximo 2 archivos permitidos (modem_a + modem_b). Seleccionaste: $($selectedFiles.Count)"
            GenLog "[~] Por favor selecciona solo 1 o 2 archivos."
            return
        }
        GenLog "[+] Archivos seleccionados: $($selectedFiles.Count)"
        foreach ($f in $selectedFiles) {
            $fn = [System.IO.Path]::GetFileName($f)
            $fs = [math]::Round((Get-Item $f).Length / 1MB, 2)
            GenLog "  -> $fn ($fs MB)"
        }
        GenLog ""
        $modemRoot = $script:SCRIPT_ROOT
        $stamp = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
        $backDir = [System.IO.Path]::Combine($modemRoot, "BACKUPS", "MODEM_MI_ACCOUNT", $stamp)
        [ModemMiPatcher]::Run($selectedFiles, $backDir)
        $Global:_modemTimer = New-Object System.Windows.Forms.Timer
        $Global:_modemTimer.Interval = 500
        $Global:_modemTimer.Add_Tick({
            $msg = ""
            while ([ModemMiPatcher]::Q.TryDequeue([ref]$msg)) { GenLog $msg }
            if ([ModemMiPatcher]::Done) {
                $Global:_modemTimer.Stop(); $Global:_modemTimer.Dispose()
                $btnEFSMod.Enabled = $true
                $btnEFSMod.Text = "MODEM MI ACCOUNT"
            }
        })
        $Global:_modemTimer.Start()
    } catch {
        GenLog "[!] Error inesperado: $_"
        $btnEFSMod.Enabled = $true; $btnEFSMod.Text = "MODEM MI ACCOUNT"
    }
})


#==========================================================================
# BLOQUE 3 - TALLER / GESTION
#==========================================================================

# ---- [0] CREAR FICHA CLIENTE ----
$btnsG3[0].Add_Click({
    $btn = $btnsG3[0]; $btn.Enabled=$false; $btn.Text="CREANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        Ensure-TallerDirs
        GenLog ""
        GenLog "=============================================="
        GenLog "  CREAR FICHA CLIENTE - RNX TOOL PRO"
        GenLog "=============================================="

        # Formulario de ingreso
        $frmCliente = New-Object System.Windows.Forms.Form
        $frmCliente.Text = "NUEVA FICHA CLIENTE - RNX TOOL PRO"
        $frmCliente.Size = New-Object System.Drawing.Size(460, 420)
        $frmCliente.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
        $frmCliente.StartPosition = "CenterScreen"
        $frmCliente.FormBorderStyle = "FixedDialog"
        $frmCliente.ControlBox = $false
        $frmCliente.TopMost = $true

        $mkLbl = {
            param($txt,$y)
            $l = New-Object System.Windows.Forms.Label
            $l.Text=$txt; $l.Location=New-Object System.Drawing.Point(16,$y)
            $l.Size=New-Object System.Drawing.Size(130,18)
            $l.ForeColor=[System.Drawing.Color]::Cyan
            $l.Font=New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
            $frmCliente.Controls.Add($l)
        }
        $mkTxt = {
            param($y,$default="")
            $t = New-Object System.Windows.Forms.TextBox
            $t.Location=New-Object System.Drawing.Point(155,$y)
            $t.Size=New-Object System.Drawing.Size(270,22)
            $t.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
            $t.ForeColor=[System.Drawing.Color]::White
            $t.BorderStyle="FixedSingle"
            $t.Font=New-Object System.Drawing.Font("Segoe UI",9)
            $t.Text=$default
            $frmCliente.Controls.Add($t); return $t
        }

        & $mkLbl "Nombre:" 20;  $txNombre   = & $mkTxt 18
        & $mkLbl "Teléfono:" 52; $txTelefono = & $mkTxt 50
        & $mkLbl "Equipo:" 84;  $txEquipo   = & $mkTxt 82
        & $mkLbl "Modelo:" 116; $txModelo   = & $mkTxt 114

        $lbProb = New-Object System.Windows.Forms.Label
        $lbProb.Text="Problema:"; $lbProb.Location=New-Object System.Drawing.Point(16,148)
        $lbProb.Size=New-Object System.Drawing.Size(130,18)
        $lbProb.ForeColor=[System.Drawing.Color]::Cyan
        $lbProb.Font=New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
        $frmCliente.Controls.Add($lbProb)

        $txProblema = New-Object System.Windows.Forms.TextBox
        $txProblema.Location=New-Object System.Drawing.Point(155,146)
        $txProblema.Size=New-Object System.Drawing.Size(270,70)
        $txProblema.Multiline=$true; $txProblema.ScrollBars="Vertical"
        $txProblema.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $txProblema.ForeColor=[System.Drawing.Color]::White
        $txProblema.BorderStyle="FixedSingle"
        $txProblema.Font=New-Object System.Drawing.Font("Segoe UI",9)
        $frmCliente.Controls.Add($txProblema)

        & $mkLbl "Precio:" 228; $txPrecio = & $mkTxt 226 "0"

        $lbEst = New-Object System.Windows.Forms.Label
        $lbEst.Text="Estado:"; $lbEst.Location=New-Object System.Drawing.Point(16,260)
        $lbEst.Size=New-Object System.Drawing.Size(130,18); $lbEst.ForeColor=[System.Drawing.Color]::Cyan
        $lbEst.Font=New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
        $frmCliente.Controls.Add($lbEst)

        $cbEstado = New-Object System.Windows.Forms.ComboBox
        $cbEstado.Location=New-Object System.Drawing.Point(155,258)
        $cbEstado.Size=New-Object System.Drawing.Size(270,22)
        $cbEstado.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $cbEstado.ForeColor=[System.Drawing.Color]::White
        $cbEstado.DropDownStyle="DropDownList"
        "Pendiente","En proceso","Listo","Entregado","Cancelado" | ForEach-Object { $cbEstado.Items.Add($_) | Out-Null }
        $cbEstado.SelectedIndex=0
        $frmCliente.Controls.Add($cbEstado)

        $script:clienteOK = $false

        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text="GUARDAR"; $btnOK.Location=New-Object System.Drawing.Point(100,320)
        $btnOK.Size=New-Object System.Drawing.Size(110,34); $btnOK.FlatStyle="Flat"
        $btnOK.ForeColor=[System.Drawing.Color]::Lime
        $btnOK.FlatAppearance.BorderColor=[System.Drawing.Color]::Lime
        $btnOK.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $btnOK.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $btnOK.Add_Click({ $script:clienteOK=$true; $frmCliente.Close() })
        $frmCliente.Controls.Add($btnOK)

        $btnCancelarC = New-Object System.Windows.Forms.Button
        $btnCancelarC.Text="CANCELAR"; $btnCancelarC.Location=New-Object System.Drawing.Point(240,320)
        $btnCancelarC.Size=New-Object System.Drawing.Size(110,34); $btnCancelarC.FlatStyle="Flat"
        $btnCancelarC.ForeColor=[System.Drawing.Color]::Gray
        $btnCancelarC.FlatAppearance.BorderColor=[System.Drawing.Color]::Gray
        $btnCancelarC.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $btnCancelarC.Font=New-Object System.Drawing.Font("Segoe UI",9)
        $btnCancelarC.Add_Click({ $frmCliente.Close() })
        $frmCliente.Controls.Add($btnCancelarC)

        $frmCliente.ShowDialog() | Out-Null

        if (-not $script:clienteOK) { GenLog "[~] Cancelado."; return }
        if (-not $txNombre.Text.Trim()) { GenLog "[!] El nombre es obligatorio."; return }

        $fecha  = Get-Date -Format "yyyy-MM-dd"
        $hora   = Get-Date -Format "HH:mm"
        $id     = Get-NextClienteID

        $cliente = [ordered]@{
            id        = $id
            nombre    = $txNombre.Text.Trim()
            telefono  = $txTelefono.Text.Trim()
            equipo    = $txEquipo.Text.Trim()
            modelo    = $txModelo.Text.Trim()
            problema  = $txProblema.Text.Trim()
            precio    = $txPrecio.Text.Trim()
            estado    = $cbEstado.SelectedItem.ToString()
            fecha     = $fecha
            hora      = $hora
        }

        # Guardar JSON individual
        $jsonPath = Join-Path (Join-Path $script:RNX_TALLER "clientes") "$id.json"
        $cliente | ConvertTo-Json -Depth 3 | Out-File $jsonPath -Encoding UTF8

        # Crear carpeta de trabajo estructurada
        $workDir = Join-Path (Join-Path $script:RNX_TALLER "trabajos") $id
        foreach ($sub in @("Firmware","Backup","Logs","Reportes")) {
            New-Item (Join-Path $workDir $sub) -ItemType Directory -Force | Out-Null
        }

        GenLog "[OK] Cliente creado: $id"
        GenLog "     Nombre  : $($cliente.nombre)"
        GenLog "     Equipo  : $($cliente.equipo) $($cliente.modelo)"
        GenLog "     Problema: $($cliente.problema)"
        GenLog "     Estado  : $($cliente.estado)"
        GenLog "     Carpeta : $workDir"
        GenLog ""

        [System.Windows.Forms.MessageBox]::Show(
            "Ficha creada exitosamente`n`nID: $id`nCliente: $($cliente.nombre)`n`nCarpeta de trabajo creada en:`n$workDir",
            "CLIENTE CREADO", "OK", "Information") | Out-Null

    } catch { GenLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="CREAR FICHA CLIENTE" }
})

# ---- [1] ADMIN CLIENTES (mini CRM) ----
$btnsG3[1].Add_Click({
    $btn = $btnsG3[1]; $btn.Enabled=$false; $btn.Text="CARGANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        Ensure-TallerDirs
        GenLog ""
        GenLog "=============================================="
        GenLog "  ADMIN CLIENTES - RNX TOOL PRO"
        GenLog "=============================================="

        $clientesDir = Join-Path $script:RNX_TALLER "clientes"
        $jsonFiles   = Get-ChildItem $clientesDir -Filter "*.json" -ErrorAction SilentlyContinue

        $frmAdmin = New-Object System.Windows.Forms.Form
        $frmAdmin.Text = "ADMINISTRADOR DE CLIENTES - RNX TOOL PRO"
        $frmAdmin.Size = New-Object System.Drawing.Size(900, 540)
        $frmAdmin.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
        $frmAdmin.StartPosition = "CenterScreen"
        $frmAdmin.FormBorderStyle = "Sizable"
        $frmAdmin.TopMost = $true

        # Barra de busqueda
        $pnlTop = New-Object System.Windows.Forms.Panel
        $pnlTop.Location = New-Object System.Drawing.Point(0,0)
        $pnlTop.Size = New-Object System.Drawing.Size(900,40)
        $pnlTop.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
        $frmAdmin.Controls.Add($pnlTop)

        $lbBuscar = New-Object System.Windows.Forms.Label
        $lbBuscar.Text="Buscar:"; $lbBuscar.Location=New-Object System.Drawing.Point(8,12)
        $lbBuscar.Size=New-Object System.Drawing.Size(55,18)
        $lbBuscar.ForeColor=[System.Drawing.Color]::Cyan
        $lbBuscar.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $pnlTop.Controls.Add($lbBuscar)

        $txBuscar = New-Object System.Windows.Forms.TextBox
        $txBuscar.Location=New-Object System.Drawing.Point(68,9)
        $txBuscar.Size=New-Object System.Drawing.Size(280,22)
        $txBuscar.BackColor=[System.Drawing.Color]::FromArgb(40,40,40)
        $txBuscar.ForeColor=[System.Drawing.Color]::White
        $txBuscar.BorderStyle="FixedSingle"
        $txBuscar.Font=New-Object System.Drawing.Font("Segoe UI",9)
        $pnlTop.Controls.Add($txBuscar)

        $lbTotal = New-Object System.Windows.Forms.Label
        $lbTotal.Location=New-Object System.Drawing.Point(360,12)
        $lbTotal.Size=New-Object System.Drawing.Size(200,18)
        $lbTotal.ForeColor=[System.Drawing.Color]::FromArgb(120,120,120)
        $lbTotal.Font=New-Object System.Drawing.Font("Segoe UI",8.5)
        $pnlTop.Controls.Add($lbTotal)

        # Grid
        $grid = New-Object System.Windows.Forms.DataGridView
        $grid.Location = New-Object System.Drawing.Point(0,42)
        $grid.Size = New-Object System.Drawing.Size(884,400)
        $grid.BackgroundColor = [System.Drawing.Color]::FromArgb(25,25,25)
        $grid.ForeColor = [System.Drawing.Color]::White
        $grid.GridColor = [System.Drawing.Color]::FromArgb(50,50,50)
        $grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
        $grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::Cyan
        $grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
        $grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(28,28,28)
        $grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
        $grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0,80,120)
        $grid.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
        $grid.SelectionMode = "FullRowSelect"
        $grid.MultiSelect = $false
        $grid.ReadOnly = $true
        $grid.AllowUserToAddRows = $false
        $grid.AllowUserToDeleteRows = $false
        $grid.RowHeadersVisible = $false
        $grid.AutoSizeColumnsMode = "Fill"
        $grid.Anchor = "Top,Left,Right,Bottom"
        $frmAdmin.Controls.Add($grid)

        # Botonera inferior
        $pnlBot = New-Object System.Windows.Forms.Panel
        $pnlBot.Location = New-Object System.Drawing.Point(0,444)
        $pnlBot.Size = New-Object System.Drawing.Size(900,58)
        $pnlBot.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
        $frmAdmin.Controls.Add($pnlBot)

        $mkBtnAdmin = {
            param($txt,$clr,$x)
            $b = New-Object System.Windows.Forms.Button
            $b.Text=$txt; $b.Location=New-Object System.Drawing.Point($x,12)
            $b.Size=New-Object System.Drawing.Size(130,34); $b.FlatStyle="Flat"
            $b.ForeColor=$clr; $b.FlatAppearance.BorderColor=$clr
            $b.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
            $b.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
            $pnlBot.Controls.Add($b); return $b
        }

        $btnVerFicha   = & $mkBtnAdmin "VER FICHA"       ([System.Drawing.Color]::Cyan)        8
        $btnEditCliente= & $mkBtnAdmin "CAMBIAR ESTADO"  ([System.Drawing.Color]::Orange)     146
        $btnEliminar   = & $mkBtnAdmin "ELIMINAR"        ([System.Drawing.Color]::Red)        284
        $btnAbrirCarp  = & $mkBtnAdmin "ABRIR CARPETA"   ([System.Drawing.Color]::Lime)       422
        $btnNuevoAdmin = & $mkBtnAdmin "NUEVO CLIENTE"   ([System.Drawing.Color]::Magenta)    560
        $btnCerrarAdm  = & $mkBtnAdmin "CERRAR"          ([System.Drawing.Color]::Gray)       706

        # Cargar datos
        $script:adminClientes = @()
        $script:adminFiles    = @()

        function Load-Clientes($filtro="") {
            $grid.Rows.Clear()
            $grid.Columns.Clear()
            foreach ($col in @("ID","Nombre","Telefono","Equipo","Modelo","Estado","Fecha")) {
                $grid.Columns.Add($col,$col) | Out-Null
            }
            $script:adminClientes = @()
            $script:adminFiles    = @()
            $all = Get-ChildItem $clientesDir -Filter "*.json" -EA SilentlyContinue |
                   Sort-Object LastWriteTime -Descending
            foreach ($f in $all) {
                try {
                    $c = Get-Content $f.FullName | ConvertFrom-Json
                    $filt = $filtro.ToLower()
                    if ($filt -and
                        $c.nombre.ToLower()   -notmatch $filt -and
                        $c.equipo.ToLower()   -notmatch $filt -and
                        $c.modelo.ToLower()   -notmatch $filt -and
                        $c.id.ToLower()       -notmatch $filt) { continue }
                    $grid.Rows.Add($c.id,$c.nombre,$c.telefono,$c.equipo,$c.modelo,$c.estado,$c.fecha) | Out-Null
                    # Color por estado
                    $row = $grid.Rows[$grid.Rows.Count-1]
                    $clrEst = switch ($c.estado) {
                        "Pendiente"   { [System.Drawing.Color]::FromArgb(60,40,10) }
                        "En proceso"  { [System.Drawing.Color]::FromArgb(10,40,60) }
                        "Listo"       { [System.Drawing.Color]::FromArgb(10,50,10) }
                        "Entregado"   { [System.Drawing.Color]::FromArgb(25,25,25) }
                        "Cancelado"   { [System.Drawing.Color]::FromArgb(50,10,10) }
                        default       { [System.Drawing.Color]::FromArgb(28,28,28) }
                    }
                    $row.DefaultCellStyle.BackColor = $clrEst
                    $script:adminClientes += $c
                    $script:adminFiles    += $f.FullName
                } catch {}
            }
            $lbTotal.Text = "$($script:adminClientes.Count) cliente(s)"
        }

        Load-Clientes

        $txBuscar.Add_TextChanged({ Load-Clientes $txBuscar.Text })

        $btnVerFicha.Add_Click({
            if ($grid.SelectedRows.Count -eq 0) { return }
            $idx = $grid.SelectedRows[0].Index
            $c   = $script:adminClientes[$idx]
            $msg = @"
ID       : $($c.id)
Nombre   : $($c.nombre)
Telefono : $($c.telefono)
Equipo   : $($c.equipo)
Modelo   : $($c.modelo)
Problema : $($c.problema)
Precio   : $($c.precio)
Estado   : $($c.estado)
Fecha    : $($c.fecha) $($c.hora)
"@
            [System.Windows.Forms.MessageBox]::Show($msg,"FICHA: $($c.nombre)","OK","Information") | Out-Null
        })

        $btnEditCliente.Add_Click({
            if ($grid.SelectedRows.Count -eq 0) { return }
            $idx = $grid.SelectedRows[0].Index
            $c   = $script:adminClientes[$idx]

            # Popup propio con TopMost para que nunca quede atras de la UI principal
            $frmEstado = New-Object System.Windows.Forms.Form
            $frmEstado.Text = "CAMBIAR ESTADO"
            $frmEstado.Size = New-Object System.Drawing.Size(380, 200)
            $frmEstado.StartPosition = "CenterScreen"
            $frmEstado.FormBorderStyle = "FixedDialog"
            $frmEstado.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
            $frmEstado.TopMost = $true
            $frmEstado.ControlBox = $false

            $lbInfo = New-Object System.Windows.Forms.Label
            $lbInfo.Text = "Cliente: $($c.nombre)`nEstado actual: $($c.estado)"
            $lbInfo.Location = New-Object System.Drawing.Point(14,12)
            $lbInfo.Size = New-Object System.Drawing.Size(348,38)
            $lbInfo.ForeColor = [System.Drawing.Color]::Cyan
            $lbInfo.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
            $frmEstado.Controls.Add($lbInfo)

            $cbNuevo = New-Object System.Windows.Forms.ComboBox
            $cbNuevo.Location = New-Object System.Drawing.Point(14,60)
            $cbNuevo.Size = New-Object System.Drawing.Size(348,24)
            $cbNuevo.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
            $cbNuevo.ForeColor = [System.Drawing.Color]::White
            $cbNuevo.DropDownStyle = "DropDownList"
            $cbNuevo.Font = New-Object System.Drawing.Font("Segoe UI",9)
            "Pendiente","En proceso","Listo","Entregado","Cancelado" | ForEach-Object { $cbNuevo.Items.Add($_) | Out-Null }
            $idx2 = $cbNuevo.Items.IndexOf($c.estado)
            $cbNuevo.SelectedIndex = if ($idx2 -ge 0) { $idx2 } else { 0 }
            $frmEstado.Controls.Add($cbNuevo)

            $script:estadoOK = $false
            $btnGuardarE = New-Object System.Windows.Forms.Button
            $btnGuardarE.Text = "GUARDAR"; $btnGuardarE.Location = New-Object System.Drawing.Point(60,110)
            $btnGuardarE.Size = New-Object System.Drawing.Size(110,34); $btnGuardarE.FlatStyle = "Flat"
            $btnGuardarE.ForeColor = [System.Drawing.Color]::Lime
            $btnGuardarE.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
            $btnGuardarE.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
            $btnGuardarE.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
            $btnGuardarE.Add_Click({ $script:estadoOK = $true; $frmEstado.Close() })
            $frmEstado.Controls.Add($btnGuardarE)

            $btnCancelarE = New-Object System.Windows.Forms.Button
            $btnCancelarE.Text = "CANCELAR"; $btnCancelarE.Location = New-Object System.Drawing.Point(200,110)
            $btnCancelarE.Size = New-Object System.Drawing.Size(110,34); $btnCancelarE.FlatStyle = "Flat"
            $btnCancelarE.ForeColor = [System.Drawing.Color]::Gray
            $btnCancelarE.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
            $btnCancelarE.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
            $btnCancelarE.Font = New-Object System.Drawing.Font("Segoe UI",9)
            $btnCancelarE.Add_Click({ $frmEstado.Close() })
            $frmEstado.Controls.Add($btnCancelarE)

            $frmEstado.ShowDialog($frmAdmin) | Out-Null

            if ($script:estadoOK -and $cbNuevo.SelectedItem) {
                $c.estado = $cbNuevo.SelectedItem.ToString()
                $c | ConvertTo-Json -Depth 3 | Out-File $script:adminFiles[$idx] -Encoding UTF8
                Load-Clientes $txBuscar.Text
            }
        })

        $btnEliminar.Add_Click({
            if ($grid.SelectedRows.Count -eq 0) { return }
            $idx = $grid.SelectedRows[0].Index
            $c   = $script:adminClientes[$idx]
            $conf = [System.Windows.Forms.MessageBox]::Show(
                "Eliminar cliente: $($c.nombre) ($($c.id))?`n`nSe eliminara solo la ficha (no la carpeta de trabajo).",
                "CONFIRMAR ELIMINACION","YesNo","Warning")
            if ($conf -eq "Yes") {
                Remove-Item $script:adminFiles[$idx] -Force -EA SilentlyContinue
                Load-Clientes $txBuscar.Text
            }
        })

        $btnAbrirCarp.Add_Click({
            if ($grid.SelectedRows.Count -eq 0) { return }
            $idx = $grid.SelectedRows[0].Index
            $c   = $script:adminClientes[$idx]
            $wDir = Join-Path (Join-Path $script:RNX_TALLER "trabajos") $c.id
            if (Test-Path $wDir) { Start-Process explorer.exe $wDir }
            else { [System.Windows.Forms.MessageBox]::Show("Carpeta no encontrada:`n$wDir","INFO","OK","Information") | Out-Null }
        })

        $btnNuevoAdmin.Add_Click({ $frmAdmin.Close(); $btnsG3[0].PerformClick() })
        $btnCerrarAdm.Add_Click({ $frmAdmin.Close() })

        $frmAdmin.ShowDialog() | Out-Null
        GenLog "[OK] Admin Clientes cerrado."

    } catch { GenLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="ADMIN CLIENTES" }
})

# ---- [2] GENERAR REPORTE TECNICO ----
$btnsG3[2].Add_Click({
    $btn = $btnsG3[2]; $btn.Enabled=$false; $btn.Text="GENERANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        Ensure-TallerDirs
        GenLog ""
        GenLog "=============================================="
        GenLog "  GENERAR REPORTE TECNICO - RNX TOOL PRO"
        GenLog "=============================================="

        $clientesDir = Join-Path $script:RNX_TALLER "clientes"
        $jsonFiles   = Get-ChildItem $clientesDir -Filter "*.json" -EA SilentlyContinue |
                       Sort-Object LastWriteTime -Descending

        if ($jsonFiles.Count -eq 0) {
            GenLog "[!] No hay clientes registrados. Crea una ficha primero."
            return
        }

        # Selector de cliente
        $frmSel = New-Object System.Windows.Forms.Form
        $frmSel.Text = "SELECCIONAR CLIENTE - Reporte"
        $frmSel.Size = New-Object System.Drawing.Size(480, 360)
        $frmSel.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
        $frmSel.StartPosition = "CenterScreen"
        $frmSel.FormBorderStyle = "FixedDialog"
        $frmSel.ControlBox = $false
        $frmSel.TopMost = $true

        $lbSelTit = New-Object System.Windows.Forms.Label
        $lbSelTit.Text="Selecciona el cliente:"; $lbSelTit.Location=New-Object System.Drawing.Point(16,14)
        $lbSelTit.Size=New-Object System.Drawing.Size(440,20)
        $lbSelTit.ForeColor=[System.Drawing.Color]::Cyan
        $lbSelTit.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $frmSel.Controls.Add($lbSelTit)

        $lbxClientes = New-Object System.Windows.Forms.ListBox
        $lbxClientes.Location=New-Object System.Drawing.Point(16,40)
        $lbxClientes.Size=New-Object System.Drawing.Size(436,230)
        $lbxClientes.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $lbxClientes.ForeColor=[System.Drawing.Color]::White
        $lbxClientes.Font=New-Object System.Drawing.Font("Consolas",8.5)
        $lbxClientes.BorderStyle="FixedSingle"
        $frmSel.Controls.Add($lbxClientes)

        $clientes = @()
        foreach ($f in $jsonFiles) {
            try {
                $c = Get-Content $f.FullName | ConvertFrom-Json
                $lbxClientes.Items.Add("$($c.id)  |  $($c.nombre)  |  $($c.modelo)  |  $($c.estado)") | Out-Null
                $clientes += $c
            } catch {}
        }
        $lbxClientes.SelectedIndex = 0

        $script:repOK = $false
        $btnSelOK = New-Object System.Windows.Forms.Button
        $btnSelOK.Text="SELECCIONAR"; $btnSelOK.Location=New-Object System.Drawing.Point(100,285)
        $btnSelOK.Size=New-Object System.Drawing.Size(120,34); $btnSelOK.FlatStyle="Flat"
        $btnSelOK.ForeColor=[System.Drawing.Color]::Lime
        $btnSelOK.FlatAppearance.BorderColor=[System.Drawing.Color]::Lime
        $btnSelOK.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $btnSelOK.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $btnSelOK.Add_Click({ $script:repOK=$true; $frmSel.Close() })
        $frmSel.Controls.Add($btnSelOK)

        $btnSelCancelar = New-Object System.Windows.Forms.Button
        $btnSelCancelar.Text="CANCELAR"; $btnSelCancelar.Location=New-Object System.Drawing.Point(255,285)
        $btnSelCancelar.Size=New-Object System.Drawing.Size(100,34); $btnSelCancelar.FlatStyle="Flat"
        $btnSelCancelar.ForeColor=[System.Drawing.Color]::Gray
        $btnSelCancelar.FlatAppearance.BorderColor=[System.Drawing.Color]::Gray
        $btnSelCancelar.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $btnSelCancelar.Font=New-Object System.Drawing.Font("Segoe UI",9)
        $btnSelCancelar.Add_Click({ $frmSel.Close() })
        $frmSel.Controls.Add($btnSelCancelar)

        $frmSel.ShowDialog() | Out-Null
        if (-not $script:repOK -or $lbxClientes.SelectedIndex -lt 0) {
            GenLog "[~] Cancelado."; return
        }

        $cliente = $clientes[$lbxClientes.SelectedIndex]

        # Solicitar datos del reporte
        Add-Type -AssemblyName Microsoft.VisualBasic
        $diag   = [Microsoft.VisualBasic.Interaction]::InputBox("Diagnóstico técnico:", "REPORTE - Diagnóstico", "")
        $trabajo = [Microsoft.VisualBasic.Interaction]::InputBox("Trabajo realizado:", "REPORTE - Trabajo", "")
        $estado  = [Microsoft.VisualBasic.Interaction]::InputBox("Estado final del equipo:", "REPORTE - Estado Final", "Funcionando correctamente")

        if (-not $trabajo.Trim()) { GenLog "[~] Reporte cancelado (trabajo vacío)."; return }

        $fechaRep = Get-Date -Format "dd/MM/yyyy HH:mm"
        $tallerNombre = "RNX TOOL PRO - Servicio Técnico"

        $reporte = @"
================================================================
  $tallerNombre
  REPORTE TÉCNICO DE SERVICIO
================================================================

FECHA      : $fechaRep
ID CLIENTE : $($cliente.id)

----------------------------------------------------------------
  DATOS DEL CLIENTE
----------------------------------------------------------------
Nombre     : $($cliente.nombre)
Teléfono   : $($cliente.telefono)
Fecha ingr.: $($cliente.fecha) $($cliente.hora)

----------------------------------------------------------------
  DATOS DEL EQUIPO
----------------------------------------------------------------
Equipo     : $($cliente.equipo)
Modelo     : $($cliente.modelo)
Problema   : $($cliente.problema)
Precio     : $($cliente.precio)

----------------------------------------------------------------
  INFORME TÉCNICO
----------------------------------------------------------------
DIAGNÓSTICO:
$diag

TRABAJO REALIZADO:
$trabajo

ESTADO FINAL:
$estado

================================================================
  Firmado: $tallerNombre
  Fecha  : $fechaRep
================================================================
"@

        # Guardar reporte
        $repDir  = Join-Path (Join-Path (Join-Path $script:RNX_TALLER "trabajos") $cliente.id) "Reportes"
        New-Item $repDir -ItemType Directory -Force | Out-Null
        $repFile = Join-Path $repDir "Reporte_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $reporte | Out-File $repFile -Encoding UTF8

        # Actualizar estado del cliente
        $cliente.estado = $estado
        $jsonPath = Join-Path $clientesDir "$($cliente.id).json"
        if (Test-Path $jsonPath) {
            $cliente | ConvertTo-Json -Depth 3 | Out-File $jsonPath -Encoding UTF8
        }

        GenLog "[OK] Reporte generado: $([System.IO.Path]::GetFileName($repFile))"
        GenLog "     Cliente : $($cliente.nombre)"
        GenLog "     Estado  : $estado"
        GenLog "     Ruta    : $repFile"

        $abrir = [System.Windows.Forms.MessageBox]::Show(
            "Reporte generado correctamente.`nCliente: $($cliente.nombre)`n`nAbrir reporte?",
            "REPORTE OK","YesNo","Information")
        if ($abrir -eq "Yes") { Start-Process notepad.exe $repFile }

    } catch { GenLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="GENERAR REPORTE" }
})

# ---- [3] ABRIR CARPETA TRABAJO ----
$btnsG3[3].Add_Click({
    $btn = $btnsG3[3]; $btn.Enabled=$false; $btn.Text="CARGANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        Ensure-TallerDirs
        GenLog ""
        GenLog "=============================================="
        GenLog "  ABRIR CARPETA TRABAJO - RNX TOOL PRO"
        GenLog "=============================================="

        $trabajosDir = Join-Path $script:RNX_TALLER "trabajos"
        $carpetas    = Get-ChildItem $trabajosDir -Directory -EA SilentlyContinue |
                       Sort-Object LastWriteTime -Descending

        if ($carpetas.Count -eq 0) {
            # Abrir directamente el directorio de trabajos
            GenLog "[~] No hay carpetas de trabajo. Abriendo directorio principal..."
            New-Item $trabajosDir -ItemType Directory -Force | Out-Null
            Start-Process explorer.exe $trabajosDir
            return
        }

        $clientesDir = Join-Path $script:RNX_TALLER "clientes"

        # Selector visual
        $frmWork = New-Object System.Windows.Forms.Form
        $frmWork.Text = "ABRIR CARPETA TRABAJO - RNX TOOL PRO"
        $frmWork.Size = New-Object System.Drawing.Size(520, 400)
        $frmWork.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
        $frmWork.StartPosition = "CenterScreen"
        $frmWork.FormBorderStyle = "FixedDialog"
        $frmWork.ControlBox = $false
        $frmWork.TopMost = $true

        $lbWTit = New-Object System.Windows.Forms.Label
        $lbWTit.Text="Selecciona trabajo a abrir:"; $lbWTit.Location=New-Object System.Drawing.Point(16,14)
        $lbWTit.Size=New-Object System.Drawing.Size(480,20)
        $lbWTit.ForeColor=[System.Drawing.Color]::Lime
        $lbWTit.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $frmWork.Controls.Add($lbWTit)

        $lbxWork = New-Object System.Windows.Forms.ListBox
        $lbxWork.Location=New-Object System.Drawing.Point(16,40)
        $lbxWork.Size=New-Object System.Drawing.Size(476,270)
        $lbxWork.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $lbxWork.ForeColor=[System.Drawing.Color]::White
        $lbxWork.Font=New-Object System.Drawing.Font("Consolas",8.5)
        $lbxWork.BorderStyle="FixedSingle"
        $frmWork.Controls.Add($lbxWork)

        foreach ($c in $carpetas) {
            $clienteJson = Join-Path $clientesDir "$($c.Name).json"
            if (Test-Path $clienteJson) {
                try {
                    $cli = Get-Content $clienteJson | ConvertFrom-Json
                    $lbxWork.Items.Add("$($c.Name)  |  $($cli.nombre)  |  $($cli.modelo)  |  $($cli.estado)") | Out-Null
                } catch {
                    $lbxWork.Items.Add($c.Name) | Out-Null
                }
            } else {
                $lbxWork.Items.Add($c.Name) | Out-Null
            }
        }
        $lbxWork.SelectedIndex = 0

        $script:workOK = $false
        $btnWOK = New-Object System.Windows.Forms.Button
        $btnWOK.Text="ABRIR"; $btnWOK.Location=New-Object System.Drawing.Point(100,325)
        $btnWOK.Size=New-Object System.Drawing.Size(110,38); $btnWOK.FlatStyle="Flat"
        $btnWOK.ForeColor=[System.Drawing.Color]::Lime
        $btnWOK.FlatAppearance.BorderColor=[System.Drawing.Color]::Lime
        $btnWOK.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $btnWOK.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $btnWOK.Add_Click({ $script:workOK=$true; $frmWork.Close() })
        $frmWork.Controls.Add($btnWOK)

        $btnWRaiz = New-Object System.Windows.Forms.Button
        $btnWRaiz.Text="ABRIR RAIZ"; $btnWRaiz.Location=New-Object System.Drawing.Point(222,325)
        $btnWRaiz.Size=New-Object System.Drawing.Size(110,38); $btnWRaiz.FlatStyle="Flat"
        $btnWRaiz.ForeColor=[System.Drawing.Color]::Cyan
        $btnWRaiz.FlatAppearance.BorderColor=[System.Drawing.Color]::Cyan
        $btnWRaiz.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $btnWRaiz.Font=New-Object System.Drawing.Font("Segoe UI",9)
        $btnWRaiz.Add_Click({ Start-Process explorer.exe $trabajosDir; $frmWork.Close() })
        $frmWork.Controls.Add($btnWRaiz)

        $btnWCancelar = New-Object System.Windows.Forms.Button
        $btnWCancelar.Text="CERRAR"; $btnWCancelar.Location=New-Object System.Drawing.Point(344,325)
        $btnWCancelar.Size=New-Object System.Drawing.Size(110,38); $btnWCancelar.FlatStyle="Flat"
        $btnWCancelar.ForeColor=[System.Drawing.Color]::Gray
        $btnWCancelar.FlatAppearance.BorderColor=[System.Drawing.Color]::Gray
        $btnWCancelar.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
        $btnWCancelar.Font=New-Object System.Drawing.Font("Segoe UI",9)
        $btnWCancelar.Add_Click({ $frmWork.Close() })
        $frmWork.Controls.Add($btnWCancelar)

        $frmWork.ShowDialog() | Out-Null

        if (-not $script:workOK -or $lbxWork.SelectedIndex -lt 0) {
            GenLog "[~] Cancelado."; return
        }

        $selCarpeta = $carpetas[$lbxWork.SelectedIndex]
        Start-Process explorer.exe $selCarpeta.FullName
        GenLog "[OK] Abierta: $($selCarpeta.FullName)"

    } catch { GenLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="ABRIR CARPETA TRABAJO" }
})


# EFS SAMSUNG SIM 2
$btnEFSDirec.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "EFS Image (*.img;*.bin)|*.img;*.bin|Todos|*.*"
    $fd.Title = "Selecciona archivo EFS Samsung (efs.img / efs.bin)"
    if ($fd.ShowDialog() -ne "OK") { return }
    $Global:_efsPath = $fd.FileName
    $Global:_efsRoot = $script:SCRIPT_ROOT
    $fn = [System.IO.Path]::GetFileName($Global:_efsPath)
    $fs = (Get-Item $Global:_efsPath).Length
    GenLog "`r`n[*] ===== EFS SAMSUNG SIM 2 ====="
    GenLog "[*] Archivo : $fn ($([math]::Round($fs/1KB,2)) KB)"
    GenLog "[~] Editando imagen EFS directamente (sin ADB, sin montar)..."
    $Global:_btnEfsDirec = $btnEFSDirec
    $Global:_btnEfsDirec.Enabled = $false
    $Global:_btnEfsDirec.Text = "PROCESANDO..."
    $stamp = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
    $backDir = [System.IO.Path]::Combine($Global:_efsRoot, "BACKUPS", "EFS_SAMSUNG_SIM2", $stamp)
    [EfsPatcher]::Run($Global:_efsPath, $backDir)
    $Global:_efsDirTimer = New-Object System.Windows.Forms.Timer
    $Global:_efsDirTimer.Interval = 400
    $Global:_efsDirTimer.Add_Tick({
        $msg = ""
        while ([EfsPatcher]::Q.TryDequeue([ref]$msg)) { GenLog $msg }
        if ([EfsPatcher]::Done) {
            $Global:_efsDirTimer.Stop(); $Global:_efsDirTimer.Dispose()
            $Global:_btnEfsDirec.Enabled = $true
            $Global:_btnEfsDirec.Text = "EFS SAMSUNG SIM 2"
        }
    })
    $Global:_efsDirTimer.Start()
})

# PERSIST MI ACCOUNT
$btnPersist.Add_Click({
    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Filter = "Persist Image (*.img;*.bin)|*.img;*.bin|Todos|*.*"
    $fd.Title = "Selecciona archivo Persist Xiaomi (persist.img / persist.bin)"
    if ($fd.ShowDialog() -ne "OK") { return }
    $Global:_persistPath = $fd.FileName
    $Global:_persistRoot = $script:SCRIPT_ROOT
    $fn = [System.IO.Path]::GetFileName($Global:_persistPath)
    $fs = (Get-Item $Global:_persistPath).Length
    GenLog "`r`n[*] ===== PERSIST MI ACCOUNT ====="
    GenLog "[*] Archivo : $fn ($([math]::Round($fs/1KB,2)) KB)"
    GenLog "[~] Navegando ext4 (superblock->inode->fdsd->st->rn)..."
    $Global:_btnPersist = $btnPersist
    $Global:_btnPersist.Enabled = $false
    $Global:_btnPersist.Text = "PROCESANDO..."
    $stamp = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
    $backDir = [System.IO.Path]::Combine($Global:_persistRoot, "BACKUPS", "PERSIST_MI_ACCOUNT", $stamp)
    [PersistPatcher]::Run($Global:_persistPath, $backDir)
    $Global:_persistTimer = New-Object System.Windows.Forms.Timer
    $Global:_persistTimer.Interval = 400
    $Global:_persistTimer.Add_Tick({
        $msg = ""
        while ([PersistPatcher]::Q.TryDequeue([ref]$msg)) { GenLog $msg }
        if ([PersistPatcher]::Done) {
            $Global:_persistTimer.Stop(); $Global:_persistTimer.Dispose()
            $Global:_btnPersist.Enabled = $true
            $Global:_btnPersist.Text = "PERSIST MI ACCOUNT"
        }
    })
    $Global:_persistTimer.Start()
})

#=================================================================# ACTIVAR RESET / MISC MOTOROLA (btnsG2[4])
# Parcha misc.bin para habilitar opciones de recovery en Motorola
# Inserta los bytes de boot-recovery + wipe_data + wipe_cache en offset 0x00
#==========================================================================
$btnRepairNV.Add_Click({
    $btn = $btnRepairNV
    $btn.Enabled = $false; $btn.Text = "PARCHEANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        GenLog ""
        GenLog "[*] =========================================="
        GenLog "[*] ACTIVAR RESET / MISC MOTOROLA - RNX TOOL PRO"
        GenLog "[*] Parcha misc.bin para activar recovery"
        GenLog "[*] =========================================="
        GenLog ""

        # ---- Selector de archivo ----
        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Title  = "Selecciona el archivo misc.bin a parchear"
        $fd.Filter = "misc.bin|misc.bin;misc*.bin|Binarios (*.bin)|*.bin|Todos|*.*"
        if ($fd.ShowDialog() -ne "OK") { GenLog "[~] Cancelado."; return }

        $miscPath = $fd.FileName
        $miscName = [System.IO.Path]::GetFileName($miscPath)
        $miscDir  = [System.IO.Path]::GetDirectoryName($miscPath)
        $miscSz   = (Get-Item $miscPath).Length
        GenLog "[+] Archivo : $miscPath"
        GenLog "[+] Tamano  : $miscSz bytes"
        GenLog ""

        # ---- Validacion minima de tamano (misc.bin Motorola tipicamente 1MB o 4MB) ----
        if ($miscSz -lt 160) {
            GenLog "[!] Archivo demasiado pequeno ($miscSz bytes). Verifica que sea misc.bin correcto."
            return
        }

        # ---- Leer archivo ----
        $bytes = [System.IO.File]::ReadAllBytes($miscPath)
        GenLog "[~] Archivo leido OK ($($bytes.Length) bytes)"

        # ---- SHA256 original ----
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashOrig = [BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace "-",""
        GenLog "[+] SHA256 original : $hashOrig"
        GenLog ""

        # ---- Verificar si ya esta parcheado ----
        # Los primeros 13 bytes deben ser "boot-recovery" = 62 6F 6F 74 2D 72 65 63 6F 76 65 72 79
        $bootRecovery = @(0x62,0x6F,0x6F,0x74,0x2D,0x72,0x65,0x63,0x6F,0x76,0x65,0x72,0x79)
        $yaParcheado = $true
        for ($ci=0; $ci -lt $bootRecovery.Count; $ci++) {
            if ($bytes[$ci] -ne $bootRecovery[$ci]) { $yaParcheado = $false; break }
        }
        if ($yaParcheado) {
            GenLog "[~] El archivo YA contiene el patron boot-recovery."
            $overwrite = [System.Windows.Forms.MessageBox]::Show(
                "misc.bin ya parece estar parcheado (contiene 'boot-recovery' al inicio).`n`nSobrescribir de todas formas?",
                "Ya parcheado", "YesNo", "Warning")
            if ($overwrite -ne "Yes") { GenLog "[~] Cancelado."; return }
        }

        # ---- Backup con SHA256 ----
        $stamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $bakDir = Join-Path (Join-Path $script:SCRIPT_ROOT "BACKUPS") "ACTIVAR RESET MISC MOTOROLA\$stamp"
        New-Item $bakDir -ItemType Directory -Force | Out-Null
        $bakPath = Join-Path $bakDir ($miscName + ".bak")
        [System.IO.File]::WriteAllBytes($bakPath, $bytes)
        $hashBak = [BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace "-",""
        Set-Content (Join-Path $bakDir ($miscName + ".bak.sha256.txt")) $hashBak
        GenLog "[+] Backup guardado : $bakPath"
        GenLog "[+] SHA256 backup   : $hashBak"
        GenLog ""

        # ---- Construir payload (160 bytes = 3 bloques de 64 bytes) ----
        # Bloque 1 (offset 0x00, 64 bytes): "boot-recovery" + zeros hasta completar 64
        # Bloque 2 (offset 0x40, 64 bytes): "recovery\n--wipe_data" + zeros hasta 64
        # Bloque 3 (offset 0x80, 32 bytes): "recovery\n--wipe_cache" + zeros hasta 32
        # (segun imagen HxD: total 0xA0 = 160 bytes modificados)

        $payload = [byte[]]::new(160)  # 160 bytes, todos 0x00 por defecto

        # Bloque 1: "boot-recovery" = 13 bytes en ASCII
        $str1 = [System.Text.Encoding]::ASCII.GetBytes("boot-recovery")
        [Array]::Copy($str1, 0, $payload, 0x00, $str1.Length)

        # Bloque 2 (offset 0x40 = 64): "recovery\n--wipe_data" = 20 bytes
        $str2 = [System.Text.Encoding]::ASCII.GetBytes("recovery`n--wipe_data")
        [Array]::Copy($str2, 0, $payload, 0x40, $str2.Length)

        # Bloque 3 (offset 0x80 = 128): "recovery\n--wipe_cache" = 21 bytes
        $str3 = [System.Text.Encoding]::ASCII.GetBytes("recovery`n--wipe_cache")
        [Array]::Copy($str3, 0, $payload, 0x80, $str3.Length)

        GenLog "[~] Payload de 160 bytes construido:"
        GenLog "    0x00: boot-recovery ($($str1.Length) bytes)"
        GenLog "    0x40: recovery + --wipe_data ($($str2.Length) bytes)"
        GenLog "    0x80: recovery + --wipe_cache ($($str3.Length) bytes)"
        GenLog ""

        # ---- Aplicar payload al archivo (sobreescribir bytes 0x00 a 0x9F) ----
        [Array]::Copy($payload, 0, $bytes, 0, $payload.Length)

        # ---- SHA256 resultado ----
        $hashNew = [BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace "-",""
        GenLog "[+] SHA256 parcheado: $hashNew"

        # ---- Guardar archivo parcheado ----
        $outName  = [System.IO.Path]::GetFileNameWithoutExtension($miscName) + "_patched.bin"
        $outPath  = Join-Path $bakDir $outName
        [System.IO.File]::WriteAllBytes($outPath, $bytes)
        Set-Content (Join-Path $bakDir ($outName + ".sha256.txt")) $hashNew
        # Copia adicional en carpeta original del archivo fuente
        try { [System.IO.File]::WriteAllBytes((Join-Path $miscDir $outName), $bytes) } catch {}

        # ---- Guardar meta ----
        $meta = @"
RNX TOOL PRO - MISC MOTOROLA PATCH
Fecha       : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
Original    : $miscPath
Backup      : $bakPath
Parcheado   : $outPath
SHA256 orig : $hashOrig
SHA256 new  : $hashNew
Payload     : 160 bytes (boot-recovery + recovery/wipe_data + recovery/wipe_cache)
"@
        Set-Content (Join-Path $bakDir "patch_info.txt") $meta

        GenLog ""
        GenLog "[OK] =========================================="
        GenLog "[OK] MISC.BIN PARCHEADO CORRECTAMENTE"
        GenLog "[OK] =========================================="
        GenLog "     Original : $miscName"
        GenLog "     Parcheado: $outName"
        GenLog "     Backup   : $bakPath"
        GenLog ""
        GenLog "[~] Proximos pasos:"
        GenLog "    1. Flashea $outName a la particion misc via EDL o fastboot"
        GenLog "    2. fastboot flash misc $outName"
        GenLog "    3. O usa EDL -> Flashear Particion -> misc"
        GenLog ""

        $abrir = [System.Windows.Forms.MessageBox]::Show(
            "misc.bin parcheado correctamente.`n`nArchivo: $outName`nBackup: $bakPath`n`nAbrir carpeta?",
            "MISC PARCHEADO", "YesNo", "Information")
        if ($abrir -eq "Yes") { Start-Process explorer.exe $miscDir }

    } catch { GenLog "[!] Error: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "ACTIVAR RESET / MISC MOTOROLA" }
})

#==========================================================================
# FLASH PARTICION IMG (btnsG2[5])
# Selector de archivo .img + nombre de particion -> flash via Fastboot o ADB
#==========================================================================
$btnFlashPart.Add_Click({
    $btn = $btnFlashPart
    $btn.Enabled = $false; $btn.Text = "EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        GenLog ""
        GenLog "[*] =========================================="
        GenLog "[*] FLASH PARTICION IMG - RNX TOOL PRO"
        GenLog "[*] =========================================="
        GenLog ""
        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "Imagen de particion (*.img;*.bin)|*.img;*.bin|Todos|*.*"
        $fd.Title = "Selecciona imagen de particion (.img)"
        if ($fd.ShowDialog() -ne "OK") { GenLog "[~] Cancelado."; return }
        $imgPath = $fd.FileName
        $imgName = [System.IO.Path]::GetFileName($imgPath)
        $imgSz = [math]::Round((Get-Item $imgPath).Length / 1MB, 2)
        GenLog "[+] Archivo : $imgName ($imgSz MB)"
        Add-Type -AssemblyName Microsoft.VisualBasic
        $partName = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Nombre exacto de la particion a flashear:`n(ej: system, vendor, product, boot, recovery, modem, efs, nvdata...)",
            "FLASH PARTICION IMG",
            [System.IO.Path]::GetFileNameWithoutExtension($imgPath)
        )
        if (-not $partName -or -not $partName.Trim()) { GenLog "[~] Cancelado."; return }
        $partName = $partName.Trim()
        GenLog "[+] Particion: $partName"
        GenLog ""
        $fbExe = Get-FastbootExe
        $fbDev = if ($fbExe) { (& $fbExe devices 2>$null) -join "" } else { "" }
        $adbDev = (& adb devices 2>$null) -join ""
        if ($fbDev -imatch "\tfastboot") {
            GenLog "[+] Modo Fastboot - flasheando $partName ..."
            $ec = Invoke-FastbootLive "flash $partName `"$imgPath`""
            if ($ec -eq 0) {
                GenLog ""
                GenLog "[OK] Particion '$partName' flasheada correctamente."
            } else { GenLog "[!] Flash termino con codigo: $ec" }
        } elseif ($adbDev -imatch "`tdevice") {
            GenLog "[+] Modo ADB - verificando root para dd-flash..."
            $rootCheck = (& adb shell "su -c id" 2>$null) -join ""
            if ($rootCheck -notmatch "uid=0") {
                GenLog "[!] ROOT requerido para flashear via ADB."
                GenLog "[~] Reinicia en fastboot (adb reboot bootloader) y vuelve a intentar."
                return
            }
            $remotePath = "/data/local/tmp/rnx_part.img"
            GenLog "[~] Copiando imagen al dispositivo..."
            & adb push "$imgPath" $remotePath 2>$null | Out-Null
            GenLog "[~] Buscando particion en /dev/block/by-name/$partName ..."
            $partDev = (& adb shell "su -c 'readlink -f /dev/block/by-name/$partName 2>/dev/null'" 2>$null) -join ""
            $partDev = $partDev.Trim()
            if (-not $partDev) { $partDev = "/dev/block/by-name/$partName" }
            GenLog "[+] Dispositivo de bloque: $partDev"
            GenLog "[~] Ejecutando dd (puede tardar segun tamano)..."
            $ddOut = (& adb shell "su -c 'dd if=$remotePath of=$partDev bs=4096 conv=fsync 2>&1'" 2>$null) -join "`n"
            foreach ($dl in ($ddOut -split "`n")) { $dl=$dl.Trim(); if ($dl) { GenLog "  $dl" } }
            & adb shell "su -c 'rm -f $remotePath'" 2>$null | Out-Null
            if ($ddOut -imatch "records out|bytes") {
                GenLog ""
                GenLog "[OK] Particion '$partName' flasheada correctamente via dd."
            } else { GenLog "[~] Verifica el log - no se confirmo escritura completa." }
        } else {
            GenLog "[!] No se detecta dispositivo ADB ni Fastboot."
            GenLog "    Conecta el equipo y reintenta."
        }
    } catch { GenLog "[!] Error inesperado: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "FLASH PARTICION IMG" }
})

#==========================================================================
# NOTE: btnWinUSB handler removed (Samsung tab replaced)