#==========================================================================
# 07_tab_fastboot.ps1 - TAB XIAOMI UTILS
# Reemplaza la tab FASTBOOT anterior
# Contiene:
#   [BLOQUE 1] INFO Y CONTROL (Cyan)
#              - Leer Info Dinamico (ADB/Fastboot/Sideload auto-detect)
#              - Ver Slot Activo (detallado)
#              - Ver A/R Anti-Rollback (detallado)
#              - Ver Estado Cuenta Mi
#   [BLOQUE 2] FASTBOOT / ENG ROM (Orange)
#              - Cambiar Slot Activo (dropdown A/B)
#              - Fix System Destroyed (fastboot oem erase-vb-index)
#              - Borrar EFS (fsg, modemst1, modemst2 automatico)
#              - Borrar/Escribir Particion Independiente (mini UI + checkboxes)
#   [BLOQUE 3] FUNCIONES ADB (Lime)
#              - Activar DIAG (logica migrada desde tab ADB)
#              - Debloat Xiaomi (logica migrada desde tab ADB)
#              - Lanzar Xiaomi Utils (XiaomiIMEITools.exe)
#              - Mini interfase descarga de firmwares
#
# Helpers reutilizados: FbLog, Get-FastbootExe, Invoke-Fastboot,
#                       Invoke-FastbootLive, Check-Fastboot,
#                       Check-ADB, AdbLog, Get-XiaomiCodename
#==========================================================================

# =========================================================================
# FUNCIONES AUXILIARES (compatibilidad con funciones ya definidas en otros
# modulos - solo se definen si no existen)
# =========================================================================

# FbLog ya debe estar definida en 09_logger.ps1
# Get-FastbootExe, Invoke-Fastboot, Invoke-FastbootLive, Check-Fastboot
# ya definidas en este mismo archivo (se mantienen de la version anterior)

# ---- Tabla codename Xiaomi/Redmi/POCO (ro.product.device -> codename) ----
# (Mantenida de la version anterior para compatibilidad)
if (-not (Get-Command "Get-XiaomiCodename" -ErrorAction SilentlyContinue)) {
    function Get-XiaomiCodename($device) {
        if (-not $device -or $device -eq "") { return "" }
        $d = $device.ToLower().Trim()
        $map = @{
            "vayu"="POCO X3 Pro"; "bhima"="POCO X3 Pro (IN)"; "surya"="POCO X3 NFC"
            "karna"="POCO X3 (IN)"; "veux"="POCO X4 Pro 5G"; "ares"="POCO X5 Pro 5G"
            "marble"="POCO X5 Pro 5G (alt)"; "camellia"="POCO M3 Pro 5G"
            "citrus"="POCO M2 Pro"; "gram"="POCO M4 Pro"; "fleur"="POCO M4 Pro 5G"
            "light"="POCO M5"; "earth"="POCO M5s"; "fog"="POCO M4 5G"
            "lmi"="POCO F2 Pro"; "phoenix"="POCO F1 (Pocophone)"; "alioth"="POCO X3 GT / Redmi K40 / Mi 11X"
            "spes"="Redmi Note 11 4G"; "spesn"="Redmi Note 11 NFC"
            "sapphire"="Redmi Note 13 5G"; "emerald"="Redmi Note 12 5G"
            "tapas"="Redmi Note 12 4G"; "sweet"="Redmi Note 10 Pro"
            "curtana"="Redmi Note 9 Pro"; "merlin"="Redmi Note 9 4G"
            "cannon"="Redmi Note 9"; "ginkgo"="Redmi Note 8"; "violet"="Redmi Note 7 Pro"
            "lavender"="Redmi Note 7"; "whyred"="Redmi Note 5 Pro"
            "begonia"="Redmi Note 8 Pro"; "star"="Redmi Note 10 5G"
            "lancelot"="Redmi 9"; "angelica"="Redmi 9A/9C"; "carbon"="Redmi 10"
            "wind"="Redmi 10C"; "ice"="Redmi 12C"; "sky"="Redmi 12"
            "apollo"="Mi 10T / Redmi K30S"; "ingres"="Mi 11T Pro"; "agate"="Mi 11T"
            "haydn"="Mi 11 Ultra"; "venus"="Mi 11 Pro"; "fuxi"="Xiaomi 13"
            "nuwa"="Xiaomi 13 Pro"; "ishtar"="Xiaomi 13T"; "corot"="Xiaomi 13T Pro"
            "houji"="Xiaomi 14"; "shennong"="Xiaomi 14 Pro"
        }
        if ($map.ContainsKey($d)) { return $map[$d] }
        return $d
    }
}

# ---- Motor Fastboot sincronico ----
function Invoke-Fastboot($fbArgs) {
    $fbExe = Get-FastbootExe
    if (-not $fbExe) { FbLog "[!] fastboot.exe no encontrado"; return $null }
    try {
        $tmpF2 = [System.IO.Path]::GetTempFileName()
        & cmd.exe /c "`"$fbExe`" $fbArgs > `"$tmpF2`" 2>&1"
        $res2 = if (Test-Path $tmpF2) {
            [System.IO.File]::ReadAllText($tmpF2, [System.Text.Encoding]::UTF8)
        } else { "" }
        try { Remove-Item $tmpF2 -Force -EA SilentlyContinue } catch {}
        return $res2.Trim()
    } catch { FbLog "[!] Error ejecutando fastboot: $_"; return $null }
}

# ---- Motor Fastboot live (linea a linea, para flash/wipe) ----
function Invoke-FastbootLive($fbArgs) {
    $fbExe = Get-FastbootExe
    if (-not $fbExe) { FbLog "[!] fastboot.exe no encontrado"; return -1 }
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $fbExe
        $psi.Arguments = $fbArgs
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute  = $false
        $psi.CreateNoWindow   = $true
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $psi
        $errQ = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
        $p.add_ErrorDataReceived({ param($s,$e); if ($e.Data) { $errQ.Enqueue($e.Data) } })
        $p.Start() | Out-Null
        $p.BeginErrorReadLine()
        $script:FB_ACTIVE_PROC = $p
        if ($Global:fbBtnStop) { $Global:fbBtnStop.Enabled = $true }
        while (-not $p.StandardOutput.EndOfStream) {
            $line = $p.StandardOutput.ReadLine()
            if ($line.Trim()) { FbLog " $line" }
            $eq = ""
            while ($errQ.TryDequeue([ref]$eq)) { if ($eq.Trim()) { FbLog " $eq" } }
            [System.Windows.Forms.Application]::DoEvents()
            if ($p.HasExited) { break }
        }
        $p.WaitForExit()
        $eq = ""
        while ($errQ.TryDequeue([ref]$eq)) { if ($eq.Trim()) { FbLog " $eq" } }
        return $p.ExitCode
    } catch { FbLog "[!] Error: $_"; return -1 }
    finally {
        $script:FB_ACTIVE_PROC = $null
        if ($Global:fbBtnStop) { $Global:fbBtnStop.Enabled = $false }
    }
}

# ---- Helper: obtener fastboot.exe path ----
function Get-FastbootExe {
    $candidates = @(
        (Join-Path $script:TOOLS_DIR "fastboot.exe"),
        (Join-Path $script:SCRIPT_ROOT "fastboot.exe"),
        ".\fastboot.exe",
        "$env:ProgramFiles\Minimal ADB and Fastboot\fastboot.exe",
        "${env:ProgramFiles(x86)}\Minimal ADB and Fastboot\fastboot.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\fastboot.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\fastboot.exe",
        "C:\platform-tools\fastboot.exe",
        "C:\adb\fastboot.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c -EA SilentlyContinue)) { return $c }
    }
    foreach ($dir in ($env:PATH -split ";")) {
        $full = Join-Path $dir.Trim() "fastboot.exe"
        if (Test-Path $full -EA SilentlyContinue) { return $full }
    }
    try { $gc = Get-Command "fastboot" -EA SilentlyContinue; if ($gc) { return $gc.Source } } catch {}
    return $null
}

# ---- Check: dispositivo fastboot disponible ----
function Check-Fastboot {
    $fbExe = Get-FastbootExe
    if (-not $fbExe) {
        FbLog "[!] fastboot.exe no encontrado."
        FbLog "    Coloca fastboot.exe en la carpeta tools\ del script"
        return $false
    }
    $devOut = Invoke-Fastboot "devices"
    if (-not $devOut -or $devOut -notmatch "\tfastboot") {
        FbLog "[!] No hay dispositivo en modo Fastboot."
        FbLog "    Ejecuta: adb reboot bootloader"
        return $false
    }
    return $true
}

#==========================================================================
# CONSTRUCCION UI - TAB XIAOMI UTILS
# Layout: 2 columnas simetricas (igual al resto de tabs)
# Col izq x=6  ancho=422 : 3 grupos de botones
# Col der x=436 ancho=422 : STOP + Log
# Metricas identicas a ADB/Generales/Control:
#   BW=195 BH=50 PX=14 PY=20 GX=8 GY=8 GW=422
#==========================================================================

$tabFb = New-Object Windows.Forms.TabPage
$tabFb.Text       = "XIAOMI UTILS"
$tabFb.BackColor  = [System.Drawing.Color]::FromArgb(30,30,30)
$tabs.TabPages.Add($tabFb)

# Metricas
$FB_PAD  = 6
$FB_GW   = 422
$FB_GAP  = 8
$FB_BW   = 195
$FB_BH   = 46
$FB_PX   = 14
$FB_PY   = 20
$FB_GX   = 8
$FB_GY   = 6
$FB_BFULL = $FB_BW*2 + $FB_GX
$FB_COL2  = $FB_PAD + $FB_GW + $FB_GAP   # x=436

# Alturas de grupos:
# G1 INFO Y CONTROL   : 2 filas (4 botones)
# G2 FASTBOOT/ENG ROM : 2 filas (4 botones)
# G3 FUNCIONES ADB    : 2 filas (4 botones)

$fbG1H = $FB_PY + 2*($FB_BH+$FB_GY) - $FB_GY + 14
$fbG2H = $FB_PY + 2*($FB_BH+$FB_GY) - $FB_GY + 14
$fbG3H = $FB_PY + 2*($FB_BH+$FB_GY) - $FB_GY + 14

$fbG1Y = $FB_PAD
$fbG2Y = $fbG1Y + $fbG1H + $FB_GAP
$fbG3Y = $fbG2Y + $fbG2H + $FB_GAP

# ---- BLOQUE 1: INFO Y CONTROL ----
$fbGrp1 = New-GBox $tabFb "BLOQUE 1 - INFO Y CONTROL" $FB_PAD $fbG1Y $FB_GW $fbG1H "Cyan"

$fbBtnLeerInfo   = New-FlatBtn $fbGrp1 "LEER INFO DINAMICO"        "Cyan"   $FB_PX                    $FB_PY                  $FB_BW $FB_BH
$fbBtnSlotVer    = New-FlatBtn $fbGrp1 "VER SLOT ACTIVO"           "Cyan"   ($FB_PX+$FB_BW+$FB_GX)   $FB_PY                  $FB_BW $FB_BH
$fbBtnAntiRB     = New-FlatBtn $fbGrp1 "VER A/R ANTI-ROLLBACK"     "Cyan"   $FB_PX                    ($FB_PY+$FB_BH+$FB_GY)  $FB_BW $FB_BH
$fbBtnMiAccount  = New-FlatBtn $fbGrp1 "VER ESTADO CUENTA MI"      "Cyan"   ($FB_PX+$FB_BW+$FB_GX)   ($FB_PY+$FB_BH+$FB_GY)  $FB_BW $FB_BH

# ---- BLOQUE 2: FASTBOOT / ENG ROM ----
$fbGrp2 = New-GBox $tabFb "BLOQUE 2 - FASTBOOT / ENG ROM" $FB_PAD $fbG2Y $FB_GW $fbG2H "Orange"

$fbBtnCambiarSlot = New-FlatBtn $fbGrp2 "CAMBIAR SLOT ACTIVO v"    "Orange" $FB_PX                    $FB_PY                  $FB_BW $FB_BH
$fbBtnFixSys      = New-FlatBtn $fbGrp2 "FIX SYSTEM DESTROYED"     "Orange" ($FB_PX+$FB_BW+$FB_GX)   $FB_PY                  $FB_BW $FB_BH
$fbBtnBorrarEFS   = New-FlatBtn $fbGrp2 "BORRAR EFS"               "Red"    $FB_PX                    ($FB_PY+$FB_BH+$FB_GY)  $FB_BW $FB_BH
$fbBtnPartMgr     = New-FlatBtn $fbGrp2 "BORRAR / ESCRIBIR PART."  "Orange" ($FB_PX+$FB_BW+$FB_GX)   ($FB_PY+$FB_BH+$FB_GY)  $FB_BW $FB_BH

# Ajuste visual boton rojo EFS
$fbBtnBorrarEFS.BackColor                  = [System.Drawing.Color]::FromArgb(50,15,15)
$fbBtnBorrarEFS.FlatAppearance.BorderColor = [System.Drawing.Color]::Red

# ---- BLOQUE 3: FUNCIONES ADB ----
$fbGrp3 = New-GBox $tabFb "BLOQUE 3 - FUNCIONES ADB / XIAOMI" $FB_PAD $fbG3Y $FB_GW $fbG3H "Lime"

$fbBtnActivarDiag = New-FlatBtn $fbGrp3 "ACTIVAR DIAG"             "Lime"   $FB_PX                    $FB_PY                  $FB_BW $FB_BH
$fbBtnDebloat     = New-FlatBtn $fbGrp3 "DEBLOAT XIAOMI"           "Lime"   ($FB_PX+$FB_BW+$FB_GX)   $FB_PY                  $FB_BW $FB_BH
$fbBtnXiaoUtils   = New-FlatBtn $fbGrp3 "XIAOMI IMEI TOOLS"        "Yellow" $FB_PX                    ($FB_PY+$FB_BH+$FB_GY)  $FB_BW $FB_BH
$fbBtnFirmDL      = New-FlatBtn $fbGrp3 "DESCARGA DE FIRMWARES"    "Lime"   ($FB_PX+$FB_BW+$FB_GX)   ($FB_PY+$FB_BH+$FB_GY)  $FB_BW $FB_BH

# Ajuste visual boton amarillo XiaomiUtils
$fbBtnXiaoUtils.BackColor                  = [System.Drawing.Color]::FromArgb(40,38,10)
$fbBtnXiaoUtils.FlatAppearance.BorderColor = [System.Drawing.Color]::Yellow

# ---- COLUMNA DERECHA: STOP + Log ----
$fbStopH   = 28
$fbStopGap = 4
$fbLogReal = $FB_PAD + $fbStopH + $fbStopGap
$fbLogH    = 628 - $fbLogReal - $FB_PAD

$fbBtnStop = New-Object Windows.Forms.Button
$fbBtnStop.Text     = "STOP"
$fbBtnStop.Location = New-Object System.Drawing.Point($FB_COL2, $FB_PAD)
$fbBtnStop.Size     = New-Object System.Drawing.Size($FB_GW, $fbStopH)
$fbBtnStop.FlatStyle = "Flat"
$fbBtnStop.ForeColor = [System.Drawing.Color]::White
$fbBtnStop.BackColor = [System.Drawing.Color]::FromArgb(45,20,20)
$fbBtnStop.FlatAppearance.BorderColor = [System.Drawing.Color]::White
$fbBtnStop.Font    = New-Object System.Drawing.Font("Segoe UI",9.5,[System.Drawing.FontStyle]::Bold)
$fbBtnStop.Enabled = $false
$tabFb.Controls.Add($fbBtnStop)

$Global:logFb = New-Object Windows.Forms.TextBox
$Global:logFb.Multiline    = $true
$Global:logFb.Location     = New-Object System.Drawing.Point($FB_COL2, $fbLogReal)
$Global:logFb.Size         = New-Object System.Drawing.Size($FB_GW, $fbLogH)
$Global:logFb.BackColor    = "Black"
$Global:logFb.ForeColor    = [System.Drawing.Color]::Cyan
$Global:logFb.BorderStyle  = "FixedSingle"
$Global:logFb.ScrollBars   = "Vertical"
$Global:logFb.Font         = New-Object System.Drawing.Font("Consolas",8.5)
$Global:logFb.ReadOnly     = $true
$tabFb.Controls.Add($Global:logFb)

$ctxFb        = New-Object System.Windows.Forms.ContextMenuStrip
$mnuClearFb   = $ctxFb.Items.Add("Limpiar Log")
$mnuClearFb.Font     = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$mnuClearFb.ForeColor = [System.Drawing.Color]::OrangeRed
$mnuClearFb.Add_Click({ $Global:logFb.Clear() })
$Global:logFb.ContextMenuStrip = $ctxFb

$script:FB_ACTIVE_PROC = $null
$Global:fbBtnStop      = $fbBtnStop

#==========================================================================
# LOGICA - STOP
#==========================================================================
$fbBtnStop.Add_Click({
    if ($script:FB_ACTIVE_PROC -and -not $script:FB_ACTIVE_PROC.HasExited) {
        try {
            $script:FB_ACTIVE_PROC.Kill()
            FbLog ""
            FbLog "[!] Proceso detenido por el usuario."
        } catch { FbLog "[!] No se pudo detener: $_" }
    } else { FbLog "[~] No hay proceso activo que detener." }
    $fbBtnStop.Enabled = $false
})

#==========================================================================
# BLOQUE 1 - LOGICA
#==========================================================================

# --------------------------------------------------------------------------
# Helper: deteccion automatica de modo (ADB / Fastboot / Sideload)
# Devuelve: "adb", "fastboot", "sideload" o $null
# --------------------------------------------------------------------------
function Detect-DeviceMode {
    # 1. ADB
    $adbDevs = (& adb devices 2>$null) | Where-Object { $_ -match "\tdevice$" }
    if ($adbDevs) { return "adb" }

    # 2. Sideload
    $adbSide = (& adb devices 2>$null) | Where-Object { $_ -match "\tsideload" }
    if ($adbSide) { return "sideload" }

    # 3. Fastboot
    $fbExe = Get-FastbootExe
    if ($fbExe) {
        $fbDevs = (& cmd.exe /c "`"$fbExe`" devices" 2>$null) | Where-Object { $_ -match "\tfastboot" }
        if ($fbDevs) { return "fastboot" }
    }
    return $null
}

# --------------------------------------------------------------------------
# Helper: SafeShell para comandos ADB shell
# --------------------------------------------------------------------------
function SafeShellXu { param($cmd)
    $r = & adb shell $cmd 2>$null
    if ($null -eq $r) { return "" }
    if ($r -is [array]) { return ($r -join " ").Trim() }
    return $r.ToString().Trim()
}

# --------------------------------------------------------------------------
# BOTON: LEER INFO DINAMICO
# Auto-detecta modo ADB / Fastboot / Sideload y muestra info completa
# --------------------------------------------------------------------------
$fbBtnLeerInfo.Add_Click({
    $btn = $fbBtnLeerInfo
    $btn.Enabled = $false; $btn.Text = "DETECTANDO..."
    $Global:logFb.Clear()
    FbLog "[~] Detectando modo del dispositivo..."
    [System.Windows.Forms.Application]::DoEvents()

    $modo = Detect-DeviceMode

    if (-not $modo) {
        FbLog "[!] No se detecta ningun dispositivo."
        FbLog "    - En modo ADB     : activa USB Debugging y conecta"
        FbLog "    - En modo Fastboot: mantiene Vol- al encender"
        FbLog "    - En modo Sideload: recovery -> Apply update -> ADB sideload"
        $btn.Enabled = $true; $btn.Text = "LEER INFO DINAMICO"
        return
    }

    FbLog "[+] Modo detectado: $($modo.ToUpper())"
    FbLog ""

    # ---- MODO ADB ----
    if ($modo -eq "adb") {
        FbLog "=============================================="
        FbLog " INFO DISPOSITIVO - MODO ADB"
        FbLog "=============================================="
        FbLog ""
        try {
            $brand    = (SafeShellXu "getprop ro.product.brand").ToUpper()
            $model    = SafeShellXu "getprop ro.product.model"
            $deviceId = (SafeShellXu "getprop ro.product.device").ToUpper()
            $android  = SafeShellXu "getprop ro.build.version.release"
            $patch    = SafeShellXu "getprop ro.build.version.security_patch"
            $build    = SafeShellXu "getprop ro.build.display.id"
            $serial   = (& adb get-serialno 2>$null)
            if ($serial -is [array]) { $serial = $serial[0].Trim() } else { $serial = "$serial".Trim() }
            $miuiVer  = SafeShellXu "getprop ro.miui.ui.version.name"
            $region   = SafeShellXu "getprop ro.miui.region"
            $blLock   = SafeShellXu "getprop ro.boot.flash.locked"
            $vbs      = SafeShellXu "getprop ro.boot.verifiedbootstate"
            $antiRaw  = SafeShellXu "getprop ro.boot.anti_version"
            $blStr    = if ($blLock -eq "1") { "LOCKED" } else { "UNLOCKED" }
            $codename = Get-XiaomiCodename $deviceId

            # Deteccion IMEI
            $imeiRaw = SafeShellXu "service call iphonesubinfo 1"
            $imei = "UNKNOWN"
            if ($imeiRaw -match "[0-9]{15}") { $imei = $Matches[0] }

            FbLog " MARCA        : $brand"
            FbLog " MODELO       : $model"
            if ($codename -ne "" -and $codename -ne $deviceId) {
                FbLog " CODENAME     : $codename"
            }
            FbLog " ANDROID      : $android"
            FbLog " PARCHE SEG.  : $patch"
            FbLog " BUILD        : $build"
            if ($miuiVer -ne "") { FbLog " MIUI VERSION : $miuiVer" }
            if ($region -ne "")  { FbLog " REGION MIUI  : $region" }
            FbLog " SERIAL       : $serial"
            FbLog " IMEI         : $imei"
            FbLog ""
            FbLog " BL LOCK      : $blStr"
            FbLog " BOOT STATE   : $vbs"
            if ($antiRaw -ne "" -and $antiRaw -match "^\d+$") {
                FbLog " ANTI-ROLLBACK: $antiRaw"
            }
            FbLog ""
            FbLog "=============================================="
            FbLog "[OK] LECTURA ADB COMPLETADA"

            # Actualizar sidebar
            $Global:lblModo.Text    = "MODO : ADB"
            $Global:lblModo.ForeColor = [System.Drawing.Color]::Cyan
            $Global:lblDisp.Text    = "DISPOSITIVO : $brand"
            $Global:lblModel.Text   = "MODELO : $model"
            $Global:lblSerial.Text  = "SERIAL : $serial"
        } catch { FbLog "[!] Error leyendo ADB: $_" }
    }

    # ---- MODO FASTBOOT ----
    elseif ($modo -eq "fastboot") {
        FbLog "=============================================="
        FbLog " INFO DISPOSITIVO - MODO FASTBOOT"
        FbLog "=============================================="
        FbLog ""
        try {
            function RunFbDirect2($exe, $fbArgs) {
                $tmpF = [System.IO.Path]::GetTempFileName()
                & cmd.exe /c "`"$exe`" $fbArgs > `"$tmpF`" 2>&1"
                $result = if (Test-Path $tmpF) {
                    [System.IO.File]::ReadAllText($tmpF, [System.Text.Encoding]::UTF8)
                } else { "" }
                try { Remove-Item $tmpF -Force -EA SilentlyContinue } catch {}
                return $result.Trim()
            }

            $fbExe   = Get-FastbootExe
            $allVars = RunFbDirect2 $fbExe "getvar all"
            $devOut  = RunFbDirect2 $fbExe "devices"

            $devLine = ($devOut -split "`n") | Where-Object { $_ -imatch "fastboot" } | Select-Object -First 1
            $serial  = ("$devLine").Trim() -replace "\s*fastboot\s*$",""

            $info = @{
                Product="?"; VersionBoot="?"; Unlocked="?"; FlashingUnlocked="?"
                SecureBoot="?"; VerifiedBootState="?"; SlotCount="1"; CurrentSlot="N/A"
                Anti="?"; Variant="?"; CPU="?"
            }
            foreach ($line in ($allVars -split "`n")) {
                $l = $line.Trim() -replace "^<[^>]+>\s*","" -replace "^\(bootloader\)\s*","" `
                                  -replace "^OKAY\s*","" -replace "^INFO\s*",""
                $l = $l.Trim(); if (-not $l) { continue }
                if ($l -imatch "^product\s*:\s*(.+)")             { $info.Product           = $Matches[1].Trim() }
                if ($l -imatch "version-bootloader\s*:\s*(.+)")   { $info.VersionBoot        = $Matches[1].Trim() }
                if ($l -imatch "^unlocked\s*:\s*(.+)")            { $info.Unlocked           = $Matches[1].Trim() }
                if ($l -imatch "flashing-unlocked\s*:\s*(.+)")    { $info.FlashingUnlocked   = $Matches[1].Trim() }
                if ($l -imatch "secure-boot\s*:\s*(.+)|^secure\s*:\s*(.+)") {
                    $info.SecureBoot = if ($Matches[1]) { $Matches[1].Trim() } else { $Matches[2].Trim() }
                }
                if ($l -imatch "verifiedbootstate\s*:\s*(.+)")    { $info.VerifiedBootState  = $Matches[1].Trim() }
                if ($l -imatch "slot-count\s*:\s*(.+)")           { $info.SlotCount          = $Matches[1].Trim() }
                if ($l -imatch "current-slot\s*:\s*(.+)")         { $info.CurrentSlot        = $Matches[1].Trim() }
                if ($l -imatch "^anti\s*:\s*(.+)")                { $info.Anti              = $Matches[1].Trim() }
                if ($l -imatch "^variant\s*:\s*(.+)")             { $info.Variant            = $Matches[1].Trim() }
                if ($l -imatch "^cpu\s*:\s*(.+)|processor\s*:\s*(.+)") {
                    $info.CPU = if ($Matches[1]) { $Matches[1].Trim() } else { $Matches[2].Trim() }
                }
            }

            $blUnlocked = ($info.Unlocked -imatch "yes|true|1") -or ($info.FlashingUnlocked -imatch "yes|true|1")
            $blStr      = if ($blUnlocked) { "UNLOCKED" } else { "LOCKED" }
            $hasAB      = ($info.SlotCount -match "2")

            FbLog " PRODUCTO     : $($info.Product)"
            FbLog " SERIAL       : $serial"
            if ($info.Variant -ne "?" -and $info.Variant -ne "") { FbLog " VARIANTE     : $($info.Variant)" }
            if ($info.CPU -ne "?" -and $info.CPU -ne "")         { FbLog " CPU          : $($info.CPU)" }
            FbLog " BOOTLOADER   : $($info.VersionBoot)"
            FbLog " BL STATUS    : $blStr"
            if ($info.SecureBoot -ne "?")        { FbLog " SECURE BOOT  : $($info.SecureBoot)" }
            if ($info.VerifiedBootState -ne "?") { FbLog " VERIFIED BOOT: $($info.VerifiedBootState)" }
            if ($info.Anti -ne "?")              { FbLog " ANTI-ROLLBACK: $($info.Anti)" }
            FbLog ""
            FbLog " SLOTS A/B    : $(if ($hasAB) { 'SI (2 slots)' } else { 'NO (slot unico)' })"
            if ($hasAB) { FbLog " SLOT ACTIVO  : $($info.CurrentSlot)" }
            FbLog ""
            FbLog "=============================================="
            FbLog "[OK] LECTURA FASTBOOT COMPLETADA"

            $Global:lblModo.Text      = "MODO : FASTBOOT"
            $Global:lblModo.ForeColor = [System.Drawing.Color]::Yellow
            $Global:lblDisp.Text      = "DISPOSITIVO : $($info.Product)"
            $Global:lblSerial.Text    = "SERIAL : $serial"
            $Global:lblFRP.Text       = "BL : $blStr"
            $Global:lblFRP.ForeColor  = if ($blUnlocked) { [System.Drawing.Color]::Lime } else { [System.Drawing.Color]::Red }
        } catch { FbLog "[!] Error leyendo Fastboot: $_" }
    }

    # ---- MODO SIDELOAD ----
    elseif ($modo -eq "sideload") {
        FbLog "=============================================="
        FbLog " INFO DISPOSITIVO - MODO SIDELOAD"
        FbLog "=============================================="
        FbLog ""
        FbLog " El equipo esta en modo ADB Sideload."
        FbLog " En este modo la informacion disponible es limitada."
        FbLog ""
        $sideDevs = (& adb devices 2>$null) | Where-Object { $_ -match "\tsideload" }
        foreach ($sd in $sideDevs) {
            $serial = ($sd -split "\t")[0].Trim()
            FbLog " SERIAL       : $serial"
        }
        FbLog " MODO SIDELOAD: ACTIVO"
        FbLog ""
        FbLog " INSTRUCCIONES:"
        FbLog " - Para flashear: adb sideload <archivo.zip>"
        FbLog " - Cuando termine el equipo volvera a recovery"
        FbLog ""
        FbLog "[OK] SIDELOAD DETECTADO"
        $Global:lblModo.Text      = "MODO : SIDELOAD"
        $Global:lblModo.ForeColor = [System.Drawing.Color]::Magenta
    }

    $btn.Enabled = $true; $btn.Text = "LEER INFO DINAMICO"
})

# --------------------------------------------------------------------------
# BOTON: VER SLOT ACTIVO (detallado)
# --------------------------------------------------------------------------
$fbBtnSlotVer.Add_Click({
    $btn = $fbBtnSlotVer
    $btn.Enabled = $false; $btn.Text = "LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        # Detectar modo primero
        $modo = Detect-DeviceMode
        FbLog ""
        FbLog "=============================================="
        FbLog " VER SLOT ACTIVO - INFO DETALLADA"
        FbLog "=============================================="
        FbLog ""

        if ($modo -eq "adb") {
            FbLog "[~] Consultando via ADB..."
            $slotFromProp = SafeShellXu "getprop ro.boot.slot_suffix"
            $slotCount    = SafeShellXu "getprop ro.boot.slot_count"
            if ($slotCount -eq "") { $slotCount = "1" }
            FbLog " MODO LECTURA : ADB"
            FbLog " SLOT ACTIVO  : $(if ($slotFromProp) { $slotFromProp.ToUpper() } else { 'N/A (slot unico)' })"
            FbLog " TOTAL SLOTS  : $slotCount"
            FbLog ""
            if ($slotCount -match "2") {
                # Info adicional A/B via ADB
                $otaSlot = SafeShellXu "getprop ro.boot.slot"
                if ($otaSlot -ne "") { FbLog " OTA SLOT     : $otaSlot" }
                $ufbSlot = SafeShellXu "getprop ro.update_package"
                FbLog ""
                FbLog " El dispositivo usa sistema A/B."
                FbLog " Los updates se instalan en el slot inactivo."
                FbLog " El slot activo es el que corre actualmente."
            } else {
                FbLog " INFO: Dispositivo de slot unico (no A/B)"
            }
        } elseif ($modo -eq "fastboot") {
            if (-not (Check-Fastboot)) { return }
            FbLog "[~] Consultando via Fastboot..."

            $rawSlot  = Invoke-Fastboot "getvar current-slot"
            $rawCount = Invoke-Fastboot "getvar slot-count"
            $slotActivo = "DESCONOCIDO"
            $slotCount  = "1"
            foreach ($ln in ($rawSlot  -split "`n")) { if ($ln -imatch "current-slot\s*:\s*(.+)") { $slotActivo = $Matches[1].Trim(); break } }
            foreach ($ln in ($rawCount -split "`n")) { if ($ln -imatch "slot-count\s*:\s*(.+)")   { $slotCount  = $Matches[1].Trim(); break } }

            FbLog " MODO LECTURA : FASTBOOT"
            FbLog " SLOT ACTIVO  : $($slotActivo.ToUpper())"
            FbLog " TOTAL SLOTS  : $slotCount"
            FbLog ""

            if ($slotCount -match "^[2-9]") {
                foreach ($s in @("a","b")) {
                    $sucRaw = Invoke-Fastboot "getvar slot-successful:$s"
                    $unbRaw = Invoke-Fastboot "getvar slot-unbootable:$s"
                    $retRaw = Invoke-Fastboot "getvar slot-retry-count:$s"

                    $sucVal = if (($sucRaw -split "`n" | Where-Object { $_ -imatch "slot-successful.*:$s" } | Select-Object -First 1) -imatch ":\s*(.+)$") { $Matches[1].Trim() } else { "?" }
                    $unbVal = if (($unbRaw -split "`n" | Where-Object { $_ -imatch "slot-unbootable.*:$s" } | Select-Object -First 1) -imatch ":\s*(.+)$") { $Matches[1].Trim() } else { "?" }
                    $retVal = if (($retRaw -split "`n" | Where-Object { $_ -imatch "slot-retry-count.*:$s" } | Select-Object -First 1) -imatch ":\s*(.+)$") { $Matches[1].Trim() } else { "?" }

                    $marker = if ($slotActivo -eq $s) { "  <-- ACTIVO" } else { "" }
                    FbLog " SLOT $($s.ToUpper())$marker"
                    FbLog "   successful   : $sucVal  (1=OK / 0=fallo)"
                    FbLog "   unbootable   : $unbVal  (0=OK / 1=no arranca)"
                    FbLog "   retry-count  : $retVal  (intentos restantes)"
                    FbLog ""
                }
            } else {
                FbLog " INFO: Dispositivo de slot unico (no A/B)."
            }
        } else {
            FbLog "[!] No hay dispositivo conectado (ADB ni Fastboot)."
            FbLog "    Conecta el equipo en ADB o Fastboot mode."
            return
        }

        FbLog "[OK] Consulta de slot completada."
    } catch { FbLog "[!] Error: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "VER SLOT ACTIVO" }
})

# --------------------------------------------------------------------------
# BOTON: VER A/R ANTI-ROLLBACK (detallado)
# --------------------------------------------------------------------------
$fbBtnAntiRB.Add_Click({
    $btn = $fbBtnAntiRB
    $btn.Enabled = $false; $btn.Text = "LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        $modo = Detect-DeviceMode
        FbLog ""
        FbLog "=============================================="
        FbLog " VER A/R - VERSION Y ESTADO ANTI-ROLLBACK"
        FbLog "=============================================="
        FbLog ""

        if ($modo -eq "adb") {
            FbLog "[~] Leyendo Anti-Rollback via ADB..."

            $antiV1 = SafeShellXu "getprop ro.boot.anti_version"
            $antiV2 = SafeShellXu "getprop ro.boot.anti"
            $antiV3 = SafeShellXu "getprop persist.miui.extm.anti_version"
            $vbs    = SafeShellXu "getprop ro.boot.verifiedbootstate"
            $blLock = SafeShellXu "getprop ro.boot.flash.locked"
            $blStr  = if ($blLock -eq "1") { "LOCKED" } else { "UNLOCKED" }

            $antiVal = if ($antiV1 -ne "") { $antiV1 }
                       elseif ($antiV2 -ne "") { $antiV2 }
                       elseif ($antiV3 -ne "") { $antiV3 }
                       else { "No disponible (puede ser prop. oculta)" }

            FbLog " MODO LECTURA   : ADB"
            FbLog " ANTI-ROLLBACK  : $antiVal"
            FbLog " VERIFIED BOOT  : $vbs"
            FbLog " BL LOCK        : $blStr"
            FbLog ""
            FbLog " EXPLICACION:"
            FbLog " - Anti-Rollback (A/R) es un contador de version de seguridad."
            FbLog " - Un ROM con A/R mas ALTO que el dispositivo no se puede flashear."
            FbLog " - Un ROM con A/R mas BAJO que el dispositivo puede briquearlo."
            FbLog " - Valor 0 = sin version de seguridad (roms eng/CN sin firmar)."
            FbLog ""
            if ($antiV1 -eq "" -and $antiV2 -eq "" -and $antiV3 -eq "") {
                FbLog " [i] Anti-Rollback no expuesto via ADB en este dispositivo."
                FbLog "     Usa Fastboot mode: fastboot getvar anti"
            }
        } elseif ($modo -eq "fastboot") {
            if (-not (Check-Fastboot)) { return }
            FbLog "[~] Leyendo Anti-Rollback via Fastboot..."

            $antiRaw  = Invoke-Fastboot "getvar anti"
            $vbsRaw   = Invoke-Fastboot "getvar verifiedbootstate"
            $prodRaw  = Invoke-Fastboot "getvar product"

            $antiVal = "No disponible"
            $vbsVal  = "?"
            $prodVal = "?"
            foreach ($ln in ($antiRaw -split "`n")) {
                if ($ln -imatch "^anti\s*:\s*(.+)") { $antiVal = $Matches[1].Trim(); break }
                $ln2 = $ln -replace "^\(bootloader\)\s*","" -replace "^INFO\s*","" -replace "^OKAY\s*",""
                if ($ln2 -imatch "^anti\s*:\s*(.+)") { $antiVal = $Matches[1].Trim(); break }
            }
            foreach ($ln in ($vbsRaw -split "`n")) {
                $l2 = $ln -replace "^\(bootloader\)\s*","" -replace "^INFO\s*",""
                if ($l2 -imatch "verifiedbootstate\s*:\s*(.+)") { $vbsVal = $Matches[1].Trim(); break }
            }
            foreach ($ln in ($prodRaw -split "`n")) {
                $l2 = $ln -replace "^\(bootloader\)\s*","" -replace "^INFO\s*",""
                if ($l2 -imatch "^product\s*:\s*(.+)") { $prodVal = $Matches[1].Trim(); break }
            }

            FbLog " MODO LECTURA   : FASTBOOT"
            FbLog " PRODUCTO       : $prodVal"
            FbLog " ANTI-ROLLBACK  : $antiVal"
            FbLog " VERIFIED BOOT  : $vbsVal"
            FbLog ""
            FbLog " EXPLICACION:"
            FbLog " - Anti = version de anti-rollback del dispositivo."
            FbLog " - ROM con Anti mayor al dispositivo: BLOQUEO. No flasheable."
            FbLog " - ROM con Anti menor al dispositivo: PELIGRO de brick."
            FbLog " - Anti 0 o 'no disponible' = firma no activa (roms dev)."
            FbLog ""
            if ($antiVal -match "^\d+$") {
                FbLog " [+] Version A/R numerica detectada: $antiVal"
                FbLog "     Usa ROMs con Anti igual o menor a este valor."
            }
        } else {
            FbLog "[!] No hay dispositivo conectado."
            FbLog "    Conecta en ADB o Fastboot mode."
            return
        }
        FbLog "[OK] Consulta Anti-Rollback completada."
    } catch { FbLog "[!] Error: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "VER A/R ANTI-ROLLBACK" }
})

# --------------------------------------------------------------------------
# BOTON: VER ESTADO CUENTA MI
# --------------------------------------------------------------------------
$fbBtnMiAccount.Add_Click({
    $btn = $fbBtnMiAccount
    $btn.Enabled = $false; $btn.Text = "LEYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        FbLog ""
        FbLog "=============================================="
        FbLog " VER ESTADO CUENTA MI / BLOQUEO MI ACCOUNT"
        FbLog "=============================================="
        FbLog ""

        $modo = Detect-DeviceMode

        if ($modo -eq "adb") {
            FbLog "[~] Consultando estado Mi Account via ADB..."

            # Estado de bloqueo FRP/Mi Account
            $miLock1  = SafeShellXu "getprop ro.setupwizard.mode"
            $miLock2  = SafeShellXu "getprop persist.sys.miui_msa_globle_login"
            $miLock3  = SafeShellXu "settings get global find_device_enabled"
            $miLockFrp= SafeShellXu "getprop ro.frp.pst"
            $miStatus = SafeShellXu "pm list packages | grep -i xiaomi.find"

            # Intentar leer estado de bloqueo
            $findDevice = SafeShellXu "settings get secure android_id"

            FbLog " MODO LECTURA   : ADB"
            FbLog ""
            FbLog " ------ ESTADO FIND DEVICE / MI ACCOUNT ------"

            if ($miLock3 -ne "") { FbLog " Find Device    : $miLock3  (1=ACTIVO 0=INACTIVO)" }
            if ($miLock2 -ne "") { FbLog " MSA Login      : $miLock2" }
            if ($miLock1 -ne "") { FbLog " Setup Mode     : $miLock1" }
            if ($miLockFrp -ne "") { FbLog " FRP Prop       : $miLockFrp" }
            FbLog " Android ID     : $findDevice"
            FbLog ""

            # Verificar si hay cuenta Mi vinculada
            $acctPkg = SafeShellXu "pm list packages | grep com.xiaomi.account"
            $acctMSA = SafeShellXu "pm list packages | grep com.xiaomi.msa"
            $findPkg  = SafeShellXu "pm list packages | grep com.miui.find"

            FbLog " ------ PAQUETES RELACIONADOS ------"
            if ($acctPkg -ne "")  { FbLog " [+] Mi Account App    : PRESENTE ($acctPkg)" }
            else                  { FbLog " [-] Mi Account App    : no encontrado" }
            if ($acctMSA -ne "")  { FbLog " [+] MSA App           : PRESENTE" }
            if ($findPkg -ne "")  { FbLog " [+] Find Device App   : PRESENTE" }
            else                  { FbLog " [-] Find Device App   : no encontrado (quizas desbloqueado)" }
            FbLog ""

            # Intentar leer el estado de bloqueo de cuenta Mi via dumpsys
            $dumpMi = SafeShellXu "dumpsys device_policy | grep -i account"
            if ($dumpMi -ne "") {
                FbLog " ------ INFO DEVICE POLICY ------"
                foreach ($line in ($dumpMi -split "\n")) {
                    $lt = $line.Trim()
                    if ($lt -ne "") { FbLog " $lt" }
                }
                FbLog ""
            }

            FbLog " ------ INTERPRETACION ------"
            FbLog " - Si Find Device esta ACTIVO y hay cuenta vinculada:"
            FbLog "   el equipo tiene bloqueo Mi Account activo."
            FbLog " - Para desvincular: Configuracion > Mi Account > Salir"
            FbLog "   o desactiva Find Device antes de resetear."
            FbLog " - Equipo reseteado con Mi Account = BRICKEADO por FRP Mi."
        } elseif ($modo -eq "fastboot") {
            if (-not (Check-Fastboot)) { return }
            FbLog "[~] Consultando estado via Fastboot..."

            $allVars = Invoke-Fastboot "getvar all"
            $miLockFb = "DESCONOCIDO"
            foreach ($line in ($allVars -split "`n")) {
                $l = $line.Trim() -replace "^\(bootloader\)\s*","" -replace "^INFO\s*",""
                if ($l -imatch "cid\s*:\s*(.+)")           { FbLog " CID          : $($Matches[1].Trim())" }
                if ($l -imatch "mi-locked\s*:\s*(.+)")      { $miLockFb = $Matches[1].Trim() }
                if ($l -imatch "flashing-unlocked\s*:\s*(.+)") {
                    FbLog " BL Unlock    : $($Matches[1].Trim())"
                }
            }

            FbLog " MODO LECTURA : FASTBOOT"
            FbLog " MI LOCKED    : $miLockFb"
            FbLog ""
            FbLog " INTERPRETACION:"
            FbLog " - mi-locked: yes = equipo con bloqueo Mi Account"
            FbLog " - mi-locked: no  = sin bloqueo Mi Account"
            FbLog " - DESCONOCIDO    = este dispositivo no expone la variable"
            FbLog "   (puede ser normal en algunas versiones de firmware)"
        } else {
            FbLog "[!] No hay dispositivo conectado."
            FbLog "    Conecta en ADB o Fastboot mode."
            return
        }
        FbLog ""
        FbLog "[OK] Consulta Mi Account completada."
    } catch { FbLog "[!] Error: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "VER ESTADO CUENTA MI" }
})

#==========================================================================
# BLOQUE 2 - LOGICA
#==========================================================================

# --------------------------------------------------------------------------
# BOTON: CAMBIAR SLOT ACTIVO (dropdown A / B)
# --------------------------------------------------------------------------
$ctxSlotCambiar = New-Object System.Windows.Forms.ContextMenuStrip
$ctxSlotCambiar.BackColor = [System.Drawing.Color]::FromArgb(28,28,28)
$ctxSlotCambiar.ForeColor = [System.Drawing.Color]::Orange
$ctxSlotCambiar.Font      = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)

$slotCamA = $ctxSlotCambiar.Items.Add("Cambiar a SLOT A  (set_active a)")
$slotCamA.ForeColor = [System.Drawing.Color]::Cyan
$slotCamA.Font      = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)

$slotCamB = $ctxSlotCambiar.Items.Add("Cambiar a SLOT B  (set_active b)")
$slotCamB.ForeColor = [System.Drawing.Color]::Lime
$slotCamB.Font      = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)

$fbBtnCambiarSlot.Add_Click({
    $ctxSlotCambiar.Show($fbBtnCambiarSlot, 0, $fbBtnCambiarSlot.Height)
})

$slotCamA.Add_Click({
    if (-not (Check-Fastboot)) { return }
    $fbBtnCambiarSlot.Enabled = $false; $fbBtnCambiarSlot.Text = "CAMBIANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        FbLog ""
        FbLog "[*] === CAMBIAR SLOT -> A ==="
        FbLog "[~] Ejecutando: fastboot set_active a"
        $ec = Invoke-FastbootLive "set_active a"
        if ($ec -eq 0) {
            FbLog "[OK] Slot A activado. El equipo arrancara desde SLOT A."
            FbLog "[~] Reinicia para aplicar: fastboot reboot"
            $Global:lblModo.Text      = "MODO : Fastboot (SLOT A)"
            $Global:lblModo.ForeColor = [System.Drawing.Color]::Cyan
        } else {
            FbLog "[!] set_active a fallo (cod: $ec)"
            FbLog "[~] Verifica que el dispositivo soporte A/B slots."
        }
    } catch { FbLog "[!] Error: $_" }
    finally { $fbBtnCambiarSlot.Enabled = $true; $fbBtnCambiarSlot.Text = "CAMBIAR SLOT ACTIVO v" }
})

$slotCamB.Add_Click({
    if (-not (Check-Fastboot)) { return }
    $fbBtnCambiarSlot.Enabled = $false; $fbBtnCambiarSlot.Text = "CAMBIANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        FbLog ""
        FbLog "[*] === CAMBIAR SLOT -> B ==="
        FbLog "[~] Ejecutando: fastboot set_active b"
        $ec = Invoke-FastbootLive "set_active b"
        if ($ec -eq 0) {
            FbLog "[OK] Slot B activado. El equipo arrancara desde SLOT B."
            FbLog "[~] Reinicia para aplicar: fastboot reboot"
            $Global:lblModo.Text      = "MODO : Fastboot (SLOT B)"
            $Global:lblModo.ForeColor = [System.Drawing.Color]::Lime
        } else {
            FbLog "[!] set_active b fallo (cod: $ec)"
        }
    } catch { FbLog "[!] Error: $_" }
    finally { $fbBtnCambiarSlot.Enabled = $true; $fbBtnCambiarSlot.Text = "CAMBIAR SLOT ACTIVO v" }
})

# --------------------------------------------------------------------------
# BOTON: FIX SYSTEM DESTROYED
# --------------------------------------------------------------------------
$fbBtnFixSys.Add_Click({
    $btn = $fbBtnFixSys
    if (-not (Check-Fastboot)) { return }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "FIX SYSTEM DESTROYED`n`nEsto ejecutara:`n  fastboot oem erase-vb-index`n`nUsar en equipos con error 'System Destroyed' al arrancar.`n`nContinuar?",
        "FIX SYSTEM DESTROYED",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm -ne "Yes") { FbLog "[~] Operacion cancelada."; return }

    $btn.Enabled = $false; $btn.Text = "EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        FbLog ""
        FbLog "[*] === FIX SYSTEM DESTROYED ==="
        FbLog "[~] Ejecutando: fastboot oem erase-vb-index"
        FbLog "[~] Este comando borra el indice de Verified Boot corrupto."
        FbLog ""
        $ec = Invoke-FastbootLive "oem erase-vb-index"
        if ($ec -eq 0) {
            FbLog ""
            FbLog "[OK] Comando completado exitosamente."
            FbLog "[~] Reinicia el equipo: fastboot reboot"
            FbLog "[~] El sistema ya no deberia mostrar 'System Destroyed'."
        } else {
            FbLog ""
            FbLog "[!] Comando fallo (cod: $ec)"
            FbLog "[~] Verifica que el equipo sea Xiaomi y este en Fastboot clasico."
            FbLog "[~] Algunos modelos no soportan este OEM command."
        }
    } catch { FbLog "[!] Error: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "FIX SYSTEM DESTROYED" }
})

# --------------------------------------------------------------------------
# BOTON: BORRAR EFS (fsg, modemst1, modemst2 automatico)
# --------------------------------------------------------------------------
$fbBtnBorrarEFS.Add_Click({
    $btn = $fbBtnBorrarEFS
    if (-not (Check-Fastboot)) { return }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "BORRAR EFS`n`nEsto borrara las siguientes particiones EFS:`n`n  - fsg`n  - modemst1`n  - modemst2`n`nATENCION: Esta operacion borrara el IMEI y calibracion de modem.`nSolo ejecutar si sabes lo que haces o vas a restaurar un backup de EFS.`n`nConfirmar BORRADO de EFS?",
        "BORRAR EFS - CONFIRMACION",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Stop
    )
    if ($confirm -ne "Yes") { FbLog "[~] Operacion cancelada."; return }

    # Segunda confirmacion
    $confirm2 = [System.Windows.Forms.MessageBox]::Show(
        "SEGUNDA CONFIRMACION REQUERIDA`n`nEsta operacion ES IRREVERSIBLE sin backup.`n`n¿Estas completamente seguro de borrar EFS?",
        "CONFIRMACION FINAL",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($confirm2 -ne "Yes") { FbLog "[~] Operacion cancelada por doble confirmacion."; return }

    $btn.Enabled = $false; $btn.Text = "BORRANDO EFS..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        FbLog ""
        FbLog "[*] ====================================="
        FbLog "[*] BORRAR EFS - PARTICIONES MODEM"
        FbLog "[*] ====================================="
        FbLog ""

        $particionesEFS = @("fsg", "modemst1", "modemst2")
        $errores = 0

        foreach ($part in $particionesEFS) {
            FbLog "[~] Borrando particion: $part"
            $ec = Invoke-FastbootLive "erase $part"
            if ($ec -eq 0) {
                FbLog "[OK] $part borrada correctamente."
            } else {
                FbLog "[!] Error borrando $part (cod: $ec)"
                FbLog "    Puede no existir en este dispositivo o nombre distinto."
                $errores++
            }
            FbLog ""
        }

        FbLog "============================================"
        if ($errores -eq 0) {
            FbLog "[OK] TODAS las particiones EFS borradas."
        } else {
            FbLog "[!] $errores particion(es) con error."
            FbLog "    Verifica los nombres de particion para tu modelo."
        }
        FbLog ""
        FbLog "[i] PROXIMOS PASOS:"
        FbLog "    1. Flashea un backup de EFS si tienes uno."
        FbLog "    2. Flashea la ROM completa para regenerar EFS."
        FbLog "    3. Reinicia: fastboot reboot"
        FbLog ""
        FbLog "[!] SIN EFS valido el equipo no tendra IMEI ni senal."
    } catch { FbLog "[!] Error: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "BORRAR EFS" }
})

# --------------------------------------------------------------------------
# BOTON: BORRAR / ESCRIBIR PARTICION INDEPENDIENTE
# Mini UI con lista de particiones comunes + checkboxes + flash libre
# --------------------------------------------------------------------------
$fbBtnPartMgr.Add_Click({
    $btn = $fbBtnPartMgr
    if (-not (Check-Fastboot)) { return }

    # ---- Mini Form gestor de particiones ----
    $frmPart = New-Object System.Windows.Forms.Form
    $frmPart.Text          = "BORRAR / ESCRIBIR PARTICION - RNX TOOL PRO"
    $frmPart.ClientSize    = New-Object System.Drawing.Size(580, 500)
    $frmPart.BackColor     = [System.Drawing.Color]::FromArgb(18,18,22)
    $frmPart.FormBorderStyle = "FixedDialog"
    $frmPart.StartPosition = "CenterScreen"
    $frmPart.TopMost       = $true

    # Header
    $lbHdr = New-Object Windows.Forms.Label
    $lbHdr.Text      = "  GESTION DE PARTICIONES - FASTBOOT"
    $lbHdr.Location  = New-Object System.Drawing.Point(0,0)
    $lbHdr.Size      = New-Object System.Drawing.Size(580,32)
    $lbHdr.BackColor = [System.Drawing.Color]::FromArgb(200,90,0)
    $lbHdr.ForeColor = [System.Drawing.Color]::White
    $lbHdr.Font      = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lbHdr.TextAlign = "MiddleLeft"
    $frmPart.Controls.Add($lbHdr)

    # Label borrar
    $lbBorrar = New-Object Windows.Forms.Label
    $lbBorrar.Text     = "SELECCIONA PARTICIONES A BORRAR (erase):"
    $lbBorrar.Location = New-Object System.Drawing.Point(12,40)
    $lbBorrar.Size     = New-Object System.Drawing.Size(400,18)
    $lbBorrar.ForeColor= [System.Drawing.Color]::Orange
    $lbBorrar.Font     = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmPart.Controls.Add($lbBorrar)

    # Particiones comunes Xiaomi con descripcion
    $partList = @(
        @{ Name="userdata";   Desc="Datos de usuario (wipe data)" }
        @{ Name="cache";      Desc="Cache del sistema" }
        @{ Name="boot";       Desc="Imagen de arranque (boot.img)" }
        @{ Name="recovery";   Desc="Particion recovery" }
        @{ Name="system";     Desc="Sistema (solo slot activo)" }
        @{ Name="vendor";     Desc="Vendor (drivers)" }
        @{ Name="cust";       Desc="Personalizacion / OPCUST" }
        @{ Name="persist";    Desc="Datos persistentes (calibracion)" }
        @{ Name="metadata";   Desc="Metadatos encriptacion" }
        @{ Name="frp";        Desc="Factory Reset Protection" }
        @{ Name="keystore";   Desc="Keystore / claves" }
        @{ Name="misc";       Desc="Flags de arranque / recovery flags" }
    )

    $checkBoxes = @()
    $yChk = 62
    $colW  = 270
    $col   = 0

    foreach ($p in $partList) {
        $chk = New-Object Windows.Forms.CheckBox
        $chk.Text      = "$($p.Name)  - $($p.Desc)"
        $chk.Location  = New-Object System.Drawing.Point((12 + $col*$colW), $yChk)
        $chk.Size      = New-Object System.Drawing.Size(260, 20)
        $chk.ForeColor = [System.Drawing.Color]::LightGray
        $chk.BackColor = [System.Drawing.Color]::Transparent
        $chk.Font      = New-Object System.Drawing.Font("Segoe UI",7.5)
        $chk.Tag       = $p.Name
        $frmPart.Controls.Add($chk)
        $checkBoxes += $chk
        $col++
        if ($col -ge 2) { $col = 0; $yChk += 22 }
    }

    # Campo particion custom
    $yChk += 10
    $lbCustom = New-Object Windows.Forms.Label
    $lbCustom.Text     = "PARTICION PERSONALIZADA:"
    $lbCustom.Location = New-Object System.Drawing.Point(12, $yChk)
    $lbCustom.Size     = New-Object System.Drawing.Size(200,16)
    $lbCustom.ForeColor= [System.Drawing.Color]::Cyan
    $lbCustom.Font     = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmPart.Controls.Add($lbCustom)

    $txtCustom = New-Object Windows.Forms.TextBox
    $txtCustom.Location  = New-Object System.Drawing.Point(12, ($yChk+18))
    $txtCustom.Size      = New-Object System.Drawing.Size(200, 24)
    $txtCustom.BackColor = [System.Drawing.Color]::FromArgb(35,35,45)
    $txtCustom.ForeColor = [System.Drawing.Color]::Cyan
    $txtCustom.Font      = New-Object System.Drawing.Font("Consolas",9)
    $txtCustom.Text      = ""
    $frmPart.Controls.Add($txtCustom)

    # Seccion flash de imagen
    $yFlash = $yChk + 48
    $lbFlash = New-Object Windows.Forms.Label
    $lbFlash.Text     = "ESCRIBIR IMAGEN EN PARTICION:"
    $lbFlash.Location = New-Object System.Drawing.Point(230, $yChk)
    $lbFlash.Size     = New-Object System.Drawing.Size(250,16)
    $lbFlash.ForeColor= [System.Drawing.Color]::Lime
    $lbFlash.Font     = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmPart.Controls.Add($lbFlash)

    $txtFlashPart = New-Object Windows.Forms.TextBox
    $txtFlashPart.Location  = New-Object System.Drawing.Point(230, ($yChk+18))
    $txtFlashPart.Size      = New-Object System.Drawing.Size(120,24)
    $txtFlashPart.BackColor = [System.Drawing.Color]::FromArgb(35,35,45)
    $txtFlashPart.ForeColor = [System.Drawing.Color]::Lime
    $txtFlashPart.Font      = New-Object System.Drawing.Font("Consolas",9)
    $txtFlashPart.Text      = "boot"
    $frmPart.Controls.Add($txtFlashPart)

    $btnSelImg = New-Object Windows.Forms.Button
    $btnSelImg.Text      = "SELEC. IMG"
    $btnSelImg.Location  = New-Object System.Drawing.Point(358, ($yChk+16))
    $btnSelImg.Size      = New-Object System.Drawing.Size(100, 26)
    $btnSelImg.FlatStyle = "Flat"
    $btnSelImg.ForeColor = [System.Drawing.Color]::Lime
    $btnSelImg.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $btnSelImg.BackColor = [System.Drawing.Color]::FromArgb(18,35,18)
    $btnSelImg.Font      = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
    $frmPart.Controls.Add($btnSelImg)

    $lbImgSel = New-Object Windows.Forms.Label
    $lbImgSel.Text     = "(ninguna seleccionada)"
    $lbImgSel.Location = New-Object System.Drawing.Point(230, ($yChk+46))
    $lbImgSel.Size     = New-Object System.Drawing.Size(330,16)
    $lbImgSel.ForeColor= [System.Drawing.Color]::FromArgb(110,110,110)
    $lbImgSel.Font     = New-Object System.Drawing.Font("Consolas",7.5)
    $frmPart.Controls.Add($lbImgSel)

    $script:partImgPath = $null
    $btnSelImg.Add_Click({
        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "Imagen (*.img)|*.img|Todos los archivos|*.*"
        $fd.Title  = "Selecciona imagen a flashear"
        if ($fd.ShowDialog() -eq "OK") {
            $script:partImgPath = $fd.FileName
            $lbImgSel.Text = [System.IO.Path]::GetFileName($fd.FileName)
            $lbImgSel.ForeColor = [System.Drawing.Color]::Lime
        }
    })

    # Botones accion
    $yBtns = $yFlash + 80

    $btnErase = New-Object Windows.Forms.Button
    $btnErase.Text     = "BORRAR SELECCIONADAS"
    $btnErase.Location = New-Object System.Drawing.Point(12, $yBtns)
    $btnErase.Size     = New-Object System.Drawing.Size(200, 36)
    $btnErase.FlatStyle = "Flat"
    $btnErase.ForeColor = [System.Drawing.Color]::Red
    $btnErase.FlatAppearance.BorderColor = [System.Drawing.Color]::Red
    $btnErase.BackColor = [System.Drawing.Color]::FromArgb(40,12,12)
    $btnErase.Font      = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmPart.Controls.Add($btnErase)

    $btnFlashImg = New-Object Windows.Forms.Button
    $btnFlashImg.Text      = "ESCRIBIR IMAGEN"
    $btnFlashImg.Location  = New-Object System.Drawing.Point(230, $yBtns)
    $btnFlashImg.Size      = New-Object System.Drawing.Size(200, 36)
    $btnFlashImg.FlatStyle = "Flat"
    $btnFlashImg.ForeColor = [System.Drawing.Color]::Lime
    $btnFlashImg.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $btnFlashImg.BackColor = [System.Drawing.Color]::FromArgb(14,40,14)
    $btnFlashImg.Font      = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmPart.Controls.Add($btnFlashImg)

    $btnCerrarPart = New-Object Windows.Forms.Button
    $btnCerrarPart.Text     = "CERRAR"
    $btnCerrarPart.Location = New-Object System.Drawing.Point(450, $yBtns)
    $btnCerrarPart.Size     = New-Object System.Drawing.Size(100, 36)
    $btnCerrarPart.FlatStyle = "Flat"
    $btnCerrarPart.ForeColor = [System.Drawing.Color]::Gray
    $btnCerrarPart.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70,70,70)
    $btnCerrarPart.BackColor = [System.Drawing.Color]::FromArgb(28,28,35)
    $btnCerrarPart.Font      = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnCerrarPart.Add_Click({ $frmPart.Close() })
    $frmPart.Controls.Add($btnCerrarPart)

    # Logica BORRAR
    $btnErase.Add_Click({
        $selParts = @()
        foreach ($chk in $checkBoxes) { if ($chk.Checked) { $selParts += $chk.Tag } }
        $custom = $txtCustom.Text.Trim()
        if ($custom -ne "") { $selParts += $custom }
        if ($selParts.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "No hay particiones seleccionadas.",
                "Sin seleccion", "OK", "Information") | Out-Null
            return
        }
        $lista = $selParts -join ", "
        $ok = [System.Windows.Forms.MessageBox]::Show(
            "Se van a BORRAR las siguientes particiones:`n`n$lista`n`nConfirmar?",
            "BORRAR PARTICIONES", "YesNo", "Warning")
        if ($ok -ne "Yes") { return }

        $btnErase.Enabled = $false
        foreach ($p in $selParts) {
            FbLog "[~] Borrando particion: $p"
            [System.Windows.Forms.Application]::DoEvents()
            $ec = Invoke-FastbootLive "erase $p"
            if ($ec -eq 0) { FbLog "[OK] $p borrada." }
            else           { FbLog "[!] Error en $p (cod: $ec)" }
        }
        FbLog "[OK] Operacion de borrado completada."
        $btnErase.Enabled = $true
    })

    # Logica FLASH IMAGEN
    $btnFlashImg.Add_Click({
        $partDest = $txtFlashPart.Text.Trim()
        if ($partDest -eq "") {
            [System.Windows.Forms.MessageBox]::Show("Ingresa el nombre de particion destino.", "Sin particion", "OK", "Warning") | Out-Null
            return
        }
        if (-not $script:partImgPath -or -not (Test-Path $script:partImgPath)) {
            [System.Windows.Forms.MessageBox]::Show("Selecciona una imagen .img primero.", "Sin imagen", "OK", "Warning") | Out-Null
            return
        }
        $imgName = [System.IO.Path]::GetFileName($script:partImgPath)
        $ok = [System.Windows.Forms.MessageBox]::Show(
            "Flashear '$imgName' en la particion '$partDest'?",
            "CONFIRMAR FLASH", "YesNo", "Warning")
        if ($ok -ne "Yes") { return }
        $btnFlashImg.Enabled = $false
        FbLog ""
        FbLog "[*] FLASH -> $partDest"
        FbLog "[+] Imagen : $imgName"
        $ec = Invoke-FastbootLive "flash $partDest `"$($script:partImgPath)`""
        if ($ec -eq 0) { FbLog "[OK] Flash $partDest completado." }
        else           { FbLog "[!] Flash fallo (cod: $ec)" }
        $btnFlashImg.Enabled = $true
    })

    $frmPart.ShowDialog() | Out-Null
})

#==========================================================================
# BLOQUE 3 - LOGICA
#==========================================================================

# --------------------------------------------------------------------------
# BOTON: ACTIVAR DIAG
# Logica migrada desde tab ADB (btnsA3[0] ACTIVAR DIAG XIAOMI)
# --------------------------------------------------------------------------
$fbBtnActivarDiag.Add_Click({
    $btn = $fbBtnActivarDiag
    $btn.Enabled = $false; $btn.Text = "ACTIVANDO..."
    $Global:logFb.Clear()
    FbLog "[*] === ACTIVAR DIAG XIAOMI ==="
    FbLog ""
    [System.Windows.Forms.Application]::DoEvents()

    if (-not (Check-ADB)) {
        FbLog "[!] No hay dispositivo ADB. Conecta en modo ADB."
        $btn.Enabled = $true; $btn.Text = "ACTIVAR DIAG"
        return
    }

    try {
        # Verificar brand
        $brand = (& adb shell "getprop ro.product.brand" 2>$null)
        if ($brand -is [array]) { $brand = $brand[0].Trim() } else { $brand = "$brand".Trim() }

        FbLog "[+] Marca detectada: $($brand.ToUpper())"
        FbLog ""

        if ($brand -notmatch "xiaomi|redmi|poco") {
            FbLog "[!] Advertencia: este equipo no parece ser Xiaomi/Redmi/POCO."
            FbLog "    El comando DIAG puede no funcionar correctamente."
            FbLog ""
        }

        FbLog "[~] Metodo 1: adb shell setprop sys.usb.config diag,adb"
        & adb shell "setprop sys.usb.config diag,adb" 2>$null | Out-Null
        Start-Sleep -Milliseconds 800

        FbLog "[~] Metodo 2: adb shell setprop sys.usb.config diag,serial_smd,rmnet_bam,adb"
        & adb shell "setprop sys.usb.config diag,serial_smd,rmnet_bam,adb" 2>$null | Out-Null
        Start-Sleep -Milliseconds 500

        FbLog "[~] Verificando modo USB actual..."
        $usbCfg = (& adb shell "getprop sys.usb.config" 2>$null)
        if ($usbCfg -is [array]) { $usbCfg = $usbCfg[0].Trim() } else { $usbCfg = "$usbCfg".Trim() }
        FbLog "[+] USB config actual: $usbCfg"
        FbLog ""

        if ($usbCfg -imatch "diag") {
            FbLog "[OK] MODO DIAG ACTIVADO CORRECTAMENTE"
            FbLog ""
            FbLog "[i] Puerto COM DIAG deberia aparecer en el"
            FbLog "    Administrador de dispositivos de Windows."
            FbLog "    Si no aparece: instala Qualcomm USB Drivers."
        } else {
            FbLog "[~] DIAG no confirmado via prop. Intentando via ADB diag..."
            & adb shell "echo -e 'AT+QCFG=""usbnet"",1' > /dev/ttyHS0" 2>$null | Out-Null
            Start-Sleep -Milliseconds 500
            FbLog "[i] Si el COM DIAG no aparece:"
            FbLog "    1. El equipo puede necesitar ROM Engineer/ENG."
            FbLog "    2. Instala Qualcomm HS-USB Drivers."
            FbLog "    3. Prueba con XiaomiIMEITools (boton de esta tab)."
        }
    } catch { FbLog "[!] Error: $_" }
    $btn.Enabled = $true; $btn.Text = "ACTIVAR DIAG"
})

# --------------------------------------------------------------------------
# BOTON: DEBLOAT XIAOMI
# Logica migrada desde tab ADB (btnsA3[1] DEBLOAT XIAOMI)
# --------------------------------------------------------------------------
$fbBtnDebloat.Add_Click({
    $btn = $fbBtnDebloat
    $btn.Enabled = $false; $btn.Text = "CARGANDO..."
    $Global:logFb.Clear()
    FbLog "[*] === DEBLOAT XIAOMI ==="
    FbLog ""
    [System.Windows.Forms.Application]::DoEvents()

    if (-not (Check-ADB)) {
        FbLog "[!] No hay dispositivo ADB. Conecta en modo ADB."
        $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"
        return
    }

    # Lista de bloatware Xiaomi/MIUI conocido
    $bloatList = @(
        # Xiaomi/MIUI Services
        "com.miui.analytics",
        "com.xiaomi.mipicks",
        "com.miui.msa.global",
        "com.miui.systemAdSolution",
        "com.miui.daemon",
        "com.miui.personalassistant",
        "com.milink.service",
        "com.xiaomi.market",
        "com.miui.bugreport",
        "com.miui.cloudservice",
        "com.miui.cloudservice.sysbase",
        "com.miui.cloudbackup",
        "com.xiaomi.gamecenter.sdk.service",
        "com.miui.videoplayer",
        "com.miui.player",
        "com.mi.globalbrowser",
        "com.miui.yellowpage",
        "com.miui.compass",
        "com.xiaomi.joyose",
        "com.miui.newmidrive",
        "com.xiaomi.micloud.sdk",
        "com.miui.cleanmaster",
        "com.miui.screenshot",
        "com.miui.gallery",
        "com.miui.weather2",
        # Extras opcionales
        "com.android.calendar",
        "com.android.email"
    )

    FbLog "[+] Paquetes de bloatware detectados: $($bloatList.Count)"
    FbLog ""

    # Mini form de seleccion
    $frmBloat = New-Object System.Windows.Forms.Form
    $frmBloat.Text          = "DEBLOAT XIAOMI - RNX TOOL PRO"
    $frmBloat.ClientSize    = New-Object System.Drawing.Size(560,520)
    $frmBloat.BackColor     = [System.Drawing.Color]::FromArgb(15,18,15)
    $frmBloat.FormBorderStyle = "FixedDialog"
    $frmBloat.StartPosition = "CenterScreen"
    $frmBloat.TopMost       = $true

    $lbHdrB = New-Object Windows.Forms.Label
    $lbHdrB.Text      = "  DEBLOAT XIAOMI - Selecciona paquetes a desactivar"
    $lbHdrB.Location  = New-Object System.Drawing.Point(0,0)
    $lbHdrB.Size      = New-Object System.Drawing.Size(560,30)
    $lbHdrB.BackColor = [System.Drawing.Color]::FromArgb(20,100,20)
    $lbHdrB.ForeColor = [System.Drawing.Color]::White
    $lbHdrB.Font      = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $lbHdrB.TextAlign = "MiddleLeft"
    $frmBloat.Controls.Add($lbHdrB)

    $lbInfo2 = New-Object Windows.Forms.Label
    $lbInfo2.Text     = "Se usara 'pm disable-user' (reversible). El equipo no perdera datos."
    $lbInfo2.Location = New-Object System.Drawing.Point(10,32)
    $lbInfo2.Size     = New-Object System.Drawing.Size(540,16)
    $lbInfo2.ForeColor= [System.Drawing.Color]::FromArgb(0,200,100)
    $lbInfo2.Font     = New-Object System.Drawing.Font("Segoe UI",7.5)
    $frmBloat.Controls.Add($lbInfo2)

    $clbBloat = New-Object System.Windows.Forms.CheckedListBox
    $clbBloat.Location      = New-Object System.Drawing.Point(10,52)
    $clbBloat.Size          = New-Object System.Drawing.Size(540,360)
    $clbBloat.BackColor     = [System.Drawing.Color]::FromArgb(18,22,18)
    $clbBloat.ForeColor     = [System.Drawing.Color]::Lime
    $clbBloat.Font          = New-Object System.Drawing.Font("Consolas",8)
    $clbBloat.BorderStyle   = "FixedSingle"
    $clbBloat.CheckOnClick  = $true
    foreach ($pkg in $bloatList) { $clbBloat.Items.Add($pkg,$false) | Out-Null }
    $frmBloat.Controls.Add($clbBloat)

    $btnSelectAllB = New-Object Windows.Forms.Button
    $btnSelectAllB.Text     = "SEL. TODOS"
    $btnSelectAllB.Location = New-Object System.Drawing.Point(10,420)
    $btnSelectAllB.Size     = New-Object System.Drawing.Size(100,28)
    $btnSelectAllB.FlatStyle = "Flat"
    $btnSelectAllB.ForeColor = [System.Drawing.Color]::Lime
    $btnSelectAllB.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $btnSelectAllB.BackColor = [System.Drawing.Color]::FromArgb(20,38,20)
    $btnSelectAllB.Font      = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
    $btnSelectAllB.Add_Click({
        for ($i=0; $i -lt $clbBloat.Items.Count; $i++) { $clbBloat.SetItemChecked($i,$true) }
    })
    $frmBloat.Controls.Add($btnSelectAllB)

    $btnDeselB = New-Object Windows.Forms.Button
    $btnDeselB.Text     = "NINGUNO"
    $btnDeselB.Location = New-Object System.Drawing.Point(118,420)
    $btnDeselB.Size     = New-Object System.Drawing.Size(100,28)
    $btnDeselB.FlatStyle = "Flat"
    $btnDeselB.ForeColor = [System.Drawing.Color]::Gray
    $btnDeselB.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
    $btnDeselB.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
    $btnDeselB.Font      = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
    $btnDeselB.Add_Click({
        for ($i=0; $i -lt $clbBloat.Items.Count; $i++) { $clbBloat.SetItemChecked($i,$false) }
    })
    $frmBloat.Controls.Add($btnDeselB)

    $btnDisableB = New-Object Windows.Forms.Button
    $btnDisableB.Text      = "DESACTIVAR SELECCIONADOS"
    $btnDisableB.Location  = New-Object System.Drawing.Point(230,420)
    $btnDisableB.Size      = New-Object System.Drawing.Size(200,28)
    $btnDisableB.FlatStyle = "Flat"
    $btnDisableB.ForeColor = [System.Drawing.Color]::White
    $btnDisableB.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $btnDisableB.BackColor = [System.Drawing.Color]::FromArgb(40,80,40)
    $btnDisableB.Font      = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnDisableB.Add_Click({
        $toDisable = @()
        for ($i=0; $i -lt $clbBloat.Items.Count; $i++) {
            if ($clbBloat.GetItemChecked($i)) { $toDisable += $clbBloat.Items[$i] }
        }
        if ($toDisable.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No hay paquetes seleccionados.","Sin seleccion","OK","Information") | Out-Null
            return
        }
        $btnDisableB.Enabled = $false; $btnDisableB.Text = "PROCESANDO..."
        $ok2 = 0; $err2 = 0
        foreach ($pkg in $toDisable) {
            FbLog "[~] Desactivando: $pkg"
            $r = (& adb shell "pm disable-user --user 0 $pkg" 2>$null)
            $rStr = if ($r -is [array]) { $r -join " " } else { "$r" }
            if ($rStr -imatch "disabled|success") { FbLog "[OK] $pkg"; $ok2++ }
            else { FbLog "[!] $pkg -> $rStr"; $err2++ }
            [System.Windows.Forms.Application]::DoEvents()
        }
        FbLog ""
        FbLog "[OK] Completado: $ok2 desactivados, $err2 con error."
        $btnDisableB.Enabled = $true; $btnDisableB.Text = "DESACTIVAR SELECCIONADOS"
    })
    $frmBloat.Controls.Add($btnDisableB)

    $btnCerrarB = New-Object Windows.Forms.Button
    $btnCerrarB.Text     = "CERRAR"
    $btnCerrarB.Location = New-Object System.Drawing.Point(448,420)
    $btnCerrarB.Size     = New-Object System.Drawing.Size(100,28)
    $btnCerrarB.FlatStyle = "Flat"
    $btnCerrarB.ForeColor = [System.Drawing.Color]::Gray
    $btnCerrarB.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70,70,70)
    $btnCerrarB.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
    $btnCerrarB.Font      = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnCerrarB.Add_Click({ $frmBloat.Close() })
    $frmBloat.Controls.Add($btnCerrarB)

    $lbRestoreNote = New-Object Windows.Forms.Label
    $lbRestoreNote.Text     = "Para reactivar: adb shell pm enable --user 0 <paquete>"
    $lbRestoreNote.Location = New-Object System.Drawing.Point(10,456)
    $lbRestoreNote.Size     = New-Object System.Drawing.Size(540,16)
    $lbRestoreNote.ForeColor= [System.Drawing.Color]::FromArgb(80,80,80)
    $lbRestoreNote.Font     = New-Object System.Drawing.Font("Consolas",7)
    $frmBloat.Controls.Add($lbRestoreNote)

    $frmBloat.ShowDialog() | Out-Null
    $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"
})

# --------------------------------------------------------------------------
# BOTON: XIAOMI IMEI TOOLS (lanza XiaomiIMEITools.exe)
# Busca en carpetas del PC primero antes de pedir al usuario
# --------------------------------------------------------------------------
$fbBtnXiaoUtils.Add_Click({
    $btn = $fbBtnXiaoUtils
    $btn.Enabled = $false; $btn.Text = "BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()

    FbLog ""
    FbLog "[*] === XIAOMI IMEI TOOLS ==="
    FbLog ""
    FbLog "[~] Buscando en carpetas del sistema..."

    $exePath = $null

    # 1. Rutas directas conocidas (tools\ y subcarpetas)
    $directPaths = @(
        (Join-Path $script:TOOLS_DIR "XiaomiIMEITools.exe"),
        (Join-Path $script:TOOLS_DIR "xiaomiimeitools.exe"),
        (Join-Path $script:TOOLS_DIR "imei\XiaomiIMEITools.exe"),
        (Join-Path $script:TOOLS_DIR "xiaomi\XiaomiIMEITools.exe"),
        (Join-Path $script:SCRIPT_ROOT "XiaomiIMEITools.exe"),
        (Join-Path $script:SCRIPT_ROOT "tools\XiaomiIMEITools.exe"),
        ".\XiaomiIMEITools.exe",
        ".	ools\XiaomiIMEITools.exe"
    )
    foreach ($c in $directPaths) {
        if ($c -and (Test-Path $c -EA SilentlyContinue)) { $exePath = $c; break }
    }

    # 2. Busqueda recursiva en tools\ completa
    if (-not $exePath) {
        FbLog "[~] Buscando en tools\ recursivamente..."
        $found = Get-ChildItem $script:TOOLS_DIR -Recurse -File -EA SilentlyContinue |
                 Where-Object { $_.Name -imatch "xiaomi.*imei|imei.*xiaomi|XiaomiIMEI" -and $_.Extension -imatch "\.exe$" } |
                 Select-Object -First 1
        if ($found) { $exePath = $found.FullName }
    }

    # 3. Program Files
    if (-not $exePath) {
        FbLog "[~] Buscando en Program Files..."
        foreach ($pf in @($env:ProgramFiles, "${env:ProgramFiles(x86)}", "$env:LOCALAPPDATA\Programs")) {
            if (-not $pf -or -not (Test-Path $pf -EA SilentlyContinue)) { continue }
            $found = Get-ChildItem $pf -Recurse -Filter "*XiaomiIMEI*" -EA SilentlyContinue |
                     Where-Object { $_.Extension -imatch "\.exe$" } | Select-Object -First 1
            if ($found) { $exePath = $found.FullName; break }
        }
    }

    # 4. Desktop, Documents, Downloads
    if (-not $exePath) {
        FbLog "[~] Buscando en Escritorio y carpetas de usuario..."
        foreach ($dir in @("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:USERPROFILE\Downloads")) {
            if (-not (Test-Path $dir -EA SilentlyContinue)) { continue }
            $found = Get-ChildItem $dir -Recurse -File -EA SilentlyContinue |
                     Where-Object { $_.Name -imatch "xiaomi.*imei|imei.*xiaomi|XiaomiIMEI" -and $_.Extension -imatch "\.exe$" } |
                     Select-Object -First 1
            if ($found) { $exePath = $found.FullName; break }
        }
    }

    if ($exePath) {
        FbLog "[+] Encontrado: $exePath"
        try {
            Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath)
            FbLog "[OK] XiaomiIMEITools abierto."
            FbLog ""
            FbLog "[i] XiaomiIMEITools permite:"
            FbLog "    - Leer y escribir IMEI via DIAG"
            FbLog "    - Verificar EFS integrity"
            FbLog "    - Reparar IMEI en Xiaomi/Redmi/POCO"
            FbLog "[i] Activa el puerto DIAG antes con el boton 'ACTIVAR DIAG'"
        } catch {
            FbLog "[~] Intentando sin elevacion..."
            try { Start-Process $exePath; FbLog "[OK] Abierto." }
            catch { FbLog "[!] Error al abrir: $_" }
        }
    } else {
        FbLog "[!] XiaomiIMEITools.exe no encontrado en el sistema."
        FbLog ""
        FbLog "    Coloca XiaomiIMEITools.exe en alguna de estas rutas:"
        FbLog "    - $($script:TOOLS_DIR)"
        FbLog "    - $($script:TOOLS_DIR)\imei\"
        FbLog "    - $($script:TOOLS_DIR)\xiaomi\"
        FbLog ""
        FbLog "[i] Antes de usar XiaomiIMEITools activa el puerto DIAG"
        FbLog "    con el boton 'ACTIVAR DIAG' de esta misma tab."

        $resp = [System.Windows.Forms.MessageBox]::Show(
            "XiaomiIMEITools.exe no encontrado en el sistema.`n`nColoca XiaomiIMEITools.exe en:`n$($script:TOOLS_DIR)`n`nSubcarpetas validas: imei\ o xiaomi\",
            "XiaomiIMEITools no encontrado", "OK", "Warning")
    }

    $btn.Enabled = $true; $btn.Text = "XIAOMI IMEI TOOLS"
})


# --------------------------------------------------------------------------
# BOTON: DESCARGA DE FIRMWARES - mifirm.net  (mini interfaz estilo SamFW)
# Modo 1: Auto-identificar codename/region via ADB
# Modo 2: Busqueda manual por codename o modelo
# --------------------------------------------------------------------------
$fbBtnFirmDL.Add_Click({
    $btn = $fbBtnFirmDL
    $btn.Enabled = $false; $btn.Text = "ABRIENDO..."
    [System.Windows.Forms.Application]::DoEvents()

    FbLog ""
    FbLog "================================================"
    FbLog "   MIFIRM FIRMWARE DOWNLOADER  -  RNX TOOL PRO"
    FbLog "   $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    FbLog "================================================"
    FbLog ""

    $frmMiFirm = New-Object System.Windows.Forms.Form
    $frmMiFirm.Text = "MiFirm Firmware Downloader - RNX TOOL PRO"
    $frmMiFirm.ClientSize = New-Object System.Drawing.Size(560, 400)
    $frmMiFirm.BackColor = [System.Drawing.Color]::FromArgb(14,14,22)
    $frmMiFirm.FormBorderStyle = "FixedDialog"
    $frmMiFirm.StartPosition = "CenterScreen"
    $frmMiFirm.TopMost = $true

    # Header
    $lbHdrMi = New-Object Windows.Forms.Label
    $lbHdrMi.Text      = "  MIFIRM FIRMWARE DOWNLOADER"
    $lbHdrMi.Location  = New-Object System.Drawing.Point(0,0)
    $lbHdrMi.Size      = New-Object System.Drawing.Size(560,34)
    $lbHdrMi.BackColor = [System.Drawing.Color]::FromArgb(200,80,0)
    $lbHdrMi.ForeColor = [System.Drawing.Color]::White
    $lbHdrMi.Font      = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $lbHdrMi.TextAlign = "MiddleLeft"
    $frmMiFirm.Controls.Add($lbHdrMi)

    # ---- SECCION A: Auto-identificar por ADB ----
    $pnlAutoMi = New-Object Windows.Forms.Panel
    $pnlAutoMi.Location  = New-Object System.Drawing.Point(10,44)
    $pnlAutoMi.Size      = New-Object System.Drawing.Size(538,165)
    $pnlAutoMi.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $pnlAutoMi.BorderStyle = "FixedSingle"
    $frmMiFirm.Controls.Add($pnlAutoMi)

    $lbAutoTitleMi = New-Object Windows.Forms.Label
    $lbAutoTitleMi.Text      = "  MODO 1: Auto-identificar (requiere dispositivo Xiaomi/MIUI por ADB)"
    $lbAutoTitleMi.Location  = New-Object System.Drawing.Point(0,0)
    $lbAutoTitleMi.Size      = New-Object System.Drawing.Size(538,26)
    $lbAutoTitleMi.BackColor = [System.Drawing.Color]::FromArgb(140,50,0)
    $lbAutoTitleMi.ForeColor = [System.Drawing.Color]::White
    $lbAutoTitleMi.Font      = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $lbAutoTitleMi.TextAlign = "MiddleLeft"
    $pnlAutoMi.Controls.Add($lbAutoTitleMi)

    $lbMiModel = New-Object Windows.Forms.Label
    $lbMiModel.Text     = "Modelo  : --"
    $lbMiModel.Location = New-Object System.Drawing.Point(14,34)
    $lbMiModel.Size     = New-Object System.Drawing.Size(510,18)
    $lbMiModel.ForeColor = [System.Drawing.Color]::Lime
    $lbMiModel.Font     = New-Object System.Drawing.Font("Consolas",9)
    $pnlAutoMi.Controls.Add($lbMiModel)

    $lbMiRegion = New-Object Windows.Forms.Label
    $lbMiRegion.Text     = "Region  : --"
    $lbMiRegion.Location = New-Object System.Drawing.Point(14,54)
    $lbMiRegion.Size     = New-Object System.Drawing.Size(510,18)
    $lbMiRegion.ForeColor = [System.Drawing.Color]::Lime
    $lbMiRegion.Font     = New-Object System.Drawing.Font("Consolas",9)
    $pnlAutoMi.Controls.Add($lbMiRegion)

    $lbMiBuild = New-Object Windows.Forms.Label
    $lbMiBuild.Text     = "Build   : --"
    $lbMiBuild.Location = New-Object System.Drawing.Point(14,74)
    $lbMiBuild.Size     = New-Object System.Drawing.Size(510,18)
    $lbMiBuild.ForeColor = [System.Drawing.Color]::FromArgb(180,180,180)
    $lbMiBuild.Font     = New-Object System.Drawing.Font("Consolas",8)
    $pnlAutoMi.Controls.Add($lbMiBuild)

    $lbMiUrl = New-Object Windows.Forms.Label
    $lbMiUrl.Text     = "URL     : --"
    $lbMiUrl.Location = New-Object System.Drawing.Point(14,94)
    $lbMiUrl.Size     = New-Object System.Drawing.Size(510,18)
    $lbMiUrl.ForeColor = [System.Drawing.Color]::Cyan
    $lbMiUrl.Font     = New-Object System.Drawing.Font("Consolas",7.5)
    $pnlAutoMi.Controls.Add($lbMiUrl)

    $btnAutoDetectMi = New-Object Windows.Forms.Button
    $btnAutoDetectMi.Text     = "AUTO IDENTIFICAR"
    $btnAutoDetectMi.Location = New-Object System.Drawing.Point(14,126)
    $btnAutoDetectMi.Size     = New-Object System.Drawing.Size(160,30)
    $btnAutoDetectMi.FlatStyle = "Flat"
    $btnAutoDetectMi.ForeColor = [System.Drawing.Color]::Lime
    $btnAutoDetectMi.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $btnAutoDetectMi.BackColor = [System.Drawing.Color]::FromArgb(15,35,15)
    $btnAutoDetectMi.Font     = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $pnlAutoMi.Controls.Add($btnAutoDetectMi)

    $btnAutoOpenMi = New-Object Windows.Forms.Button
    $btnAutoOpenMi.Text     = "IR A MIFIRM"
    $btnAutoOpenMi.Location = New-Object System.Drawing.Point(184,126)
    $btnAutoOpenMi.Size     = New-Object System.Drawing.Size(130,30)
    $btnAutoOpenMi.FlatStyle = "Flat"
    $btnAutoOpenMi.ForeColor = [System.Drawing.Color]::White
    $btnAutoOpenMi.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(200,80,0)
    $btnAutoOpenMi.BackColor = [System.Drawing.Color]::FromArgb(80,30,0)
    $btnAutoOpenMi.Font     = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnAutoOpenMi.Enabled  = $false
    $pnlAutoMi.Controls.Add($btnAutoOpenMi)

    $script:MiFirm_AutoURL = ""

    $btnAutoDetectMi.Add_Click({
        $btnAutoDetectMi.Enabled = $false; $btnAutoDetectMi.Text = "LEYENDO..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            $miBrand    = SafeShellXu "getprop ro.product.brand"
            $miModel    = SafeShellXu "getprop ro.product.model"
            $miCodename = SafeShellXu "getprop ro.product.device"
            $miBuild    = SafeShellXu "getprop ro.build.display.id"
            $miMiui     = SafeShellXu "getprop ro.miui.ui.version.name"
            if (-not $miCodename) { $miCodename = SafeShellXu "getprop ro.product.name" }
            $miRegion   = SafeShellXu "getprop ro.miui.region"
            if (-not $miRegion) { $miRegion = SafeShellXu "getprop ro.product.locale" }
            if (-not $miRegion) { $miRegion = SafeShellXu "getprop persist.sys.locale" }

            if (-not $miModel) {
                $lbMiModel.Text     = "Modelo  : [Sin dispositivo ADB/Fastboot]"
                $lbMiModel.ForeColor = [System.Drawing.Color]::OrangeRed
            } elseif ($miBrand -notmatch "xiaomi|redmi|poco") {
                $lbMiModel.Text     = "Modelo  : $miModel  [$miBrand] - Solo Xiaomi/Redmi/POCO"
                $lbMiModel.ForeColor = [System.Drawing.Color]::OrangeRed
            } else {
                $lbMiModel.Text      = "Modelo  : $miModel  (codename: $miCodename)"
                $lbMiModel.ForeColor = [System.Drawing.Color]::Lime
                $lbMiRegion.Text     = "Region  : $(if($miRegion){$miRegion}else{'NO DETECTADA'})"
                $lbMiBuild.Text      = "Build   : $miBuild  |  MIUI/HyperOS: $miMiui"
                $miUrl = if ($miCodename) { "https://mifirm.net/model/$miCodename" } else { "https://mifirm.net/" }
                $lbMiUrl.Text       = "URL     : $miUrl"
                $script:MiFirm_AutoURL = $miUrl
                $btnAutoOpenMi.Enabled = $true
                FbLog "[+] Auto-detecto: $miModel | Codename: $miCodename | Region: $miRegion"
                FbLog "[+] URL: $miUrl"
            }
        } catch {
            $lbMiModel.Text      = "Error: $_"
            $lbMiModel.ForeColor = [System.Drawing.Color]::Red
        }
        $btnAutoDetectMi.Enabled = $true; $btnAutoDetectMi.Text = "AUTO IDENTIFICAR"
    })

    $btnAutoOpenMi.Add_Click({
        if ($script:MiFirm_AutoURL) {
            try { Start-Process $script:MiFirm_AutoURL; FbLog "[OK] Navegador abierto: $($script:MiFirm_AutoURL)" }
            catch { FbLog "[!] Error: $_" }
        }
    })

    # ---- SECCION B: Busqueda manual ----
    $pnlManualMi = New-Object Windows.Forms.Panel
    $pnlManualMi.Location  = New-Object System.Drawing.Point(10,220)
    $pnlManualMi.Size      = New-Object System.Drawing.Size(538,140)
    $pnlManualMi.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $pnlManualMi.BorderStyle = "FixedSingle"
    $frmMiFirm.Controls.Add($pnlManualMi)

    $lbManTitleMi = New-Object Windows.Forms.Label
    $lbManTitleMi.Text      = "  MODO 2: Buscar por codename o modelo (sin telefono conectado)"
    $lbManTitleMi.Location  = New-Object System.Drawing.Point(0,0)
    $lbManTitleMi.Size      = New-Object System.Drawing.Size(538,26)
    $lbManTitleMi.BackColor = [System.Drawing.Color]::FromArgb(60,40,0)
    $lbManTitleMi.ForeColor = [System.Drawing.Color]::White
    $lbManTitleMi.Font      = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $lbManTitleMi.TextAlign = "MiddleLeft"
    $pnlManualMi.Controls.Add($lbManTitleMi)

    $lbManMiModel = New-Object Windows.Forms.Label
    $lbManMiModel.Text     = "Codename/Modelo:"
    $lbManMiModel.Location = New-Object System.Drawing.Point(14,36)
    $lbManMiModel.Size     = New-Object System.Drawing.Size(120,20)
    $lbManMiModel.ForeColor = [System.Drawing.Color]::LightGray
    $lbManMiModel.Font     = New-Object System.Drawing.Font("Segoe UI",8)
    $pnlManualMi.Controls.Add($lbManMiModel)

    $txtManMiModel = New-Object Windows.Forms.TextBox
    $txtManMiModel.Location  = New-Object System.Drawing.Point(142,34)
    $txtManMiModel.Size      = New-Object System.Drawing.Size(150,24)
    $txtManMiModel.BackColor = [System.Drawing.Color]::FromArgb(30,30,45)
    $txtManMiModel.ForeColor = [System.Drawing.Color]::White
    $txtManMiModel.BorderStyle = "FixedSingle"
    $txtManMiModel.Font      = New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold)
    $txtManMiModel.Text      = ""
    $pnlManualMi.Controls.Add($txtManMiModel)

    $lbManMiHint = New-Object Windows.Forms.Label
    $lbManMiHint.Text     = "Ej: marble, pissarro, sweet, veux, spes, rosemary, melt..."
    $lbManMiHint.Location = New-Object System.Drawing.Point(14,64)
    $lbManMiHint.Size     = New-Object System.Drawing.Size(510,16)
    $lbManMiHint.ForeColor = [System.Drawing.Color]::FromArgb(100,100,120)
    $lbManMiHint.Font     = New-Object System.Drawing.Font("Segoe UI",7.5)
    $pnlManualMi.Controls.Add($lbManMiHint)

    $lbManMiHint2 = New-Object Windows.Forms.Label
    $lbManMiHint2.Text     = "Tambien puedes buscar por modelo: Redmi Note 12, POCO X5 Pro..."
    $lbManMiHint2.Location = New-Object System.Drawing.Point(14,82)
    $lbManMiHint2.Size     = New-Object System.Drawing.Size(510,16)
    $lbManMiHint2.ForeColor = [System.Drawing.Color]::FromArgb(80,80,100)
    $lbManMiHint2.Font     = New-Object System.Drawing.Font("Segoe UI",7)
    $pnlManualMi.Controls.Add($lbManMiHint2)

    $btnManOpenMi = New-Object Windows.Forms.Button
    $btnManOpenMi.Text     = "BUSCAR EN MIFIRM"
    $btnManOpenMi.Location = New-Object System.Drawing.Point(310,30)
    $btnManOpenMi.Size     = New-Object System.Drawing.Size(150,60)
    $btnManOpenMi.FlatStyle = "Flat"
    $btnManOpenMi.ForeColor = [System.Drawing.Color]::FromArgb(255,160,0)
    $btnManOpenMi.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,160,0)
    $btnManOpenMi.BackColor = [System.Drawing.Color]::FromArgb(45,30,0)
    $btnManOpenMi.Font     = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $pnlManualMi.Controls.Add($btnManOpenMi)

    $btnManOpenMi.Add_Click({
        $manInput = $txtManMiModel.Text.Trim()
        if (-not $manInput) {
            [System.Windows.Forms.MessageBox]::Show(
                "Ingresa el codename o modelo Xiaomi`n(ej: marble, sweet, pissarro, Redmi Note 12)",
                "Modelo requerido","OK","Warning") | Out-Null
            return
        }
        $manUrl = "https://mifirm.net/model/$manInput"
        FbLog "[+] Busqueda manual: $manInput"
        FbLog "[+] URL: $manUrl"
        try { Start-Process $manUrl; FbLog "[OK] Navegador abierto" }
        catch { FbLog "[!] Error: $_" }
    })

    # Boton cerrar
    $btnCloseMi = New-Object Windows.Forms.Button
    $btnCloseMi.Text     = "CERRAR"
    $btnCloseMi.Location = New-Object System.Drawing.Point(200,366)
    $btnCloseMi.Size     = New-Object System.Drawing.Size(160,28)
    $btnCloseMi.FlatStyle = "Flat"
    $btnCloseMi.ForeColor = [System.Drawing.Color]::Gray
    $btnCloseMi.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70,70,70)
    $btnCloseMi.BackColor = [System.Drawing.Color]::FromArgb(25,25,35)
    $btnCloseMi.Font     = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $btnCloseMi.Add_Click({ $frmMiFirm.Close() })
    $frmMiFirm.Controls.Add($btnCloseMi)

    FbLog "[i] Mini interfaz MiFirm abierta"
    FbLog "    Modo 1: conecta el telefono y usa AUTO IDENTIFICAR"
    FbLog "    Modo 2: escribe el codename para buscar sin telefono"
    FbLog "    mifirm.net - base de datos completa de firmwares Xiaomi/Redmi/POCO"

    $frmMiFirm.ShowDialog() | Out-Null
    $btn.Enabled = $true; $btn.Text = "DESCARGA DE FIRMWARES"
})


# Fin: 07_tab_fastboot.ps1 - XIAOMI UTILS