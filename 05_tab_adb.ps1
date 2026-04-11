#==========================================================================
# TAB ADB: UTILIDADES ADB - Layout y construccion de controles
# (Movido desde 04_tab_samsung.ps1 para separar logica Samsung de ADB)
#==========================================================================

$tabAdb           = New-Object Windows.Forms.TabPage
$tabAdb.Text      = "UTILIDADES ADB"
$tabAdb.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$tabs.TabPages.Add($tabAdb)

# ---------------------------------------------------------------
# METRICAS TAB ADB  -  2 columnas simetricas
# Area util tab: 856px  ->  col izq x=6 w=422 | gap=8 | col der x=436 w=422
# Botones: BW=196 BH=56  2 por fila con gap 8  ->  196*2+8=400 < 422-24=398 ~OK
# Ajuste: BW=195 para que 2*195+8+2*PPX = 2*195+8+32 = 426 -> cabe en 422 con margin
# Grupos col izq altura total: ~606 px  (margen inf ~12px)
# ---------------------------------------------------------------
$AX=6; $AGAP=8; $ALOGX=436
$ABTW=195; $ABTH=56; $APX=14; $APY=20; $AGX=8; $AGY=8
$AGW=422                       # ancho de cada columna
$ALOGW=$AGW                    # log misma anchura que columna

# Alturas de grupos
# grpA1: 2 filas (4 botones: info+reiniciar modo+OTA+adware)
# grpA2: 3 filas (6 botones: reparacion/seguridad Samsung)
# grpA3: 1 fila  (2 botones: herramientas Xiaomi)
# grpA4: 1 fila  (2 botones: automatizacion entregas)
$AGH1 = $APY + 2*($ABTH+$AGY) - $AGY + 14   # Grupo1: 2 filas (4 botones)
$AGH2 = $APY + 3*($ABTH+$AGY) - $AGY + 14   # Grupo2: 3 filas (6 botones)
$AGH3 = $APY + 2*($ABTH+$AGY) - $AGY + 14   # Grupo3: 2 filas (4 botones Xiaomi)
$AGH4 = $APY + 1*($ABTH+$AGY) - $AGY + 14   # Grupo4: 1 fila  (2 botones)

$AY1=6
$AY2=$AY1+$AGH1+$AGAP
$AY3=$AY2+$AGH2+$AGAP
$AY4=$AY3+$AGH3+$AGAP

# --- GRUPOS ---
$grpA1 = New-GBox $tabAdb "INFO, CONTROL Y PROTECCION"   $AX $AY1 $AGW $AGH1 "Cyan"
$grpA2 = New-GBox $tabAdb "REPARACION Y BYPASS"          $AX $AY2 $AGW $AGH2 "Orange"
$grpA3 = New-GBox $tabAdb "HERRAMIENTAS XIAOMI"          $AX $AY3 $AGW $AGH3 "Lime"
$grpA4 = New-GBox $tabAdb "AUTOMATIZACION Y ENTREGAS"    $AX $AY4 $AGW $AGH4 "Magenta"

# grpA1: LEER INFO, REINICIAR MODO (dropdown), BLOQUEAR OTA, REMOVER ADWARE
$AL1=@("LEER INFO COMPLETA","REINICIAR MODO","BLOQUEAR OTA","REMOVER ADWARE")
# grpA2: mismo que antes
$AL2=@("AUTOROOT MAGISK","BYPASS BANCARIO","FIX LOGO SAMSUNG","ACTIVAR SIM 2 SAMSUNG",
       "INSTALAR MAGISK","RESTAURAR BACKUP")
# grpA3: ACTIVAR DIAG XIAOMI + DEBLOAT XIAOMI (antes tenia 4 botones, ahora 2)
$AL3=@("ACTIVAR DIAG XIAOMI","DEBLOAT XIAOMI","DESCARGAR FIRMWARE","XIAOMI IMEI TOOLS")
# grpA4: RESET ENTREGA + INSTALAR APKs
$AL4=@("RESET RAPIDO ENTREGA","INSTALAR APKs")

$btnsA1=Place-Grid $grpA1 $AL1 "Cyan"    2 $ABTW $ABTH $APX $APY $AGX $AGY
$btnsA2=Place-Grid $grpA2 $AL2 "Orange"  2 $ABTW $ABTH $APX $APY $AGX $AGY
$btnsA3=Place-Grid $grpA3 $AL3 "Lime"    2 $ABTW $ABTH $APX $APY $AGX $AGY
$btnsA4=Place-Grid $grpA4 $AL4 "Magenta" 2 $ABTW $ABTH $APX $APY $AGX $AGY

$btnReadAdb   =$btnsA1[0]; $btnRebootSys=$btnsA1[1]
$btnRemFRP    =$btnsA2[0]

# Log ocupa toda la altura de la columna derecha
$ALOGY=$AY1; $ALOGH=616

# Variable global para proceso ADB largo activo (usado por STOP)
$script:ADB_ACTIVE_PROC = $null

# Boton STOP tab ADB - encima del log, color blanco para visibilidad
$adbStopH   = 26
$adbStopGap = 4
$btnAdbStop           = New-Object Windows.Forms.Button
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
        try {
            $script:ADB_ACTIVE_PROC.Kill()
            AdbLog "[!] Proceso detenido por el usuario."
        } catch { AdbLog "[!] No se pudo detener: $_" }
    }
    $btnAdbStop.Enabled = $false
})

# Ajustar posicion y alto del log ADB para dejar espacio al STOP
$adbLogRealY = $ALOGY + $adbStopH + $adbStopGap
$adbLogRealH = $ALOGH - $adbStopH - $adbStopGap

$Global:logAdb           = New-Object Windows.Forms.TextBox
$Global:logAdb.Multiline = $true
$Global:logAdb.Location  = New-Object System.Drawing.Point($ALOGX, $adbLogRealY)
$Global:logAdb.Size      = New-Object System.Drawing.Size($ALOGW, $adbLogRealH)
$Global:logAdb.BackColor = "Black"; $Global:logAdb.ForeColor=[System.Drawing.Color]::Cyan
$Global:logAdb.BorderStyle="FixedSingle"; $Global:logAdb.ScrollBars="Vertical"
$Global:logAdb.Font      = New-Object System.Drawing.Font("Consolas",8.5)
$tabAdb.Controls.Add($Global:logAdb)
# Context menu: Limpiar Log
$ctxAdb = New-Object System.Windows.Forms.ContextMenuStrip
$mnuClearAdb = $ctxAdb.Items.Add("Limpiar Log")
$mnuClearAdb.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$mnuClearAdb.ForeColor = [System.Drawing.Color]::OrangeRed
$mnuClearAdb.Add_Click({ $Global:logAdb.Clear() })
$Global:logAdb.ContextMenuStrip = $ctxAdb

#==========================================================================
# TAB 3: UTILIDADES GENERALES
# Layout: 2 columnas simetricas identico a ADB
#   Col izq  x=10  ancho=424  : 3 grupos de botones apilados
#   Col der  x=444 ancho=424  : log box altura completa
# Grupos:
#   G1 (Red)     FUNCIONES ROOT      4 btn  2 filas  h=172
#   G2 (Cyan)    UTILIDADES FIRMWARE 4 btn  2 filas  h=172
#   G3 (Magenta) HERRAMIENTAS MTK    4 btn  2 filas  h=172
#   Total col izq: 172+8+172+8+172 = 532 < 628 OK

#==========================================================================
# LOGICA - TAB SAMSUNG FLASHER
#==========================================================================
# Odin tab handlers removed - Samsung tab replaced by Control tab (04_tab_control.ps1)

#==========================================================================
# LOGICA - TAB UTILIDADES ADB
#==========================================================================
$btnReadAdb.Add_Click({
    if ($Global:logAdb) { $Global:logAdb.Clear() }
    AdbLog "[*] Iniciando lectura profunda..."
    if (-not (Check-ADB)) { return }
    try {
        # Helpers null-safe para ADB (evitan error si devuelve array o null)
        function SafeShell {
            param($cmd)
            $r = & adb shell $cmd 2>$null
            if ($null -eq $r) { return "" }
            if ($r -is [array]) { return ($r -join " ").Trim() }
            return $r.ToString().Trim()
        }
        function SafeAdb {
            param($cmd)
            $parts = $cmd -split " "
            $r = & adb @parts 2>$null
            if ($null -eq $r) { return "" }
            if ($r -is [array]) { return ($r -join " ").Trim() }
            return $r.ToString().Trim()
        }

        $brand   = (SafeShell "getprop ro.product.brand").ToUpper()
        $model    = SafeShell "getprop ro.product.model"
        $deviceId = (SafeShell "getprop ro.product.device").ToUpper()
        $modDevId = (SafeShell "getprop ro.product.mod_device").ToUpper()
        $devId    = if ($modDevId -ne "" -and $modDevId -ne $deviceId) { $modDevId } else { $deviceId }
        $modelFull = if ($devId -ne "" -and $devId -ne $model.ToUpper()) { "$model  [$devId]" } else { $model }
        $mfr     = (SafeShell "getprop ro.product.manufacturer").ToUpper()
        $android = SafeShell "getprop ro.build.version.release"
        $patch   = SafeShell "getprop ro.build.version.security_patch"
        $build   = SafeShell "getprop ro.build.display.id"
        $serial  = SafeAdb "get-serialno"
        $bootldr = SafeShell "getprop ro.boot.bootloader"
        $cpu     = Get-TechnicalCPU
        $frp1    = SafeShell "getprop ro.frp.pst"
        $oemLk   = SafeShell "getprop ro.boot.flash.locked"
        $root    = Detect-Root

        # Storage: deteccion multi-senal UFS vs eMMC (solo /sys/class/ufs falla en muchos UFS)
        $ufsNode3 = SafeShell "ls /sys/class/ufs 2>/dev/null"
        $ufsDev3  = SafeShell "ls /dev/block/sda 2>/dev/null"
        $ufsHost3 = SafeShell "ls /sys/bus/platform/drivers/ufshcd 2>/dev/null"
        $ufsType3 = SafeShell "getprop ro.boot.storage_type"
        $mmcBlk3  = SafeShell "ls /dev/block/mmcblk0 2>/dev/null"
        $isUFS3   = ($ufsNode3 -ne "" -or $ufsDev3 -ne "" -or $ufsHost3 -ne "" -or
                     ($ufsType3 -imatch "ufs") -or ($mmcBlk3 -eq "" -and $ufsDev3 -ne ""))
        $storage  = if ($isUFS3) { "UFS" } else { "eMMC" }

        # IMEI via service call
        $imeiRaw = SafeShell "service call iphonesubinfo 1"
        $imei = "UNKNOWN"
        if ($imeiRaw -match "[0-9]{15}") { $imei = $Matches[0] }
        elseif ($imeiRaw -match "Result: Parcel") {
            $digits = ($imeiRaw -replace "[^0-9]","")
            if ($digits.Length -ge 15) { $imei = $digits.Substring(0,15) }
        }

        # Pre-calcular strings para evitar if() dentro de strings
        $frpStr  = if ($frp1  -and $frp1  -ne "") { "PRESENT" } else { "NOT SET"  }
        $oemStr  = if ($oemLk -eq "1")             { "LOCKED"  } else { "UNLOCKED" }
        $rootStr = if ($root  -ne "NO ROOT")        { "SI"      } else { "NO"       }

        AdbLog ""
        AdbLog "=============================================="
        AdbLog "  INFO DISPOSITIVO  -  $brand $modelFull"
        AdbLog "=============================================="
        AdbLog ""
        AdbLog "  MARCA          : $brand"
        AdbLog "  MODELO         : $modelFull"
        AdbLog "  ANDROID        : $android"
        AdbLog "  PARCHE SEG.    : $patch"
        AdbLog "  BUILD          : $build"
        $board_gen = SafeShell "getprop ro.board.platform"
        AdbLog "  CPU            : $cpu"
        if ($board_gen -ne "") { AdbLog "  PLATAFORMA     : $board_gen" }
        AdbLog "  SERIAL         : $serial"
        AdbLog "  STORAGE        : $storage"
        AdbLog ""
        AdbLog "  ROOT           : $rootStr"
        AdbLog "  FRP            : $frpStr"
        AdbLog "  OEM LOCK       : $oemStr"
        AdbLog ""

        # ---- INFO ESPECIFICA POR MARCA ----
        if ($brand -match "SAMSUNG") {
            AdbLog "  --- SAMSUNG ---"
            $cscProp = SafeShell "getprop ro.csc.country.code"
            if ($cscProp -eq "") { $cscProp = SafeShell "getprop ro.product.csc" }
            if ($cscProp -ne "") { AdbLog "  CSC            : $cscProp - $(Get-CSCDecoded $cscProp)" }
            $kg   = SafeShell "getprop ro.boot.kg_state"
            $knox = SafeShell "getprop ro.boot.warranty_bit"
            if ($kg   -ne "") { AdbLog "  KG STATE       : $kg"   }
            if ($knox -ne "") { AdbLog "  WARRANTY VOID  : $knox" }
            $binary = Get-BinaryFromBuild $bootldr
            AdbLog "  BOOTLOADER     : $bootldr"
            AdbLog "  BINARIO        : $binary"
        }
        elseif ($brand -match "MOTOROLA|MOTO|LENOVO") {
            AdbLog "  --- MOTOROLA ---"
            $board  = SafeShell "getprop ro.board.platform"
            $hw     = SafeShell "getprop ro.hardware"
            $sku    = SafeShell "getprop ro.product.device"
            $locale = SafeShell "getprop ro.product.locale"
            $blLk   = SafeShell "getprop ro.boot.flash.locked"
            $blStr  = if ($blLk -eq "1") { "LOCKED" } else { "UNLOCKED" }
            $modVer = SafeShell "getprop ro.product.mod_version"
            $bbRaw  = SafeShell "getprop gsm.version.baseband"
            $bb     = ($bbRaw -split "`n")[0]
            if ($hw -ne $board) { AdbLog "  HARDWARE       : $hw" }
            AdbLog "  DEVICE SKU     : $sku"
            AdbLog "  LOCALE         : $locale"
            AdbLog "  BL ESTADO      : $blStr"
            if ($modVer -ne "") { AdbLog "  MOD VERSION    : $modVer" }
            if ($bb     -ne "") { AdbLog "  BASEBAND       : $bb"     }
            AdbLog "  IMEI           : $imei"
        }
        elseif ($brand -match "XIAOMI|REDMI|POCO") {
            AdbLog "  --- XIAOMI ---"
            $miuiVer  = SafeShell "getprop ro.miui.ui.version.name"
            $miuiBuild= SafeShell "getprop ro.miui.ui.version.code"
            $region   = SafeShell "getprop ro.miui.region"
            $blLk2    = SafeShell "getprop ro.boot.flash.locked"
            $vbs      = SafeShell "getprop ro.boot.verifiedbootstate"
            $blStr2   = if ($blLk2 -eq "1") { "LOCKED" } else { "UNLOCKED" }
            $devProp  = SafeShell "getprop ro.product.device"
            $codename = Get-XiaomiCodename $devProp
            $antiRaw  = SafeShell "getprop ro.boot.anti_version"
            if (-not $antiRaw) { $antiRaw = SafeShell "getprop ro.boot.verifiedbootstate" }
            AdbLog "  MIUI VERSION   : $miuiVer"
            if ($miuiBuild -ne "") { AdbLog "  MIUI BUILD     : $miuiBuild" }
            AdbLog "  REGION MIUI    : $region"
            AdbLog "  BL LOCK        : $blStr2"
            AdbLog "  BOOT STATE     : $vbs"
            AdbLog "  DEVICE         : $devProp"
            if ($codename -ne "" -and $codename -ne $devProp) {
                AdbLog "  CODENAME       : $codename"
            }
            if ($antiRaw -ne "" -and $antiRaw -match "^\d+$") {
                AdbLog "  ANTI-ROLLBACK  : $antiRaw"
            }
            AdbLog "  IMEI           : $imei"
        }
        elseif ($brand -match "HUAWEI|HONOR") {
            AdbLog "  --- HUAWEI ---"
            $emui = SafeShell "getprop ro.build.version.emui"
            $hw2  = SafeShell "getprop ro.hardware"
            AdbLog "  EMUI VERSION   : $emui"
            AdbLog "  HARDWARE       : $hw2"
            AdbLog "  IMEI           : $imei"
        }
        else {
            AdbLog "  --- INFO ADICIONAL ---"
            $board2 = SafeShell "getprop ro.board.platform"
            $bbRaw2 = SafeShell "getprop gsm.version.baseband"
            $bb2    = ($bbRaw2 -split "`n")[0]
            if ($bb2    -ne "") { AdbLog "  BASEBAND       : $bb2"    }
            AdbLog "  IMEI           : $imei"
            AdbLog "  BOOTLOADER     : $bootldr"
        }

        AdbLog ""
        AdbLog "=============================================="
        AdbLog "[OK] LECTURA COMPLETADA"

        # Actualizar sidebar
        $Global:lblDisp.Text      = "DISPOSITIVO : $brand"
        $Global:lblModel.Text     = "MODELO      : $modelFull"
        $Global:lblSerial.Text    = "SERIAL      : $serial"
        $Global:lblCPU.Text       = "CPU         : $cpu"
        $Global:lblStorage.Text   = "STORAGE     : $storage"
        $Global:lblFRP.Text       = "FRP         : $frpStr"
        $Global:lblFRP.ForeColor  = if ($frp1 -and $frp1 -ne "") { [System.Drawing.Color]::Red } else { [System.Drawing.Color]::Lime }
        $Global:lblRoot.Text      = "ROOT        : $rootStr"
        $Global:lblRoot.ForeColor = if ($root -ne "NO ROOT") { [System.Drawing.Color]::Lime } else { [System.Drawing.Color]::Red }

    } catch { AdbLog "[!] Error: $_" }
})
$btnRebootSys.Add_Click({
    if (-not (Check-ADB)) { return }
    # Crear menu contextual con las opciones de reinicio
    $ctxReboot = New-Object System.Windows.Forms.ContextMenuStrip
    $ctxReboot.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $ctxReboot.ForeColor = [System.Drawing.Color]::Cyan
    $ctxReboot.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)

    $itemSys = $ctxReboot.Items.Add("Reiniciar sistema")
    $itemSys.ForeColor = [System.Drawing.Color]::Cyan
    $itemSys.Add_Click({
        AdbLog "[*] Reiniciando sistema..."; & adb reboot 2>$null; AdbLog "[OK] Reiniciando"
    })

    $itemRec = $ctxReboot.Items.Add("Reiniciar a recovery")
    $itemRec.ForeColor = [System.Drawing.Color]::Orange
    $itemRec.Add_Click({
        AdbLog "[*] Reiniciando a Recovery..."; & adb reboot recovery 2>$null; AdbLog "[OK] Recovery"
    })

    $itemFast = $ctxReboot.Items.Add("Reiniciar a fastboot")
    $itemFast.ForeColor = [System.Drawing.Color]::Lime
    $itemFast.Add_Click({
        AdbLog "[*] Reiniciando a Fastboot/Bootloader..."; & adb reboot bootloader 2>$null; AdbLog "[OK] Fastboot"
    })

    $itemDown = $ctxReboot.Items.Add("Reiniciar a download")
    $itemDown.ForeColor = [System.Drawing.Color]::Magenta
    $itemDown.Add_Click({
        AdbLog "[*] Reiniciando a Download Mode..."; & adb reboot download 2>$null; AdbLog "[OK] Download"
    })

    # Mostrar el menu justo debajo del boton
    $pt = $btnRebootSys.PointToScreen([System.Drawing.Point]::new(0, $btnRebootSys.Height))
    $ctxReboot.Show($pt)
})
#==========================================================================
# AUTOROOT MAGISK 1-CLICK  -  Integrado en boton AUTOROOT MAGISK
# Flujo: Seleccion AP.tar.md5 -> Escaneo rapido TAR -> Extraccion quirurgica
#        boot.img.lz4 o init_boot.img.lz4 -> Parcheo magiskboot en PC ->
#        Generacion .tar -> Flash via Heimdall CLI o apertura Odin
#
# BINARIOS REQUERIDOS en .\tools\
#   magiskboot_v24.exe   <- Magisk 24.1  (modelos legacy: A21s / A13 / A51 5G)
#   magiskboot_v27.exe   <- Magisk 27    (todos los demas modelos)
#   lz4.exe
#   heimdall.exe
#   Odin3.exe            (opcional, fallback GUI)
#
# MODELOS LEGACY (usan magiskboot_v24.exe / Magisk 24.1):
#   SM-A217M  -  Galaxy A21s
#   SM-A135M  -  Galaxy A13 4G
#   SM-A515G  -  Galaxy A51 5G (Exynos)
#==========================================================================

function AutoRoot-Log($msg) {
    AdbLog $msg
}

function AutoRoot-SetStatus($btn, $txt) {
    $btn.Text    = $txt
    $btn.Enabled = ($txt -eq "AUTOROOT MAGISK")
    [System.Windows.Forms.Application]::DoEvents()
}

# ---- Tabla de modelos que requieren Magisk 24.1 (magiskboot legacy) ----
# Estos equipos tienen kernel antiguo incompatible con Magisk 25+
# Agregar aqui nuevos modelos legacy si se identifican
$script:MAGISK_LEGACY_MODELS = @(
    "SM-A217M",   # Galaxy A21s       - Exynos 850
    "SM-A217F",   # Galaxy A21s (EU)  - Exynos 850
    "SM-A135M",   # Galaxy A13 4G     - Exynos 850
    "SM-A135F",   # Galaxy A13 4G (EU)- Exynos 850
    "SM-A515G",   # Galaxy A51 5G     - Exynos 980
    "SM-A515F"    # Galaxy A51 5G (EU)- Exynos 980
)
$script:MAGISKBOOT    = Join-Path $script:TOOLS_DIR "magiskboot.exe"   # Windows x64 nativo
$script:MAGISK_APK_27 = Join-Path $script:TOOLS_DIR "magisk27.apk"
$script:MAGISK_APK_24 = Join-Path $script:TOOLS_DIR "magisk24.apk"
$script:MAGISK_BINS   = Join-Path $script:TOOLS_DIR "magisk_bins"      # cache de binarios extraidos

# ---- Extrae binarios ARM64 del APK de Magisk usando 7z ----
function Extract-MagiskBins($apkPath, $binsDir, $label) {
    $7z = Join-Path $script:TOOLS_DIR "7z.exe"
    if (-not (Test-Path $7z)) { AutoRoot-Log "[!] 7z.exe no encontrado en .\tools\"; return $false }
    if (-not (Test-Path $binsDir)) { New-Item $binsDir -ItemType Directory -Force | Out-Null }
    AutoRoot-Log "[~] Extrayendo binarios Magisk de $label ..."
    & $7z x "$apkPath" "lib\arm64-v8a\*" "-o$binsDir" -y 2>&1 | Out-Null
    $arm64 = Join-Path $binsDir "lib\arm64-v8a"
    if (-not (Test-Path $arm64)) {
        AutoRoot-Log "[!] No se encontro lib\arm64-v8a en el APK"
        return $false
    }
    $map = @{
        "libmagisk64.so"   = "magisk64"
        "libmagisk32.so"   = "magisk32"
        "libmagiskinit.so" = "magiskinit"
        "libstub.so"       = "stub.apk"
    }
    foreach ($so in $map.Keys) {
        $src = Join-Path $arm64 $so
        $dst = Join-Path $binsDir $map[$so]
        if (Test-Path $src) { Copy-Item $src $dst -Force; AutoRoot-Log "  [+] $so -> $($map[$so])" }
    }
    if (Test-Path (Join-Path $binsDir "magiskinit")) {
        AutoRoot-Log "[+] Binarios Magisk extraidos OK en: $binsDir"
        return $true
    }
    AutoRoot-Log "[!] magiskinit no encontrado - APK puede estar corrupto"
    return $false
}

# ---- Selector automatico de version de Magisk segun modelo ----
function Get-MagiskbootExe($model) {
    $modelClean = $model.Trim().ToUpper()
    $isLegacy   = $false
    foreach ($leg in $script:MAGISK_LEGACY_MODELS) {
        if ($modelClean -eq $leg.ToUpper()) { $isLegacy = $true; break }
    }
    $apkToUse = if ($isLegacy) { $script:MAGISK_APK_24 } else { $script:MAGISK_APK_27 }
    $apkLabel = if ($isLegacy) { "magisk24.apk (Magisk 24.1 - legacy)" } else { "magisk27.apk (Magisk 27)" }
    if ($isLegacy) {
        AutoRoot-Log "[*] MODELO LEGACY detectado: $modelClean"
        AutoRoot-Log "[*] Usando Magisk 24.1 (kernel antiguo incompatible con Magisk 25+)"
    } else {
        AutoRoot-Log "[*] Modelo estandar: $modelClean"
        AutoRoot-Log "[*] Usando Magisk 27"
    }
    if (-not (Test-Path $script:MAGISKBOOT)) {
        AutoRoot-Log "[!] magiskboot.exe no encontrado en .\tools\"
        AutoRoot-Log "[~] Descarga: github.com/affggh/magiskboot_build/releases"
        AutoRoot-Log "[~] Archivo : magiskboot-...-windows-mingw-w64-ucrt-x86_64..."
        return $null
    }
    $binsDirSub = if ($isLegacy) { "v24" } else { "v27" }
    $binsDir = Join-Path $script:MAGISK_BINS $binsDirSub
    $initBin = Join-Path $binsDir "magiskinit"
    if (-not (Test-Path $initBin)) {
        if (-not (Test-Path $apkToUse)) {
            AutoRoot-Log "[!] APK no encontrado: $apkToUse"
            AutoRoot-Log "[~] Coloca $([System.IO.Path]::GetFileName($apkToUse)) en .\tools\"
            return $null
        }
        $ok = Extract-MagiskBins $apkToUse $binsDir $apkLabel
        if (-not $ok) { return $null }
    } else {
        AutoRoot-Log "[+] Binarios Magisk en cache: $binsDir"
    }
    return @{ Exe = (Resolve-Path $script:MAGISKBOOT).Path; BinsDir = $binsDir; IsLegacy = $isLegacy }
}

# ---- Busqueda rapida en TAR sin extraer todo (solo lee cabeceras) ----
function Find-BootInTar($tarPath) {
    $result = @{ Target=$null; InitBoot=$false; Boot=$false; InitBootFile=$null; BootFile=$null }
    try {
        $hasTar = Get-Command tar -ErrorAction SilentlyContinue
        if (-not $hasTar) {
            AutoRoot-Log "[!] tar.exe no encontrado. Requiere Windows 10 build 17063+"
            return $result
        }
        AutoRoot-Log "[~] Escaneando indice TAR (sin extraer)..."
        $listing = & tar -tf "$tarPath" 2>&1
        foreach ($line in $listing) {
            $name = "$line".Trim()
            if ($name -imatch "init_boot\.img\.lz4$" -or $name -imatch "init_boot\.lz4$") {
                $result.InitBoot = $true
                $result.InitBootFile = $name
            }
            if ($name -imatch "^boot\.img\.lz4$" -or $name -imatch "^boot\.lz4$") {
                $result.Boot = $true
                $result.BootFile = $name
            }
        }
        # Regla simple:
        #   solo init_boot         -> usar init_boot
        #   solo boot              -> usar boot
        #   ambos (boot+init_boot) -> usar init_boot
        if ($result.InitBoot)       { $result.Target = $result.InitBootFile }
        elseif ($result.Boot)       { $result.Target = $result.BootFile }
    } catch { AutoRoot-Log "[!] Error escaneando TAR: $_" }
    return $result
}

# ---- Extraccion quirurgica: solo 1 archivo del TAR grande ----
function Extract-SingleFromTar($tarPath, $targetFile, $outDir) {
    try {
        if (-not (Test-Path $outDir)) { New-Item $outDir -ItemType Directory -Force | Out-Null }
        AutoRoot-Log "[~] Extrayendo: $targetFile"
        & tar -xf "$tarPath" -C "$outDir" "$targetFile" 2>&1 | Out-Null
        $extracted = Get-ChildItem $outDir -Recurse -Filter ($targetFile -replace ".*/","") -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($extracted -and (Test-Path $extracted.FullName)) {
            AutoRoot-Log "[+] Extraido: $($extracted.FullName) ($([math]::Round($extracted.Length/1KB,1)) KB)"
            return $extracted.FullName
        }
        AutoRoot-Log "[!] No se encontro el archivo extraido en: $outDir"
    } catch { AutoRoot-Log "[!] Error en extraccion: $_" }
    return $null
}

# ---- Descomprimir LZ4 usando lz4.exe del directorio tools ----
function Expand-LZ4($lz4Path, $outImg) {
    $lz4exe = $null
    foreach ($candidate in @((Join-Path $script:TOOLS_DIR "lz4.exe"), ".\lz4.exe", "lz4")) {
        if (Get-Command $candidate -ErrorAction SilentlyContinue) { $lz4exe = $candidate; break }
        if (Test-Path $candidate) { $lz4exe = $candidate; break }
    }
    if (-not $lz4exe) {
        # Fallback: usar 7z si disponible (puede descomprimir LZ4)
        foreach ($z in @((Join-Path $script:TOOLS_DIR "7z.exe"),".\7z.exe","7z")) {
            if (Get-Command $z -ErrorAction SilentlyContinue -or (Test-Path $z)) {
                AutoRoot-Log "[~] Descomprimiendo LZ4 con 7z..."
                & $z e "$lz4Path" "-o$(Split-Path $outImg)" -y 2>&1 | Out-Null
                $extracted = Get-ChildItem (Split-Path $outImg) -File | Where-Object { $_.Extension -ne ".lz4" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($extracted) { Rename-Item $extracted.FullName $outImg -Force -EA SilentlyContinue; return (Test-Path $outImg) }
            }
        }
        AutoRoot-Log "[!] lz4.exe no encontrado. Coloca lz4.exe en .\tools\"
        AutoRoot-Log "[~] Descarga desde: https://github.com/lz4/lz4/releases"
        return $false
    }
    AutoRoot-Log "[~] Descomprimiendo LZ4 -> $([System.IO.Path]::GetFileName($outImg))"
    & $lz4exe -d -f "$lz4Path" "$outImg" 2>&1 | Out-Null
    return (Test-Path $outImg)
}

# ---- Parchear boot con magiskboot.exe (Windows x64) + binarios ARM64 del APK ----
# $mbInfo: hashtable { Exe, BinsDir, IsLegacy } devuelto por Get-MagiskbootExe
function Patch-BootWithMagiskboot($imgPath, $workDir, $mbInfo) {
    if (-not $mbInfo -or -not (Test-Path $mbInfo.Exe)) {
        AutoRoot-Log "[!] magiskboot.exe no encontrado"
        return $null
    }
    $mbExe   = $mbInfo.Exe
    $binsDir = $mbInfo.BinsDir
    AutoRoot-Log "[+] magiskboot : $([System.IO.Path]::GetFileName($mbExe))"
    AutoRoot-Log "[+] Binarios   : $binsDir"

    if (-not (Test-Path $workDir)) { New-Item $workDir -ItemType Directory -Force | Out-Null }
    $imgName    = [System.IO.Path]::GetFileName($imgPath)
    $workImg    = Join-Path $workDir $imgName
    $patchedImg = Join-Path $workDir "patched_$imgName"
    Copy-Item $imgPath $workImg -Force

    # Copiar binarios ARM64 al workdir (magiskboot los busca en el directorio actual)
    foreach ($bin in @("magisk64","magisk32","magiskinit","stub.apk")) {
        $src = Join-Path $binsDir $bin
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $workDir $bin) -Force
            AutoRoot-Log "  [+] Copiado: $bin"
        }
    }

    $origDir = Get-Location
    try {
        Set-Location $workDir

        # PASO 1: Desempaquetar boot.img
        AutoRoot-Log "[~] Paso 1/3: magiskboot unpack $imgName"
        $out = & $mbExe unpack $imgName 2>&1
        $out | ForEach-Object { $line = "$_".Trim(); if ($line) { AutoRoot-Log "    $line" } }

        if (-not (Test-Path "ramdisk.cpio")) {
            AutoRoot-Log "[!] magiskboot unpack no genero ramdisk.cpio"
            AutoRoot-Log "[!] Verifica que boot.img sea valido y no este corrupto"
            return $null
        }
        AutoRoot-Log "[+] Unpack OK - ramdisk.cpio generado"

        # PASO 2: Inyectar Magisk en el ramdisk
        # Metodo exacto de customize.sh de Magisk:
        #   - "add 0750 init magiskinit"  reemplaza /init con el init de Magisk
        #   - "mkdir 0750 overlay.d"      directorio para overlays de Magisk
        #   - "mkdir 0750 overlay.d/sbin" overlay del sbin de Magisk  
        #   - "patch"                     CRITICO: parchea SHA1, dm-verity y AVB
        #                                 sin este comando Magisk aparece en gris
        # Todo en UN SOLO comando cpio (no llamadas separadas)
        AutoRoot-Log "[~] Paso 2/3: Inyectando Magisk en ramdisk (metodo oficial)..."
        $injectOut = & $mbExe cpio ramdisk.cpio `
            "add 0750 init magiskinit" `
            "mkdir 0750 overlay.d" `
            "mkdir 0750 overlay.d/sbin" `
            "patch" 2>&1
        $injectOut | ForEach-Object { $line = "$_".Trim(); if ($line) { AutoRoot-Log "    $line" } }

        if (-not (Test-Path "ramdisk.cpio")) {
            AutoRoot-Log "[!] ramdisk.cpio desaparecio tras la inyeccion"
            return $null
        }
        AutoRoot-Log "[+] Inyeccion OK"

        # PASO 3: Reempaquetar boot.img parcheado
        # magiskboot repack usa el boot.img original como referencia para
        # mantener cabecera, kernel, dtb y parametros exactos
        AutoRoot-Log "[~] Paso 3/3: magiskboot repack $imgName"
        $repackOut = & $mbExe repack $imgName 2>&1
        $repackOut | ForEach-Object { $line = "$_".Trim(); if ($line) { AutoRoot-Log "    $line" } }

        # magiskboot repack genera siempre "new-boot.img" en el directorio actual
        $newBoot = Join-Path $workDir "new-boot.img"
        if (Test-Path $newBoot) {
            $sz = [math]::Round((Get-Item $newBoot).Length/1KB,1)
            AutoRoot-Log "[+] Boot parcheado OK: new-boot.img ($sz KB)"
            # Renombrar a patched_boot.img para consistencia
            Rename-Item $newBoot $patchedImg -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $patchedImg)) {
                # Si el rename fallo (mismo nombre u otro problema), usar new-boot.img directo
                $patchedImg = $newBoot
            }
            return $patchedImg
        } else {
            # Algunos builds de magiskboot usan "patched_$imgName" como nombre de salida
            $altOut = Join-Path $workDir "patched_$imgName"
            if (Test-Path $altOut) {
                $sz = [math]::Round((Get-Item $altOut).Length/1KB,1)
                AutoRoot-Log "[+] Boot parcheado OK: patched_$imgName ($sz KB)"
                return $altOut
            }
            AutoRoot-Log "[!] magiskboot repack no genero new-boot.img ni patched_$imgName"
            AutoRoot-Log "[!] Revisa el log de repack arriba para ver el error"
            return $null
        }
    } catch {
        AutoRoot-Log "[!] Error en parcheo: $_"
        return $null
    } finally {
        Set-Location $origDir
        foreach ($tmp in @("kernel","kernel_dtb","ramdisk.cpio","dtb","extra",
                           "recovery_dtbo","vbmeta","magisk64","magisk32",
                           "magiskinit","stub.apk","config")) {
            Remove-Item (Join-Path $workDir $tmp) -Force -EA SilentlyContinue
        }
    }
}

# ---- Crear .tar compatible con Odin (formato USTAR, sin extensiones GNU) ----
# tar.exe de Windows genera cabeceras GNU que Odin no acepta -> congela en NAND Write.
# Se escribe el TAR byte a byte en formato USTAR puro que Odin acepta correctamente.
function Build-OdinTar($imgPath, $outDir, $isInitBootHint = $null) {
    # El nombre del archivo DENTRO del TAR determina a que particion flashea Odin:
    #   "boot.img"       -> particion BOOT      (correcto)
    #   "patched_boot.img" -> "Unassigned file" -> FAIL
    # Se usa el nombre canonico segun el tipo de imagen detectado.
    # $isInitBootHint: $true/$false pasado desde el caller (mas fiable que el nombre del archivo)
    $origName = [System.IO.Path]::GetFileName($imgPath)
    $detectedInitBoot = if ($isInitBootHint -ne $null) {
        [bool]$isInitBootHint
    } else {
        $origName -imatch "init_boot"
    }
    $tarEntryName = if ($detectedInitBoot) { "init_boot.img" } else { "boot.img" }
    $tarName = "autoroot_patched.tar"
    $tarPath = [System.IO.Path]::Combine($outDir, $tarName)
    try {
        if (-not (Test-Path $outDir)) { New-Item $outDir -ItemType Directory -Force | Out-Null }
        AutoRoot-Log "[~] Creando $tarName (nombre en TAR: $tarEntryName)..."

        $imgBytes   = [System.IO.File]::ReadAllBytes($imgPath)
        $imgSize    = $imgBytes.Length
        $fileStream = [System.IO.File]::Open($tarPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)

        # Cabecera USTAR 512 bytes - todos los campos en ASCII, null-padded
        $header = New-Object byte[] 512

        # Nombre (offset 0, 100 bytes) - nombre canonico que Odin reconoce
        $nameB = [System.Text.Encoding]::ASCII.GetBytes($tarEntryName)
        $nameL = [Math]::Min($nameB.Length, 99)
        [Array]::Copy($nameB, 0, $header, 0, $nameL)

        # Modo (offset 100, 8 bytes): "0000644" + null
        $modeB = [System.Text.Encoding]::ASCII.GetBytes("0000644")
        [Array]::Copy($modeB, 0, $header, 100, $modeB.Length)
        $header[107] = 0  # null terminator

        # UID (offset 108, 8 bytes): "0000000" + null
        $uidB = [System.Text.Encoding]::ASCII.GetBytes("0000000")
        [Array]::Copy($uidB, 0, $header, 108, $uidB.Length)
        $header[115] = 0

        # GID (offset 116, 8 bytes): "0000000" + null
        [Array]::Copy($uidB, 0, $header, 116, $uidB.Length)
        $header[123] = 0

        # Tamano (offset 124, 12 bytes): 11 digitos octales + espacio
        $sizeStr = [Convert]::ToString($imgSize, 8).PadLeft(11, [char]'0') + " "
        $sizeB   = [System.Text.Encoding]::ASCII.GetBytes($sizeStr)
        [Array]::Copy($sizeB, 0, $header, 124, $sizeB.Length)

        # Mtime (offset 136, 12 bytes): timestamp octal + espacio
        $mtime    = [long]([System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
        $mtimeStr = [Convert]::ToString($mtime, 8).PadLeft(11, [char]'0') + " "
        $mtimeB   = [System.Text.Encoding]::ASCII.GetBytes($mtimeStr)
        [Array]::Copy($mtimeB, 0, $header, 136, $mtimeB.Length)

        # Checksum placeholder (offset 148, 8 bytes): 8 espacios
        for ($ci = 148; $ci -lt 156; $ci++) { $header[$ci] = 0x20 }

        # Tipo de archivo (offset 156): '0' = archivo regular
        $header[156] = [byte][char]'0'

        # Magic USTAR (offset 257, 6 bytes): "ustar" + espacio + null
        $magicB = [System.Text.Encoding]::ASCII.GetBytes("ustar ")
        [Array]::Copy($magicB, 0, $header, 257, $magicB.Length)
        $header[263] = 0x20  # version " "
        $header[264] = 0x20  # version " "

        # Calcular checksum real (suma de todos los bytes, con checksum=espacios)
        $chkSum = 0
        for ($ci = 0; $ci -lt 512; $ci++) { $chkSum += $header[$ci] }

        # Escribir checksum: 6 digitos octales + null + espacio
        $chkStr = [Convert]::ToString($chkSum, 8).PadLeft(6, [char]'0')
        $chkB   = [System.Text.Encoding]::ASCII.GetBytes($chkStr)
        [Array]::Copy($chkB, 0, $header, 148, $chkB.Length)
        $header[154] = 0     # null
        $header[155] = 0x20  # espacio

        # Escribir cabecera + datos + padding + EOF
        $fileStream.Write($header, 0, 512)
        $fileStream.Write($imgBytes, 0, $imgSize)
        $pad = (512 - ($imgSize % 512)) % 512
        if ($pad -gt 0) { $fileStream.Write((New-Object byte[] $pad), 0, $pad) }
        $fileStream.Write((New-Object byte[] 1024), 0, 1024)
        $fileStream.Close()

        $sz = [math]::Round((Get-Item $tarPath).Length / 1MB, 2)
        AutoRoot-Log "[+] TAR USTAR creado: $tarPath ($sz MB)"

        # Crear .tar.md5: TAR + newline + md5hex + 2espacios + nombre + newline
        $md5Name = $tarName + ".md5"
        $md5Path = [System.IO.Path]::Combine($outDir, $md5Name)
        $md5hex  = (Get-FileHash $tarPath -Algorithm MD5).Hash.ToLower()
        Copy-Item $tarPath $md5Path -Force
        $hashLine  = [System.Text.Encoding]::ASCII.GetBytes("`n$md5hex  $tarEntryName`n")
        $fsmd5     = [System.IO.File]::Open($md5Path, [System.IO.FileMode]::Append)
        $fsmd5.Write($hashLine, 0, $hashLine.Length)
        $fsmd5.Close()

        AutoRoot-Log "[+] TAR.MD5 creado: $md5Path"
        AutoRoot-Log "[+] MD5: $md5hex"
        return @{ Tar=$tarPath; TarMd5=$md5Path; ImgName=$tarEntryName }

    } catch { AutoRoot-Log "[!] Error creando TAR: $_" }
    return $null
}

# ---- Flash via Heimdall CLI (automatico) ----
function Flash-WithHeimdall($imgPath, $partitionFlag) {
    $heimdall = $null
    foreach ($c in @((Join-Path $script:TOOLS_DIR "heimdall.exe"),".\heimdall.exe","heimdall")) {
        if (Test-Path $c) { $heimdall = $c; break }
        if (Get-Command $c -ErrorAction SilentlyContinue) { $heimdall = $c; break }
    }
    if (-not $heimdall) {
        AutoRoot-Log "[!] heimdall.exe no encontrado en .\tools\"
        return $false
    }
    AutoRoot-Log "[~] Flash via Heimdall: --$partitionFlag"
    AutoRoot-Log "[~] Asegurate que el equipo este en DOWNLOAD MODE"
    AutoRoot-Log "[~] (Vol- + Power o: adb reboot download)"
    $heimArgs = "flash --$partitionFlag `"$imgPath`" --no-reboot"
    AutoRoot-Log "[~] CMD: heimdall $heimArgs"
    $exit = Invoke-HeimdallLive $heimArgs
    return ($exit -eq 0)
}

# ---- Abrir Odin con el .tar.md5 listo para flashear ----
# Logica: SIEMPRE extrae a carpeta temporal nueva (nombre unico por timestamp+random)
#   - Crea carpeta temporal unica via GUID (nunca reutiliza residuos anteriores)
#   - Extrae Odin3.zip SIEMPRE de nuevo en carpeta fresca (logica de odin_launcher.ps1)
#   - Espera cierre de Odin y limpia carpeta temporal en Job de background
#   - Cada ejecucion es completamente independiente y sin residuos
function Open-OdinWithBoot($tarMd5Path) {
    # Logica exacta: extraer ZIP, verificar INI en misma carpeta del exe, lanzar

    # --- Paso 1: Carpeta temporal UNICA via GUID ---
    $tempDir = Join-Path $env:TEMP ("Odin_" + [guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    AutoRoot-Log "[~] Carpeta Odin temporal: $tempDir"

    # --- Paso 2: Extraer Odin3.zip ---
    $odinZip = Join-Path $script:TOOLS_DIR "Odin3.zip"
    if (-not (Test-Path $odinZip)) {
        AutoRoot-Log "[!] No se encontro Odin3.zip en: $($script:TOOLS_DIR)"
        AutoRoot-Log "[~] Coloca Odin3.zip (con Odin3.exe y Odin3.ini) en tools\"
        AutoRoot-Log "[~] Abre Odin manualmente y carga: $tarMd5Path"
        Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue
        Start-Process explorer.exe (Split-Path $tarMd5Path) -EA SilentlyContinue
        return
    }

    AutoRoot-Log "[+] Odin3.zip encontrado en tools\"
    AutoRoot-Log "[~] Extrayendo a carpeta temporal limpia..."
    try {
        Expand-Archive -Path $odinZip -DestinationPath $tempDir -Force
        AutoRoot-Log "[+] ZIP extraido OK"
    } catch {
        AutoRoot-Log "[!] Error extrayendo ZIP: $_"
        Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue
        return
    }

    # --- Paso 3: Buscar Odin3.exe ---
    $odinExeItem = Get-ChildItem -Path $tempDir -Recurse -Filter "Odin3.exe" | Select-Object -First 1
    if (-not $odinExeItem) {
        $odinExeItem = Get-ChildItem -Path $tempDir -Recurse -Filter "Odin*.exe" | Select-Object -First 1
    }
    if (-not $odinExeItem) {
        AutoRoot-Log "[!] No se encontro Odin3.exe en el ZIP"
        Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue
        return
    }
    $odinExe    = $odinExeItem.FullName
    $odinRunDir = $odinExeItem.Directory.FullName
    AutoRoot-Log "[+] Ejecutable: $($odinExeItem.Name)"

    # --- Paso 4: Verificar Odin3.ini en la misma carpeta del exe ---
    # El ZIP DEBE incluir Odin3.ini junto a Odin3.exe
    $iniPath = Join-Path $odinRunDir "Odin3.ini"
    if (-not (Test-Path $iniPath)) {
        AutoRoot-Log "[!] Odin3.ini no encontrado junto al exe"
        AutoRoot-Log "[~] El ZIP debe contener Odin3.exe Y Odin3.ini en la misma carpeta"
        Remove-Item $tempDir -Recurse -Force -EA SilentlyContinue
        return
    }
    AutoRoot-Log "[+] Odin3.ini verificado OK"

    # --- Paso 5: Copiar ruta del boot al portapapeles ---
    $clipOk = $false
    try {
        [System.Windows.Forms.Clipboard]::SetText($tarMd5Path)
        $clipOk = $true
        AutoRoot-Log "[+] Portapapeles: $([System.IO.Path]::GetFileName($tarMd5Path))  <-- Ctrl+V en Odin slot AP"
    } catch {
        try { $tarMd5Path | & clip.exe; $clipOk = $true } catch {}
        if ($clipOk) { AutoRoot-Log "[+] Portapapeles OK (clip.exe)" }
        else { AutoRoot-Log "[~] Portapapeles no disponible - copia la ruta manualmente" }
    }

    # --- Paso 6: Lanzar Odin3 DESDE su carpeta ---
    AutoRoot-Log "[~] Lanzando Odin3..."
    $odinProc = $null
    try {
        $odinProc = Start-Process `
            -FilePath      $odinExe `
            -WorkingDirectory $odinRunDir `
            -Verb RunAs `
            -PassThru
        if ($odinProc) { AutoRoot-Log "[+] Odin3 abierto (PID: $($odinProc.Id))" }
        else           { AutoRoot-Log "[+] Odin3 lanzado (UAC elevado)" }
    } catch {
        AutoRoot-Log "[~] RunAs fallo - intentando sin elevacion..."
        try {
            $psi2 = New-Object System.Diagnostics.ProcessStartInfo
            $psi2.FileName         = $odinExe
            $psi2.WorkingDirectory = $odinRunDir
            $psi2.UseShellExecute  = $true
            $odinProc = [System.Diagnostics.Process]::Start($psi2)
            AutoRoot-Log "[+] Odin3 abierto sin elevacion (PID: $($odinProc.Id))"
        } catch {
            AutoRoot-Log "[!] No se pudo abrir Odin3.exe: $_"
            AutoRoot-Log "[~] Abre manualmente: $odinExe"
        }
    }

    # --- Paso 7: Autolimpieza en background ---
    $cleanDir = $tempDir
    $cleanPid = if ($odinProc) { $odinProc.Id } else { 0 }
    $null = Start-Job -ScriptBlock {
        param($procId, $dirPath)
        if ($procId -gt 0) {
            try {
                $p = Get-Process -Id $procId -EA SilentlyContinue
                if ($p) { $p.WaitForExit(600000) }
            } catch {}
        } else {
            $start = Get-Date
            while (((Get-Date) - $start).TotalSeconds -lt 300) {
                Start-Sleep -Seconds 10
                $still = Get-Process -Name "Odin3*" -EA SilentlyContinue
                if (-not $still) { break }
            }
        }
        Start-Sleep -Seconds 5
        try { Remove-Item -Path $dirPath -Recurse -Force -EA SilentlyContinue } catch {}
    } -ArgumentList $cleanPid, $cleanDir
    AutoRoot-Log "[~] Autolimpieza activada"

    AutoRoot-Log ""
    AutoRoot-Log "================================================"
    AutoRoot-Log "  ODIN ABIERTO - SIGUE ESTOS PASOS:"
    AutoRoot-Log "================================================"
    AutoRoot-Log "  1. En Odin presiona el boton [ AP ]"
    AutoRoot-Log "  2. En el dialogo de archivo presiona Ctrl+V"
    AutoRoot-Log "  3. Acepta y presiona START en Odin"
    AutoRoot-Log "================================================"

    # Mensaje popup con instrucciones claras para el usuario
    [System.Windows.Forms.MessageBox]::Show(
        "El archivo parcheado ha sido copiado al portapapeles.`n`n" +
        "EN ODIN:`n" +
        "  1. Presiona el boton  [ AP ]`n" +
        "  2. En el dialogo de archivo, presiona  Ctrl+V`n" +
        "  3. Presiona START`n`n" +
        "Nombre del archivo a pegar:`n" +
        "  autoroot_patched.tar  (sin .md5)",
        "ODIN LISTO - INSTRUCCIONES",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

# ---- Verificar root post-flash ----
function Verify-RootPost {
    AutoRoot-Log "[~] Esperando que el equipo reinicie (30s)..."
    for ($i = 30; $i -gt 0; $i -= 5) {
        Start-Sleep -Seconds 5
        [System.Windows.Forms.Application]::DoEvents()
        $dev = (& adb devices 2>$null) | Where-Object { $_ -match "	device" }
        if ($dev) { break }
        AutoRoot-Log "[~] Esperando ADB... ($i s)"
    }
    $rootCheck = (& adb shell "su -c id" 2>$null)
    if ($rootCheck -match "uid=0") {
        AutoRoot-Log ""
        AutoRoot-Log "[OK] ============================================"
        AutoRoot-Log "[OK]   ROOT CONFIRMADO - Magisk activo         "
        AutoRoot-Log "[OK] ============================================"
        $Global:lblRoot.Text      = "ROOT        : SI (MAGISK)"
        $Global:lblRoot.ForeColor = [System.Drawing.Color]::Lime
        return $true
    } else {
        AutoRoot-Log "[!] Root no detectado aun - puede necesitar reinicio adicional"
        AutoRoot-Log "[~] Abre Magisk en el telefono para completar la instalacion"
        return $false
    }
}

# ---- HANDLER PRINCIPAL DEL BOTON ----
$btnRemFRP.Text = "AUTOROOT MAGISK"
$btnRemFRP.ForeColor = [System.Drawing.Color]::Magenta
$btnRemFRP.FlatAppearance.BorderColor = [System.Drawing.Color]::Magenta

# Bypass Bancario: dorado para diferenciarlo del grupo Orange
$btnsA2[1].Text = "BYPASS BANCARIO"
$btnsA2[1].ForeColor = [System.Drawing.Color]::FromArgb(255,215,0)
$btnsA2[1].BackColor = [System.Drawing.Color]::FromArgb(40,35,10)
$btnsA2[1].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,215,0)
$btnsA2[1].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# Boton btnsA2[5]: SAMFW FIRMWARE - Buscar y abrir firmware Samsung en samfw.com
$btnsA2[5].Text = "SAMFW FIRMWARE"
$btnsA2[5].ForeColor = [System.Drawing.Color]::FromArgb(0,180,255)
$btnsA2[5].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0,180,255)
$btnsA2[5].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# Boton btnsA1[2]: BLOQUEAR OTA (ahora en posicion 2, grupo reducido a 4 botones)
$btnsA1[2].Text = "BLOQUEAR OTA"
$btnsA1[2].ForeColor = [System.Drawing.Color]::FromArgb(0,220,180)
$btnsA1[2].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0,220,180)
$btnsA1[2].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# Boton btnsA1[3]: REMOVER ADWARE (ahora en posicion 3, grupo reducido a 4 botones)
$btnsA1[3].Text = "REMOVER ADWARE"
$btnsA1[3].ForeColor = [System.Drawing.Color]::FromArgb(255,100,0)
$btnsA1[3].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,100,0)
$btnsA1[3].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# Boton btnsA3[0]: ACTIVAR DIAG XIAOMI
$btnsA3[0].Text = "ACTIVAR DIAG XIAOMI"
$btnsA3[0].ForeColor = [System.Drawing.Color]::FromArgb(0,200,200)
$btnsA3[0].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0,200,200)
$btnsA3[0].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# Boton btnsA3[1]: DEBLOAT XIAOMI
$btnsA3[1].Text = "DEBLOAT XIAOMI"
$btnsA3[1].ForeColor = [System.Drawing.Color]::FromArgb(50,255,120)
$btnsA3[1].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(50,255,120)
$btnsA3[1].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# Boton btnsA4[0]: RESET RAPIDO ENTREGA
$btnsA4[0].Text = "RESET RAPIDO ENTREGA"
$btnsA4[0].ForeColor = [System.Drawing.Color]::FromArgb(220,60,220)
$btnsA4[0].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(220,60,220)
$btnsA4[0].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

# Boton btnsA4[1]: INSTALAR APKs
$btnsA4[1].Text = "INSTALAR APKs"
$btnsA4[1].ForeColor = [System.Drawing.Color]::FromArgb(180,80,255)
$btnsA4[1].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(180,80,255)
$btnsA4[1].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

$btnRemFRP.Add_Click({
    $btn = $btnRemFRP

    # --- PASO 0: Mensaje inicial y verificaciones ---
    $Global:logAdb.Clear()
    AutoRoot-Log "=============================================="
    AutoRoot-Log "   AUTOROOT MAGISK 1-CLICK  -  RNX TOOL PRO"
    AutoRoot-Log "=============================================="
    AutoRoot-Log ""
    AutoRoot-Log "[*] REQUISITOS:"
    AutoRoot-Log "    1. Bootloader DESBLOQUEADO (KG: Prenormal)"
    AutoRoot-Log "    2. Equipo conectado con USB Debugging activado"
    AutoRoot-Log "    3. magiskboot.exe (Windows x64) en .\tools\"
    AutoRoot-Log "    4. magisk27.apk (y magisk24.apk para modelos legacy) en .\tools\"
    AutoRoot-Log "    5. lz4.exe en .\tools\"
    AutoRoot-Log "    6. heimdall.exe en .\tools\ (o Odin3.exe)"
    AutoRoot-Log "    (la version de Magisk se elige automaticamente segun el modelo)"
    AutoRoot-Log ""

    # Verificar ADB activo usando la capa de servicios
    try {
        Assert-DeviceReady -Mode ADB -MinBattery 50
    } catch {
        AutoRoot-Log "[!] $_"
        AutoRoot-Log "[~] Conecta el equipo con USB Debugging activado."
        AutoRoot-Log "[~] Si el bootloader esta abierto y estas en recovery,"
        AutoRoot-Log "[~] activa ADB desde: Ajustes > Opciones desarrollador > Depuracion USB"
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }

    # Loguear estado del dispositivo antes de la operacion
    Write-RNXLogSection "AUTOROOT MAGISK"
    Get-DeviceStateSummary | ForEach-Object { Write-RNXLog "INFO" $_ "ADB" }

    # --- PASO 1: Leer info del dispositivo via adb directo (igual al resto de botones) ---
    AutoRoot-Log "[1] Leyendo informacion del dispositivo..."
    AutoRoot-SetStatus $btn "LEYENDO INFO..."
    [System.Windows.Forms.Application]::DoEvents()

    # Resolver ejecutable adb: intentar SVC_ADB cacheado, luego buscar manual, luego PATH
    $script:_arAdb = $null
    if ($script:SVC_ADB -and (Test-Path $script:SVC_ADB -ErrorAction SilentlyContinue)) {
        $script:_arAdb = $script:SVC_ADB
    } else {
        foreach ($c in @(
            (Join-Path $script:TOOLS_DIR "adb.exe"),
            "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
            "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
            "C:\platform-tools\adb.exe",
            "C:\android\platform-tools\adb.exe"
        )) {
            if (Test-Path $c -ErrorAction SilentlyContinue) { $script:_arAdb = $c; break }
        }
        if (-not $script:_arAdb) {
            try { $gc = Get-Command "adb" -ErrorAction SilentlyContinue; if ($gc) { $script:_arAdb = $gc.Source } } catch {}
        }
    }

    # Helper de lectura directa - igual al patron que funciona en Leer Info / Instalar Magisk
    function AR-Getprop([string]$prop) {
        if (-not $script:_arAdb) { return "" }
        try { $v = (& $script:_arAdb shell getprop $prop 2>$null); if ($v) { return $v.Trim() } } catch {}
        return ""
    }

    $devModel    = AR-Getprop "ro.product.model"
    $devBuild    = AR-Getprop "ro.build.display.id"
    $devAndroid  = AR-Getprop "ro.build.version.release"
    $devPatch    = AR-Getprop "ro.build.version.security_patch"
    $devCodename = AR-Getprop "ro.product.device"
    $devCsc      = AR-Getprop "ro.csc.sales_code"
    if (-not $devCsc) { $devCsc = AR-Getprop "ro.csc.country.code" }
    $oemLock     = AR-Getprop "ro.boot.flash.locked"
    $devSerial   = ""
    try {
        if ($script:_arAdb) { $devSerial = (& $script:_arAdb get-serialno 2>$null).Trim() }
    } catch { $devSerial = "" }

    # Mostrar siempre, incluso si vacio (para diagnostico)
    AutoRoot-Log "    MODELO      : $(if($devModel)  {$devModel}  else {'(no disponible)'})"
    AutoRoot-Log "    BUILD       : $(if($devBuild)  {$devBuild}  else {'(no disponible)'})"
    AutoRoot-Log "    ANDROID     : $(if($devAndroid){$devAndroid} else {'(no disponible)'})"
    AutoRoot-Log "    PARCHE SEG. : $(if($devPatch)  {$devPatch}  else {'(no disponible)'})"
    AutoRoot-Log "    CODENAME    : $(if($devCodename){$devCodename} else {'(no disponible)'})"
    AutoRoot-Log "    CSC         : $(if($devCsc)    {$devCsc}    else {'(no disponible)'})"
    AutoRoot-Log "    SERIAL      : $(if($devSerial) {$devSerial} else {'(no disponible)'})"
    AutoRoot-Log "    OEM LOCK    : $(if($oemLock -eq '1'){'LOCKED - Abrir BL primero!'} else {'UNLOCKED OK'})"
    AutoRoot-Log ""
    [System.Windows.Forms.Application]::DoEvents()

    # --- SELECCION AUTOMATICA DE VERSION DE MAGISK ---
    # Asegurar que devModel este limpio antes de la deteccion legacy
    $devModelClean = if ($devModel) { $devModel.Trim().ToUpper() } else { "" }
    if (-not $devModelClean) {
        AutoRoot-Log "[!] No se pudo leer el modelo del dispositivo."
        AutoRoot-Log "[~] Verifica la conexion ADB y USB Debugging activo."
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }
    $magiskbootExe = Get-MagiskbootExe $devModelClean
    if (-not $magiskbootExe) {
        AutoRoot-Log "[!] No se pudo preparar magiskboot o los binarios de Magisk"
        AutoRoot-Log "[~] Verifica que tienes en .\tools\:"
        AutoRoot-Log "    magiskboot.exe   <- descarga de github.com/affggh/magiskboot_build/releases"
        AutoRoot-Log "    magisk27.apk     <- Magisk v27 (ya lo tienes)"
        AutoRoot-Log "    magisk24.apk     <- solo para modelos legacy (A21s/A13/A51 5G)"
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }
    AutoRoot-Log ""

    if ($oemLock -eq "1") {
        AutoRoot-Log "[!] ERROR: El bootloader esta BLOQUEADO."
        AutoRoot-Log "[!] No es posible flashear el boot parcheado."
        AutoRoot-Log "[~] Abre el bootloader primero desde: Ajustes > Info tel. > Num. compilacion (x7) > Dev options > OEM unlock"
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }

    # --- PASO 2: Seleccionar archivo AP firmware ---
    AutoRoot-Log "[2] Selecciona el archivo AP_*.tar.md5 del firmware Samsung..."
    AutoRoot-SetStatus $btn "SELECCIONAR AP..."
    [System.Windows.Forms.Application]::DoEvents()

    $fd = New-Object System.Windows.Forms.OpenFileDialog
    $fd.Title  = "Selecciona el archivo AP del firmware Samsung (AP_*.tar.md5)"
    $fd.Filter = "Samsung AP Firmware|AP_*.tar.md5;AP_*.tar;AP_*.md5|Todos los tar|*.tar;*.md5;*.tar.md5|Todos|*.*"
    $fd.InitialDirectory = $script:SCRIPT_ROOT

    if ($fd.ShowDialog() -ne "OK") {
        AutoRoot-Log "[~] Cancelado por el usuario."
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }
    $apFile = $fd.FileName
    $apName = [System.IO.Path]::GetFileName($apFile)
    $apSizeMB = [math]::Round((Get-Item $apFile).Length / 1MB, 1)
    AutoRoot-Log "[+] AP seleccionado: $apName ($apSizeMB MB)"

    # Validar nombre del AP contra el modelo del telefono
    if ($apName -match "AP_([A-Z0-9]+)_") {
        $apBuildRaw    = $Matches[1]
        $devModelClean = $devModel -replace "[^A-Z0-9]",""
        # Extraer sufijo de firmware del build del dispositivo
        # Ej: "AP3A.240905.015.A2.G990EXXSIGYI3" -> "G990EXXSIGYI3"
        $devFwSuffix   = if ($devBuild -match "\.([A-Z0-9]{8,})$") { $Matches[1] } else { $devBuild -replace "[^A-Z0-9]","" }
        $match = $false
        if ($apBuildRaw -imatch [regex]::Escape($devModelClean))    { $match = $true }
        if ($apBuildRaw -eq $devFwSuffix)                           { $match = $true }
        if ($devFwSuffix -and $apBuildRaw -imatch [regex]::Escape($devFwSuffix)) { $match = $true }
        if ($match) {
            AutoRoot-Log "[+] VALIDACION: Firmware compatible con el dispositivo conectado"
            AutoRoot-Log "    AP build  : $apBuildRaw"
            AutoRoot-Log "    Dev build : $devBuild"
        } else {
            AutoRoot-Log "[!] ADVERTENCIA: El nombre del AP no coincide exactamente con el build del dispositivo"
            AutoRoot-Log "    AP build  : $apBuildRaw"
            AutoRoot-Log "    Dev build : $devBuild"
            AutoRoot-Log "[~] Puede ser de una version diferente."
            $cont = [System.Windows.Forms.MessageBox]::Show(
                "El firmware puede no coincidir exactamente con el dispositivo.`n`nAP:  $apBuildRaw`nDev: $devBuild`n`nContinuar de todas formas?",
                "Advertencia de compatibilidad",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($cont -ne "Yes") {
                AutoRoot-Log "[~] Cancelado."
                AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
                return
            }
        }
    }
    AutoRoot-Log ""

    # --- PASO 3: Escaneo rapido del TAR ---
    AutoRoot-Log "[3] Escaneando contenido del TAR..."
    AutoRoot-SetStatus $btn "ESCANEANDO TAR..."

    $scanResult = Find-BootInTar $apFile
    AutoRoot-Log "    init_boot encontrado : $($scanResult.InitBoot)"
    AutoRoot-Log "    boot encontrado      : $($scanResult.Boot)"

    if (-not $scanResult.Target) {
        AutoRoot-Log "[!] No se encontro boot.img.lz4 ni init_boot.img.lz4 en el AP"
        AutoRoot-Log "[!] Verifica que sea un firmware Samsung valido (AP_*.tar.md5)"
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }

    $targetFile  = $scanResult.Target
    $isInitBoot  = ($targetFile -imatch "init_boot")
    $partName    = if ($isInitBoot) { "INIT_BOOT" } else { "BOOT" }

    AutoRoot-Log "[+] Archivo objetivo: $targetFile"
    AutoRoot-Log "[+] Particion Samsung: $partName"
    if ($scanResult.InitBoot -and $scanResult.Boot) {
        AutoRoot-Log "[+] Encontrados boot e init_boot -> usando init_boot"
    } elseif ($isInitBoot) {
        AutoRoot-Log "[+] Solo init_boot encontrado -> usando init_boot"
    } else {
        AutoRoot-Log "[+] Solo boot encontrado -> usando boot.img"
    }
    AutoRoot-Log ""

    # --- PASO 4: Extraccion quirurgica ---
    AutoRoot-Log "[4] Extrayendo solo el archivo necesario del firmware..."
    AutoRoot-SetStatus $btn "EXTRAYENDO BOOT..."

    $stamp   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $workDir = [System.IO.Path]::Combine($script:SCRIPT_ROOT, "BACKUPS", "AUTOROOT", $stamp)
    New-Item $workDir -ItemType Directory -Force | Out-Null

    $extractedLz4 = Extract-SingleFromTar $apFile $targetFile $workDir
    if (-not $extractedLz4) {
        AutoRoot-Log "[!] Error extrayendo el boot del firmware."
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }

    # --- PASO 5: Descomprimir LZ4 ---
    AutoRoot-Log ""
    AutoRoot-Log "[5] Descomprimiendo LZ4..."
    AutoRoot-SetStatus $btn "DESCOMPRIMIENDO..."

    $imgBase = [System.IO.Path]::GetFileName($extractedLz4) -replace "\.lz4$",""
    $imgPath = [System.IO.Path]::Combine($workDir, $imgBase)
    $lz4ok   = Expand-LZ4 $extractedLz4 $imgPath

    if (-not $lz4ok) {
        AutoRoot-Log "[!] Error descomprimiendo LZ4."
        AutoRoot-Log "[~] Verifica que lz4.exe este en .\tools\"
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }
    $imgSz = [math]::Round((Get-Item $imgPath).Length/1MB,2)
    AutoRoot-Log "[+] Imagen descomprimida: $imgBase ($imgSz MB)"
    AutoRoot-Log ""

    # --- PASO 6: Parcheo via Magisk App en el dispositivo ---
    # magiskboot.exe en Windows no puede leer propiedades del sistema Android
    # (KEEPVERITY, PREINITDEVICE, estado AVB) -> parcheo incorrecto -> bootloop.
    # La solucion es usar Magisk App directamente en el dispositivo (ARM64 nativo)
    # que detecta y aplica correctamente todos los parametros del modelo especifico.
    # Funciona para cualquier modelo: G990E (Android 15), A125M (Android 11-12), etc.
    AutoRoot-Log "[6] Parcheando boot via Magisk App en el dispositivo..."
    AutoRoot-SetStatus $btn "PARCHEANDO..."

    # Instalar Magisk APK si no esta instalado
    $apkPath  = if ($magiskbootExe.IsLegacy) { $script:MAGISK_APK_24 } else { $script:MAGISK_APK_27 }
    $apkLabel = if ($magiskbootExe.IsLegacy) { "Magisk 24 (legacy)" } else { "Magisk 27" }
    $magiskPkg = (& adb shell "pm list packages com.topjohnwu.magisk" 2>$null) -join ""
    if ($magiskPkg -notmatch "com.topjohnwu.magisk") {
        AutoRoot-Log "[~] Instalando $apkLabel en el dispositivo..."
        $instOut = (& adb install -r "$apkPath" 2>&1) -join ""
        if ($instOut -imatch "Success") {
            AutoRoot-Log "[+] $apkLabel instalado OK"
            Start-Sleep -Seconds 2
        } else {
            AutoRoot-Log "[!] Error instalando Magisk: $instOut"
            AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
            return
        }
    } else {
        AutoRoot-Log "[+] Magisk App ya instalada"
    }

    # Limpiar parches previos para no confundir la busqueda
    & adb shell "rm -f /sdcard/magisk_patched*.img /sdcard/Download/magisk_patched*.img" 2>$null | Out-Null

    # Subir boot.img al dispositivo
    # adb push reporta velocidad en stderr, NO es un error - verificar con ls
    $remoteBootPath = "/sdcard/rnx_boot_toparchear.img"
    $imgSzMB = [math]::Round((Get-Item $imgPath).Length/1MB,1)
    AutoRoot-Log "[~] Subiendo boot.img al dispositivo ($imgSzMB MB)..."
    $pushRaw = (& adb push "$imgPath" $remoteBootPath 2>&1)
    $pushRaw | ForEach-Object { $l = "$_".Trim(); if ($l) { AutoRoot-Log "    [push] $l" } }
    $remoteCheck = (& adb shell "ls $remoteBootPath 2>/dev/null" 2>$null) -join ""
    if (-not $remoteCheck -or $remoteCheck -notmatch "rnx_boot_toparchear") {
        AutoRoot-Log "[!] El archivo no llego al dispositivo - verifica la conexion ADB"
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }
    AutoRoot-Log "[+] boot.img subido OK: $remoteBootPath"

    # Abrir Magisk App en el dispositivo
    AutoRoot-Log "[~] Abriendo Magisk App..."
    & adb shell "am start -n com.topjohnwu.magisk/.ui.MainActivity" 2>$null | Out-Null
    Start-Sleep -Seconds 2
    [System.Windows.Forms.Application]::DoEvents()

    # Instrucciones en el log (siempre visibles)
    AutoRoot-Log ""
    AutoRoot-Log "================================================"
    AutoRoot-Log "  PASOS EN EL TELEFONO:"
    AutoRoot-Log "  1. Toca [ Instalar ] en la seccion Magisk"
    AutoRoot-Log "  2. Toca [ Seleccionar y parchear un archivo ]"
    AutoRoot-Log "  3. Navega a Almacenamiento interno"
    AutoRoot-Log "  4. Selecciona: rnx_boot_toparchear.img"
    AutoRoot-Log "  5. Toca [ EMPECEMOS ] y espera 'Listo!'"
    AutoRoot-Log "================================================"
    AutoRoot-Log ""

    # Dialogo bloqueante - el usuario confirma cuando Magisk termino
    $instrMsg = "Magisk App esta abierta en el telefono.`n`n" +
        "PASOS EN EL TELEFONO:`n" +
        "  1. Toca [ Instalar ] en la seccion Magisk`n" +
        "  2. Toca [ Seleccionar y parchear un archivo ]`n" +
        "  3. Navega a Almacenamiento interno`n" +
        "  4. Selecciona: rnx_boot_toparchear.img`n" +
        "  5. Toca [ EMPECEMOS ] y espera 'Listo!'`n`n" +
        "Presiona OK SOLO CUANDO Magisk muestre 'Listo!' / '!Listo!'"
    [System.Windows.Forms.MessageBox]::Show(
        $instrMsg, "PASO 6 - Parchear con Magisk App",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null

    # Buscar el archivo parcheado - Magisk lo guarda en /sdcard/Download/ (Android 13+)
    # o en /sdcard/ (Android 11-12). Buscar en ambas rutas.
    function Find-MagiskPatched {
        $candidates = @(
            "/sdcard/Download/magisk_patched*.img",
            "/sdcard/magisk_patched*.img",
            "/storage/emulated/0/Download/magisk_patched*.img",
            "/storage/emulated/0/magisk_patched*.img"
        )
        foreach ($pattern in $candidates) {
            $result = (& adb shell "ls $pattern 2>/dev/null" 2>$null) |
                Where-Object { "$_" -imatch "magisk_patched" } | Select-Object -First 1
            if ($result) { return "$result".Trim() }
        }
        # Fallback: find recursivo en ruta real del almacenamiento
        $result2 = (& adb shell "find /storage/emulated/0 -name 'magisk_patched*.img' 2>/dev/null" 2>$null) |
            Where-Object { "$_" -imatch "magisk_patched" } | Select-Object -First 1
        if ($result2) { return "$result2".Trim() }
        return $null
    }

    AutoRoot-Log "[~] Buscando boot parcheado en el dispositivo..."
    AutoRoot-Log "    (busca en /sdcard/Download/ y /sdcard/)"
    AutoRoot-SetStatus $btn "DESCARGANDO BOOT..."
    $patchedRemote = $null

    # 5 intentos automaticos con 3 segundos entre cada uno
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        $patchedRemote = Find-MagiskPatched
        if ($patchedRemote) { break }
        AutoRoot-Log "[~] No encontrado, reintentando ($($attempt+1)/5)..."
        Start-Sleep -Seconds 3
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Si no se encontro, dar opcion de reintentar indefinidamente
    while (-not $patchedRemote) {
        $retryRes = [System.Windows.Forms.MessageBox]::Show(
            "No se encontro el archivo parcheado.`n`n" +
            "Magisk lo guarda en:/sdcard/Download/magisk_patched-XXXXX.img`n`n" +
            "- OK: buscar de nuevo`n- Cancelar: abortar",
            "Archivo no encontrado",
            [System.Windows.Forms.MessageBoxButtons]::OKCancel,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($retryRes -ne "OK") { break }
        AutoRoot-Log "[~] Buscando de nuevo..."
        for ($r = 0; $r -lt 3; $r++) {
            $patchedRemote = Find-MagiskPatched
            if ($patchedRemote) { break }
            Start-Sleep -Seconds 3
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    if (-not $patchedRemote) {
        AutoRoot-Log "[!] Boot parcheado no encontrado"
        AutoRoot-Log "[~] Verifica: adb shell find /sdcard -name 'magisk_patched*'"
        & adb shell "rm -f $remoteBootPath" 2>$null | Out-Null
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }
    AutoRoot-Log "[+] Encontrado: $patchedRemote"

    # Descargar el boot parcheado al PC
    # Nombrar el archivo segun el tipo real: init_boot o boot
    $patchedImgName = if ($isInitBoot) { "magisk_patched_init_boot.img" } else { "magisk_patched_boot.img" }
    $patchedImg = [System.IO.Path]::Combine($workDir, $patchedImgName)
    AutoRoot-Log "[~] Descargando boot parcheado al PC..."
    & adb pull $patchedRemote $patchedImg 2>&1 | Out-Null
    if (-not (Test-Path $patchedImg)) {
        AutoRoot-Log "[!] Error descargando el boot parcheado"
        & adb shell "rm -f $remoteBootPath $patchedRemote" 2>$null | Out-Null
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }
    $pSz = [math]::Round((Get-Item $patchedImg).Length/1MB,2)
    AutoRoot-Log "[+] Boot parcheado listo: $pSz MB"
    & adb shell "rm -f $remoteBootPath $patchedRemote" 2>$null | Out-Null
    AutoRoot-Log "[+] Archivos temporales eliminados del dispositivo"
    AutoRoot-Log ""

    # --- PASO 7: Crear .tar y .tar.md5 para flash ---
    AutoRoot-Log "[7] Preparando archivos para flash..."
    AutoRoot-SetStatus $btn "PREPARANDO TAR..."

    $flashDir  = [System.IO.Path]::Combine($workDir, "flash")
    New-Item $flashDir -ItemType Directory -Force | Out-Null
    $tarResult = Build-OdinTar $patchedImg $flashDir $isInitBoot

    if (-not $tarResult) {
        AutoRoot-Log "[!] Error creando el archivo TAR."
        AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
        return
    }
    AutoRoot-Log ""

    # --- PASO 8: Flash via Odin (semi-manual) ---
    AutoRoot-Log "[8] Preparando flash con Odin..."
    AutoRoot-Log "[!] IMPORTANTE: El equipo debe estar en DOWNLOAD MODE"
    AutoRoot-Log "[~] Reiniciando a Download Mode via ADB..."
    & adb reboot download 2>$null
    AutoRoot-Log "[~] Esperando entrada a Download Mode..."
    Start-Sleep -Seconds 5
    [System.Windows.Forms.Application]::DoEvents()

    # Mensaje de espera: instrucciones mientras el equipo entra en DL mode
    [System.Windows.Forms.MessageBox]::Show(
        "El equipo esta reiniciando a DOWNLOAD MODE.`n`nEspera a que aparezca la pantalla de descarga en el telefono.`n`nDespues presiona OK para abrir Odin.",
        "Esperando Download Mode",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null

    AutoRoot-Log "[~] Abriendo Odin con el TAR parcheado..."
    AutoRoot-SetStatus $btn "ABRIENDO ODIN..."
    Open-OdinWithBoot $tarResult.TarMd5

    # --- Resumen final ---
    AutoRoot-Log ""
    AutoRoot-Log "=============================================="
    AutoRoot-Log "  RESUMEN AUTOROOT"
    AutoRoot-Log "=============================================="
    AutoRoot-Log "  Dispositivo : $devModel"
    AutoRoot-Log "  Build       : $devBuild"
    AutoRoot-Log "  Particion   : $partName"
    AutoRoot-Log "  Magiskboot  : $([System.IO.Path]::GetFileName($magiskbootExe.Exe))"
    AutoRoot-Log "  Boot img    : $([System.IO.Path]::GetFileName($patchedImg))"
    AutoRoot-Log "  TAR Odin    : $([System.IO.Path]::GetFileName($tarResult.TarMd5))"
    AutoRoot-Log "  Carpeta     : $workDir"
    AutoRoot-Log "=============================================="
    AutoRoot-Log ""
    AutoRoot-Log "[~] Si el equipo queda en RECOVERY MODE:"
    AutoRoot-Log "    Entra a: Wipe > Factory Reset > Yes"
    AutoRoot-Log "    Luego:   Reboot System"
    AutoRoot-Log ""
    AutoRoot-Log "[~] Archivos generados en:"
    AutoRoot-Log "    $workDir"
    # Abrir carpeta de trabajo automaticamente
    Start-Process explorer.exe $workDir -ErrorAction SilentlyContinue

    AutoRoot-SetStatus $btn "AUTOROOT MAGISK"
    $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  AUTOROOT completado  |  Ver log"
})

#==========================================================================
# BYPASS BANCARIO  -  Sistema completo de ocultacion de root
# Shamiko + LSPosed + Zygisk-Next + DenyList
# ARCHIVOS en .\tools\modules\ : Paso_1.zip Paso_2.zip Paso_3.zip Magisk-Delta-V27.zip
# ARCHIVOS en .\tools\          : magisk27.apk  magisk24.apk  magisk_delta.apk
#==========================================================================

function Bypass-Log($msg) { AdbLog $msg }
function Bypass-SetStatus($btn,$txt) {
    $btn.Text=$txt; $btn.Enabled=($txt -eq "BYPASS BANCARIO")
    [System.Windows.Forms.Application]::DoEvents()
}
function AdbRoot($cmd) {
    $r=(& adb shell "su -c '$cmd'" 2>$null)
    if ($r -is [array]) { return ($r -join "`n").Trim() }
    return "$r".Trim()
}
function Set-MagiskSetting($key, $value) {
    # Crea un script sh en el dispositivo que ejecuta el SQL sin problemas de comillas
    $script = "magisk --sqlite `'INSERT OR REPLACE INTO settings (key,value) VALUES(`"$key`",$value)`'"
    $tmpFile = [System.IO.Path]::GetTempFileName() + ".sh"
    $script | Set-Content -Path $tmpFile -Encoding ASCII -NoNewline
    & adb push "$tmpFile" "/data/local/tmp/rnx_set.sh" 2>$null | Out-Null
    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    $r = (& adb shell "su -c 'sh /data/local/tmp/rnx_set.sh'" 2>$null)
    if ($r -is [array]) { $r = ($r -join "").Trim() } else { $r = "$r".Trim() }
    return $r
}
function Get-MagiskSetting($key) {
    $script = "magisk --sqlite `'SELECT value FROM settings WHERE key=`"$key`"`'"
    $tmpFile = [System.IO.Path]::GetTempFileName() + ".sh"
    $script | Set-Content -Path $tmpFile -Encoding ASCII -NoNewline
    & adb push "$tmpFile" "/data/local/tmp/rnx_get.sh" 2>$null | Out-Null
    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    $r = (& adb shell "su -c 'sh /data/local/tmp/rnx_get.sh'" 2>$null)
    if ($r -is [array]) { $r = ($r -join "").Trim() } else { $r = "$r".Trim() }
    # Output de magisk --sqlite tiene formato "value=X"
    if ($r -match "value=(.+)") { return $Matches[1].Trim() }
    if ($r) { return $r } else { return "?" }
}
function Wait-AdbReconnect($timeoutSec) {
    Bypass-Log "[~] Esperando reconexion ADB (max $timeoutSec s)..."
    $elapsed=0
    while ($elapsed -lt $timeoutSec) {
        Start-Sleep -Seconds 3; $elapsed+=3
        [System.Windows.Forms.Application]::DoEvents()
        $devs=(& adb devices 2>$null) -join ""
        if ($devs -match "`tdevice") {
            Bypass-Log "[+] ADB reconectado ($elapsed s)"
            Start-Sleep -Seconds 4; [System.Windows.Forms.Application]::DoEvents()
            return $true
        }
        if ($elapsed % 15 -eq 0) { Bypass-Log "[~] Esperando... ($elapsed s)" }
    }
    Bypass-Log "[!] Timeout ($timeoutSec s)"; return $false
}
function Get-MagiskInfo {
    # magisk -c devuelve algo como "27000" o "27000:MAGISK:R"
    $ver = ""
    $verRaw = ((& adb shell "magisk -c" 2>$null) -join "").Trim()
    if ($verRaw -match "^(\d+)") { $ver = $Matches[1] }   # solo los digitos iniciales
    if (-not $ver) {
        $ver = ((& adb shell "getprop ro.magisk.version" 2>$null) -join "").Trim()
        if ($ver -match "^(\d+)") { $ver = $Matches[1] }
    }
    $vn = 0
    $verDisplay = $ver
    if ($ver -match "^(\d+)") {
        $vn = [int]$Matches[1]
        if ($vn -gt 1000) { $verDisplay = [string][int]([math]::Floor($vn / 1000)); $vn = [int]$verDisplay }
    }
    $isDelta = $false
    $dc = ((& adb shell "magisk -c 2>/dev/null" 2>$null) -join "")
    if ($dc -imatch "kitsune|delta") { $isDelta = $true }

    # Verifica APK instalado (binario puede existir sin APK)
    $apkInstalled = $false
    $pkgCheck = (& adb shell "pm list packages com.topjohnwu.magisk" 2>$null) -join ""
    if ($pkgCheck -imatch "com.topjohnwu.magisk") { $apkInstalled = $true }
    if (-not $apkInstalled) {
        $pkgDelta = (& adb shell "pm list packages io.github.huskydg.magisk" 2>$null) -join ""
        if ($pkgDelta -imatch "io.github.huskydg.magisk") { $apkInstalled = $true; $isDelta = $true }
    }

    return @{ Version=$verDisplay; VerNum=$vn; IsDelta=$isDelta; BinaryInstalled=($vn -gt 0); ApkInstalled=$apkInstalled; Installed=($vn -gt 0 -and $apkInstalled) }
}
function Install-Apk($apkPath,$label) {
    if (-not (Test-Path $apkPath)) { Bypass-Log "[!] APK no encontrado: $apkPath"; return $false }
    Bypass-Log "[~] Instalando $label..."
    $r=(& adb install -r "$apkPath" 2>&1) -join ""
    if ($r -imatch "Success") { Bypass-Log "[+] $label OK"; return $true }
    Bypass-Log "[!] Error: $r"; return $false
}
function Uninstall-Pkg($pkg,$label) {
    Bypass-Log "[~] Desinstalando $label..."
    $r=(& adb shell "pm uninstall $pkg" 2>$null) -join ""
    if ($r -imatch "Success") { Bypass-Log "[+] $label desinstalado"; return $true }
    Bypass-Log "[!] Error: $r"; return $false
}
function Install-MagiskModule($zipPath,$moduleName) {
    if (-not (Test-Path $zipPath)) { Bypass-Log "[!] No encontrado: $zipPath"; return $false }
    $rem="/sdcard/rnx_modules/$([System.IO.Path]::GetFileName($zipPath))"
    Bypass-Log "[~] Subiendo $moduleName..."
    & adb shell "mkdir -p /sdcard/rnx_modules" 2>$null | Out-Null
    # adb push reporta velocidad en stderr - NO es un error
    # Verificar exito comprobando que el archivo existe en el dispositivo
    & adb push "$zipPath" "$rem" 2>&1 | ForEach-Object { if ("$_" -match "KB/s|MB/s|bytes") { Bypass-Log "    [push] $_" } }
    $pushCheck = (& adb shell "ls $rem 2>/dev/null" 2>$null) -join ""
    if (-not $pushCheck -or $pushCheck -notmatch [regex]::Escape([System.IO.Path]::GetFileName($rem))) {
        Bypass-Log "[!] Push fallido - archivo no llego al dispositivo"
        return $false
    }
    Bypass-Log "[+] Subido OK"
    Bypass-Log "[~] Instalando modulo $moduleName..."
    $inst=AdbRoot "magisk --install-module $rem"
    AdbRoot "rm -f $rem" | Out-Null
    if ($inst -imatch "Done|Success|installed") { Bypass-Log "[+] $moduleName instalado"; return $true }
    # Verificar directamente en /data/adb/modules
    $idMap=@{shamiko="zygisk_shamiko";lsposed="zygisk_lsposed";zygisk="zygisksu";delta="magisk_delta"}
    $modId=""
    foreach ($k in $idMap.Keys) { if ($moduleName -imatch $k) { $modId=$idMap[$k]; break } }
    if ($modId) {
        $chk=AdbRoot "ls /data/adb/modules/$modId 2>/dev/null"
        if ($chk) { Bypass-Log "[+] $moduleName verificado en modules/$modId"; return $true }
    }
    Bypass-Log "[~] Respuesta: $inst"; Bypass-Log "[+] Asumiendo OK (confirmar al reiniciar)"
    return $true
}
function Configure-MagiskDenyList {
    # Solo busca apps bancarias y las agrega a DenyList
    # Zygisk y DenyList ya activados por el flujo principal antes de llamar esta funcion
    $bankKw=@("yape","bcp","bbva","interbank","scotiabank","bim","ripley","falabella","bcpbankapp","mibanco","intercorp","scotiam")
    Bypass-Log "[~] Buscando apps bancarias instaladas..."
    $allPkgs=(& adb shell "pm list packages" 2>$null) -join "`n"
    $allPkgs=$allPkgs -replace "package:",""
    $found=@()
    foreach ($kw in $bankKw) {
        $ms=($allPkgs -split "`n" | Where-Object { $_ -imatch $kw -and $_.Trim() -ne "" })
        foreach ($p in $ms) { $p=$p.Trim(); if ($p -and $found -notcontains $p) { $found+=$p } }
    }
    if ($found.Count -eq 0) {
        Bypass-Log "[!] No se encontraron apps bancarias - agregar manualmente en Magisk > DenyList"
    } else {
        Bypass-Log "[+] Apps encontradas: $($found.Count)"
        foreach ($pkg in $found) {
            Bypass-Log "    -> $pkg"
            AdbRoot "magisk --denylist add $pkg" | Out-Null
            AdbRoot "magisk --denylist add $pkg $pkg" | Out-Null
            Bypass-Log "    [OK] $pkg -> DenyList"
        }
    }
    $dlRaw = AdbRoot "magisk --denylist ls 2>/dev/null"
    $dc = ($dlRaw -split "[`n`r]+" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { ($_ -split "/")[0].Trim() } | Select-Object -Unique).Count
    Bypass-Log "[+] DenyList configurada: $dc entradas"
    return $found
}

$btnsA2[1].Add_Click({
    $btn=$btnsA2[1]
    $Global:logAdb.Clear()
    Bypass-Log "=============================================="
    Bypass-Log "   BYPASS BANCARIO  -  RNX TOOL PRO"
    Bypass-Log "   Shamiko + LSPosed + Zygisk-Next"
    Bypass-Log "=============================================="
    Bypass-Log ""
    Bypass-Log "[*] TARGET: Yape, BCP, BBVA, Interbank, Scotiabank, BIM, Ripley, Falabella"
    Bypass-Log "[*] LEGACY (A21s/A135/A515): Magisk 24 -> Delta 27 -> flujo estandar"
    Bypass-Log ""
    $toolsDir   = $script:TOOLS_DIR
    $modulesDir = $script:MODULES_DIR
    $zipPaso1=Join-Path $modulesDir "Paso_1.zip"
    $zipPaso2=Join-Path $modulesDir "Paso_2.zip"
    $zipPaso3=Join-Path $modulesDir "Paso_3.zip"
    $zipDelta=Join-Path $modulesDir "Magisk-Delta-V27.zip"
    $apkM27=Join-Path $toolsDir "magisk27.apk"
    $apkM24=Join-Path $toolsDir "magisk24.apk"
    $apkDelta=Join-Path $toolsDir "magisk_delta.apk"

    Bypass-Log "[1] Verificando ADB..."
    Bypass-SetStatus $btn "VERIFICANDO..."
    $adbCheck = $false
    try { $adbCheck = ((& adb devices 2>$null) -join "" -match "`tdevice") } catch {}
    if (-not $adbCheck) {
        Bypass-Log "[!] Sin equipo ADB conectado."
        Bypass-Log "[~] Conecta el equipo con USB Debugging activo."
        Bypass-Log "[~] NOTA: Requiere AUTOROOT MAGISK previo."
        Bypass-Log ""
        Bypass-Log "[~] Si ves error de virus/antivirus en el log:"
        Bypass-Log "    Windows Defender bloquea adb.exe (falso positivo)."
        Bypass-Log "    Solucion: Win Security > Historial > Permitir adb.exe"
        Bypass-Log "    O: Win Security > Exclusiones > Agregar carpeta C:\RNX_TOOL\"
        Bypass-SetStatus $btn "BYPASS BANCARIO"; return
    }
    $devModelRaw = $null
    try { $devModelRaw = (& adb shell getprop ro.product.model 2>$null) } catch {}
    $devModel = if ($devModelRaw -and $devModelRaw -isnot [System.Management.Automation.ErrorRecord]) {
        if ($devModelRaw -is [array]) { ($devModelRaw -join "").Trim() } else { "$devModelRaw".Trim() }
    } else { "" }
    $isLegacy = $false
    if ($devModel -ne "") {
        foreach ($leg in $script:MAGISK_LEGACY_MODELS) {
            if ($devModel.ToUpper() -eq $leg.ToUpper()) { $isLegacy = $true; break }
        }
    }
    $modelDisp = if ($devModel) { $devModel } else { "(no detectado)" }
    Bypass-Log "[+] Modelo: $modelDisp $(if($isLegacy){'[LEGACY]'} else {'[ESTANDAR]'})"
    Bypass-Log ""

    Bypass-Log "[2] Verificando root..."
    Bypass-SetStatus $btn "CHEQUEANDO ROOT..."
    if ((AdbRoot "id") -notmatch "uid=0") {
        Bypass-Log "[!] Sin root. Ejecuta AUTOROOT MAGISK primero."
        Bypass-SetStatus $btn "BYPASS BANCARIO"; return
    }
    Bypass-Log "[+] Root OK"
    Bypass-Log ""

    Bypass-Log "[3] Detectando Magisk..."
    Bypass-SetStatus $btn "DETECTANDO MAGISK..."
    $mInfo=Get-MagiskInfo
    Bypass-Log "[~] Binario: $(if($mInfo.BinaryInstalled){'OK v'+$mInfo.Version} else {'NO ENCONTRADO'})  |  APK: $(if($mInfo.ApkInstalled){'INSTALADO'} else {'NO INSTALADO'})"

    # Si el binario no esta -> instalar APK completo
    if (-not $mInfo.BinaryInstalled) {
        Bypass-Log "[!] Magisk no detectado - instalando APK..."
        if ($isLegacy) { Install-Apk $apkM24 "Magisk 24.1" | Out-Null }
        else { Install-Apk $apkM27 "Magisk 27" | Out-Null }
        Start-Sleep -Seconds 3; $mInfo=Get-MagiskInfo
    } else {
        # Binario OK -> siempre reinstalar APK para asegurar que este fresco y funcional
        Bypass-Log "[~] Reinstalando APK de Magisk (forzado)..."
        Bypass-SetStatus $btn "INSTALANDO MAGISK APK..."
        if ($isLegacy) { Install-Apk $apkM24 "Magisk 24.1" | Out-Null }
        else { Install-Apk $apkM27 "Magisk 27" | Out-Null }
        Start-Sleep -Seconds 2; $mInfo=Get-MagiskInfo
    }

    Bypass-Log "[+] Magisk v$($mInfo.Version) | APK: $(if($mInfo.ApkInstalled){'OK'} else {'FALLO - instalar manualmente'}) | Delta: $($mInfo.IsDelta)"
    Bypass-Log ""

    # RAMA LEGACY: Flujo Magisk 24 -> Delta -> Magisk 27 completo
    if ($isLegacy) {
        Bypass-Log "================================================"
        Bypass-Log "  RUTA LEGACY: A21s / A13 / A51 - Flujo completo"
        Bypass-Log "  Magisk 24 -> Delta Module -> Magisk 27"
        Bypass-Log "================================================"
        Bypass-Log ""

        # --- PASO L1: Verificar e instalar Magisk 24 ---
        Bypass-Log "[L1] Verificando Magisk 24..."
        Bypass-SetStatus $btn "VERIFICANDO MAGISK 24..."
        $m24Info = Get-MagiskInfo
        if (-not $m24Info.BinaryInstalled -or $m24Info.VerNum -ge 25) {
            Bypass-Log "[~]  Magisk 24 no instalado o version incorrecta -> instalando..."
            if (-not (Test-Path $apkM24)) {
                Bypass-Log "[!] No se encontro magisk24.apk en tools\"
                Bypass-SetStatus $btn "BYPASS BANCARIO"; return
            }
            Install-Apk $apkM24 "Magisk 24" | Out-Null
            Start-Sleep -Seconds 3
            $m24Info = Get-MagiskInfo
            if (-not $m24Info.BinaryInstalled) {
                Bypass-Log "[!] Fallo instalacion de Magisk 24. Verifica el APK."
                Bypass-SetStatus $btn "BYPASS BANCARIO"; return
            }
        }
        Bypass-Log "[+] Magisk 24 OK  (v$($m24Info.Version))"
        Bypass-Log ""

        # --- PASO L2: Cargar modulo Delta v27 al equipo ---
        Bypass-Log "[L2] Subiendo modulo Magisk-Delta al equipo..."
        Bypass-SetStatus $btn "SUBIENDO DELTA ZIP..."
        if (-not (Test-Path $zipDelta)) {
            Bypass-Log "[!] No se encontro Magisk-Delta-V27.zip en tools\modules\"
            Bypass-SetStatus $btn "BYPASS BANCARIO"; return
        }
        & adb shell "mkdir -p /sdcard/rnx_modules" 2>$null | Out-Null
        & adb push "$zipDelta" "/sdcard/rnx_modules/Magisk-Delta-V27.zip" 2>&1 | ForEach-Object {
            if ("$_" -match "KB/s|MB/s|bytes") { Bypass-Log "    $_" }
        }
        $chkDelta = (& adb shell "[ -f /sdcard/rnx_modules/Magisk-Delta-V27.zip ] && echo OK || echo FAIL" 2>$null) -join ""
        if ($chkDelta -notmatch "OK") {
            Bypass-Log "[!] Error subiendo Magisk-Delta-V27.zip al equipo"
            Bypass-SetStatus $btn "BYPASS BANCARIO"; return
        }
        Bypass-Log "[+] Magisk-Delta-V27.zip subido -> /sdcard/rnx_modules/"
        Bypass-Log ""

        # --- PASO L3: Abrir Magisk y mostrar instrucciones para instalar Delta zip ---
        Bypass-Log "[L3] Abriendo Magisk en el celular para instalar modulo Delta..."
        & adb shell "am start -n com.topjohnwu.magisk/.ui.MainActivity" 2>$null | Out-Null
        Start-Sleep -Milliseconds 1000
        $screenSz = (& adb shell "wm size" 2>$null) -join ""
        $tapX2 = 540; $tapY2 = 900
        if ($screenSz -match "(\d+)x(\d+)") {
            $sw2 = [int]$Matches[1]; $sh2 = [int]$Matches[2]
            $tapX2 = [int]($sw2 * 0.375); $tapY2 = [int]($sh2 * 0.962)
        }
        & adb shell "input tap $tapX2 $tapY2" 2>$null | Out-Null
        Start-Sleep -Milliseconds 600
        [System.Windows.Forms.Application]::DoEvents()

        $nl = "`r`n"
        $instrDelta  = "-------------------------------------------------------$nl"
        $instrDelta += "  MODULO DELTA LISTO EN: /sdcard/rnx_modules/$nl"
        $instrDelta += "  (Magisk 24 ya se abrio en el celular)$nl"
        $instrDelta += "-------------------------------------------------------$nl"
        $instrDelta += "$nl"
        $instrDelta += "  Sigue estos pasos en el celular:$nl"
        $instrDelta += "$nl"
        $instrDelta += "  [1]  En Magisk 24 toca la pestana MODULOS (icono puzzle)$nl"
        $instrDelta += "$nl"
        $instrDelta += "  [2]  Toca >> Instalar desde almacenamiento$nl"
        $instrDelta += "$nl"
        $instrDelta += "  [3]  Navega a: /sdcard/rnx_modules/$nl"
        $instrDelta += "$nl"
        $instrDelta += "  [4]  Selecciona e instala: Magisk-Delta-V27.zip$nl"
        $instrDelta += "$nl"
        $instrDelta += "  [5]  Si pide reinicio, toca 'Mas tarde'$nl"
        $instrDelta += "       NO reinicies todavia.$nl"
        $instrDelta += "$nl"
        $instrDelta += "  [6]  Con el modulo instalado, vuelve aqui y$nl"
        $instrDelta += "       presiona el boton verde para continuar.$nl"
        $instrDelta += "$nl"
        $instrDelta += "-------------------------------------------------------$nl"
        $instrDelta += "  IMPORTANTE: Instala el modulo Delta SIN reiniciar$nl"
        $instrDelta += "  El programa continuara automaticamente despues.$nl"
        $instrDelta += "-------------------------------------------------------$nl"

        $dlgDelta = New-Object System.Windows.Forms.Form
        $dlgDelta.Text = "RNX TOOL PRO - Instalar Modulo Delta en Magisk 24"
        $dlgDelta.ClientSize = New-Object System.Drawing.Size(560, 460)
        $dlgDelta.BackColor = [System.Drawing.Color]::FromArgb(18,18,18)
        $dlgDelta.FormBorderStyle = "FixedDialog"
        $dlgDelta.StartPosition = "CenterScreen"
        $dlgDelta.TopMost = $true

        $lbDeltaTitulo = New-Object Windows.Forms.Label
        $lbDeltaTitulo.Text = "INSTALAR MODULO DELTA EN MAGISK 24  [LEGACY]"
        $lbDeltaTitulo.Location = New-Object System.Drawing.Point(14,12)
        $lbDeltaTitulo.Size = New-Object System.Drawing.Size(532,20)
        $lbDeltaTitulo.ForeColor = [System.Drawing.Color]::FromArgb(255,180,0)
        $lbDeltaTitulo.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $dlgDelta.Controls.Add($lbDeltaTitulo)

        $txtDelta = New-Object Windows.Forms.TextBox
        $txtDelta.Multiline = $true; $txtDelta.ReadOnly = $true; $txtDelta.Text = $instrDelta
        $txtDelta.Location = New-Object System.Drawing.Point(14,38)
        $txtDelta.Size = New-Object System.Drawing.Size(532,370)
        $txtDelta.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
        $txtDelta.ForeColor = [System.Drawing.Color]::White
        $txtDelta.Font = New-Object System.Drawing.Font("Consolas",9)
        $txtDelta.ScrollBars = "Vertical"
        $dlgDelta.Controls.Add($txtDelta)

        $btnDeltaOK = New-Object Windows.Forms.Button
        $btnDeltaOK.Text = "YA INSTALE EL MODULO DELTA - CONTINUAR"
        $btnDeltaOK.Location = New-Object System.Drawing.Point(14,416)
        $btnDeltaOK.Size = New-Object System.Drawing.Size(340,36)
        $btnDeltaOK.FlatStyle = "Flat"
        $btnDeltaOK.BackColor = [System.Drawing.Color]::FromArgb(0,120,0)
        $btnDeltaOK.ForeColor = [System.Drawing.Color]::White
        $btnDeltaOK.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $btnDeltaOK.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
        $btnDeltaOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $dlgDelta.Controls.Add($btnDeltaOK)

        $btnDeltaCancel = New-Object Windows.Forms.Button
        $btnDeltaCancel.Text = "CANCELAR"
        $btnDeltaCancel.Location = New-Object System.Drawing.Point(366,416)
        $btnDeltaCancel.Size = New-Object System.Drawing.Size(180,36)
        $btnDeltaCancel.FlatStyle = "Flat"
        $btnDeltaCancel.BackColor = [System.Drawing.Color]::FromArgb(80,20,20)
        $btnDeltaCancel.ForeColor = [System.Drawing.Color]::White
        $btnDeltaCancel.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $btnDeltaCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::OrangeRed
        $btnDeltaCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $dlgDelta.Controls.Add($btnDeltaCancel)
        $dlgDelta.AcceptButton = $btnDeltaOK; $dlgDelta.CancelButton = $btnDeltaCancel

        Bypass-Log "[~] Esperando que el usuario instale el modulo Delta..."
        Bypass-SetStatus $btn "ESPERANDO DELTA..."
        $resDelta = $dlgDelta.ShowDialog()
        if ($resDelta -ne [System.Windows.Forms.DialogResult]::OK) {
            Bypass-Log "[!] Cancelado por el usuario."
            Bypass-SetStatus $btn "BYPASS BANCARIO"; return
        }
        Bypass-Log "[+] Usuario confirmo modulo Delta instalado."
        Bypass-Log ""

        # --- PASO L4: Instalar Magisk Delta APK ---
        Bypass-Log "[L4] Instalando Magisk Delta APK..."
        Bypass-SetStatus $btn "INSTALANDO DELTA APK..."
        if (-not (Test-Path $apkDelta)) {
            Bypass-Log "[!] No se encontro magisk_delta.apk en tools\"
            Bypass-SetStatus $btn "BYPASS BANCARIO"; return
        }
        Install-Apk $apkDelta "Magisk Delta v27" | Out-Null
        Bypass-Log ""

        # --- PASO L5: Desinstalar Magisk 24 original ---
        Bypass-Log "[L5] Desinstalando Magisk 24 original..."
        Bypass-SetStatus $btn "DESINSTALANDO MAGISK 24..."
        Uninstall-Pkg "com.topjohnwu.magisk" "Magisk 24" | Out-Null
        Bypass-Log ""

        # --- PASO L6: Reiniciar y esperar reconexion ---
        Bypass-Log "[L6] Reiniciando para activar Magisk Delta..."
        Bypass-Log "[~]  El programa esperara la reconexion automaticamente..."
        Bypass-SetStatus $btn "REINICIANDO..."
        & adb reboot 2>$null; Start-Sleep -Seconds 10
        [System.Windows.Forms.Application]::DoEvents()
        if (-not (Wait-AdbReconnect 180)) {
            Bypass-Log "[!] Reconexion ADB fallida tras reinicio."
            Bypass-Log "[~]  Reconecta el cable USB y espera que el equipo arranque completamente."
            Bypass-Log "[~]  Luego vuelve a presionar BYPASS BANCARIO para continuar."
            Bypass-SetStatus $btn "BYPASS BANCARIO"; return
        }
        Start-Sleep -Seconds 5
        [System.Windows.Forms.Application]::DoEvents()
        $mInfo = Get-MagiskInfo
        Bypass-Log "[+] Post-reboot: Magisk v$($mInfo.Version) | Delta: $($mInfo.IsDelta) | APK: $(if($mInfo.ApkInstalled){'OK'} else {'NO'})"
        Bypass-Log "[OK] Migracion Legacy completada: Magisk 24 -> Delta 27"
        Bypass-Log "[~] Continuando con flujo estandar: modulos + Zygisk + DenyList..."
        Bypass-Log ""
        # A partir de aqui cae al flujo principal (identico a Magisk 27 estandar)
        # El flujo principal instala los 3 modulos, activa Zygisk, configura DenyList,
        # desactiva Zygisk, oculta Magisk y reinicia
    } elseif ($mInfo.VerNum -lt 25 -and -not $mInfo.IsDelta) {
        # Legacy detectado pero no en tabla (fallback por version)
        Bypass-Log "[!] Magisk antiguo detectado y modelo no en tabla legacy."
        Bypass-Log "[~]  Actualiza Magisk manualmente a v27 y reintenta."
        Bypass-SetStatus $btn "BYPASS BANCARIO"; return
    }

    # RAMA PRINCIPAL: flujo comun para Magisk 27 estandar Y Legacy (post-migracion)
    # 1. Subir + instalar 3 modulos (Paso_1/2/3.zip)
    # 2. Activar Zygisk=1 + DenyList=1 en DB
    # 3. Agregar apps bancarias a DenyList
    # 4. Shamiko blacklist mode
    # 5. Desactivar Zygisk (DenyList queda activa)
    # 6. Ocultar Magisk
    # 7. Reiniciar
    Bypass-Log "================================================"
    Bypass-Log "  BYPASS BANCARIO - INSTALANDO MODULOS"
    Bypass-Log "  [Aplica a Magisk 27 y Legacy post-migracion]"
    Bypass-Log "================================================"
    Bypass-Log ""

    # Verificar que los zips existen
    $modOk = $true
    foreach ($pair in @(@($zipPaso1,"Paso_1.zip (Shamiko)"),@($zipPaso2,"Paso_2.zip (LSPosed)"),@($zipPaso3,"Paso_3.zip (Zygisk Next)"))) {
        if (-not (Test-Path $pair[0])) { Bypass-Log "[!] Falta: $($pair[1]) en tools\modules\"; $modOk = $false }
    }
    if (-not $modOk) { Bypass-SetStatus $btn "BYPASS BANCARIO"; return }

    # -------------------------------------------------------
    # PASO 1: Subir los 3 zips al dispositivo
    # -------------------------------------------------------
    Bypass-Log "[1] Subiendo modulos al dispositivo..."
    & adb shell "mkdir -p /sdcard/rnx_modules" 2>$null | Out-Null
    Bypass-SetStatus $btn "SUBIENDO ZIPS..."

    foreach ($pair in @(@($zipPaso1,"Paso_1.zip"),@($zipPaso2,"Paso_2.zip"),@($zipPaso3,"Paso_3.zip"))) {
        $zipPath = $pair[0]; $zipName = $pair[1]
        Bypass-Log "[~] Subiendo $zipName..."
        & adb push "$zipPath" "/sdcard/rnx_modules/$zipName" 2>&1 | ForEach-Object {
            if ("$_" -match "KB/s|MB/s|bytes") { Bypass-Log "    $_" }
        }
        $chk = (& adb shell "[ -f /sdcard/rnx_modules/$zipName ] && echo OK || echo FAIL" 2>$null) -join ""
        if ($chk -imatch "OK") { Bypass-Log "[+] $zipName subido OK" }
        else { Bypass-Log "[!] Error subiendo $zipName"; Bypass-SetStatus $btn "BYPASS BANCARIO"; return }
    }
    Bypass-Log ""
    Bypass-Log "[+] Los 3 modulos estan en: /sdcard/rnx_modules/"
    Bypass-Log ""

    # -------------------------------------------------------
    # PASO 2: Abrir Magisk en pestana Modulos + mostrar instrucciones
    # -------------------------------------------------------
    Bypass-Log "[~] Abriendo Magisk en el celular (pestana Modulos)..."
    # Abre Magisk y navega a la pestana Modulos (tab index 1 = Modules en Magisk 24+)
    & adb shell "am start -n com.topjohnwu.magisk/.ui.MainActivity" 2>$null | Out-Null
    Start-Sleep -Milliseconds 1000
    # Simula tap en el icono de Modulos (segundo icono de la barra inferior)
    # Primero obtiene resolucion de pantalla para calcular coordenadas
    $screenSize = (& adb shell "wm size" 2>$null) -join ""
    $tapX = 540; $tapY = 900   # coordenadas por defecto para 1080p
    if ($screenSize -match "(\d+)x(\d+)") {
        $sw = [int]$Matches[1]; $sh = [int]$Matches[2]
        # El icono Modulos es el 2do de 4 en la barra inferior, a ~37.5% del ancho, ~96% del alto
        $tapX = [int]($sw * 0.375)
        $tapY = [int]($sh * 0.962)
    }
    & adb shell "input tap $tapX $tapY" 2>$null | Out-Null
    Start-Sleep -Milliseconds 600
    [System.Windows.Forms.Application]::DoEvents()
    Bypass-Log "[+] Magisk abierto - ve a la pestana MODULOS si no se abrio sola"
    Bypass-Log ""

    # Armar instrucciones con saltos CRLF que Windows Forms requiere
    $nl = "`r`n"
    $instrucciones  = "-------------------------------------------------------$nl"
    $instrucciones += "  MODULOS LISTOS EN: /sdcard/rnx_modules/$nl"
    $instrucciones += "  (Magisk ya se abrio en el celular)$nl"
    $instrucciones += "-------------------------------------------------------$nl"
    $instrucciones += "$nl"
    $instrucciones += "  Sigue estos pasos en el celular:$nl"
    $instrucciones += "$nl"
    $instrucciones += "  [1]  En Magisk toca la pestana MODULOS (icono puzzle)$nl"
    $instrucciones += "$nl"
    $instrucciones += "  [2]  Toca >> Instalar desde almacenamiento$nl"
    $instrucciones += "$nl"
    $instrucciones += "  [3]  Navega a: /sdcard/rnx_modules/$nl"
    $instrucciones += "$nl"
    $instrucciones += "  [4]  Instala los zips EN ESTE ORDEN:$nl"
    $instrucciones += "         - Paso_1.zip  (Shamiko)$nl"
    $instrucciones += "         - Paso_2.zip  (LSPosed)$nl"
    $instrucciones += "         - Paso_3.zip  (Zygisk Next)$nl"
    $instrucciones += "$nl"
    $instrucciones += "  [5]  Instala los 3 SIN reiniciar entre cada uno.$nl"
    $instrucciones += "       Si Magisk pide reinicio, toca 'Mas tarde'$nl"
    $instrucciones += "       hasta tener los 3 instalados.$nl"
    $instrucciones += "$nl"
    $instrucciones += "  [6]  Con los 3 listos, vuelve aqui y presiona$nl"
    $instrucciones += "       el boton verde de abajo.$nl"
    $instrucciones += "$nl"
    $instrucciones += "-------------------------------------------------------$nl"
    $instrucciones += "  IMPORTANTE: Zygisk debe estar ACTIVADO en Magisk$nl"
    $instrucciones += "              durante todo el proceso de instalacion$nl"
    $instrucciones += "-------------------------------------------------------$nl"

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "RNX TOOL PRO - Flashear Modulos en Magisk"
    $dlg.ClientSize = New-Object System.Drawing.Size(560, 460)
    $dlg.BackColor = [System.Drawing.Color]::FromArgb(18,18,18)
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.StartPosition = "CenterScreen"
    $dlg.TopMost = $true

    $lbTitulo = New-Object Windows.Forms.Label
    $lbTitulo.Text = "FLASHEAR MODULOS MANUALMENTE EN MAGISK"
    $lbTitulo.Location = New-Object System.Drawing.Point(14,12)
    $lbTitulo.Size = New-Object System.Drawing.Size(532,20)
    $lbTitulo.ForeColor = [System.Drawing.Color]::Lime
    $lbTitulo.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $dlg.Controls.Add($lbTitulo)

    $txtInstr = New-Object Windows.Forms.TextBox
    $txtInstr.Multiline = $true
    $txtInstr.ReadOnly = $true
    $txtInstr.Text = $instrucciones
    $txtInstr.Location = New-Object System.Drawing.Point(14,38)
    $txtInstr.Size = New-Object System.Drawing.Size(532,370)
    $txtInstr.BackColor = [System.Drawing.Color]::FromArgb(25,25,25)
    $txtInstr.ForeColor = [System.Drawing.Color]::White
    $txtInstr.Font = New-Object System.Drawing.Font("Consolas",9)
    $txtInstr.ScrollBars = "Vertical"
    $dlg.Controls.Add($txtInstr)

    $btnOK = New-Object Windows.Forms.Button
    $btnOK.Text = "YA FLASHEE LOS 3 MODULOS - CONTINUAR"
    $btnOK.Location = New-Object System.Drawing.Point(14,416)
    $btnOK.Size = New-Object System.Drawing.Size(340,36)
    $btnOK.FlatStyle = "Flat"
    $btnOK.BackColor = [System.Drawing.Color]::FromArgb(0,120,0)
    $btnOK.ForeColor = [System.Drawing.Color]::White
    $btnOK.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnOK.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dlg.Controls.Add($btnOK)

    $btnCancel = New-Object Windows.Forms.Button
    $btnCancel.Text = "CANCELAR"
    $btnCancel.Location = New-Object System.Drawing.Point(366,416)
    $btnCancel.Size = New-Object System.Drawing.Size(180,36)
    $btnCancel.FlatStyle = "Flat"
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(80,20,20)
    $btnCancel.ForeColor = [System.Drawing.Color]::White
    $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $btnCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::OrangeRed
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dlg.Controls.Add($btnCancel)

    $dlg.AcceptButton = $btnOK
    $dlg.CancelButton = $btnCancel

    Bypass-Log "[~] Esperando confirmacion del usuario..."
    Bypass-SetStatus $btn "ESPERANDO..."
    $resultado = $dlg.ShowDialog()

    if ($resultado -ne [System.Windows.Forms.DialogResult]::OK) {
        Bypass-Log "[!] Cancelado por el usuario."
        Bypass-SetStatus $btn "BYPASS BANCARIO"; return
    }
    Bypass-Log "[+] Usuario confirmo - continuando automatico..."
    Bypass-Log ""

    # -------------------------------------------------------
    # PASO 3: Activar Zygisk=1 + DenyList=1 en DB
    # -------------------------------------------------------
    Bypass-Log "[2] Activando Zygisk y DenyList en DB..."
    $zv1 = Set-MagiskSetting "zygisk" "1"
    $dl1 = Set-MagiskSetting "denylist" "1"
    Bypass-Log "[+] Zygisk: '$zv1'  DenyList: '$dl1'"
    Bypass-Log ""

    # -------------------------------------------------------
    # PASO 4: Agregar apps bancarias a DenyList
    # -------------------------------------------------------
    Bypass-Log "[3] Configurando DenyList con apps bancarias..."
    Bypass-SetStatus $btn "DENYLIST..."
    $foundApps = Configure-MagiskDenyList
    Bypass-Log ""

    # -------------------------------------------------------
    # PASO 5: Shamiko blacklist mode
    # -------------------------------------------------------
    Bypass-Log "[4] Shamiko blacklist mode..."
    & adb shell "su -c 'mkdir -p /data/adb/shamiko && rm -f /data/adb/shamiko/whitelist'" 2>$null | Out-Null
    $wl = (& adb shell "su -c '[ -f /data/adb/shamiko/whitelist ] && echo EXISTE || echo AUSENTE'" 2>$null) -join ""
    Bypass-Log "[+] whitelist: $($wl.Trim())  (AUSENTE = blacklist mode)"
    Bypass-Log ""

    # -------------------------------------------------------
    # PASO 6: Desactivar Zygisk (DenyList queda activa)
    # -------------------------------------------------------
    Bypass-Log "[5] Desactivando Zygisk (DenyList queda activa aunque aparezca gris)..."
    $zv2 = Set-MagiskSetting "zygisk" "0"
    $dl2 = Set-MagiskSetting "denylist" "1"
    Bypass-Log "[+] Zygisk: '$zv2'  DenyList: '$dl2'  (correcto: 0 y 1)"
    Bypass-Log ""

    # Limpiar flags disable
    Bypass-Log "[6] Limpiando flags disable de modulos..."
    foreach ($mid in @("zygisk_shamiko","zygisk_lsposed","zygisksu")) {
        & adb shell "su -c 'rm -f /data/adb/modules/$mid/disable'" 2>$null | Out-Null
        Bypass-Log "    [OK] $mid"
    }
    Bypass-Log ""

    # -------------------------------------------------------
    # PASO 7: Ocultar Magisk (renombrar app para que no sea detectable)
    # METODO: "Ocultar la app" de Magisk - renombra el paquete APK a uno
    #         aleatorio (ej: com.rnx.manager) y cambia el icono.
    #         La app sigue funcionando con el nuevo nombre/icono.
    # -------------------------------------------------------
    Bypass-Log "[7] Ocultando Magisk..."
    Bypass-SetStatus $btn "OCULTANDO MAGISK..."
    Bypass-Log "    METODO: Magisk 'Ocultar la app' (renombrado de paquete)"
    Bypass-Log "    El APK se reinstala con nombre de paquete aleatorio."
    Bypass-Log "    Apps bancarias no pueden detectarlo por nombre de paquete."
    Bypass-Log ""

    # Intentar hide automatico via CLI
    $hideResult = AdbRoot "magisk --hide enable 2>/dev/null || echo NO_SUPPORTED"
    $hideOk = $false
    if ($hideResult -notmatch "NO_SUPPORTED|error|fail") {
        Bypass-Log "[+] Magisk hide activado automaticamente via CLI"
        $hideOk = $true
    } else {
        AdbRoot "pm hide com.topjohnwu.magisk 2>/dev/null" | Out-Null
        $pmHide = AdbRoot "pm list packages -d com.topjohnwu.magisk 2>/dev/null"
        if ($pmHide -imatch "com.topjohnwu.magisk") {
            Bypass-Log "[+] Magisk ocultado del launcher (pm hide fallback)"
            $hideOk = $true
        }
    }

    if (-not $hideOk) {
        Bypass-Log "[~] Hide automatico no disponible - ACCION MANUAL (30 seg):"
        Bypass-Log "       1. Abre Magisk en el telefono"
        Bypass-Log "       2. Ve a: Configuracion (engranaje)"
        Bypass-Log "       3. Toca: 'Ocultar la app Magisk'"
        Bypass-Log "       4. Ingresa un nombre cualquiera (ej: 'Gestor')"
        Bypass-Log "       5. Toca OK y acepta la reinstalacion"
        Bypass-Log "       -> La app reaparece con el nuevo nombre e icono"
    }

    Bypass-Log ""
    Bypass-Log "    COMO REVERTIR (hacer Magisk visible de nuevo):"
    Bypass-Log "    OPCION A - Desde la app renombrada:"
    Bypass-Log "       1. Busca el icono con el nombre que elegiste (ej: 'Gestor')"
    Bypass-Log "       2. Configuracion -> 'Restaurar app Magisk'"
    Bypass-Log "       3. La app vuelve a llamarse 'Magisk' con icono original"
    Bypass-Log "    OPCION B - Via ADB (si no encuentras la app):"
    Bypass-Log "       adb shell pm list packages | findstr magisk"
    Bypass-Log "       (el paquete aleatorio aparece listado)"
    Bypass-Log "       adb shell pm unhide <nombre.paquete.aleatorio>"
    Bypass-Log "    OPCION C - Via ADB root:"
    Bypass-Log "       adb shell su -c 'pm unhide com.topjohnwu.magisk'"
    Bypass-Log ""

    # -------------------------------------------------------
    # PASO 8: Reiniciar
    # -------------------------------------------------------
    Bypass-Log "[8] Reiniciando..."
    Bypass-SetStatus $btn "REINICIANDO..."
    & adb reboot 2>$null; Start-Sleep -Seconds 8
    [System.Windows.Forms.Application]::DoEvents()

    if (Wait-AdbReconnect 150) {
        Start-Sleep -Seconds 8
        [System.Windows.Forms.Application]::DoEvents()
        $rootFinal = AdbRoot "id"

        # Estado de modulos post-reboot
        $modLines = @()
        foreach ($checkMod in @("zygisk_shamiko","zygisk_lsposed","zygisksu")) {
            $isDis = (& adb shell "su -c '[ -f /data/adb/modules/$checkMod/disable ] && echo SUSPENDIDO || echo ACTIVO'" 2>$null) -join ""
            $modLines += "$checkMod -> $($isDis.Trim())"
        }

        $denylistDB = Get-MagiskSetting "denylist"
        $zygiskDB   = Get-MagiskSetting "zygisk"
        $znStatus   = AdbRoot "cat /data/adb/modules/zygisksu/status 2>/dev/null || grep '^version' /data/adb/modules/zygisksu/module.prop 2>/dev/null"

        Bypass-Log ""
        Bypass-Log "============================================="
        Bypass-Log "  RESUMEN BYPASS BANCARIO"
        Bypass-Log "============================================="
        Bypass-Log "  Dispositivo   : $devModel"
        Bypass-Log "  Root final    : $rootFinal"
        Bypass-Log "  Zygisk DB     : $zygiskDB  (debe ser 0)"
        Bypass-Log "  DenyList DB   : $denylistDB  (debe ser 1)"
        Bypass-Log ""
        Bypass-Log "  Estado modulos:"
        foreach ($ml in $modLines) { Bypass-Log "    $ml" }
        Bypass-Log ""
        Bypass-Log "  Zygisk Next   : $($znStatus.Trim())"
        Bypass-Log "  Apps ocultas  : $($foundApps.Count)"
        foreach ($app in $foundApps) { Bypass-Log "    * $app" }
        Bypass-Log "============================================="
        Bypass-Log ""
        Bypass-Log "[OK] BYPASS COMPLETADO"
        Bypass-Log ""
        Bypass-Log "[~] VERIFICACION:"
        Bypass-Log "    1. Magisk > Modulos: 3 modulos activos"
        Bypass-Log "    2. Magisk > Zygisk OFF -> NORMAL"
        Bypass-Log "    3. Abre Yape/BCP -> no detecta root"
        $Global:lblRoot.ForeColor = [System.Drawing.Color]::Lime
        $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  BYPASS OK  |  $devModel"
    } else {
        Bypass-Log "[~] Verificacion no disponible - reconecta ADB manualmente"
    }
    Bypass-SetStatus $btn "BYPASS BANCARIO"
})
#==========================================================================
# FIX LOGO SAMSUNG - Galeria interactiva de logos extraidos de up_param
# Flujo:
#   1. Verificar ADB + root
#   2. Extraer particion up_param del dispositivo via dd
#   3. Parsear JPEGs embebidos y mostrar galeria con checkboxes
#   4. Usuario elige cual es el logo Samsung original (verde)
#      y cuales quiere reemplazar (rojo)
#   5. Clonar el logo original sobre los destinos en el binario
#   6. Pushear el binario modificado y flashear via dd + root
#   + Backup automatico antes de cualquier escritura
#==========================================================================
$btnsA2[2].Add_Click({
    $btn = $btnsA2[2]

    # -- Estado de sesion: hashtable MUTABLE accesible desde event handlers anidados --
    # (Los scriptblocks Add_Click/Add_CheckedChanged tienen su propio scope y NO pueden
    #  modificar variables simples del scope padre. Un hashtable si es mutable por referencia.)
    $fl = @{
        sourceID      = $null
        selectedTargets = [System.Collections.Generic.List[string]]::new()
        binPath       = $null
        fixedPath     = $null
        dumpDir       = $null
        panels        = [System.Collections.Generic.List[object]]::new()
    }

    $Global:logAdb.Clear()
    AdbLog "=============================================="
    AdbLog "   FIX LOGO SAMSUNG  -  RNX TOOL PRO"
    AdbLog "   $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    AdbLog "=============================================="
    AdbLog ""

    # --- VERIFICAR ADB + ROOT ---
    $adbOut = (& adb devices 2>$null) -join ""
    if ($adbOut -notmatch "`tdevice") {
        AdbLog "[!] No hay dispositivo ADB conectado."
        AdbLog "    Conecta el equipo con Depuracion USB habilitada."
        return
    }
    $model  = (& adb shell getprop ro.product.model  2>$null).Trim()
    $serial = (& adb get-serialno 2>$null).Trim()
    AdbLog "[+] Dispositivo : $model  ($serial)"

    AdbLog "[~] Verificando root..."
    $rootCheck = (& adb shell "su -c id" 2>$null) -join ""
    if ($rootCheck -notmatch "uid=0") {
        AdbLog "[!] ROOT no detectado. Fix Logo requiere acceso root."
        AdbLog "    Instala Magisk y otorga permisos root al proceso ADB."
        return
    }
    AdbLog "[+] Root: OK"
    AdbLog ""

    # --- ADVERTENCIA ANTES DE PROCEDER ---
    $warn = [System.Windows.Forms.MessageBox]::Show(
        "FIX LOGO SAMSUNG - Advertencia`n`n" +
        "Esta operacion modifica directamente la particion up_param`n" +
        "del almacenamiento interno del dispositivo.`n`n" +
        "Se creara un backup automatico antes de cualquier escritura.`n`n" +
        "REQUISITOS:`n" +
        "  - Root (Magisk) activo`n" +
        "  - Dispositivo Samsung con particion up_param`n" +
        "  - Bateria >= 30%`n`n" +
        "Continuar?",
        "FIX LOGO SAMSUNG",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($warn -ne "Yes") { AdbLog "[~] Cancelado por el usuario."; return }

    $btn.Enabled = $false; $btn.Text = "EXTRAYENDO..."
    [System.Windows.Forms.Application]::DoEvents()

    # --- PREPARAR CARPETAS ---
    $stamp      = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $workDir    = [System.IO.Path]::Combine($script:SCRIPT_ROOT, "BACKUPS", "FIX_LOGO", $stamp)
    $fl.dumpDir   = [System.IO.Path]::Combine($workDir, "img_dump")
    New-Item $workDir        -ItemType Directory -Force | Out-Null
    New-Item $fl.dumpDir     -ItemType Directory -Force | Out-Null

    $fl.binPath   = [System.IO.Path]::Combine($workDir, "up_param_backup.bin")
    $fl.fixedPath = [System.IO.Path]::Combine($workDir, "up_param_fixed.bin")

    # --- PASO 1: EXTRAER up_param via dd + adb pull ---
    AdbLog "[1] Extrayendo particion up_param del dispositivo..."
    AdbLog "[~] Buscando ruta de la particion..."

    # Buscar la particion (puede llamarse up_param o logo segun modelo)
    $partPath = ""
    foreach ($pname in @("up_param","UP_PARAM","logo","LOGO")) {
        $found = (& adb shell "su -c 'ls /dev/block/by-name/$pname 2>/dev/null'" 2>$null) -join ""
        if ($found -imatch $pname) { $partPath = "/dev/block/by-name/$pname"; break }
    }
    if (-not $partPath) {
        # Fallback: buscar via find
        $found2 = (& adb shell "su -c 'find /dev/block/platform -name up_param 2>/dev/null || find /dev/block/platform -name logo 2>/dev/null'" 2>$null) -join ""
        if ($found2.Trim()) { $partPath = $found2.Trim().Split("`n")[0].Trim() }
    }
    if (-not $partPath) {
        AdbLog "[!] No se encontro la particion up_param/logo."
        AdbLog "    Este modelo puede no tener logo editable, o requiere un nombre diferente."
        $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"; return
    }
    AdbLog "[+] Particion : $partPath"

    AdbLog "[~] Extrayendo (dd)... puede tardar 10-30 segundos..."
    [System.Windows.Forms.Application]::DoEvents()
    & adb shell "su -c 'dd if=$partPath of=/sdcard/rnx_up_param.bin bs=4096 2>/dev/null'" 2>$null | Out-Null

    AdbLog "[~] Descargando al PC (adb pull)..."
    & adb pull /sdcard/rnx_up_param.bin $fl.binPath 2>$null | Out-Null
    & adb shell "su -c 'rm -f /sdcard/rnx_up_param.bin'" 2>$null | Out-Null

    if (-not (Test-Path $fl.binPath) -or (Get-Item $fl.binPath).Length -lt 1024) {
        AdbLog "[!] Error: no se pudo descargar up_param o el archivo esta vacio."
        AdbLog "    Verifica que el dispositivo tenga la particion accesible con root."
        $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"; return
    }
    $binSz = [math]::Round((Get-Item $fl.binPath).Length / 1KB, 1)
    AdbLog "[+] Backup guardado: $($fl.binPath) ($binSz KB)"
    AdbLog ""

    # --- PASO 2: PARSEAR JPEGs EMBEBIDOS ---
    AdbLog "[2] Parseando logos JPEG embebidos..."
    $bin = [System.IO.File]::ReadAllBytes($fl.binPath)
    $jpegCount = 0
    $jpegFiles = @()

    for ($i = 0; $i -lt ($bin.Length - 3); $i++) {
        if ($bin[$i] -eq 0xFF -and $bin[$i+1] -eq 0xD8 -and $bin[$i+2] -eq 0xFF) {
            $jpegStart = $i
            $jpegEnd   = $bin.Length
            for ($j = $i + 2; $j -lt ($bin.Length - 1); $j++) {
                if ($bin[$j] -eq 0xFF -and $bin[$j+1] -eq 0xD9) { $jpegEnd = $j + 2; break }
            }
            $jpegCount++
            $chunk = New-Object byte[] ($jpegEnd - $jpegStart)
            [Array]::Copy($bin, $jpegStart, $chunk, 0, ($jpegEnd - $jpegStart))
            $outJpeg = [System.IO.Path]::Combine($($fl.dumpDir), "img_${jpegCount}.jpg")
            [System.IO.File]::WriteAllBytes($outJpeg, $chunk)
            $jpegFiles += [PSCustomObject]@{ Id=$jpegCount; Path=$outJpeg; Start=$jpegStart; End=$jpegEnd; Size=($jpegEnd-$jpegStart) }
            $i = $jpegEnd - 1  # saltar al siguiente
        }
    }

    AdbLog "[+] Logos encontrados: $jpegCount"
    AdbLog ""

    if ($jpegCount -eq 0) {
        AdbLog "[!] No se encontraron imagenes JPEG en up_param."
        AdbLog "    El archivo puede estar en formato diferente o estar vacio."
        $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"; return
    }

    $btn.Text = "GALERIA ABIERTA"
    [System.Windows.Forms.Application]::DoEvents()

    # ===================================================================
    # GALERIA INTERACTIVA - ventana modal estilo RNX
    # ===================================================================
    $pop = New-Object Windows.Forms.Form
    $pop.Text            = "RNX TOOL PRO  -  FIX LOGO SAMSUNG  -  GALERIA DE LOGOS"
    $pop.ClientSize      = New-Object System.Drawing.Size(920, 700)
    $pop.BackColor       = [System.Drawing.Color]::FromArgb(18, 18, 18)
    $pop.FormBorderStyle = "FixedDialog"
    $pop.StartPosition   = "CenterScreen"
    $pop.MaximizeBox     = $false
    $pop.TopMost         = $true

    # -- Barra de instrucciones superior --
    $pnlInstr = New-Object Windows.Forms.Panel
    $pnlInstr.Location  = New-Object System.Drawing.Point(0, 0)
    $pnlInstr.Size      = New-Object System.Drawing.Size(920, 72)
    $pnlInstr.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 28)
    $pop.Controls.Add($pnlInstr)

    # Linea decorativa superior
    $lineTop = New-Object Windows.Forms.Panel
    $lineTop.Location  = New-Object System.Drawing.Point(0, 0)
    $lineTop.Size      = New-Object System.Drawing.Size(920, 2)
    $lineTop.BackColor = [System.Drawing.Color]::FromArgb(0, 188, 212)
    $pnlInstr.Controls.Add($lineTop)

    $lblPaso1 = New-Object Windows.Forms.Label
    $lblPaso1.Text      = "  PASO 1  ->  Haz clic sobre la imagen del Logo Samsung original (se pondra VERDE)"
    $lblPaso1.Location  = New-Object System.Drawing.Point(0, 8)
    $lblPaso1.Size      = New-Object System.Drawing.Size(920, 26)
    $lblPaso1.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 120)
    $lblPaso1.Font      = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $pnlInstr.Controls.Add($lblPaso1)

    $lblPaso2 = New-Object Windows.Forms.Label
    $lblPaso2.Text      = "  PASO 2  ->  Marca el checkbox de los logos que quieres REEMPLAZAR (se pondran ROJO)"
    $lblPaso2.Location  = New-Object System.Drawing.Point(0, 38)
    $lblPaso2.Size      = New-Object System.Drawing.Size(920, 26)
    $lblPaso2.ForeColor = [System.Drawing.Color]::FromArgb(255, 80, 80)
    $lblPaso2.Font      = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $pnlInstr.Controls.Add($lblPaso2)

    # Linea decorativa inferior del header
    $lineHdr = New-Object Windows.Forms.Panel
    $lineHdr.Location  = New-Object System.Drawing.Point(0, 70)
    $lineHdr.Size      = New-Object System.Drawing.Size(920, 2)
    $lineHdr.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $pnlInstr.Controls.Add($lineHdr)

    # -- FlowLayoutPanel con scroll para las tarjetas --
    $flGallery = New-Object Windows.Forms.FlowLayoutPanel
    $flGallery.Location   = New-Object System.Drawing.Point(0, 72)
    $flGallery.Size       = New-Object System.Drawing.Size(920, 560)
    $flGallery.AutoScroll = $true
    $flGallery.BackColor  = [System.Drawing.Color]::FromArgb(22, 22, 22)
    $flGallery.Padding    = New-Object Windows.Forms.Padding(12)
    $flGallery.WrapContents = $true
    $pop.Controls.Add($flGallery)

    # -- Barra inferior: contador + boton confirmar --
    $pnlBottom = New-Object Windows.Forms.Panel
    $pnlBottom.Location  = New-Object System.Drawing.Point(0, 632)
    $pnlBottom.Size      = New-Object System.Drawing.Size(920, 68)
    $pnlBottom.BackColor = [System.Drawing.Color]::FromArgb(28, 28, 28)
    $pop.Controls.Add($pnlBottom)

    $lineBot = New-Object Windows.Forms.Panel
    $lineBot.Location  = New-Object System.Drawing.Point(0, 0)
    $lineBot.Size      = New-Object System.Drawing.Size(920, 1)
    $lineBot.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $pnlBottom.Controls.Add($lineBot)

    $lblStatus = New-Object Windows.Forms.Label
    $lblStatus.Text      = "Sin seleccion  |  $jpegCount logos encontrados"
    $lblStatus.Location  = New-Object System.Drawing.Point(14, 10)
    $lblStatus.Size      = New-Object System.Drawing.Size(480, 50)
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
    $lblStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5)
    $pnlBottom.Controls.Add($lblStatus)

    $btnConfirm = New-Object Windows.Forms.Button
    $btnConfirm.Text     = "CONFIRMAR SELECCION Y APLICAR"
    $btnConfirm.Location = New-Object System.Drawing.Point(560, 12)
    $btnConfirm.Size     = New-Object System.Drawing.Size(344, 44)
    $btnConfirm.FlatStyle = "Flat"
    $btnConfirm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
    $btnConfirm.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $btnConfirm.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $btnConfirm.Font     = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btnConfirm.Enabled  = $false
    $pnlBottom.Controls.Add($btnConfirm)

    # -- Funcion de actualizacion del estado y boton confirmar --
    $updateStatus = {
        $srcOk  = ($fl.sourceID -ne $null)
        $dstCnt = $fl.selectedTargets.Count
        if ($srcOk -and $dstCnt -gt 0) {
            $lblStatus.Text      = "Logo origen: ID $($fl.sourceID)  |  Destinos a reemplazar: $dstCnt"
            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 220, 100)
            $btnConfirm.Enabled  = $true
            $btnConfirm.BackColor = [System.Drawing.Color]::FromArgb(10, 100, 10)
            $btnConfirm.ForeColor = [System.Drawing.Color]::White
            $btnConfirm.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 200, 80)
        } elseif ($srcOk) {
            $lblStatus.Text      = "Logo origen: ID $($fl.sourceID)  |  Selecciona logos a reemplazar (PASO 2)"
            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 188, 212)
            $btnConfirm.Enabled  = $false
            $btnConfirm.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
            $btnConfirm.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
            $btnConfirm.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        } else {
            $lblStatus.Text      = "Sin seleccion  |  $jpegCount logos encontrados  -  Haz clic en el logo original (PASO 1)"
            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(140, 140, 140)
            $btnConfirm.Enabled  = $false
        }
    }

    # -- Crear tarjeta por cada JPEG --
    $fl.panels = [System.Collections.Generic.List[object]]::new()
    foreach ($jpeg in $jpegFiles) {
        $jId = $jpeg.Id

        try {
            $jBytes = [System.IO.File]::ReadAllBytes($jpeg.Path)
            $jMs    = New-Object System.IO.MemoryStream(,$jBytes)
            $jImg   = [System.Drawing.Image]::FromStream($jMs)

            # Tarjeta contenedor
            $card = New-Object Windows.Forms.Panel
            $card.Size        = New-Object System.Drawing.Size(190, 248)
            $card.Tag         = $jId
            $card.BackColor   = [System.Drawing.Color]::FromArgb(32, 32, 32)
            $card.BorderStyle = "FixedSingle"
            $card.Margin      = New-Object Windows.Forms.Padding(8)
            $card.Cursor      = "Default"

            # Etiqueta del numero de imagen
            $lblId = New-Object Windows.Forms.Label
            $lblId.Text      = "LOGO  #$jId"
            $lblId.Location  = New-Object System.Drawing.Point(0, 4)
            $lblId.Size      = New-Object System.Drawing.Size(188, 18)
            $lblId.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
            $lblId.Font      = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
            $lblId.TextAlign = "MiddleCenter"
            $card.Controls.Add($lblId)

            # Imagen
            $pb = New-Object Windows.Forms.PictureBox
            $pb.Size     = New-Object System.Drawing.Size(170, 168)
            $pb.Location = New-Object System.Drawing.Point(10, 24)
            $pb.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
            $pb.Image    = $jImg
            $pb.BackColor = [System.Drawing.Color]::FromArgb(12, 12, 12)
            $pb.Cursor   = [System.Windows.Forms.Cursors]::Hand
            $pb.Tag      = $jId
            $card.Controls.Add($pb)

            # Separador entre imagen y checkbox
            $sep = New-Object Windows.Forms.Panel
            $sep.Location  = New-Object System.Drawing.Point(10, 196)
            $sep.Size      = New-Object System.Drawing.Size(170, 1)
            $sep.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
            $card.Controls.Add($sep)

            # Checkbox "REEMPLAZAR ESTE"
            $ck = New-Object Windows.Forms.CheckBox
            $ck.Text      = "REEMPLAZAR ESTE"
            $ck.Location  = New-Object System.Drawing.Point(0, 200)
            $ck.Size      = New-Object System.Drawing.Size(188, 40)
            $ck.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
            $ck.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $ck.TextAlign = "MiddleCenter"
            $ck.Tag       = $jId
            $ck.BackColor = [System.Drawing.Color]::Transparent
            $card.Controls.Add($ck)

            # --- CLICK en la imagen: seleccionar como LOGO ORIGINAL (verde) ---
            $pb.Add_Click({
                param($sender, $e)
                $clickedId = $sender.Tag

                # Quitar verde de todas las tarjetas que no esten en rojo
                foreach ($pn in $fl.panels) {
                    $pnCk = $pn.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] }
                    $pnLbl = $pn.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Size -lt 8 }
                    if (-not $pnCk.Checked) {
                        $pn.BackColor   = [System.Drawing.Color]::FromArgb(32, 32, 32)
                        $pnLbl.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
                    }
                }

                # Marcar la tarjeta clickeada como origen (verde)
                $sender.Parent.BackColor = [System.Drawing.Color]::FromArgb(10, 80, 10)
                $lbl = $sender.Parent.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Size -lt 8 }
                $lbl.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 120)
                $fl.sourceID = $clickedId

                & $updateStatus
            })

            # --- CHECKED: marcar como destino a REEMPLAZAR (rojo) ---
            $ck.Add_CheckedChanged({
                param($sender, $e)
                $ckId = $sender.Tag
                $lbl  = $sender.Parent.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Size -lt 8 }

                if ($sender.Checked) {
                    $sender.Parent.BackColor = [System.Drawing.Color]::FromArgb(80, 10, 10)
                    $sender.ForeColor        = [System.Drawing.Color]::FromArgb(255, 100, 100)
                    $lbl.ForeColor           = [System.Drawing.Color]::FromArgb(255, 100, 100)
                    if ($fl.selectedTargets -notcontains $ckId) {
                        $fl.selectedTargets.Add($ckId)
                    }
                } else {
                    # Restaurar color segun si es el origen o neutro
                    if ($ckId -eq $fl.sourceID) {
                        $sender.Parent.BackColor = [System.Drawing.Color]::FromArgb(10, 80, 10)
                        $lbl.ForeColor           = [System.Drawing.Color]::FromArgb(0, 230, 120)
                    } else {
                        $sender.Parent.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)
                        $lbl.ForeColor           = [System.Drawing.Color]::FromArgb(100, 100, 100)
                    }
                    $sender.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 160)
                    $fl.selectedTargets.Remove($ckId) | Out-Null
                }
                & $updateStatus
            })

            $flGallery.Controls.Add($card)
            $fl.panels.Add($card)

        } catch {
            AdbLog "[~] No se pudo cargar img_${jId}.jpg: $_"
        }
    }

    # --- BOTON CONFIRMAR ---
    $btnConfirm.Add_Click({
        if (-not $fl.sourceID) {
            [System.Windows.Forms.MessageBox]::Show(
                "Debes hacer clic sobre la imagen del logo Samsung original (PASO 1) antes de continuar.",
                "Sin logo origen",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if ($fl.selectedTargets.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "No hay logos marcados para reemplazar (PASO 2).`nMarca al menos uno con el checkbox.",
                "Sin destinos",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        $pop.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $pop.Close()
    })

    $popResult = $pop.ShowDialog()

    # Si cerro sin confirmar
    if ($popResult -ne [System.Windows.Forms.DialogResult]::OK -or -not $fl.sourceID) {
        AdbLog "[~] Galeria cerrada sin confirmar."
        $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"; return
    }

    AdbLog "[+] Seleccion confirmada:"
    AdbLog "    Logo origen (Samsung): ID $($fl.sourceID)"
    AdbLog "    Logos a reemplazar   : $($fl.selectedTargets -join ', ')"
    AdbLog ""

    # --- PASO 3: CLONAR LOGO ORIGEN SOBRE DESTINOS ---
    AdbLog "[3] Procesando binario..."
    $btn.Text = "PROCESANDO..."; [System.Windows.Forms.Application]::DoEvents()

    # Recargar el binario original
    $bin2 = [System.IO.File]::ReadAllBytes($fl.binPath)

    # Extraer bytes del logo origen
    $logoBytes = $null
    $cnt = 0
    for ($i = 0; $i -lt ($bin2.Length - 3); $i++) {
        if ($bin2[$i] -eq 0xFF -and $bin2[$i+1] -eq 0xD8 -and $bin2[$i+2] -eq 0xFF) {
            $cnt++
            $jStart = $i; $jEnd = $bin2.Length
            for ($j = $i+2; $j -lt ($bin2.Length-1); $j++) {
                if ($bin2[$j] -eq 0xFF -and $bin2[$j+1] -eq 0xD9) { $jEnd = $j+2; break }
            }
            if ($cnt.ToString() -eq $fl.sourceID.ToString()) {
                $logoBytes = New-Object byte[] ($jEnd - $jStart)
                [Array]::Copy($bin2, $jStart, $logoBytes, 0, ($jEnd - $jStart))
                AdbLog "[+] Logo origen extraido: $($logoBytes.Length) bytes (ID $($fl.sourceID))"
                break
            }
            $i = $jEnd - 1
        }
    }

    if (-not $logoBytes) {
        AdbLog "[!] No se pudo extraer el logo origen del binario."
        $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"; return
    }

    # Reemplazar logos destino en el binario
    $cnt = 0; $replaced = 0
    for ($i = 0; $i -lt ($bin2.Length - 3); $i++) {
        if ($bin2[$i] -eq 0xFF -and $bin2[$i+1] -eq 0xD8 -and $bin2[$i+2] -eq 0xFF) {
            $cnt++
            $jStart = $i; $jEnd = $bin2.Length
            for ($j = $i+2; $j -lt ($bin2.Length-1); $j++) {
                if ($bin2[$j] -eq 0xFF -and $bin2[$j+1] -eq 0xD9) { $jEnd = $j+2; break }
            }
            if ($fl.selectedTargets -contains $cnt.ToString()) {
                $space = $jEnd - $jStart
                if ($logoBytes.Length -le $space) {
                    # Limpiar el espacio original con ceros
                    for ($k = $jStart; $k -lt $jEnd; $k++) { $bin2[$k] = 0 }
                    # Escribir el logo origen en su lugar
                    [Array]::Copy($logoBytes, 0, $bin2, $jStart, $logoBytes.Length)
                    AdbLog "[+] ID $cnt reemplazado OK  (espacio: $space B  logo: $($logoBytes.Length) B)"
                    $replaced++
                } else {
                    AdbLog "[!] ID $cnt NO reemplazado - logo origen ($($logoBytes.Length) B) > espacio disponible ($space B)"
                }
            }
            $i = $jEnd - 1
        }
    }

    if ($replaced -eq 0) {
        AdbLog "[!] Ningun logo fue reemplazado (problema de espacio o IDs invalidos)."
        $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"; return
    }
    AdbLog "[+] $replaced logo(s) reemplazado(s) correctamente"

    # Guardar binario modificado
    [System.IO.File]::WriteAllBytes($fl.fixedPath, $bin2)
    $fixSz = [math]::Round((Get-Item $fl.fixedPath).Length / 1KB, 1)
    AdbLog "[+] Binario modificado guardado: $($fl.fixedPath) ($fixSz KB)"
    AdbLog ""

    # --- PASO 4: FLASHEAR AL DISPOSITIVO ---
    AdbLog "[4] Flasheando up_param modificado al dispositivo..."
    $btn.Text = "FLASHEANDO..."; [System.Windows.Forms.Application]::DoEvents()

    $confirm2 = [System.Windows.Forms.MessageBox]::Show(
        "Listo para flashear $replaced logo(s) modificado(s).`n`n" +
        "Backup guardado en:`n$($fl.binPath)`n`n" +
        "Se escribira via: dd if=up_param_fixed.bin of=$partPath`n`n" +
        "Confirmas la escritura al dispositivo?",
        "CONFIRMAR FLASH",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)

    if ($confirm2 -ne "Yes") {
        AdbLog "[~] Flash cancelado por el usuario."
        AdbLog "[~] El binario modificado esta guardado en:"
        AdbLog "    $($fl.fixedPath)"
        AdbLog "[~] Puedes flashearlo manualmente con:"
        AdbLog "    adb push up_param_fixed.bin /sdcard/up_fixed.bin"
        AdbLog "    adb shell su -c 'dd if=/sdcard/up_fixed.bin of=$partPath'"
        $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"; return
    }

    # Push al dispositivo
    AdbLog "[~] Subiendo binario al dispositivo..."
    & adb push $fl.fixedPath /sdcard/rnx_up_fixed.bin 2>$null | Out-Null

    $pushCheck = (& adb shell "ls /sdcard/rnx_up_fixed.bin 2>/dev/null" 2>$null) -join ""
    if ($pushCheck -notmatch "rnx_up_fixed") {
        AdbLog "[!] Error: no se pudo subir el binario al dispositivo."
        $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"; return
    }
    AdbLog "[+] Binario subido al dispositivo"

    # Flashear via dd con root
    AdbLog "[~] Ejecutando dd (escritura a particion)..."
    $ddOut = (& adb shell "su -c 'dd if=/sdcard/rnx_up_fixed.bin of=$partPath bs=4096 conv=fsync 2>&1'" 2>$null) -join "`n"
    foreach ($dl in ($ddOut -split "`n")) { $dl = $dl.Trim(); if ($dl) { AdbLog "    $dl" } }

    # Limpiar archivo temporal del dispositivo
    & adb shell "su -c 'rm -f /sdcard/rnx_up_fixed.bin'" 2>$null | Out-Null

    AdbLog ""
    if ($ddOut -imatch "records out|bytes|copied") {
        AdbLog "[OK] ============================================"
        AdbLog "[OK]   FIX LOGO SAMSUNG COMPLETADO"
        AdbLog "[OK] ============================================"
        AdbLog "[~] $replaced logo(s) modificado(s) correctamente."
        AdbLog "[~] Reiniciando dispositivo para ver los cambios..."
        AdbLog ""
        AdbLog "[~] Backup del original en:"
        AdbLog "    $($fl.binPath)"
        $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  FIX LOGO OK  |  $model"

        $reboot = [System.Windows.Forms.MessageBox]::Show(
            "Logo flasheado correctamente.`n`nReinicia el dispositivo para ver los cambios de logo en el arranque.`n`nReiniciar ahora?",
            "FIX LOGO OK",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Information)
        if ($reboot -eq "Yes") {
            AdbLog "[~] Reiniciando..."
            & adb reboot 2>$null
        }
    } else {
        AdbLog "[!] El dd no confirmo escritura. Verifica manualmente."
        AdbLog "[~] El binario modificado esta guardado localmente:"
        AdbLog "    $($fl.fixedPath)"
    }

    $btn.Enabled = $true; $btn.Text = "FIX LOGO SAMSUNG"
})
#==========================================================================
# ACTIVAR SIM 2 SAMSUNG - logica EFS backup + modificacion via ADB root
# (funcionalidad transferida del boton EFS BACKUP/MOD de Utilidades Firmware)
#==========================================================================
$btnsA2[3].Add_Click({
    $btn = $btnsA2[3]
    $btn.Enabled = $false; $btn.Text = "EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        $Global:logAdb.Clear()
        AdbLog ""
        AdbLog "[*] =========================================="
        AdbLog "[*]   ACTIVAR SIM 2 SAMSUNG  -  RNX TOOL PRO"
        AdbLog "[*]   EFS Backup + Modificacion (ADB Root)"
        AdbLog "[*] =========================================="
        AdbLog ""

        # Verificar ADB
        $s = (& adb shell getprop ro.serialno 2>$null).Trim()
        if (-not $s) { AdbLog "[!] No hay equipo conectado via ADB"; return }
        AdbLog "[+] Dispositivo: $s"

        # Verificar root
        AdbLog "[~] Verificando root..."
        $root = (& adb shell "su -c id" 2>$null)
        if ($root -match "uid=0") {
            AdbLog "[+] ROOT : OK"
            $Global:lblRoot.Text      = "ROOT        : SI"
            $Global:lblRoot.ForeColor = [System.Drawing.Color]::Lime
        } else {
            AdbLog "[!] ROOT : NO detectado"
            $Global:lblRoot.Text      = "ROOT        : NO"
            $Global:lblRoot.ForeColor = [System.Drawing.Color]::Red
            AdbLog "[!] Esta operacion requiere root (Magisk/SuperSU)"
            return
        }

        # Crear carpeta BACKUPS
        if (-not (Test-Path "BACKUPS")) { New-Item -ItemType Directory -Name "BACKUPS" | Out-Null }
        $date   = Get-Date -Format "yyyy-MM-dd_HH-mm"
        $backup = "BACKUPS\efs_sim2_$date.img"

        # Backup EFS
        AdbLog "[~] Creando backup de EFS..."
        & adb shell "su -c 'dd if=/dev/block/by-name/efs of=/sdcard/efs_sim2.img'" 2>$null
        & adb pull /sdcard/efs_sim2.img $backup 2>$null

        if (Test-Path $backup) {
            $sz = [math]::Round((Get-Item $backup).Length / 1KB, 1)
            $sha256bak = (Get-FileHash $backup -Algorithm SHA256).Hash.ToLower()
            AdbLog "[+] Backup guardado  : $backup ($sz KB)"
            AdbLog "[+] SHA256 backup    : $($sha256bak.Substring(0,16))..."
            AdbLog "[+] SHA256 completo  : $sha256bak"
        } else {
            AdbLog "[!] No se pudo crear backup - particion EFS no encontrada"
            AdbLog "[!] Verifica que el dispositivo tenga particion EFS"
            return
        }

        # Modificacion EFS Samsung SIM 2 - renombrar archivos sensibles
        AdbLog ""
        AdbLog "[~] Modificando EFS (activando SIM 2)..."
        & adb shell "su -c 'mount -o rw,remount /efs'" 2>$null

        $efs_ops = @(
            @("mv /efs/esim.prop",    "/efs/000000000"),
            @("mv /efs/factory.prop", "/efs/000000000000"),
            @("mv /efs/wv.keys",      "/efs/0000000"),
            @("mv /efs/mps_code.dat", "/efs/000000000000_mps"),
            @("mv /efs/mep_mode",     "/efs/00000000")
        )
        foreach ($op in $efs_ops) {
            $cmd = "$($op[0]) $($op[1]) 2>/dev/null || echo SKIP"
            $res = (& adb shell "su -c '$cmd'" 2>$null).Trim()
            $opStatus = if ($res -match "SKIP") { "[SKIP]" } else { "[OK]  " }
            AdbLog "  $opStatus $($op[0]) -> $($op[1])"
        }

        # Verificacion post-modificacion
        AdbLog ""
        AdbLog "[~] Verificacion post-modificacion..."
        $efsLs = (& adb shell "su -c 'ls /efs/'" 2>$null) -join " "
        AdbLog "[+] Contenido /efs/ : $efsLs"

        AdbLog ""
        AdbLog "[+] EFS modificado correctamente"
        AdbLog "[~] Reiniciando dispositivo..."
        & adb reboot 2>$null
        AdbLog "[OK] LISTO - equipo reiniciando"
        AdbLog "[~] La SIM 2 deberia ser reconocida al iniciar"

    } catch { AdbLog "[!] Error inesperado: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "ACTIVAR SIM 2 SAMSUNG" }
})
$btnsA1[2].Add_Click({
    # ============================================================
    # BLOQUEAR OTA - version estable sin contaminacion de scope
    # ============================================================
    $btn = $btnsA1[2]
    $btn.Enabled = $false
    $btn.Text    = "BLOQUEANDO OTA..."
    [System.Windows.Forms.Application]::DoEvents()

    $Global:logAdb.Clear()
    AdbLog "=============================================="
    AdbLog "   OTA BLOCKER  -  RNX TOOL PRO"
    AdbLog "   $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    AdbLog "=============================================="
    AdbLog ""

    # Helper de log con timestamp (scriptblock, NO function - no contamina scope global)
    $otaLog = { param($m); AdbLog ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $m) }

    # Helper de bloqueo (scriptblock inline)
    # IMPORTANTE: para Xiaomi/HyperOS NUNCA se usa pm uninstall --user 0
    # porque puede dejar el sistema sin servicios criticos y entrar en bootloop.
    # Solo se usa pm disable-user (reversible) + pm clear (limpia cache).
    # pm suspend solo se aplica a Samsung como fallback adicional.
    $otaBlock = {
        param($pkg, $agr)
        try {
            # Intento 1: disable-user (reversible, seguro en todos los sistemas)
            $r1 = (& adb shell pm disable-user --user 0 $pkg 2>&1) -join ""
            if ($r1 -imatch "disabled|success") {
                # Limpiar cache del paquete deshabilitado
                try { & adb shell pm clear $pkg 2>$null | Out-Null } catch {}
                return "disabled"
            }
            # Intento 2: solo para Samsung (NO Xiaomi/HyperOS) - pm suspend como fallback
            # Para Xiaomi NO se hace pm uninstall porque puede romper el sistema
            if ($agr -eq "samsung_only") {
                $r3 = (& adb shell cmd package suspend $pkg 2>&1) -join ""
                if ($r3 -imatch "suspend|success|done") { return "disabled" }
            }
        } catch {}
        return "failed"
    }

    # -- Listas OTA por marca ------------------------------------------
    $OTA_UNIVERSAL = @(
        "com.android.updater","com.android.ota",
        "com.google.android.modulemetadata","com.google.android.configupdater",
        "com.google.android.gms.update","com.google.android.update"
    )
    $OTA_SAMSUNG = @(
        "com.wssyncmldm","com.sec.android.soagent","com.samsung.sdm",
        "com.samsung.sdm.sdmviewer","com.ws.dm","com.samsung.android.fota",
        "com.samsung.android.fotaclient","com.samsung.android.mdm",
        "com.sec.android.preloadinstaller","com.samsung.android.sm.policy",
        "com.sec.android.systemupdate","com.samsung.android.sdm.policy"
    )
    $OTA_XIAOMI = @(
        "com.android.updater","com.miui.updater","com.miui.fota",
        "com.xiaomi.mipush.sdk","com.miui.systemAdSolution","com.miui.cloudservice",
        "com.miui.analytics","com.xiaomi.xmsf","com.xiaomi.discover","com.miui.msa.global"
    )
    $OTA_OPPO    = @("com.coloros.sau","com.oplus.ota","com.oppo.ota","com.coloros.ota","com.realme.ota","com.coloros.packageinstaller")
    $OTA_MOTOROLA= @("com.motorola.ccc.ota","com.motorola.android.fota","com.motorola.MotoDMClient","com.motorola.targetnotif")
    $OTA_HUAWEI  = @("com.huawei.android.hwouc","com.huawei.android.hwota","com.hihonor.ouc","com.huawei.iconnect")
    $OTA_VIVO    = @("com.vivo.updater","com.vivo.daemonService","com.bbk.updater","com.vivo.pushclient")
    $OTA_ASUS    = @("com.asus.dm","com.asus.fota","com.asus.systemupdate")
    $OTA_SONY    = @("com.sonymobile.updatecenter","com.sonymobile.updater")
    $OTA_ONEPLUS = @("com.oneplus.ota","net.oneplus.odm")

    # -- ETAPA 0: Verificar ADB ----------------------------------------
    & $otaLog "[0/7] Verificando ADB..."
    $adbOK = $false
    try { $adbOK = ((& adb devices 2>$null) -join "" -match "`tdevice") } catch {}
    if (-not $adbOK) {
        & $otaLog "[!] Sin ADB. Conecta el equipo con USB Debugging activado."
        $btn.Enabled = $true; $btn.Text = "BLOQUEAR OTA"; return
    }

    $serial  = ""; $model = ""; $android = ""; $sdkRaw = ""; $oneui = ""; $hyperos = ""
    try { $serial  = (& adb get-serialno 2>$null).Trim() } catch {}
    try { $model   = (& adb shell getprop ro.product.model         2>$null).Trim() } catch {}
    try { $android = (& adb shell getprop ro.build.version.release 2>$null).Trim() } catch {}
    try { $sdkRaw  = (& adb shell getprop ro.build.version.sdk     2>$null).Trim() } catch {}
    try { $oneui   = (& adb shell getprop ro.build.version.oneui   2>$null).Trim() } catch {}
    try { $hyperos = (& adb shell getprop ro.mi.os.version.name    2>$null).Trim() } catch {}

    # Cast seguro del SDK
    $sdk = 0
    if ($sdkRaw -match "^\d+$") { $sdk = [int]$sdkRaw }

    & $otaLog "[+] Modelo: $model  |  Android: $android  (SDK $sdk)"
    if ($oneui)   { & $otaLog "[+] One UI  : $oneui" }
    if ($hyperos) { & $otaLog "[+] HyperOS : $hyperos" }
    AdbLog ""

    # -- ETAPA 1: Snapshot ---------------------------------------------
    AdbLog "----------------------------------------------"
    & $otaLog "[1/7] Capturando lista de paquetes..."
    $allPkgs = @()
    try { $allPkgs = (& adb shell pm list packages 2>$null) -replace "package:","" } catch {}
    $allPkgs = $allPkgs | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    $disabledBefore = 0
    try {
        $disabledBefore = ((& adb shell pm list packages -d 2>$null) -replace "package:","" |
                           ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }).Count
    } catch {}
    & $otaLog "[+] Paquetes: $($allPkgs.Count)  |  Ya deshabilitados: $disabledBefore"
    AdbLog ""

    # -- ETAPA 2: Detectar fabricante y modo ---------------------------
    AdbLog "----------------------------------------------"
    & $otaLog "[2/7] Detectando fabricante..."
    $mfrRaw = ""; $brand = ""
    try { $mfrRaw = (& adb shell getprop ro.product.manufacturer 2>$null).Trim().ToLower() } catch {}
    try { $brand  = (& adb shell getprop ro.product.brand        2>$null).Trim().ToLower() } catch {}

    $useAgressive = $false
    $OTA_BRAND    = @()
    $brandLabel   = "Desconocido"

    if ($mfrRaw -match "samsung") {
        $OTA_BRAND = $OTA_SAMSUNG
        $isOneUI78 = ($oneui -match "^[78]" -or $sdk -ge 35)
        if ($isOneUI78) {
            $brandLabel = "Samsung One UI 7/8 (Android 15/16)"
            & $otaLog "[!] One UI 7/8 / Android 15+ -> bloqueo SDM activado"
        } else { $brandLabel = "Samsung" }
    } elseif ($mfrRaw -match "xiaomi|redmi|poco") {
        $OTA_BRAND    = $OTA_XIAOMI
        $useAgressive = $true
        $hyperVer = ""
        try { $hyperVer = (& adb shell getprop ro.mi.os.version.incremental 2>$null).Trim() } catch {}
        if ($hyperos -imatch "HyperOS" -and $hyperVer -match "^2") {
            $brandLabel = "Xiaomi HyperOS 2 - modo agresivo"
            & $otaLog "[!] HyperOS 2 -> disable + uninstall fallback"
        } elseif ($hyperos -imatch "HyperOS") {
            $brandLabel = "Xiaomi HyperOS 1 - modo agresivo"
        } else { $brandLabel = "Xiaomi/MIUI - modo agresivo" }
    } elseif ($mfrRaw -match "oppo|realme")  { $OTA_BRAND = $OTA_OPPO;     $brandLabel = "OPPO/ColorOS" }
    elseif ($mfrRaw -match "motorola")        { $OTA_BRAND = $OTA_MOTOROLA; $brandLabel = "Motorola" }
    elseif ($mfrRaw -match "huawei|honor")    { $OTA_BRAND = $OTA_HUAWEI;   $brandLabel = "Huawei/Honor" }
    elseif ($mfrRaw -match "vivo")            { $OTA_BRAND = $OTA_VIVO;     $brandLabel = "Vivo/BBK" }
    elseif ($mfrRaw -match "asus")            { $OTA_BRAND = $OTA_ASUS;     $brandLabel = "ASUS" }
    elseif ($mfrRaw -match "sony")            { $OTA_BRAND = $OTA_SONY;     $brandLabel = "Sony" }
    elseif ($mfrRaw -match "oneplus")         { $OTA_BRAND = $OTA_ONEPLUS;  $brandLabel = "OnePlus" }

    if ($brandLabel -eq "Desconocido") {
        if ($brand -match "samsung")               { $OTA_BRAND = $OTA_SAMSUNG; $brandLabel = "Samsung (brand)" }
        elseif ($brand -match "xiaomi|redmi|poco") { $OTA_BRAND = $OTA_XIAOMI;  $useAgressive = $true; $brandLabel = "Xiaomi (brand)" }
    }

    & $otaLog "[+] Fabricante : $mfrRaw  |  Lista: $brandLabel"
    & $otaLog "[+] Modo agresivo: $(if($useAgressive){'SI'}else{'NO'})"

    # Combinar listas sin duplicados - HashSet para O(1) lookup
    $OTA_TARGET = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in ($OTA_UNIVERSAL + $OTA_BRAND)) {
        $p = $p.Trim()
        if ($p -and $seen.Add($p)) { $OTA_TARGET.Add($p) }
    }
    & $otaLog "[+] Total a evaluar: $($OTA_TARGET.Count)"
    AdbLog ""

    # -- ETAPA 3: Bloquear paquetes ------------------------------------
    AdbLog "----------------------------------------------"
    & $otaLog "[3/7] Bloqueando paquetes OTA..."
    AdbLog ""

    $cntFound=0; $cntDisabled=0; $cntUninstalled=0; $cntSkipped=0; $cntNotFound=0; $cntFailed=0

    # HashSet para lookups O(1) - inmune a \r\n residuales de ADB
    $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    try {
        (& adb shell pm list packages -d 2>$null) -replace "package:","" |
        ForEach-Object { $t = $_.Trim(); if ($t) { $disabledSet.Add($t) | Out-Null } }
    } catch {}

    $allPkgsSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $allPkgs) { $allPkgsSet.Add($p) | Out-Null }

    foreach ($pkg in $OTA_TARGET) {
        if (-not $allPkgsSet.Contains($pkg)) {
            & $otaLog "  [--] No encontrado  : $pkg"
            $cntNotFound++; continue
        }
        $cntFound++
        if ($disabledSet.Contains($pkg)) {
            & $otaLog "  [>>] Ya deshabilitado: $pkg"
            $cntSkipped++; continue
        }
        $result = & $otaBlock $pkg "no"
        # Para Samsung: permitir suspend como fallback adicional (no uninstall)
        if ($result -eq "failed" -and ($mfrRaw -match "samsung" -or $brand -match "samsung")) {
            $result = & $otaBlock $pkg "samsung_only"
        }
        switch ($result) {
            "disabled"    { & $otaLog "  [OK] Deshabilitado  : $pkg"; $cntDisabled++ }
            "uninstalled" { & $otaLog "  [OK] Desinstalado   : $pkg  (fallback)"; $cntUninstalled++ }
            "failed"      {
                & $otaLog "  [!!] Fallo          : $pkg"
                $cntFailed++
            }
        }
        [System.Windows.Forms.Application]::DoEvents()
    }
    AdbLog ""

    # -- ETAPA 4: Escaneo dinamico -------------------------------------
    AdbLog "----------------------------------------------"
    & $otaLog "[4/7] Escaneo dinamico..."
    $dynPattern = "\.ota\.|\.fota\.|\.fotaclient|\.updater$|\.update$|systemupdate|fotaagent|wssync|soagent|\.sdm\.|sdmviewer"
    $dynFound = 0
    foreach ($p in $allPkgs) {
        if (-not $p) { continue }
        if ($p -imatch $dynPattern -and $seen.Add($p)) {
            & $otaLog "  [~~] Detectado dinamico: $p"
            $dynFound++
            if ($disabledSet.Contains($p)) {
                & $otaLog "  [>>] Ya deshabilitado : $p"; $cntSkipped++
            } else {
                $r2 = & $otaBlock $p "no"
                switch ($r2) {
                    "disabled"    { & $otaLog "  [OK] Deshabilitado    : $p"; $cntDisabled++ }
                    "uninstalled" { & $otaLog "  [OK] Desinstalado     : $p"; $cntUninstalled++ }
                    "failed"      { & $otaLog "  [!!] Fallo            : $p"; $cntFailed++ }
                }
            }
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    if ($dynFound -eq 0) { & $otaLog "[+] Sin paquetes OTA adicionales detectados." }
    AdbLog ""

    # -- ETAPA 5: Settings globales ------------------------------------
    AdbLog "----------------------------------------------"
    & $otaLog "[5/7] Aplicando settings globales..."
    foreach ($pair in @(
        @("ota_disable_automatic_update","1"), @("auto_update_system","0"),
        @("auto_update_time","0"),             @("auto_update_wifi_only","0"),
        @("package_verifier_enable","0"),      @("verifier_verify_adb_installs","0")
    )) {
        try {
            $r = (& adb shell settings put global $pair[0] $pair[1] 2>&1) -join ""
            if (-not $r) { & $otaLog "  [OK] $($pair[0]) = $($pair[1])" }
            else          { & $otaLog "  [~]  $($pair[0]) -> $r" }
        } catch {}
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Refuerzo Samsung One UI 7/8
    if ($sdk -ge 35 -and ($mfrRaw -match "samsung" -or $brand -match "samsung")) {
        & $otaLog ""; & $otaLog "[~] Refuerzo Samsung One UI 7/8 -- limpiando cache SDM..."
        foreach ($cmd in @("pm clear com.wssyncmldm","pm clear com.sec.android.soagent",
                           "pm clear com.samsung.sdm","pm clear com.sec.android.systemupdate")) {
            try {
                $rc = (& adb shell $cmd 2>&1) -join ""
                & $otaLog "  $(if($rc -imatch 'Success'){'[OK]'}else{'[~]'}) $($cmd -replace 'pm clear ','')"
            } catch {}
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    # Refuerzo HyperOS - SOLO pm clear (seguro, no afecta servicios del sistema)
    # Se elimino cmd package suspend porque puede dejar el equipo en bootloop
    # en HyperOS 1 y 2 cuando afecta servicios del sistema criticos.
    if ($useAgressive) {
        & $otaLog ""; & $otaLog "[~] Refuerzo HyperOS -- limpiando cache OTA (pm clear)..."
        foreach ($pkg in @("com.android.updater","com.miui.updater","com.miui.fota")) {
            if ($allPkgsSet.Contains($pkg)) {
                try { & adb shell pm clear $pkg 2>$null | Out-Null } catch {}
                & $otaLog "  [OK] cache limpiado: $pkg"
            }
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    AdbLog ""

    # -- ETAPA 6: Verificacion post-bloqueo ----------------------------
    AdbLog "----------------------------------------------"
    & $otaLog "[6/7] Verificacion post-bloqueo..."
    $disabledNowSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    try {
        (& adb shell pm list packages -d 2>$null) -replace "package:","" |
        ForEach-Object { $t = $_.Trim(); if ($t) { $disabledNowSet.Add($t) | Out-Null } }
    } catch {}
    $allNowSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    try {
        (& adb shell pm list packages 2>$null) -replace "package:","" |
        ForEach-Object { $t = $_.Trim(); if ($t) { $allNowSet.Add($t) | Out-Null } }
    } catch {}
    $cntVerified=0; $cntStillActive=0
    foreach ($pkg in $OTA_TARGET) {
        if (-not $allPkgsSet.Contains($pkg)) { continue }
        if     ($disabledNowSet.Contains($pkg))  { $cntVerified++ }
        elseif (-not $allNowSet.Contains($pkg))  { $cntVerified++ }
        else { & $otaLog "  [!!] Activo aun: $pkg"; $cntStillActive++ }
    }
    & $otaLog "[+] Verificados OK: $cntVerified  |  Activos aun: $cntStillActive"
    AdbLog ""

    # -- ETAPA 7: Estado final -----------------------------------------
    AdbLog "----------------------------------------------"
    & $otaLog "[7/7] Estado final..."
    $disabledAfter = $disabledNowSet.Count
    & $otaLog "[+] Deshabilitados antes: $disabledBefore  |  Ahora: $disabledAfter  |  Nuevos: $($disabledAfter - $disabledBefore)"
    AdbLog ""

    AdbLog "=============================================="
    AdbLog "  RESUMEN OTA BLOCKER"
    AdbLog "=============================================="
    AdbLog "  Dispositivo  : $model  ($serial)"
    AdbLog "  Android      : $android  (SDK $sdk)  [$brandLabel]"
    AdbLog "  Evaluados         : $($cntFound + $cntNotFound)"
    AdbLog "  Deshabilitados OK : $cntDisabled"
    AdbLog "  Desinstalados OK  : $cntUninstalled"
    AdbLog "  Ya bloqueados     : $cntSkipped"
    AdbLog "  No encontrados    : $cntNotFound"
    AdbLog "  Fallidos          : $cntFailed"
    AdbLog "  Dinamicos extra   : $dynFound"
    AdbLog ""
    $totalOK = $cntDisabled + $cntUninstalled
    if ($totalOK -gt 0)                             { AdbLog "[OK] $totalOK paquetes OTA bloqueados exitosamente." }
    elseif ($cntSkipped -gt 0 -and $totalOK -eq 0) { AdbLog "[OK] Todos los OTA ya estaban bloqueados." }
    else                                             { AdbLog "[~]  Sin paquetes OTA activos encontrados." }
    if ($cntFailed -gt 0)      { AdbLog "[~]  $cntFailed fallaron (puede requerir root)." }
    if ($cntStillActive -gt 0) { AdbLog "[!]  $cntStillActive siguen activos -- usa root para bloqueo total." }
    if ($useAgressive)         { AdbLog "[~]  HyperOS: si OTA reaparece tras reinicio, repetir." }
    if ($sdk -ge 35 -and ($mfrRaw -match "samsung" -or $brand -match "samsung")) {
        AdbLog "[~]  Samsung: SDM puede reactivarse tras Smart Switch restore."
    }
    AdbLog "[~]  Reinicia el dispositivo para aplicar todos los cambios."
    AdbLog "=============================================="

    $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  OTA BLOQUEADO  |  $model"
    $btn.Enabled = $true
    $btn.Text    = "BLOQUEAR OTA"
})

$btnsA1[3].Add_Click({
    # ============================================================
    # REMOVER ADWARE v2 - escaner permisos, buscador, whitelist, turbo
    # ============================================================
    $btn = $btnsA1[3]
    $btn.Enabled = $false; $btn.Text = "ANALIZANDO..."
    [System.Windows.Forms.Application]::DoEvents()

    $mwLog2 = { param($m); AdbLog ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $m) }

    $adbOK = $false
    try { $adbOK = ((& adb devices 2>$null) -join "" -match "`tdevice") } catch {}
    if (-not $adbOK) {
        AdbLog "[!] Sin ADB. Conecta el equipo con USB Debugging activado."
        $btn.Enabled = $true; $btn.Text = "REMOVER ADWARE"; return
    }

    $model  = ""; $serial = ""
    try { $model  = (& adb shell getprop ro.product.model 2>$null).Trim() } catch {}
    try { $serial = (& adb get-serialno 2>$null).Trim() } catch {}

    # ============================================================
    # WHITELIST TOTAL: paquetes que se EXCLUYEN del scanner
    # (nunca aparecen en la lista, ni siquiera para mostrar)
    # ============================================================
    $sysWhitelist = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@(
            # Android core
            "android","com.android.settings","com.android.systemui","com.android.phone",
            "com.android.server.telecom","com.android.providers.telephony",
            "com.android.providers.contacts","com.android.providers.media",
            "com.android.providers.downloads","com.android.launcher3",
            "com.android.inputmethod.latin","com.android.packageinstaller",
            "com.android.permissioncontroller","com.android.shell",
            "com.android.vpndialogs","com.android.nfc","com.android.bluetooth",
            # Google core (no tocar JAMAS)
            "com.google.android.gms","com.google.android.gsf",
            "com.google.android.googlequicksearchbox","com.google.android.webview",
            "com.google.android.packageinstaller","com.google.android.permissioncontroller",
            "com.google.android.gmscore","com.google.android.syncadapters.contacts",
            "com.google.android.tts","com.google.android.inputmethod.latin"
        ),
        [System.StringComparer]::OrdinalIgnoreCase
    )

    # ============================================================
    # LISTA PROTEGIDA: apps conocidas y legitimas que SE MUESTRAN
    # pero con etiqueta [OK] en verde y NO seleccionadas por defecto.
    # El usuario puede marcarlas manualmente si lo desea.
    # Organizadas por categoria para facil mantenimiento.
    # ============================================================
    $knownSafeList = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@(
            # --- Google apps de usuario ---
            "com.google.android.youtube","com.google.android.apps.maps",
            "com.google.android.apps.photos","com.google.android.play.games",
            "com.google.android.talk","com.google.android.apps.messaging",
            "com.google.android.dialer","com.google.android.contacts",
            "com.google.android.calendar","com.google.android.keep",
            "com.google.android.apps.docs","com.google.android.apps.drive",
            "com.google.android.apps.youtube.music","com.google.android.gmail",
            "com.google.android.apps.translate","com.google.android.calculator",
            "com.google.android.deskclock","com.google.android.apps.wallpaper",
            "com.google.android.apps.chrome","com.android.chrome",
            # --- Mensajeria ---
            "com.whatsapp","com.whatsapp.w4b",
            "org.telegram.messenger","org.telegram.plus",
            "com.facebook.orca","com.facebook.mlite",
            "com.viber.voip","com.skype.raider","com.discord",
            "com.snapchat.android","com.instagram.android",
            "com.tencent.mm",  # WeChat
            # --- Redes sociales ---
            "com.facebook.katana","com.facebook.lite",
            "com.twitter.android","com.twitter.android.lite",
            "com.linkedin.android","com.pinterest",
            "com.zhiliaoapp.musically",  # TikTok
            "com.ss.android.ugc.trill",  # TikTok alternativo
            # --- Browsers ---
            "com.android.browser","com.sec.android.app.sbrowser",
            "com.mi.globalbrowser","org.mozilla.firefox","org.mozilla.focus",
            "com.opera.browser","com.opera.mini.native",
            "com.brave.browser","com.microsoft.emmx",
            "com.UCMobile.intl","com.uc.browser.en",
            # --- Samsung OEM ---
            "com.samsung.android.contacts","com.samsung.android.messaging",
            "com.samsung.android.dialer","com.samsung.android.app.galaxystore",
            "com.samsung.android.lool","com.samsung.android.mobileservice",
            "com.samsung.android.providers.contacts","com.samsung.android.app.clockpackage",
            "com.samsung.android.app.notes","com.samsung.android.calendar",
            "com.samsung.android.incallui","com.samsung.android.app.smartcapture",
            "com.samsung.android.app.spage","com.samsung.android.app.settings.bixby",
            "com.samsung.android.knox.containeragent","com.samsung.android.gallery3d",
            "com.samsung.android.app.galaxyfinder","com.samsung.android.video",
            "com.samsung.android.music","com.samsung.android.email.provider",
            "com.samsung.android.app.memo","com.samsung.android.kidsinstaller",
            # --- Xiaomi/MIUI OEM ---
            "com.miui.gallery","com.miui.videoplayer","com.miui.player",
            "com.miui.notes","com.miui.calculator","com.miui.clock",
            "com.miui.contacts","com.miui.messaging","com.miui.dialer",
            "com.miui.browser","com.mi.globalbrowser",
            "com.xiaomi.mipicks",  # GetApps
            "com.miui.securitycenter",  # Security app MIUI (OEM)
            # --- OPPO/Realme/OnePlus OEM ---
            "com.coloros.gallery3d","com.oppo.gallery3d",
            "com.heytap.browser","com.realme.community",
            "com.oneplus.gallery","com.oneplus.filemanager",
            # --- Musica y entretenimiento ---
            "com.spotify.music","com.deezer.android",
            "com.amazon.mp3","com.shazam.android",
            "com.netflix.mediaclient","com.primevideo",
            "com.disney.disneyplus","com.hbo.hbonow",
            # --- Productividad y utilidades conocidas ---
            "com.microsoft.office.word","com.microsoft.office.excel",
            "com.microsoft.office.powerpoint","com.microsoft.teams",
            "com.microsoft.launcher","com.microsoft.skydrive",
            "com.adobe.reader","com.adobe.lrmobile",
            "com.dropbox.android","com.box.android",
            "com.evernote","com.todoist","com.trello",
            "com.lastpass.lpandroid","com.dashlane",
            # --- Mapas y transporte ---
            "com.waze","com.ubercab","com.ubercab.eats",
            "com.indriver.app","com.cabify.rider",
            # --- Bancos y pagos (Peru y Latam comunes) ---
            "pe.com.interbank.appinterbank","com.bcp.banca.movil",
            "com.bbva.pe","com.scotiabank.pe",
            "com.yape.app","com.bim.wallet",
            "com.ripley.banco","com.falabella.bancafalabella",
            "pe.bn.movil","com.financiero.banbif",
            # --- Camara y foto ---
            "com.google.android.GoogleCamera","com.sec.android.app.camera",
            "com.mi.camera","com.oneplus.camera","com.coloros.camera",
            "com.adobe.lrmobile","com.snapchat.android",
            # --- Tiendas de apps ---
            "com.android.vending",  # Google Play Store
            "com.amazon.venezia"    # Amazon Appstore
        ),
        [System.StringComparer]::OrdinalIgnoreCase
    )

    # ---- PERMISOS PELIGROSOS con peso de score ----
    $dangerPerms = @{
        "RECORD_AUDIO"=3; "READ_SMS"=3; "RECEIVE_SMS"=3; "SEND_SMS"=2
        "READ_CALL_LOG"=3; "PROCESS_OUTGOING_CALLS"=2
        "ACCESS_FINE_LOCATION"=2; "ACCESS_BACKGROUND_LOCATION"=3
        "CAMERA"=1; "READ_CONTACTS"=1; "WRITE_CONTACTS"=1
        "GET_ACCOUNTS"=1; "READ_PHONE_STATE"=1
        "INSTALL_PACKAGES"=3; "REQUEST_INSTALL_PACKAGES"=2
        "SYSTEM_ALERT_WINDOW"=2; "BIND_ACCESSIBILITY_SERVICE"=3
        "BIND_DEVICE_ADMIN"=3; "RECEIVE_BOOT_COMPLETED"=1
    }

    # ---- FIRMAS Y KEYWORDS conocidas de malware ----
    $autoMark = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@(
            "com.clean.master","com.cleanmaster.mguard","com.junk.clean","com.boost.speed",
            "com.ram.cleaner","com.super.cleaner","com.phone.cleaner","com.best.cleaner",
            "com.antivirus.clean","com.cm.antivirus","com.qihoo360.mobilesafe",
            "com.shield.antivirus","com.mobile.protect","com.security.shield",
            "com.ufo.vpn","com.thunder.vpn","com.free.vpn","com.turbo.vpn","com.snap.vpn",
            "com.apus.launcher","com.go.launcher.ex","com.android.spy","com.spyphone.app",
            "com.mspy.android","com.phonespector","com.system.update.service",
            "com.flash.player.service","com.superantivirus.security","com.superantivirus.cleaner",
            "com.super.antivirus","com.nq.antivirus","com.nq.mobilesafe","am.mobile.security",
            "com.shieldav.free","com.shield.security.antivirus","com.iclean.phone",
            "com.cleanphone.free","com.power.cleaner","com.virus.remover.cleaner",
            "com.mobiapp.superantivirus"
        ),
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $autoKw = @("cleaner","booster","antivirus","virus","spyware","stalker","flashplayer",
                "systemupdate","superclean","cleanphone","mobilesafe","virusremov",
                "virusscann","mspy","spyphone","keylogger","rootkit","trojan","malware","adware")

    # ---- OBTENER LISTA DE APPS ----
    & $mwLog2 "[~] Obteniendo apps instaladas..."
    [System.Windows.Forms.Application]::DoEvents()

    $pkgLines = @()
    try { $pkgLines = (& adb shell pm list packages -3 -f 2>$null) |
          ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } } catch {}

    $appList = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($line in $pkgLines) {
        $pkgName = ""; $apkPath = ""
        if ($line -match "^package:(.+)=([^\s]+)$") {
            $apkPath = $Matches[1].Trim(); $pkgName = $Matches[2].Trim()
        } elseif ($line -match "^package:([^\s]+)$") {
            $pkgName = $Matches[1].Trim()
        }
        if (-not $pkgName) { continue }
        if ($sysWhitelist.Contains($pkgName)) { continue }   # excluir totalmente
        $safe = $knownSafeList.Contains($pkgName)
        $appList.Add(@{ pkg=$pkgName; apk=$apkPath; score=0; isSafe=$safe; permFlags=[System.Collections.Generic.List[string]]::new() })
    }

    if ($appList.Count -eq 0) {
        AdbLog "[!] No se encontraron apps de terceros."
        $btn.Enabled = $true; $btn.Text = "REMOVER ADWARE"; return
    }

    # ---- ESCANER DE PERMISOS ----
    & $mwLog2 "[~] Escaneando permisos ($($appList.Count) apps)..."
    $ii = 0
    foreach ($app in $appList) {
        $ii++
        if ($ii % 10 -eq 0) { $btn.Text = "ESCANEANDO... $ii/$($appList.Count)"; [System.Windows.Forms.Application]::DoEvents() }
        $pkg = $app.pkg; $score = 0

        # Apps protegidas: no acumulan score por permisos (son legitimas)
        # Solo marcar si coincide con firma de malware conocida
        if ($app.isSafe) {
            if ($autoMark.Contains($pkg)) { $score += 10 }  # malware conocido que usurpa nombre
            $app.score = $score
            continue
        }

        if ($autoMark.Contains($pkg)) { $score += 10 }
        foreach ($kw in $autoKw) { if ($pkg -imatch $kw) { $score += 5; break } }

        try {
            $permRaw = (& adb shell "dumpsys package $pkg 2>/dev/null | grep 'granted=true'" 2>$null) -join " "
            foreach ($perm in $dangerPerms.Keys) {
                if ($permRaw -imatch $perm) {
                    $score += $dangerPerms[$perm]
                    $app.permFlags.Add($perm) | Out-Null
                }
            }
        } catch {}
        $app.score = $score
    }

    # ---- MAPA pkg->app y lista ordenada ----
    # Orden: malware/sospechosos primero (score desc), luego normales, protegidas al final
    $appMap = @{}
    foreach ($app in $appList) { $appMap[$app.pkg] = $app }
    $allItems = [System.Collections.Generic.List[hashtable]]::new()
    $sorted = $appList | Sort-Object {
        if ($_.isSafe) { -999 } else { $_.score * -1 }
    }
    foreach ($app in $sorted) { $allItems.Add($app) }

    # Colores por categoria
    $colDanger  = [System.Drawing.Color]::FromArgb(255, 80,  80)   # Rojo     score>=10
    $colWarn    = [System.Drawing.Color]::FromArgb(255,160,  40)   # Naranja  score>=5
    $colNeutral = [System.Drawing.Color]::FromArgb(200,200,200)    # Gris claro score>=1
    $colClean   = [System.Drawing.Color]::FromArgb(130,130,130)    # Gris oscuro score=0
    $colSafe    = [System.Drawing.Color]::FromArgb( 80,220,120)    # Verde    protegida
    $colBgDark  = [System.Drawing.Color]::FromArgb( 25, 25, 25)
    $colBgSafe  = [System.Drawing.Color]::FromArgb( 15, 35, 20)   # fondo verde muy oscuro
    $colBgWarn  = [System.Drawing.Color]::FromArgb( 40, 20, 10)
    $colBgDang  = [System.Drawing.Color]::FromArgb( 45, 10, 10)

    $abbrevMap = @{
        "RECORD_AUDIO"="MIC"; "READ_SMS"="SMS_R"; "RECEIVE_SMS"="SMS_IN"; "SEND_SMS"="SMS_W"
        "ACCESS_FINE_LOCATION"="GPS"; "ACCESS_BACKGROUND_LOCATION"="GPS_BG"
        "READ_CALL_LOG"="CALLS"; "BIND_ACCESSIBILITY_SERVICE"="A11Y"
        "BIND_DEVICE_ADMIN"="ADMIN"; "INSTALL_PACKAGES"="INST_PKG"
        "REQUEST_INSTALL_PACKAGES"="REQ_INST"; "SYSTEM_ALERT_WINDOW"="OVERLAY"
        "CAMERA"="CAM"; "READ_CONTACTS"="CONT_R"; "PROCESS_OUTGOING_CALLS"="CALLS_OUT"
        "GET_ACCOUNTS"="ACCTS"; "READ_PHONE_STATE"="PHONE"; "RECEIVE_BOOT_COMPLETED"="BOOT"
        "WRITE_CONTACTS"="CONT_W"
    }

    # Estado de checks persistente entre filtros
    $checkState = @{}

    # ============================================================
    # CONSTRUIR VENTANA
    # ============================================================
    $win = New-Object Windows.Forms.Form
    $win.Text          = "REMOVER ADWARE / MALWARE  -  RNX TOOL PRO  |  $model  ($serial)"
    $win.ClientSize    = New-Object System.Drawing.Size(980, 660)
    $win.BackColor     = [System.Drawing.Color]::FromArgb(18,18,18)
    $win.FormBorderStyle = "FixedSingle"
    $win.StartPosition = "CenterScreen"
    $win.TopMost       = $true

    # ---- Leyenda de colores ----
    $pnlLegend = New-Object Windows.Forms.Panel
    $pnlLegend.Location = New-Object System.Drawing.Point(0,0)
    $pnlLegend.Size = New-Object System.Drawing.Size(980, 22)
    $pnlLegend.BackColor = [System.Drawing.Color]::FromArgb(28,28,28)
    $win.Controls.Add($pnlLegend)

    $mkLbl = {
        param($txt,$x,$col)
        $l = New-Object Windows.Forms.Label
        $l.Text = $txt; $l.Location = New-Object System.Drawing.Point($x,3)
        $l.Size = New-Object System.Drawing.Size(160,16)
        $l.ForeColor = $col; $l.Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
        $pnlLegend.Controls.Add($l)
    }
    & $mkLbl "  [!!] PELIGROSO (score>=10)"   0   $colDanger
    & $mkLbl "  [! ] SOSPECHOSO (score>=5)"  175   $colWarn
    & $mkLbl "  [~]  REVISAR (score 1-4)"    355   $colNeutral
    & $mkLbl "  [  ] SIN RIESGO"             520   $colClean
    & $mkLbl "  [OK] PROTEGIDA / CONOCIDA"   665   $colSafe

    # ---- Barra de busqueda ----
    $lblSearch = New-Object Windows.Forms.Label
    $lblSearch.Text = "Buscar:"; $lblSearch.Location = New-Object System.Drawing.Point(8,28)
    $lblSearch.Size = New-Object System.Drawing.Size(46,22)
    $lblSearch.ForeColor = [System.Drawing.Color]::FromArgb(160,160,160)
    $lblSearch.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $win.Controls.Add($lblSearch)

    $txtSearch = New-Object Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(56,26); $txtSearch.Size = New-Object System.Drawing.Size(300,22)
    $txtSearch.BackColor = [System.Drawing.Color]::FromArgb(35,35,35); $txtSearch.ForeColor = [System.Drawing.Color]::White
    $txtSearch.Font = New-Object System.Drawing.Font("Consolas",9); $txtSearch.BorderStyle = "FixedSingle"
    $win.Controls.Add($txtSearch)

    # Filtro rapido por categoria
    $cmbFilter = New-Object Windows.Forms.ComboBox
    $cmbFilter.Location = New-Object System.Drawing.Point(364,26); $cmbFilter.Size = New-Object System.Drawing.Size(140,22)
    $cmbFilter.DropDownStyle = "DropDownList"
    $cmbFilter.BackColor = [System.Drawing.Color]::FromArgb(35,35,35); $cmbFilter.ForeColor = [System.Drawing.Color]::White
    $cmbFilter.Font = New-Object System.Drawing.Font("Segoe UI",8)
    @("Todas","Solo peligrosas","Solo sospechosas","Solo protegidas","Sin riesgo") |
        ForEach-Object { $cmbFilter.Items.Add($_) | Out-Null }
    $cmbFilter.SelectedIndex = 0
    $win.Controls.Add($cmbFilter)

    $lblCount = New-Object Windows.Forms.Label
    $lblCount.Location = New-Object System.Drawing.Point(515,30); $lblCount.Size = New-Object System.Drawing.Size(460,16)
    $lblCount.ForeColor = [System.Drawing.Color]::FromArgb(110,110,110)
    $lblCount.Font = New-Object System.Drawing.Font("Segoe UI",7.5)
    $win.Controls.Add($lblCount)

    # ---- ListView principal con colores ----
    $lv = New-Object Windows.Forms.ListView
    $lv.Location = New-Object System.Drawing.Point(8,54); $lv.Size = New-Object System.Drawing.Size(962,540)
    $lv.View = [System.Windows.Forms.View]::Details
    $lv.FullRowSelect = $true; $lv.CheckBoxes = $true; $lv.GridLines = $false
    $lv.BackColor = [System.Drawing.Color]::FromArgb(22,22,22)
    $lv.ForeColor = [System.Drawing.Color]::White
    $lv.Font = New-Object System.Drawing.Font("Consolas",8.5)
    $lv.BorderStyle = "FixedSingle"
    $lv.HeaderStyle = "Nonclickable"

    $lv.Columns.Add("Estado",  60)  | Out-Null
    $lv.Columns.Add("Paquete", 430) | Out-Null
    $lv.Columns.Add("Score",    52) | Out-Null
    $lv.Columns.Add("Permisos",400) | Out-Null
    $win.Controls.Add($lv)

    # ---- Funcion para obtener color y tag de una app ----
    $script:GetAppStyle = {
        param($app)
        if ($app.isSafe) {
            return @{ tag="[OK]"; fg=$colSafe; bg=$colBgSafe }
        }
        if ($app.score -ge 10) { return @{ tag="[!!]"; fg=$colDanger; bg=$colBgDang } }
        if ($app.score -ge 5)  { return @{ tag="[! ]"; fg=$colWarn;   bg=$colBgWarn } }
        if ($app.score -ge 1)  { return @{ tag="[~ ]"; fg=$colNeutral; bg=$colBgDark } }
        return @{ tag="[  ]"; fg=$colClean; bg=$colBgDark }
    }

    # ---- Poblar ListView ----
    $script:PopulateLV = {
        param($textFilter, $catFilter)
        $lv.Items.Clear()
        $lv.BeginUpdate()
        $shown = 0; $selCount = 0

        foreach ($app in $allItems) {
            # Filtro de texto
            if ($textFilter) {
                $matchPkg   = $app.pkg -imatch [regex]::Escape($textFilter)
                $matchPerms = ($app.permFlags -join " ") -imatch [regex]::Escape($textFilter)
                if (-not ($matchPkg -or $matchPerms)) { continue }
            }
            # Filtro de categoria
            switch ($catFilter) {
                "Solo peligrosas"   { if ($app.isSafe -or $app.score -lt 10) { continue } }
                "Solo sospechosas"  { if ($app.isSafe -or $app.score -lt 5)  { continue } }
                "Solo protegidas"   { if (-not $app.isSafe) { continue } }
                "Sin riesgo"        { if ($app.isSafe -or $app.score -gt 0)  { continue } }
            }

            $style = & $script:GetAppStyle $app
            $permShort = ""
            if ($app.permFlags.Count -gt 0) {
                $flags = $app.permFlags | ForEach-Object { if ($abbrevMap.ContainsKey($_)) { $abbrevMap[$_] } else { $_ } }
                $shown4 = $flags | Select-Object -First 5
                $extra  = if ($app.permFlags.Count -gt 5) { " +$($app.permFlags.Count-5)mas" } else { "" }
                $permShort = ($shown4 -join "  ") + $extra
            }
            $scoreDisp = if ($app.score -gt 0) { "$($app.score)" } else { "-" }

            $lvi = New-Object Windows.Forms.ListViewItem($style.tag)
            $lvi.ForeColor = $style.fg
            $lvi.BackColor = $style.bg
            $lvi.SubItems.Add($app.pkg)   | Out-Null
            $lvi.SubItems.Add($scoreDisp) | Out-Null
            $lvi.SubItems.Add($permShort) | Out-Null
            $lvi.Tag = $app.pkg

            # Estado del check
            $isChecked = if ($checkState.ContainsKey($app.pkg)) {
                $checkState[$app.pkg]
            } else {
                # Por defecto: sospechosas/peligrosas marcadas, protegidas y limpias NO
                $app.score -ge 5 -and -not $app.isSafe
            }
            if (-not $checkState.ContainsKey($app.pkg)) { $checkState[$app.pkg] = $isChecked }
            $lvi.Checked = $isChecked
            if ($isChecked) { $selCount++ }

            $lv.Items.Add($lvi) | Out-Null
            $shown++
        }

        $lv.EndUpdate()
        $highRisk  = ($allItems | Where-Object { -not $_.isSafe -and $_.score -ge 10 }).Count
        $warnCount = ($allItems | Where-Object { -not $_.isSafe -and $_.score -ge 5 -and $_.score -lt 10 }).Count
        $safeCount = ($allItems | Where-Object { $_.isSafe }).Count
        $lblCount.Text = "Total: $($allItems.Count)  |  Mostrando: $shown  |  Marcadas: $selCount  |  [!!]: $highRisk  [! ]: $warnCount  [OK]: $safeCount"
    }

    & $script:PopulateLV "" "Todas"

    $lv.Add_ItemChecked({
        $pkg = $_.Item.Tag
        $checkState[$pkg] = $_.Item.Checked
        $selCount = 0
        foreach ($lvi in $lv.Items) { if ($lvi.Checked) { $selCount++ } }
        $highRisk  = ($allItems | Where-Object { -not $_.isSafe -and $_.score -ge 10 }).Count
        $warnCount = ($allItems | Where-Object { -not $_.isSafe -and $_.score -ge 5 -and $_.score -lt 10 }).Count
        $safeCount = ($allItems | Where-Object { $_.isSafe }).Count
        $lblCount.Text = "Total: $($allItems.Count)  |  Mostrando: $($lv.Items.Count)  |  Marcadas: $selCount  |  [!!]: $highRisk  [! ]: $warnCount  [OK]: $safeCount"
    })

    $txtSearch.Add_TextChanged({ & $script:PopulateLV $txtSearch.Text.Trim() $cmbFilter.SelectedItem })
    $cmbFilter.Add_SelectedIndexChanged({ & $script:PopulateLV $txtSearch.Text.Trim() $cmbFilter.SelectedItem })

    # ---- BOTONES (ahora usan $lv en vez de $clb) ----
    $btnY = 602

    $btnSelAll = New-Object Windows.Forms.Button
    $btnSelAll.Text="MARCAR TODAS"; $btnSelAll.Location=New-Object System.Drawing.Point(8,$btnY)
    $btnSelAll.Size=New-Object System.Drawing.Size(110,28); $btnSelAll.FlatStyle="Flat"
    $btnSelAll.ForeColor=[System.Drawing.Color]::White; $btnSelAll.BackColor=[System.Drawing.Color]::FromArgb(40,40,40)
    $btnSelAll.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(80,80,80)
    $btnSelAll.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnSelAll.Add_Click({
        foreach ($lvi in $lv.Items) {
            $lvi.Checked = $true; $checkState[$lvi.Tag] = $true
        }
    })
    $win.Controls.Add($btnSelAll)

    $btnNone = New-Object Windows.Forms.Button
    $btnNone.Text="DESMARCAR"; $btnNone.Location=New-Object System.Drawing.Point(126,$btnY)
    $btnNone.Size=New-Object System.Drawing.Size(95,28); $btnNone.FlatStyle="Flat"
    $btnNone.ForeColor=[System.Drawing.Color]::White; $btnNone.BackColor=[System.Drawing.Color]::FromArgb(40,40,40)
    $btnNone.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(80,80,80)
    $btnNone.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnNone.Add_Click({
        foreach ($lvi in $lv.Items) {
            $lvi.Checked = $false; $checkState[$lvi.Tag] = $false
        }
    })
    $win.Controls.Add($btnNone)

    $btnOnlySusp = New-Object Windows.Forms.Button
    $btnOnlySusp.Text="SOLO RIESGO"; $btnOnlySusp.Location=New-Object System.Drawing.Point(229,$btnY)
    $btnOnlySusp.Size=New-Object System.Drawing.Size(100,28); $btnOnlySusp.FlatStyle="Flat"
    $btnOnlySusp.ForeColor=[System.Drawing.Color]::Orange; $btnOnlySusp.BackColor=[System.Drawing.Color]::FromArgb(40,30,10)
    $btnOnlySusp.FlatAppearance.BorderColor=[System.Drawing.Color]::Orange
    $btnOnlySusp.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnOnlySusp.Add_Click({
        foreach ($lvi in $lv.Items) {
            $app = $appMap[$lvi.Tag]
            $isSusp = ($app -and -not $app.isSafe -and $app.score -ge 5)
            $lvi.Checked = $isSusp; $checkState[$lvi.Tag] = $isSusp
        }
    })
    $win.Controls.Add($btnOnlySusp)

    # MODO TURBO
    $script:turboMode = $false
    $btnTurbo = New-Object Windows.Forms.Button
    $btnTurbo.Text="!! TURBO !!"; $btnTurbo.Location=New-Object System.Drawing.Point(337,$btnY)
    $btnTurbo.Size=New-Object System.Drawing.Size(105,28); $btnTurbo.FlatStyle="Flat"
    $btnTurbo.ForeColor=[System.Drawing.Color]::Red; $btnTurbo.BackColor=[System.Drawing.Color]::FromArgb(40,10,10)
    $btnTurbo.FlatAppearance.BorderColor=[System.Drawing.Color]::OrangeRed
    $btnTurbo.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnTurbo.Add_Click({
        $targets = @($allItems | Where-Object { $_.score -ge 5 } | Sort-Object { $_.score } -Descending)
        if ($targets.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No hay apps con score >= 5.","Turbo - sin targets",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            return
        }
        # Dialogo propio con lista scrollable
        $td = New-Object Windows.Forms.Form
        $td.Text = "!! TURBO - Confirmar eliminacion !!"; $td.ClientSize = New-Object System.Drawing.Size(560,420)
        $td.BackColor = [System.Drawing.Color]::FromArgb(18,18,18); $td.FormBorderStyle = "FixedDialog"
        $td.StartPosition = "CenterScreen"; $td.TopMost = $true

        $tdLbl = New-Object Windows.Forms.Label
        $tdLbl.Text = "  Se eliminaran $($targets.Count) apps con score >= 5 SIN confirmacion adicional:"
        $tdLbl.Location = New-Object System.Drawing.Point(0,10); $tdLbl.Size = New-Object System.Drawing.Size(560,20)
        $tdLbl.ForeColor = [System.Drawing.Color]::OrangeRed; $tdLbl.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        $td.Controls.Add($tdLbl)

        $tdList = New-Object Windows.Forms.TextBox
        $tdList.Multiline = $true; $tdList.ReadOnly = $true; $tdList.ScrollBars = "Vertical"
        $tdList.Location = New-Object System.Drawing.Point(12,36); $tdList.Size = New-Object System.Drawing.Size(536,320)
        $tdList.BackColor = [System.Drawing.Color]::FromArgb(28,10,10); $tdList.ForeColor = [System.Drawing.Color]::OrangeRed
        $tdList.Font = New-Object System.Drawing.Font("Consolas",8)
        $nl = "`r`n"
        $lines = $targets | ForEach-Object {
            $permShort = if ($_.permFlags.Count -gt 0) { "  [" + (($_.permFlags | Select-Object -First 3) -join ",") + $(if($_.permFlags.Count -gt 3){"+..."}) + "]" } else {""}
            "  score:$($_.score.ToString().PadLeft(3))  $($_.pkg)$permShort"
        }
        $tdList.Text = ($lines -join $nl)
        $td.Controls.Add($tdList)

        $tdWarn = New-Object Windows.Forms.Label
        $tdWarn.Text = "  Esta accion es irreversible. Las apps de sistema se deshabilitaran, las de usuario se eliminaran."
        $tdWarn.Location = New-Object System.Drawing.Point(0,362); $tdWarn.Size = New-Object System.Drawing.Size(560,18)
        $tdWarn.ForeColor = [System.Drawing.Color]::FromArgb(160,80,80); $tdWarn.Font = New-Object System.Drawing.Font("Segoe UI",8)
        $td.Controls.Add($tdWarn)

        $tdOK = New-Object Windows.Forms.Button
        $tdOK.Text = "CONFIRMAR - ELIMINAR $($targets.Count) APPS"
        $tdOK.Location = New-Object System.Drawing.Point(12,385); $tdOK.Size = New-Object System.Drawing.Size(310,28)
        $tdOK.FlatStyle = "Flat"; $tdOK.ForeColor = [System.Drawing.Color]::White
        $tdOK.BackColor = [System.Drawing.Color]::FromArgb(120,20,20)
        $tdOK.FlatAppearance.BorderColor = [System.Drawing.Color]::OrangeRed
        $tdOK.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
        $tdOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $td.Controls.Add($tdOK)

        $tdCancel = New-Object Windows.Forms.Button
        $tdCancel.Text = "CANCELAR"; $tdCancel.Location = New-Object System.Drawing.Point(334,385)
        $tdCancel.Size = New-Object System.Drawing.Size(214,28); $tdCancel.FlatStyle = "Flat"
        $tdCancel.ForeColor = [System.Drawing.Color]::FromArgb(160,160,160)
        $tdCancel.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
        $tdCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80,80,80)
        $tdCancel.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
        $tdCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $td.Controls.Add($tdCancel)

        $td.AcceptButton = $tdOK; $td.CancelButton = $tdCancel
        $res = $td.ShowDialog()
        if ($res -ne [System.Windows.Forms.DialogResult]::OK) { return }

        # Excluir protegidas del turbo aunque tengan score (no deberian tenerlo)
        $script:uninstallResult = ($targets | Where-Object { -not $_.isSafe }) | ForEach-Object { $_.pkg }
        $script:turboMode = $true
        $win.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $win.Close()
    })
    $win.Controls.Add($btnTurbo)

    $script:uninstallResult = @()

    $btnUninstall = New-Object Windows.Forms.Button
    $btnUninstall.Text="DESINSTALAR SELECCIONADAS"; $btnUninstall.Location=New-Object System.Drawing.Point(450,$btnY)
    $btnUninstall.Size=New-Object System.Drawing.Size(238,28); $btnUninstall.FlatStyle="Flat"
    $btnUninstall.ForeColor=[System.Drawing.Color]::Lime; $btnUninstall.BackColor=[System.Drawing.Color]::FromArgb(10,40,10)
    $btnUninstall.FlatAppearance.BorderColor=[System.Drawing.Color]::Lime
    $btnUninstall.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnUninstall.Add_Click({
        $selected = @()
        foreach ($lvi in $lv.Items) {
            if ($lvi.Checked) { $selected += $lvi.Tag }
        }
        if ($selected.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No hay apps seleccionadas.","Sin seleccion",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            return
        }
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "Se desinstalaran $($selected.Count) app(s).`n`nConfirmar?",
            "Confirmar desinstalacion",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirm -ne "Yes") { return }
        $script:uninstallResult = $selected
        $win.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $win.Close()
    })
    $win.Controls.Add($btnUninstall)

    $btnClose = New-Object Windows.Forms.Button
    $btnClose.Text="CERRAR"; $btnClose.Location=New-Object System.Drawing.Point(696,$btnY)
    $btnClose.Size=New-Object System.Drawing.Size(110,28); $btnClose.FlatStyle="Flat"
    $btnClose.ForeColor=[System.Drawing.Color]::FromArgb(160,160,160); $btnClose.BackColor=[System.Drawing.Color]::FromArgb(35,35,35)
    $btnClose.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(80,80,80)
    $btnClose.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnClose.Add_Click({ $win.Close() })
    $win.Controls.Add($btnClose)

    $btn.Text = "REMOVER ADWARE"
    $win.ShowDialog() | Out-Null
    $btn.Enabled = $true; $btn.Text = "REMOVER ADWARE"

    if ($script:uninstallResult.Count -eq 0) { return }

    $Global:logAdb.Clear()
    AdbLog "=============================================="
    AdbLog "   DESINSTALACION EN BLOQUE  -  RNX TOOL PRO"
    AdbLog "   $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    if ($script:turboMode) { AdbLog "   !! MODO TURBO !!" }
    AdbLog "=============================================="
    AdbLog "[~] Apps a procesar: $($script:uninstallResult.Count)"
    AdbLog ""

    $cntOK = 0; $cntFail = 0
    foreach ($pkg in $script:uninstallResult) {
        # Seguridad: nunca procesar apps protegidas aunque lleguen aqui
        if ($appMap.ContainsKey($pkg) -and $appMap[$pkg].isSafe) {
            AdbLog "[~] Saltando app protegida: $pkg  (marcada como segura)"
            continue
        }
        AdbLog "[~] Procesando: $pkg"
        if ($appMap.ContainsKey($pkg) -and $appMap[$pkg].score -gt 0) {
            AdbLog "    Score: $($appMap[$pkg].score)  Permisos: $(($appMap[$pkg].permFlags -join ', '))"
        }

        # PRE: forzar parada, revocar permisos peligrosos y limpiar datos
        try { & adb shell am force-stop $pkg 2>$null | Out-Null } catch {}
        try { & adb shell pm revoke $pkg android.permission.SYSTEM_ALERT_WINDOW 2>$null | Out-Null } catch {}
        try { & adb shell cmd appops set $pkg SYSTEM_ALERT_WINDOW deny 2>$null | Out-Null } catch {}
        try { & adb shell pm clear $pkg 2>$null | Out-Null } catch {}

        $removed = $false

        # METODO 1: uninstall --user 0  (desinstala para el usuario actual sin root)
        $r = ""
        try { $r = (& adb shell pm uninstall --user 0 $pkg 2>&1) -join "" } catch {}
        if ($r -imatch "Success|DELETE_SUCCEEDED") {
            AdbLog "[OK] Removida (uninstall --user 0) : $pkg"; $cntOK++; $removed = $true
        }

        if (-not $removed) {
            # METODO 2: uninstall sin flag  (algunos fabricantes requieren esto)
            $r2 = ""
            try { $r2 = (& adb shell pm uninstall $pkg 2>&1) -join "" } catch {}
            if ($r2 -imatch "Success|DELETE_SUCCEEDED") {
                AdbLog "[OK] Removida (uninstall)          : $pkg"; $cntOK++; $removed = $true
            }
        }

        if (-not $removed) {
            # METODO 3: cmd package uninstall (Android 8+ alternativo)
            $r3 = ""
            try { $r3 = (& adb shell "cmd package uninstall --user 0 $pkg" 2>&1) -join "" } catch {}
            if ($r3 -imatch "Success|DELETE_SUCCEEDED") {
                AdbLog "[OK] Removida (cmd package)        : $pkg"; $cntOK++; $removed = $true
            }
        }

        if (-not $removed) {
            # METODO 4: disable-user  (para apps de sistema que no se pueden desinstalar)
            $r4 = ""
            try { $r4 = (& adb shell pm disable-user --user 0 $pkg 2>&1) -join "" } catch {}
            if ($r4 -imatch "disabled|success") {
                AdbLog "[OK] Deshabilitada (disable-user)  : $pkg  (app sistema)"; $cntOK++; $removed = $true
            }
        }

        if (-not $removed) {
            # METODO 5: pm hide  (oculta la app aunque no la desinstale - ultimo recurso)
            $r5 = ""
            try { $r5 = (& adb shell pm hide $pkg 2>&1) -join "" } catch {}
            if ($r5 -imatch "hidden|success") {
                AdbLog "[OK] Ocultada (pm hide)            : $pkg  (requiere verificar)"; $cntOK++; $removed = $true
            }
        }

        if (-not $removed) {
            # Todos los metodos fallaron - app probablemente protegida por el sistema
            AdbLog "[!!] Fallo todos los metodos       : $pkg"
            AdbLog "     -> En el equipo: Ajustes > Apps > $pkg > Desinstalar"
            $cntFail++
        }
        [System.Windows.Forms.Application]::DoEvents()
    }

    AdbLog ""
    AdbLog "=============================================="
    AdbLog "  RESUMEN DESINSTALACION"
    AdbLog "=============================================="
    AdbLog "  Procesadas    : $($script:uninstallResult.Count)"
    AdbLog "  Removidas OK  : $cntOK"
    AdbLog "  Fallidas      : $cntFail"
    AdbLog ""
    if ($cntOK -gt 0) { AdbLog "[OK] $cntOK apps eliminadas/deshabilitadas exitosamente." }
    if ($cntFail -gt 0) {
        AdbLog "[!]  $cntFail apps fallaron todos los metodos ADB."
        AdbLog "[~]  Para esas apps: ve al equipo > Ajustes > Apps > selecciona la app > Desinstalar."
        AdbLog "[~]  Si no aparece el boton Desinstalar, la app es del sistema y requiere root."
        AdbLog "[~]  Opcion: usa AUTOROOT MAGISK y repite para remover del sistema."
    }
    AdbLog "[~]  Reinicia el dispositivo para aplicar todos los cambios."
    AdbLog "=============================================="

    $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  DESINSTALACION OK: $cntOK  |  $model"
})

$btnsA3[0].Add_Click({
    # ============================================================
    # ACTIVAR DIAG XIAOMI  -  Instala midiag.apk y abre puerto Qualcomm 9008
    # ============================================================
    $btn = $btnsA3[0]
    $btn.Enabled = $false; $btn.Text = "EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()

    $Global:logAdb.Clear()
    AdbLog "=============================================="
    AdbLog "   ACTIVAR DIAG XIAOMI  -  RNX TOOL PRO"
    AdbLog "   $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    AdbLog "=============================================="
    AdbLog ""

    if (-not (Check-ADB)) {
        AdbLog "[!] Sin dispositivo ADB conectado."
        $btn.Enabled = $true; $btn.Text = "ACTIVAR DIAG XIAOMI"; return
    }

    # Leer info del dispositivo
    $diagModel  = (& adb shell getprop ro.product.model      2>$null).Trim()
    $diagBrand  = (& adb shell getprop ro.product.brand      2>$null).Trim().ToUpper()
    $diagAndro  = (& adb shell getprop ro.build.version.release 2>$null).Trim()
    $diagMiui   = (& adb shell getprop ro.miui.ui.version.name  2>$null).Trim()
    $diagHyper  = (& adb shell getprop ro.mi.os.version.incremental 2>$null).Trim()
    $diagSerial = (& adb get-serialno 2>$null).Trim()

    AdbLog "[+] Dispositivo : $diagBrand  $diagModel"
    AdbLog "[+] Android     : $diagAndro"
    if ($diagMiui  -ne "") { AdbLog "[+] MIUI/HyperOS: $diagMiui" }
    if ($diagHyper -ne "") { AdbLog "[+] HyperOS ver : $diagHyper" }
    AdbLog "[+] Serial      : $diagSerial"
    AdbLog ""

    # Bloquear si no es Xiaomi - midiag.apk usa firma de sistema Xiaomi
    # y falla con INSTALL_FAILED_SHARED_USER_INCOMPATIBLE en otros fabricantes
    if ($diagBrand -notmatch "XIAOMI|REDMI|POCO") {
        AdbLog "[!] ERROR: Este dispositivo es $diagBrand - no es compatible."
        AdbLog "[!] midiag.apk usa firma de sistema Xiaomi (android.uid.system)"
        AdbLog "[!] y solo puede instalarse en dispositivos Xiaomi/Redmi/Poco."
        AdbLog ""
        AdbLog "[~] Conecta un dispositivo Xiaomi, Redmi o Poco para usar esta funcion."
        $btn.Enabled = $true; $btn.Text = "ACTIVAR DIAG XIAOMI"; return
    }

    # Buscar midiag.apk - ruta principal: RNX_TOOL_PRO\tools\midiag.apk
    $midiagApkName = "midiag.apk"
    $midiagToolsPath = Join-Path $script:TOOLS_DIR $midiagApkName
    AdbLog "[~] Buscando $midiagApkName en: $midiagToolsPath"
    $midiagPath = if (Test-Path $midiagToolsPath -EA SilentlyContinue) { $midiagToolsPath } else { $null }
    if ($midiagPath) {
        AdbLog "[+] midiag.apk encontrado en tools\"
    } else {
        AdbLog "[~] No encontrado en tools\ -> se pedira seleccion manual."
    }

    # Verificar si midiag ya esta instalada en el equipo
    AdbLog "[~] Verificando si MiDiag ya esta instalada en el equipo..."
    $midiagInstalled = $false
    $midiagPkg = "com.longcheertel.midtest"
    $pkgCheck = (& adb shell "pm list packages $midiagPkg 2>/dev/null" 2>$null) -join ""
    if ($pkgCheck -imatch $midiagPkg) {
        $midiagInstalled = $true
        AdbLog "[+] MiDiag ya esta instalada -> omitiendo instalacion."
    } else {
        AdbLog "[~] MiDiag no encontrada -> procediendo a instalar..."
        if (-not $midiagPath) {
            AdbLog "[~] midiag.apk no encontrado en rutas predeterminadas."
            AdbLog "[~] Selecciona manualmente el archivo midiag.apk ..."
            $fdDiag = New-Object System.Windows.Forms.OpenFileDialog
            $fdDiag.Filter = "MiDiag APK (*.apk)|*.apk|Todos|*.*"
            $fdDiag.Title  = "Selecciona midiag.apk"
            if ($fdDiag.ShowDialog() -ne "OK") {
                AdbLog "[~] Cancelado."
                $btn.Enabled = $true; $btn.Text = "ACTIVAR DIAG XIAOMI"; return
            }
            $midiagPath = $fdDiag.FileName
        }
        AdbLog "[+] APK: $midiagPath"
        AdbLog "[~] Instalando midiag.apk via ADB..."

        $psiDiag = New-Object System.Diagnostics.ProcessStartInfo
        $psiDiag.FileName               = "adb"
        $psiDiag.Arguments              = "install -r `"$midiagPath`""
        $psiDiag.RedirectStandardOutput = $true
        $psiDiag.RedirectStandardError  = $true
        $psiDiag.UseShellExecute        = $false
        $psiDiag.CreateNoWindow         = $true
        $pDiag = New-Object System.Diagnostics.Process
        $pDiag.StartInfo = $psiDiag; $pDiag.Start() | Out-Null
        $outDiag = $pDiag.StandardOutput.ReadToEnd()
        $errDiag = $pDiag.StandardError.ReadToEnd()
        $pDiag.WaitForExit()
        $combDiag = ($outDiag + "`n" + $errDiag).Trim()
        foreach ($line in ($combDiag -split "`n")) {
            $l = $line.Trim(); if ($l) { AdbLog "    $l" }
        }
        AdbLog ""
        if ($combDiag -imatch "Success") {
            AdbLog "[OK] MiDiag instalada correctamente."
            $midiagInstalled = $true
        } else {
            AdbLog "[!] Error al instalar MiDiag. Verifica el APK e intenta de nuevo."
            $btn.Enabled = $true; $btn.Text = "ACTIVAR DIAG XIAOMI"; return
        }
    }

    AdbLog ""

    # Ejecutar MiDiag y lanzar actividad DIAG
    if ($midiagInstalled) {
        AdbLog "[~] Lanzando MiDiag en el equipo..."
        & adb shell "am start -n com.longcheertel.midtest/com.longcheertel.midtest.Diag" 2>$null | Out-Null
        Start-Sleep -Milliseconds 1500
        AdbLog "[+] Comando DIAG enviado al equipo."
        AdbLog ""
        AdbLog "=============================================="
        AdbLog "  PASOS SIGUIENTES:"
        AdbLog "=============================================="
        AdbLog ""
        AdbLog "  [1]  El equipo deberia reiniciarse en modo DIAG"
        AdbLog "       (puede tardar 5-15 segundos)."
        AdbLog ""
        AdbLog "  [2]  En Windows, abre el Administrador de Dispositivos:"
        AdbLog "       -> Tecla Win + X -> Administrador de dispositivos"
        AdbLog "       -> Busca en: Puertos (COM y LPT)"
        AdbLog "       -> Debe aparecer: Qualcomm HS-USB QDLoader 9008"
        AdbLog "          o similar con COM port asignado."
        AdbLog ""
        AdbLog "  [3]  Si NO aparece el puerto:"
        AdbLog "       a) Desconecta y reconecta el cable USB"
        AdbLog "       b) Espera 10 segundos y revisa de nuevo"
        AdbLog "       c) Si persiste, presiona de nuevo ACTIVAR DIAG XIAOMI"
        AdbLog "          para re-ejecutar el comando."
        AdbLog ""
        AdbLog "  [4]  Si el driver no esta instalado, Windows mostrara"
        AdbLog "       el dispositivo como desconocido. Instala:"
        AdbLog "       Qualcomm HS-USB QDLoader 9008 Driver"
        AdbLog "       (disponible en paquetes de Xiaomi Flash Tool)"
        AdbLog ""
        AdbLog "=============================================="

        # Abrir administrador de dispositivos automaticamente
        AdbLog "[~] Abriendo Administrador de Dispositivos de Windows..."
        try {
            Start-Process "devmgmt.msc" -ErrorAction SilentlyContinue
            AdbLog "[+] Administrador de Dispositivos abierto."
        } catch {
            AdbLog "[~] No se pudo abrir devmgmt.msc automaticamente."
            AdbLog "[~] Abrelo manualmente: Win+X -> Administrador de dispositivos"
        }

        AdbLog ""
        AdbLog "[OK] Proceso DIAG ejecutado. Verifica el puerto en el Adm. de Dispositivos."
        $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  DIAG EJECUTADO  |  $diagModel"
    }

    $btn.Enabled = $true; $btn.Text = "ACTIVAR DIAG XIAOMI"
})

# ==========================================================================
# DEBLOAT XIAOMI  -  Eliminar apps basura MIUI con modo Basico / Completo
# + restauracion individual de paquetes desinstalados
# ==========================================================================
$btnsA3[1].Add_Click({
    $btn = $btnsA3[1]
    $btn.Enabled = $false; $btn.Text = "EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    if (-not (Check-ADB)) { $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"; return }

    # ---- Listas de paquetes ----
    # BASICO: solo apps claramente prescindibles, no afecta funcionalidad
    $debloatBasico = @(
        "com.miui.video",           # Mi Video
        "com.miui.player",          # Mi Musica
        "com.mi.globalbrowser",     # Mi Browser Global
        "com.miui.msa.global",      # Mi Ads Services
        "com.miui.analytics",       # MIUI Analytics
        "com.miui.bugreport",       # Bug Reporter
        "com.miui.fmservice",       # Radio FM (si no tiene antena)
        "com.miui.gaming",          # Mi Gaming Turbo
        "com.miui.calculator",      # Calculadora (tiene alternativa Google)
        "com.miui.cleanmaster",     # Clean Master / Limpieza
        "com.miui.compass",         # Brujula
        "com.miui.weather",         # Clima Xiaomi
        "com.miui.yellowpage",      # Paginas Amarillas
        "com.miui.antivirus",       # Antivirus MIUI (Avast)
        "com.miui.notes",           # Notas Xiaomi
        "com.xiaomi.jr.promo",      # Xiaomi Financial Promo
        "com.mihome.plugin.eleme",  # Plugin Eleme
        "com.mfashion.global",      # Fashion Xiaomi
        "com.mi.android.globalminusscreen" # Pantalla MI News
    )

    # COMPLETO: todo lo anterior + mas agresivo (cuentas, servicios cloud propietarios)
    $debloatCompleto = $debloatBasico + @(
        "com.facebook.katana",      # Facebook
        "com.facebook.services",    # Facebook Services
        "com.facebook.system",      # Facebook System
        "com.facebook.appmanager",  # Facebook App Manager
        "com.netflix.partner",      # Netflix preinstalado
        "com.opera.preinstall",     # Opera Mini preinstalado
        "com.bsp.catchlog",         # Log de sistema BSP
        "com.xiaomi.simactivate.service", # Activacion SIM Xiaomi
        "com.miui.cloudservice",    # Cloud MIUI
        "com.miui.cloudbackup",     # Backup Cloud MIUI
        "com.miui.miservice",       # Mi Service
        "com.miui.voiceassist",     # Asistente de voz Xiao AI
        "com.miui.aod",             # Always On Display MIUI
        "cn.wps.xiaomi.abroad.lite" # WPS Office preinstalado
    )

    # ---- Seleccion de modo via dialogo ----
    $modoForm = New-Object System.Windows.Forms.Form
    $modoForm.Text = "DEBLOAT XIAOMI - RNX TOOL PRO"
    $modoForm.Size = New-Object System.Drawing.Size(500, 340)
    $modoForm.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
    $modoForm.StartPosition = "CenterScreen"
    $modoForm.FormBorderStyle = "FixedDialog"
    $modoForm.ControlBox = $false
    $modoForm.TopMost = $true

    $lbTit = New-Object System.Windows.Forms.Label
    $lbTit.Text = "SELECCIONA MODO DE DEBLOAT"
    $lbTit.Location = New-Object System.Drawing.Point(16, 16)
    $lbTit.Size = New-Object System.Drawing.Size(460, 24)
    $lbTit.ForeColor = [System.Drawing.Color]::Lime
    $lbTit.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $modoForm.Controls.Add($lbTit)

    $lbBasDesc = New-Object System.Windows.Forms.Label
    $lbBasDesc.Text = "BASICO: Elimina apps basura y publicidad MIUI (seguro, sin tocar cuentas ni servicios criticos)"
    $lbBasDesc.Location = New-Object System.Drawing.Point(16, 56)
    $lbBasDesc.Size = New-Object System.Drawing.Size(460, 36)
    $lbBasDesc.ForeColor = [System.Drawing.Color]::LightGray
    $lbBasDesc.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
    $modoForm.Controls.Add($lbBasDesc)

    $lbComDesc = New-Object System.Windows.Forms.Label
    $lbComDesc.Text = "COMPLETO: Elimina todo lo anterior + Facebook, servicios cloud Xiaomi y mas (mas agresivo)"
    $lbComDesc.Location = New-Object System.Drawing.Point(16, 106)
    $lbComDesc.Size = New-Object System.Drawing.Size(460, 36)
    $lbComDesc.ForeColor = [System.Drawing.Color]::LightGray
    $lbComDesc.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
    $modoForm.Controls.Add($lbComDesc)

    $lbRestDesc = New-Object System.Windows.Forms.Label
    $lbRestDesc.Text = "RESTAURAR: Reinstala un paquete previamente desinstalado (ingresas el nombre del paquete)"
    $lbRestDesc.Location = New-Object System.Drawing.Point(16, 156)
    $lbRestDesc.Size = New-Object System.Drawing.Size(460, 36)
    $lbRestDesc.ForeColor = [System.Drawing.Color]::LightGray
    $lbRestDesc.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
    $modoForm.Controls.Add($lbRestDesc)

    $script:debloatModo = $null

    $mkBtn = {
        param($txt, $clr, $x, $y, $action)
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $txt; $b.Location = New-Object System.Drawing.Point($x,$y)
        $b.Size = New-Object System.Drawing.Size(142,38); $b.FlatStyle = "Flat"
        $b.ForeColor = $clr; $b.FlatAppearance.BorderColor = $clr
        $b.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
        $b.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
        $b.Add_Click($action); $modoForm.Controls.Add($b)
    }
    & $mkBtn "BASICO"    ([System.Drawing.Color]::Lime)   16  210 { $script:debloatModo="BASICO";    $modoForm.Close() }
    & $mkBtn "COMPLETO"  ([System.Drawing.Color]::Orange) 166 210 { $script:debloatModo="COMPLETO";  $modoForm.Close() }
    & $mkBtn "RESTAURAR" ([System.Drawing.Color]::Cyan)   316 210 { $script:debloatModo="RESTAURAR"; $modoForm.Close() }

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "CANCELAR"; $btnCancel.Location = New-Object System.Drawing.Point(170,264)
    $btnCancel.Size = New-Object System.Drawing.Size(142,32); $btnCancel.FlatStyle = "Flat"
    $btnCancel.ForeColor = [System.Drawing.Color]::Gray; $btnCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
    $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $btnCancel.Add_Click({ $script:debloatModo = $null; $modoForm.Close() })
    $modoForm.Controls.Add($btnCancel)

    $modoForm.ShowDialog() | Out-Null

    if (-not $script:debloatModo) {
        $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"; return
    }

    # ---- Modo RESTAURAR ----
    if ($script:debloatModo -eq "RESTAURAR") {
        Add-Type -AssemblyName Microsoft.VisualBasic
        $pkg = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Ingresa el nombre del paquete a restaurar:`n(ej: com.miui.video)",
            "RESTAURAR PAQUETE", "")
        if (-not $pkg -or $pkg.Trim() -eq "") {
            AdbLog "[~] Restauracion cancelada."
            $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"; return
        }
        $pkg = $pkg.Trim()
        AdbLog ""
        AdbLog "=============================================="
        AdbLog "  RESTAURAR PAQUETE - RNX TOOL PRO"
        AdbLog "=============================================="
        AdbLog "[*] Paquete: $pkg"
        $res = (& adb shell cmd package install-existing $pkg 2>&1) -join ""
        if ($res -imatch "Success|installed") {
            AdbLog "[OK] $pkg restaurado correctamente."
        } else {
            AdbLog "[!] Error o paquete no encontrado: $res"
            AdbLog "[~] Verifica que el nombre del paquete sea correcto."
        }
        $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"; return
    }

    # ---- Modo BASICO o COMPLETO ----
    $lista = if ($script:debloatModo -eq "COMPLETO") { $debloatCompleto } else { $debloatBasico }

    AdbLog ""
    AdbLog "=============================================="
    AdbLog "  DEBLOAT XIAOMI [$($script:debloatModo)] - RNX TOOL PRO"
    AdbLog "=============================================="
    AdbLog "[*] Verificando dispositivo..."

    if (-not (Check-ADB)) { $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"; return }

    $brand = (& adb shell getprop ro.product.brand 2>$null).Trim().ToUpper()
    $model = (& adb shell getprop ro.product.model 2>$null).Trim()
    AdbLog "[+] Dispositivo: $brand $model"

    if ($brand -notmatch "XIAOMI|REDMI|POCO") {
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "El dispositivo detectado ($brand $model) no parece ser Xiaomi/Redmi/POCO.`n`nDeseas continuar de todas formas?",
            "ADVERTENCIA", "YesNo", "Warning")
        if ($confirm -ne "Yes") {
            AdbLog "[~] Cancelado por el usuario."
            $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"; return
        }
    }

    # Obtener lista de paquetes instalados una sola vez
    AdbLog "[*] Obteniendo lista de paquetes instalados..."
    $pkgsInstalados = (& adb shell pm list packages 2>$null) -join "`n"

    $total = $lista.Count
    $ok = 0; $skip = 0; $fail = 0

    foreach ($i in 0..($total-1)) {
        $pkg = $lista[$i]
        $num = $i + 1
        [System.Windows.Forms.Application]::DoEvents()

        # Verificar si esta instalado
        if ($pkgsInstalados -notmatch [regex]::Escape($pkg)) {
            AdbLog "  [$num/$total] $pkg - NO INSTALADO (omitido)"
            $skip++; continue
        }

        AdbLog "  [$num/$total] Eliminando: $pkg..."
        $res = (& adb shell pm uninstall -k --user 0 $pkg 2>&1) -join ""
        if ($res -imatch "Success") {
            AdbLog "           [OK]"
            $ok++
        } else {
            AdbLog "           [!] Error: $($res.Trim())"
            $fail++
        }
    }

    AdbLog ""
    AdbLog "=============================================="
    AdbLog "  RESUMEN DEBLOAT XIAOMI [$($script:debloatModo)]"
    AdbLog "=============================================="
    AdbLog "  Eliminados OK : $ok"
    AdbLog "  No instalados : $skip"
    AdbLog "  Con error     : $fail"
    AdbLog "=============================================="
    AdbLog ""

    $reinicio = [System.Windows.Forms.MessageBox]::Show(
        "Debloat completado.`n`nEliminados: $ok  |  Errores: $fail`n`nDeseas reiniciar el dispositivo ahora?",
        "DEBLOAT COMPLETADO", "YesNo", "Information")
    if ($reinicio -eq "Yes") {
        AdbLog "[*] Reiniciando dispositivo..."
        & adb reboot 2>$null
        AdbLog "[OK] Reinicio enviado."
    }

    $btn.Enabled = $true; $btn.Text = "DEBLOAT XIAOMI"
})

# ==========================================================================
# DESCARGAR FIRMWARE XIAOMI  -  btnsA3[2]
# Mini-interfaz estilo SamFW para buscar firmware en mifirm.net
# Modo 1: Auto-identificar modelo y region via ADB
# Modo 2: Busqueda manual por modelo y region
# ==========================================================================
$btnsA3[2].ForeColor = [System.Drawing.Color]::FromArgb(255,140,0)
$btnsA3[2].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,140,0)
$btnsA3[2].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

$btnsA3[2].Add_Click({
    $btn = $btnsA3[2]
    $btn.Enabled = $false; $btn.Text = "BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()

    AdbLog ""
    AdbLog "=============================================="
    AdbLog "   MIFIRM FIRMWARE DOWNLOADER  -  RNX TOOL PRO"
    AdbLog "   $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    AdbLog "=============================================="
    AdbLog ""

    # =============================================
    # MINI INTERFAZ MIFIRM - 2 modos:
    #   A) Auto-identificar desde dispositivo ADB
    #   B) Busqueda manual por modelo y region
    # =============================================
    $frmMiFirm = New-Object System.Windows.Forms.Form
    $frmMiFirm.Text = "MiFirm Firmware Downloader - RNX TOOL PRO"
    $frmMiFirm.ClientSize = New-Object System.Drawing.Size(560, 400)
    $frmMiFirm.BackColor = [System.Drawing.Color]::FromArgb(14,14,22)
    $frmMiFirm.FormBorderStyle = "FixedDialog"
    $frmMiFirm.StartPosition = "CenterScreen"
    $frmMiFirm.TopMost = $true

    # Header
    $lbHdrMi = New-Object Windows.Forms.Label
    $lbHdrMi.Text = "  MIFIRM FIRMWARE DOWNLOADER"
    $lbHdrMi.Location = New-Object System.Drawing.Point(0,0)
    $lbHdrMi.Size = New-Object System.Drawing.Size(560,34)
    $lbHdrMi.BackColor = [System.Drawing.Color]::FromArgb(200,80,0)
    $lbHdrMi.ForeColor = [System.Drawing.Color]::White
    $lbHdrMi.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $lbHdrMi.TextAlign = "MiddleLeft"
    $frmMiFirm.Controls.Add($lbHdrMi)

    # ---- SECCION A: Auto-identificar ----
    $pnlAutoMi = New-Object Windows.Forms.Panel
    $pnlAutoMi.Location = New-Object System.Drawing.Point(10,44)
    $pnlAutoMi.Size = New-Object System.Drawing.Size(538,165)
    $pnlAutoMi.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $pnlAutoMi.BorderStyle = "FixedSingle"
    $frmMiFirm.Controls.Add($pnlAutoMi)

    $lbAutoTitleMi = New-Object Windows.Forms.Label
    $lbAutoTitleMi.Text = "  MODO 1: Auto-identificar (requiere dispositivo Xiaomi/MIUI por ADB)"
    $lbAutoTitleMi.Location = New-Object System.Drawing.Point(0,0)
    $lbAutoTitleMi.Size = New-Object System.Drawing.Size(538,26)
    $lbAutoTitleMi.BackColor = [System.Drawing.Color]::FromArgb(140,50,0)
    $lbAutoTitleMi.ForeColor = [System.Drawing.Color]::White
    $lbAutoTitleMi.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $lbAutoTitleMi.TextAlign = "MiddleLeft"
    $pnlAutoMi.Controls.Add($lbAutoTitleMi)

    $lbMiModel = New-Object Windows.Forms.Label
    $lbMiModel.Text = "Modelo  : --"
    $lbMiModel.Location = New-Object System.Drawing.Point(14,34)
    $lbMiModel.Size = New-Object System.Drawing.Size(510,18)
    $lbMiModel.ForeColor = [System.Drawing.Color]::Lime
    $lbMiModel.Font = New-Object System.Drawing.Font("Consolas",9)
    $pnlAutoMi.Controls.Add($lbMiModel)

    $lbMiRegion = New-Object Windows.Forms.Label
    $lbMiRegion.Text = "Region  : --"
    $lbMiRegion.Location = New-Object System.Drawing.Point(14,54)
    $lbMiRegion.Size = New-Object System.Drawing.Size(510,18)
    $lbMiRegion.ForeColor = [System.Drawing.Color]::Lime
    $lbMiRegion.Font = New-Object System.Drawing.Font("Consolas",9)
    $pnlAutoMi.Controls.Add($lbMiRegion)

    $lbMiBuild = New-Object Windows.Forms.Label
    $lbMiBuild.Text = "Build   : --"
    $lbMiBuild.Location = New-Object System.Drawing.Point(14,74)
    $lbMiBuild.Size = New-Object System.Drawing.Size(510,18)
    $lbMiBuild.ForeColor = [System.Drawing.Color]::FromArgb(180,180,180)
    $lbMiBuild.Font = New-Object System.Drawing.Font("Consolas",8)
    $pnlAutoMi.Controls.Add($lbMiBuild)

    $lbMiUrl = New-Object Windows.Forms.Label
    $lbMiUrl.Text = "URL     : --"
    $lbMiUrl.Location = New-Object System.Drawing.Point(14,94)
    $lbMiUrl.Size = New-Object System.Drawing.Size(510,18)
    $lbMiUrl.ForeColor = [System.Drawing.Color]::Cyan
    $lbMiUrl.Font = New-Object System.Drawing.Font("Consolas",7.5)
    $pnlAutoMi.Controls.Add($lbMiUrl)

    $btnAutoDetectMi = New-Object Windows.Forms.Button
    $btnAutoDetectMi.Text = "AUTO IDENTIFICAR"
    $btnAutoDetectMi.Location = New-Object System.Drawing.Point(14,126)
    $btnAutoDetectMi.Size = New-Object System.Drawing.Size(160,30)
    $btnAutoDetectMi.FlatStyle = "Flat"
    $btnAutoDetectMi.ForeColor = [System.Drawing.Color]::Lime
    $btnAutoDetectMi.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $btnAutoDetectMi.BackColor = [System.Drawing.Color]::FromArgb(15,35,15)
    $btnAutoDetectMi.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $pnlAutoMi.Controls.Add($btnAutoDetectMi)

    $btnAutoOpenMi = New-Object Windows.Forms.Button
    $btnAutoOpenMi.Text = "IR A MIFIRM"
    $btnAutoOpenMi.Location = New-Object System.Drawing.Point(184,126)
    $btnAutoOpenMi.Size = New-Object System.Drawing.Size(130,30)
    $btnAutoOpenMi.FlatStyle = "Flat"
    $btnAutoOpenMi.ForeColor = [System.Drawing.Color]::White
    $btnAutoOpenMi.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(200,80,0)
    $btnAutoOpenMi.BackColor = [System.Drawing.Color]::FromArgb(80,30,0)
    $btnAutoOpenMi.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnAutoOpenMi.Enabled = $false
    $pnlAutoMi.Controls.Add($btnAutoOpenMi)

    $script:MiFirm_AutoURL = ""

    $btnAutoDetectMi.Add_Click({
        $btnAutoDetectMi.Enabled = $false; $btnAutoDetectMi.Text = "LEYENDO..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            function MiFirm-Prop($prop) {
                $r = & adb shell getprop $prop 2>$null
                if ($r -is [array]) { return ($r -join "").Trim() }
                return "$r".Trim()
            }
            $miModel  = MiFirm-Prop "ro.product.model"
            $miBrand  = (MiFirm-Prop "ro.product.brand").ToUpper()
            $miBuild  = MiFirm-Prop "ro.build.display.id"
            $miMiui   = MiFirm-Prop "ro.miui.ui.version.name"
            # Region: intentar varias props
            $miRegion = MiFirm-Prop "ro.miui.region"
            if (-not $miRegion) { $miRegion = MiFirm-Prop "ro.product.locale" }
            if (-not $miRegion) { $miRegion = MiFirm-Prop "persist.sys.locale" }

            if (-not $miModel) {
                $lbMiModel.Text = "Modelo  : [Sin dispositivo ADB]"
                $lbMiModel.ForeColor = [System.Drawing.Color]::OrangeRed
            } elseif ($miBrand -notmatch "XIAOMI|REDMI|POCO") {
                $lbMiModel.Text = "Modelo  : $miModel  [$miBrand] - Solo Xiaomi/Redmi/POCO"
                $lbMiModel.ForeColor = [System.Drawing.Color]::OrangeRed
            } else {
                $lbMiModel.Text  = "Modelo  : $miModel"
                $lbMiModel.ForeColor = [System.Drawing.Color]::Lime
                $lbMiRegion.Text = "Region  : $(if($miRegion){$miRegion}else{'NO DETECTADA'})"
                $lbMiBuild.Text  = "Build   : $miBuild  |  MIUI: $miMiui"
                # mifirm.net URL: https://mifirm.net/model/{codename}
                # Intentar obtener codename (ro.product.device)
                $miCodename = MiFirm-Prop "ro.product.device"
                if (-not $miCodename) { $miCodename = MiFirm-Prop "ro.product.name" }
                $miUrl = if ($miCodename) { "https://mifirm.net/model/$miCodename" } else { "https://mifirm.net/" }
                $lbMiUrl.Text = "URL     : $miUrl"
                $script:MiFirm_AutoURL = $miUrl
                $btnAutoOpenMi.Enabled = $true
                AdbLog "[+] Auto-detecto: $miModel | Codename: $miCodename | Region: $miRegion"
                AdbLog "[+] URL: $miUrl"
            }
        } catch {
            $lbMiModel.Text = "Error: $_"
            $lbMiModel.ForeColor = [System.Drawing.Color]::Red
        }
        $btnAutoDetectMi.Enabled = $true; $btnAutoDetectMi.Text = "AUTO IDENTIFICAR"
    })

    $btnAutoOpenMi.Add_Click({
        if ($script:MiFirm_AutoURL) {
            try { Start-Process $script:MiFirm_AutoURL; AdbLog "[OK] Navegador abierto: $($script:MiFirm_AutoURL)" }
            catch { AdbLog "[!] Error: $_" }
        }
    })

    # ---- SECCION B: Busqueda manual ----
    $pnlManualMi = New-Object Windows.Forms.Panel
    $pnlManualMi.Location = New-Object System.Drawing.Point(10,220)
    $pnlManualMi.Size = New-Object System.Drawing.Size(538,140)
    $pnlManualMi.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $pnlManualMi.BorderStyle = "FixedSingle"
    $frmMiFirm.Controls.Add($pnlManualMi)

    $lbManTitleMi = New-Object Windows.Forms.Label
    $lbManTitleMi.Text = "  MODO 2: Buscar por codename o modelo (sin telefono conectado)"
    $lbManTitleMi.Location = New-Object System.Drawing.Point(0,0)
    $lbManTitleMi.Size = New-Object System.Drawing.Size(538,26)
    $lbManTitleMi.BackColor = [System.Drawing.Color]::FromArgb(60,40,0)
    $lbManTitleMi.ForeColor = [System.Drawing.Color]::White
    $lbManTitleMi.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $lbManTitleMi.TextAlign = "MiddleLeft"
    $pnlManualMi.Controls.Add($lbManTitleMi)

    $lbManMiModel = New-Object Windows.Forms.Label
    $lbManMiModel.Text = "Codename/Modelo:"
    $lbManMiModel.Location = New-Object System.Drawing.Point(14,36)
    $lbManMiModel.Size = New-Object System.Drawing.Size(120,20)
    $lbManMiModel.ForeColor = [System.Drawing.Color]::LightGray
    $lbManMiModel.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $pnlManualMi.Controls.Add($lbManMiModel)

    $txtManMiModel = New-Object Windows.Forms.TextBox
    $txtManMiModel.Location = New-Object System.Drawing.Point(142,34)
    $txtManMiModel.Size = New-Object System.Drawing.Size(150,24)
    $txtManMiModel.BackColor = [System.Drawing.Color]::FromArgb(30,30,45)
    $txtManMiModel.ForeColor = [System.Drawing.Color]::White
    $txtManMiModel.BorderStyle = "FixedSingle"
    $txtManMiModel.Font = New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold)
    $txtManMiModel.Text = ""
    $pnlManualMi.Controls.Add($txtManMiModel)

    $lbManMiHint = New-Object Windows.Forms.Label
    $lbManMiHint.Text = "Ej: marble, pissarro, sweet, veux, spes, rosemary..."
    $lbManMiHint.Location = New-Object System.Drawing.Point(14,64)
    $lbManMiHint.Size = New-Object System.Drawing.Size(510,16)
    $lbManMiHint.ForeColor = [System.Drawing.Color]::FromArgb(100,100,120)
    $lbManMiHint.Font = New-Object System.Drawing.Font("Segoe UI",7.5)
    $pnlManualMi.Controls.Add($lbManMiHint)

    $lbManMiHint2 = New-Object Windows.Forms.Label
    $lbManMiHint2.Text = "Tambien puedes buscar por modelo: Redmi Note 12, POCO X5 Pro..."
    $lbManMiHint2.Location = New-Object System.Drawing.Point(14,82)
    $lbManMiHint2.Size = New-Object System.Drawing.Size(510,16)
    $lbManMiHint2.ForeColor = [System.Drawing.Color]::FromArgb(80,80,100)
    $lbManMiHint2.Font = New-Object System.Drawing.Font("Segoe UI",7)
    $pnlManualMi.Controls.Add($lbManMiHint2)

    $btnManOpenMi = New-Object Windows.Forms.Button
    $btnManOpenMi.Text = "BUSCAR EN MIFIRM"
    $btnManOpenMi.Location = New-Object System.Drawing.Point(310,30)
    $btnManOpenMi.Size = New-Object System.Drawing.Size(150,60)
    $btnManOpenMi.FlatStyle = "Flat"
    $btnManOpenMi.ForeColor = [System.Drawing.Color]::FromArgb(255,160,0)
    $btnManOpenMi.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,160,0)
    $btnManOpenMi.BackColor = [System.Drawing.Color]::FromArgb(45,30,0)
    $btnManOpenMi.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $pnlManualMi.Controls.Add($btnManOpenMi)

    $btnManOpenMi.Add_Click({
        $manMiInput = $txtManMiModel.Text.Trim()
        if (-not $manMiInput) {
            [System.Windows.Forms.MessageBox]::Show("Ingresa el codename o modelo Xiaomi`n(ej: marble, sweet, pissarro)","Modelo requerido","OK","Warning") | Out-Null
            return
        }
        # mifirm.net soporta busqueda por codename o nombre de modelo
        $manMiUrl = "https://mifirm.net/model/$manMiInput"
        AdbLog "[+] Busqueda manual: $manMiInput"
        AdbLog "[+] URL: $manMiUrl"
        try { Start-Process $manMiUrl; AdbLog "[OK] Navegador abierto" }
        catch { AdbLog "[!] Error: $_" }
    })

    # Boton cerrar
    $btnCloseMi = New-Object Windows.Forms.Button
    $btnCloseMi.Text = "CERRAR"
    $btnCloseMi.Location = New-Object System.Drawing.Point(200,366)
    $btnCloseMi.Size = New-Object System.Drawing.Size(160,28)
    $btnCloseMi.FlatStyle = "Flat"
    $btnCloseMi.ForeColor = [System.Drawing.Color]::Gray
    $btnCloseMi.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70,70,70)
    $btnCloseMi.BackColor = [System.Drawing.Color]::FromArgb(25,25,35)
    $btnCloseMi.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $btnCloseMi.Add_Click({ $frmMiFirm.Close() })
    $frmMiFirm.Controls.Add($btnCloseMi)

    AdbLog "[i] Mini interfaz MiFirm abierta"
    AdbLog "    Modo 1: conecta el telefono por ADB y usa AUTO IDENTIFICAR"
    AdbLog "    Modo 2: escribe el codename para buscar sin telefono"
    AdbLog "    mifirm.net - base de datos de firmwares Xiaomi/Redmi/POCO"

    $frmMiFirm.ShowDialog() | Out-Null
    $btn.Enabled = $true; $btn.Text = "DESCARGAR FIRMWARE"
})

# ==========================================================================
# XIAOMI IMEI TOOLS  -  btnsA3[3]
# Busca la herramienta primero en carpetas del PC, luego ofrece descarga
# ==========================================================================
$btnsA3[3].ForeColor = [System.Drawing.Color]::FromArgb(0,220,180)
$btnsA3[3].FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0,220,180)
$btnsA3[3].Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)

$btnsA3[3].Add_Click({
    $btn = $btnsA3[3]
    $btn.Enabled = $false; $btn.Text = "BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()

    AdbLog ""
    AdbLog "=============================================="
    AdbLog "   XIAOMI IMEI TOOLS  -  RNX TOOL PRO"
    AdbLog "=============================================="
    AdbLog "[~] Buscando herramienta en el sistema..."

    $imeiTool = $null

    # 1. Buscar en tools\ del script
    $toolsSearchNames = @(
        "XiaomiIMEITool.exe","XiaomiIMEI.exe","MI_IMEI_Tool.exe","IMEI_Tool.exe",
        "Xiaomi_IMEI_Writer.exe","IMEI_Writer.exe","MiIMEI.exe","IMEI.exe"
    )
    foreach ($name in $toolsSearchNames) {
        $try = Join-Path $script:TOOLS_DIR $name
        if (Test-Path $try -EA SilentlyContinue) { $imeiTool = $try; break }
        $try2 = Join-Path (Join-Path $script:TOOLS_DIR "imei") $name
        if (Test-Path $try2 -EA SilentlyContinue) { $imeiTool = $try2; break }
        $try3 = Join-Path (Join-Path $script:TOOLS_DIR "xiaomi") $name
        if (Test-Path $try3 -EA SilentlyContinue) { $imeiTool = $try3; break }
    }

    # 2. Buscar en Program Files
    if (-not $imeiTool) {
        AdbLog "[~] Buscando en Program Files..."
        foreach ($pf in @($env:ProgramFiles, "${env:ProgramFiles(x86)}", "$env:LOCALAPPDATA\Programs")) {
            if (-not $pf -or -not (Test-Path $pf)) { continue }
            foreach ($name in $toolsSearchNames) {
                $found = Get-ChildItem $pf -Recurse -Filter $name -EA SilentlyContinue | Select-Object -First 1
                if ($found) { $imeiTool = $found.FullName; break }
            }
            if ($imeiTool) { break }
        }
    }

    # 3. Busqueda amplia por palabras clave en Desktop y Documents
    if (-not $imeiTool) {
        AdbLog "[~] Buscando en Escritorio y Documentos..."
        $searchDirs = @(
            "$env:USERPROFILE\Desktop",
            "$env:USERPROFILE\Documents",
            "$env:USERPROFILE\Downloads"
        )
        foreach ($dir in $searchDirs) {
            if (-not (Test-Path $dir -EA SilentlyContinue)) { continue }
            $found = Get-ChildItem $dir -Recurse -File -EA SilentlyContinue |
                     Where-Object { $_.Name -imatch "xiaomi.*imei|imei.*xiaomi|mi.*imei" -and $_.Extension -imatch "\.exe$" } |
                     Select-Object -First 1
            if ($found) { $imeiTool = $found.FullName; break }
        }
    }

    if ($imeiTool) {
        AdbLog "[+] Herramienta encontrada: $imeiTool"
        try {
            Start-Process -FilePath $imeiTool -WorkingDirectory (Split-Path $imeiTool) -Verb RunAs
            AdbLog "[OK] Xiaomi IMEI Tools abierto"
        } catch {
            AdbLog "[~] RunAs fallo - abriendo sin elevacion..."
            try { Start-Process $imeiTool; AdbLog "[OK] Abierto sin elevacion" }
            catch { AdbLog "[!] Error al abrir: $_" }
        }
    } else {
        AdbLog "[!] Xiaomi IMEI Tools no encontrado en el sistema"
        AdbLog "[~] Opciones:"
        AdbLog "    1. Coloca la herramienta en: $($script:TOOLS_DIR)"
        AdbLog "    2. O en subcarpeta: tools\imei\ o tools\xiaomi\"
        AdbLog "    3. Nombres buscados: XiaomiIMEITool.exe, MI_IMEI_Tool.exe, etc."
        $resp = [System.Windows.Forms.MessageBox]::Show(
            "Xiaomi IMEI Tools no encontrado en el sistema.`n`nColoca el ejecutable en:`n$($script:TOOLS_DIR)`n`nO busca 'Xiaomi IMEI Tool' en la web?",
            "No encontrado", "YesNo", "Information")
        if ($resp -eq "Yes") {
            Start-Process "https://xiaomitool.com/"
            AdbLog "[~] Pagina web abierta en el navegador"
        }
    }

    $btn.Enabled = $true; $btn.Text = "XIAOMI IMEI TOOLS"
})


# Limpia cuentas Google, Xiaomi y cache sin hacer factory reset
# ==========================================================================
$btnsA4[0].Add_Click({
    $btn = $btnsA4[0]
    $btn.Enabled = $false; $btn.Text = "EJECUTANDO..."
    [System.Windows.Forms.Application]::DoEvents()

    AdbLog ""
    AdbLog "=============================================="
    AdbLog "  RESET RAPIDO ENTREGA v3 - RNX TOOL PRO"
    AdbLog "=============================================="
    AdbLog "[*] Objetivo: dejar equipo limpio SIN factory reset"
    AdbLog ""

    if (-not (Check-ADB)) { $btn.Enabled = $true; $btn.Text = "RESET RAPIDO ENTREGA"; return }

    $brand  = (& adb shell getprop ro.product.brand  2>$null).Trim().ToUpper()
    $model  = (& adb shell getprop ro.product.model  2>$null).Trim()
    $serial = (& adb get-serialno 2>$null).Trim()
    AdbLog "[+] Dispositivo : $brand $model"
    AdbLog "[+] Serial      : $serial"
    AdbLog ""

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "RESET RAPIDO PARA ENTREGA v3`n`nDispositivo: $brand $model`n`nEsto limpiara:`n  - Cuentas Google / Xiaomi / Samsung / Oppo / Vivo / Realme / OnePlus / Motorola`n  - Historial de llamadas y mensajes SMS`n  - Cache y datos Chrome + buscadores`n  - Apps de terceros (excepto WhatsApp / Facebook / Messenger / TikTok)`n  - Galeria, contactos y referencias de fotos`n  - Knox/enrollment Samsung`n  - Ajustes de pantalla activa`n  - Cache global del sistema`n`nNO borra el sistema ni apps del fabricante.`n`nConfirmas?",
        "RESET RAPIDO v3", "YesNo", "Question")
    if ($confirm -ne "Yes") {
        AdbLog "[~] Cancelado."
        $btn.Enabled = $true; $btn.Text = "RESET RAPIDO ENTREGA"; return
    }

    $paso = 0

    function RR-Run($cmd, $etiqueta) {
        $raw = & adb shell $cmd 2>&1
        $ok  = "$raw" -imatch "Success|Done|deleted|^$|rows affected"
        AdbLog "      $(if($ok){'[OK]'}else{'[~]'}) $etiqueta"
    }

    # -----------------------------------------------------------------------
    # PASO 1: Google - GMS / GSF / Play Store / Chrome / cuentas
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Limpiando servicios Google y cuenta..."
    foreach ($pkg in @(
        "com.google.android.gms",
        "com.google.android.gsf",
        "com.android.vending",
        "com.google.android.gms.policy_sidecar_aps",
        "com.google.android.googlequicksearchbox",
        "com.google.android.gms.persistent",
        "com.google.android.syncadapters.contacts",
        "com.google.android.syncadapters.calendar",
        "com.google.android.backuptransport",
        "com.google.android.feedback",
        "com.google.android.partnersetup",
        "com.google.android.setupwizard",
        "com.google.android.apps.restore",
        "com.android.chrome",
        "com.google.android.apps.chrome",
        "com.google.android.youtube",
        "com.google.android.apps.maps",
        "com.google.android.apps.docs",
        "com.google.android.apps.photos",
        "com.google.android.talk",
        "com.google.android.gm"
    )) { & adb shell pm clear $pkg 2>$null | Out-Null; AdbLog "      [OK] $pkg" }
    # Borrar cuentas Google via content provider (quita vinculacion de cuenta)
    RR-Run "content delete --uri content://com.google.android.gsf.login/accounts" "Cuentas GSF borradas"
    # Forzar borrado de tokens de sincronizacion de cuentas
    RR-Run "am broadcast -a com.google.android.gms.auth.GOOGLE_SIGN_OUT" "Sign-out broadcast enviado"
    AdbLog "      [OK] Cuenta Google desvinculada"

    # -----------------------------------------------------------------------
    # PASO 2: Xiaomi / MIUI
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Limpiando cuenta Xiaomi / MIUI..."
    foreach ($pkg in @(
        "com.xiaomi.account","com.miui.cloudservice","com.miui.cloudbackup",
        "com.xiaomi.finddevice","com.miui.miservice","com.miui.hybrid","com.miui.analytics"
    )) { & adb shell pm clear $pkg 2>$null | Out-Null; AdbLog "      [OK] $pkg" }

    # -----------------------------------------------------------------------
    # PASO 3: Samsung Account + Knox
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Limpiando cuenta Samsung / Knox..."
    foreach ($pkg in @(
        "com.osp.app.signin","com.samsung.android.samsungaccount",
        "com.samsung.android.knox.containeragent","com.samsung.android.mdm",
        "com.sec.enterprise.knox.cloudmdm.samsungknox","com.sec.android.soagent"
    )) { & adb shell pm clear $pkg 2>$null | Out-Null; AdbLog "      [OK] $pkg" }
    RR-Run "settings put global knox_enrollment_source 0" "Knox enrollment reset"

    # -----------------------------------------------------------------------
    # PASO 4: Oppo / Realme / OnePlus / Vivo / Motorola
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Limpiando cuentas Oppo / Realme / OnePlus / Vivo / Motorola..."
    foreach ($pkg in @(
        "com.heytap.account","com.oplus.account","com.coloros.account",
        "com.realme.account","net.oneplus.account","com.oneplus.account",
        "com.vivo.account","com.vivo.cloudservice","com.bbk.account",
        "com.motorola.ccc","com.motorola.motosync"
    )) { & adb shell pm clear $pkg 2>$null | Out-Null; AdbLog "      [OK] $pkg" }

    # -----------------------------------------------------------------------
    # PASO 5: Historial de llamadas
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Borrando historial de llamadas..."
    RR-Run "content delete --uri content://call_log/calls" "Historial de llamadas eliminado"
    # Fallback Android 11+ (CallLog provider diferente)
    RR-Run "content delete --uri content://com.android.contacts.calllogbackup.CallLogBackupContract/call_log" "CallLog backup borrado"
    AdbLog "      [OK] Historial de llamadas limpio"

    # -----------------------------------------------------------------------
    # PASO 6: Historial de mensajes SMS / MMS
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Borrando historial de mensajes SMS/MMS..."
    RR-Run "content delete --uri content://sms"  "SMS eliminados"
    RR-Run "content delete --uri content://mms"  "MMS eliminados"
    # Limpiar cache de app de mensajes (Samsung, MIUI, AOSP)
    foreach ($pkg in @(
        "com.android.mms","com.samsung.android.messaging",
        "com.google.android.apps.messaging","com.miui.sms",
        "com.android.messaging"
    )) { & adb shell pm clear $pkg 2>$null | Out-Null }
    AdbLog "      [OK] SMS/MMS y cache de mensajeria limpios"

    # -----------------------------------------------------------------------
    # PASO 7: Cache y datos Chrome + buscadores
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Limpiando Chrome y buscadores..."
    foreach ($pkg in @(
        "com.android.chrome","com.google.android.apps.chrome",
        "com.sec.android.app.sbrowser","com.mi.globalbrowser",
        "com.opera.mini.native","com.opera.browser",
        "com.UCMobile.intl","com.uc.browser.en",
        "org.mozilla.firefox","com.brave.browser",
        "com.microsoft.emmx","com.duckduckgo.mobile.android",
        "com.miui.yellowpage"
    )) { & adb shell pm clear $pkg 2>$null | Out-Null; AdbLog "      [OK] $pkg" }
    AdbLog "      [OK] Navegadores limpios"

    # -----------------------------------------------------------------------
    # PASO 8: Desinstalar apps de terceros (excepto las protegidas)
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Desinstalando apps de terceros (excepto WhatsApp / Facebook / Messenger / TikTok)..."

    $pkgsProtegidos = @(
        "com.whatsapp","com.whatsapp.w4b",
        "com.facebook.katana","com.facebook.lite",
        "com.facebook.orca",
        "com.zhiliaoapp.musically","com.ss.android.ugc.trill"
    )
    $pkgsProtegidosSet = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($p in $pkgsProtegidos) { $pkgsProtegidosSet.Add($p) | Out-Null }

    # Solo apps de usuario (3er parties): pm list packages -3
    $terceros = (& adb shell "pm list packages -3" 2>$null) | ForEach-Object {
        "$_".Trim() -replace "^package:",""
    } | Where-Object { $_.Trim() -ne "" }

    $desinstaladas = 0; $omitidas = 0
    foreach ($pkg in $terceros) {
        $pkg = $pkg.Trim()
        if ($pkgsProtegidosSet.Contains($pkg)) {
            # Protegidas: solo limpiar cache y datos
            & adb shell pm clear $pkg 2>$null | Out-Null
            AdbLog "      [PROT] $pkg -> cache+datos limpiados"
            $omitidas++
            continue
        }
        $rc = (& adb shell "pm uninstall $pkg" 2>&1) -join ""
        if ($rc -imatch "Success") {
            AdbLog "      [DEL] $pkg"
            $desinstaladas++
        } else {
            # Si falla uninstall, al menos limpiar datos
            & adb shell pm clear $pkg 2>$null | Out-Null
            AdbLog "      [CLR] $pkg (no desinstalable, cache limpiado)"
        }
        [System.Windows.Forms.Application]::DoEvents()
    }
    AdbLog "      [OK] Desinstaladas: $desinstaladas | Protegidas (cache): $omitidas"

    # -----------------------------------------------------------------------
    # PASO 9: Contactos
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Borrando contactos..."
    RR-Run "content delete --uri content://com.android.contacts/contacts" "Contactos eliminados"

    # -----------------------------------------------------------------------
    # PASO 10: Galeria y referencias de fotos
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Limpiando galeria..."
    foreach ($pkg in @(
        "com.android.gallery3d","com.miui.gallery",
        "com.samsung.android.gallery.app","com.google.android.apps.photos",
        "com.sec.android.gallery3d"
    )) { & adb shell pm clear $pkg 2>$null | Out-Null; AdbLog "      [OK] $pkg" }
    RR-Run "content delete --uri content://media/external/images/media" "Referencias de fotos borradas"

    # -----------------------------------------------------------------------
    # PASO 11: Ajustes de sistema
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Reseteando ajustes de sistema..."
    RR-Run "settings put global stay_on_while_plugged_in 0" "Pantalla siempre activa = OFF"
    RR-Run "settings put secure screensaver_enabled 0"      "Daydream OFF"
    RR-Run "settings put global wifi_sleep_policy 2"        "WiFi sleep policy = normal"
    RR-Run "settings delete secure default_input_method"    "Teclado default reset"

    # -----------------------------------------------------------------------
    # PASO 12: Cache global
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Limpiando cache global del sistema..."
    & adb shell pm trim-caches 999999999999 2>$null | Out-Null
    AdbLog "      [OK] Cache global limpiado"

    # -----------------------------------------------------------------------
    # PASO 13: Soft reset MASTER_CLEAR_NOTIFICATION
    # -----------------------------------------------------------------------
    $paso++; AdbLog "[$paso] Enviando notificacion de limpieza al sistema..."
    RR-Run "am broadcast -a android.intent.action.MASTER_CLEAR_NOTIFICATION" "MASTER_CLEAR_NOTIFICATION enviado"

    AdbLog ""
    AdbLog "=============================================="
    AdbLog "  RESULTADO RESET RAPIDO v3"
    AdbLog "=============================================="
    AdbLog "  [OK] Cuentas Google / GSF borradas"
    AdbLog "  [OK] Xiaomi / Samsung / Oppo / Vivo / Realme / OnePlus / Motorola"
    AdbLog "  [OK] Historial de llamadas eliminado"
    AdbLog "  [OK] Historial SMS/MMS eliminado"
    AdbLog "  [OK] Chrome y buscadores limpios"
    AdbLog "  [OK] Apps de terceros desinstaladas: $desinstaladas"
    AdbLog "  [OK] Apps protegidas (cache limpiado): $omitidas"
    AdbLog "  [OK] Contactos eliminados"
    AdbLog "  [OK] Galeria y fotos limpias"
    AdbLog "  [OK] Ajustes de pantalla reseteados"
    AdbLog "  [OK] Cache del sistema limpio"
    AdbLog "=============================================="

    $reinicio = [System.Windows.Forms.MessageBox]::Show(
        "Reset v3 completado.`n`nDesinstaladas : $desinstaladas apps de terceros`nProtegidas    : $omitidas (cache limpiado)`n`nEquipo listo para entrega.`nDeseas reiniciarlo ahora?",
        "RESET COMPLETADO", "YesNo", "Information")
    if ($reinicio -eq "Yes") {
        AdbLog "[*] Reiniciando dispositivo..."
        & adb reboot 2>$null
        AdbLog "[OK] Reinicio enviado."
    }

    $btn.Enabled = $true; $btn.Text = "RESET RAPIDO ENTREGA"
})
# ==========================================================================
# INSTALAR APKs DESDE CARPETA LOCAL
# Escanea carpeta local de APKs, muestra lista con checkboxes, instala seleccionados
# Guarda ruta preferida en rnx_prefs.json
# ==========================================================================
$btnsA4[1].Add_Click({
    $btn = $btnsA4[1]
    $btn.Enabled = $false; $btn.Text = "CARGANDO..."
    [System.Windows.Forms.Application]::DoEvents()

    AdbLog ""
    AdbLog "=============================================="
    AdbLog "  INSTALAR APKs LOCAL - RNX TOOL PRO"
    AdbLog "=============================================="

    if (-not (Check-ADB)) { $btn.Enabled = $true; $btn.Text = "INSTALAR APKs"; return }

    # ---- Cargar / guardar preferencias ----
    $prefsPath = Join-Path $script:SCRIPT_ROOT "rnx_prefs.json"
    $prefs = @{ ApkFolder = "" }
    if (Test-Path $prefsPath) {
        try { $prefs = Get-Content $prefsPath -Raw | ConvertFrom-Json -AsHashtable } catch {}
    }

    # ---- Carpeta default ----
    $defaultApkDir = Join-Path $script:SCRIPT_ROOT "APKs"
    if (-not (Test-Path $defaultApkDir)) { New-Item $defaultApkDir -ItemType Directory -Force | Out-Null }

    $apkRoot = if ($prefs.ApkFolder -and (Test-Path $prefs.ApkFolder)) {
        $prefs.ApkFolder
    } else {
        $defaultApkDir
    }

    # ---- Formulario de seleccion de carpeta + lista ----
    $frmApk = New-Object System.Windows.Forms.Form
    $frmApk.Text = "INSTALAR APKs - RNX TOOL PRO"
    $frmApk.ClientSize = New-Object System.Drawing.Size(600, 520)
    $frmApk.BackColor  = [System.Drawing.Color]::FromArgb(18,18,18)
    $frmApk.FormBorderStyle = "FixedDialog"
    $frmApk.StartPosition   = "CenterScreen"
    $frmApk.MaximizeBox = $false

    # Header label
    $lbHdr = New-Object System.Windows.Forms.Label
    $lbHdr.Text = "INSTALAR APKs DESDE CARPETA LOCAL"
    $lbHdr.Location = New-Object System.Drawing.Point(14,12)
    $lbHdr.Size     = New-Object System.Drawing.Size(572,20)
    $lbHdr.ForeColor = [System.Drawing.Color]::FromArgb(180,80,255)
    $lbHdr.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $frmApk.Controls.Add($lbHdr)

    # Carpeta label
    $lbDir = New-Object System.Windows.Forms.Label
    $lbDir.Text = "Carpeta: $apkRoot"
    $lbDir.Location = New-Object System.Drawing.Point(14,38)
    $lbDir.Size     = New-Object System.Drawing.Size(480,16)
    $lbDir.ForeColor = [System.Drawing.Color]::LightGray
    $lbDir.Font = New-Object System.Drawing.Font("Consolas",7.5)
    $frmApk.Controls.Add($lbDir)

    # Boton cambiar carpeta
    $btnCarpeta = New-Object System.Windows.Forms.Button
    $btnCarpeta.Text = "CAMBIAR"
    $btnCarpeta.Location = New-Object System.Drawing.Point(500,32)
    $btnCarpeta.Size     = New-Object System.Drawing.Size(86,24)
    $btnCarpeta.FlatStyle = "Flat"
    $btnCarpeta.ForeColor = [System.Drawing.Color]::Cyan
    $btnCarpeta.FlatAppearance.BorderColor = [System.Drawing.Color]::Cyan
    $btnCarpeta.BackColor = [System.Drawing.Color]::FromArgb(28,28,28)
    $btnCarpeta.Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
    $frmApk.Controls.Add($btnCarpeta)

    # Separador
    $lbSep = New-Object System.Windows.Forms.Label
    $lbSep.Location = New-Object System.Drawing.Point(14,60); $lbSep.Size = New-Object System.Drawing.Size(572,1)
    $lbSep.BorderStyle = "Fixed3D"; $frmApk.Controls.Add($lbSep)

    # CheckedListBox con APKs
    $clb = New-Object System.Windows.Forms.CheckedListBox
    $clb.Location = New-Object System.Drawing.Point(14,68)
    $clb.Size     = New-Object System.Drawing.Size(572,340)
    $clb.BackColor = [System.Drawing.Color]::FromArgb(26,26,26)
    $clb.ForeColor = [System.Drawing.Color]::LightGray
    $clb.Font = New-Object System.Drawing.Font("Consolas",8.5)
    $clb.CheckOnClick = $true
    $frmApk.Controls.Add($clb)

    # Label estado / info
    $lbStatus = New-Object System.Windows.Forms.Label
    $lbStatus.Location = New-Object System.Drawing.Point(14,416)
    $lbStatus.Size     = New-Object System.Drawing.Size(572,16)
    $lbStatus.ForeColor = [System.Drawing.Color]::FromArgb(100,100,100)
    $lbStatus.Font = New-Object System.Drawing.Font("Consolas",7.5)
    $frmApk.Controls.Add($lbStatus)

    # ProgressBar
    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Location = New-Object System.Drawing.Point(14,436)
    $bar.Size     = New-Object System.Drawing.Size(572,18)
    $bar.Style = "Continuous"; $bar.Minimum = 0; $bar.Maximum = 100; $bar.Value = 0
    $frmApk.Controls.Add($bar)

    # Botones inferiores
    $btnTodos = New-Object System.Windows.Forms.Button
    $btnTodos.Text = "TODOS"; $btnTodos.Location = New-Object System.Drawing.Point(14,462)
    $btnTodos.Size = New-Object System.Drawing.Size(70,28); $btnTodos.FlatStyle = "Flat"
    $btnTodos.ForeColor = [System.Drawing.Color]::LightGray
    $btnTodos.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,60)
    $btnTodos.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $btnTodos.Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
    $frmApk.Controls.Add($btnTodos)

    $btnNinguno = New-Object System.Windows.Forms.Button
    $btnNinguno.Text = "NINGUNO"; $btnNinguno.Location = New-Object System.Drawing.Point(90,462)
    $btnNinguno.Size = New-Object System.Drawing.Size(70,28); $btnNinguno.FlatStyle = "Flat"
    $btnNinguno.ForeColor = [System.Drawing.Color]::LightGray
    $btnNinguno.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,60)
    $btnNinguno.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $btnNinguno.Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
    $frmApk.Controls.Add($btnNinguno)

    $btnInstalar = New-Object System.Windows.Forms.Button
    $btnInstalar.Text = "INSTALAR SELECCIONADOS"
    $btnInstalar.Location = New-Object System.Drawing.Point(310,460)
    $btnInstalar.Size     = New-Object System.Drawing.Size(200,30)
    $btnInstalar.FlatStyle = "Flat"
    $btnInstalar.ForeColor = [System.Drawing.Color]::FromArgb(180,80,255)
    $btnInstalar.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(180,80,255)
    $btnInstalar.BackColor = [System.Drawing.Color]::FromArgb(30,20,40)
    $btnInstalar.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmApk.Controls.Add($btnInstalar)

    $btnCerrar = New-Object System.Windows.Forms.Button
    $btnCerrar.Text = "CERRAR"
    $btnCerrar.Location = New-Object System.Drawing.Point(516,460)
    $btnCerrar.Size     = New-Object System.Drawing.Size(70,30)
    $btnCerrar.FlatStyle = "Flat"
    $btnCerrar.ForeColor = [System.Drawing.Color]::FromArgb(180,60,60)
    $btnCerrar.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(180,60,60)
    $btnCerrar.BackColor = [System.Drawing.Color]::FromArgb(30,18,18)
    $btnCerrar.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $frmApk.Controls.Add($btnCerrar)

    # ---- Mapa APK: label -> FileInfo ----
    $apkMap = @{}

    # ---- Funcion: escanear carpeta y poblar lista ----
    function Cargar-APKs($carpeta) {
        $clb.Items.Clear(); $apkMap.Clear()
        $apks = Get-ChildItem $carpeta -Recurse -Filter "*.apk" -EA SilentlyContinue |
                Sort-Object Name
        if ($apks.Count -eq 0) {
            $lbStatus.Text = "No se encontraron APKs en: $carpeta"
            return
        }
        foreach ($apk in $apks) {
            $sz    = [math]::Round($apk.Length / 1MB, 1)
            $label = "$($apk.Name)  [$sz MB]"
            $clb.Items.Add($label, $false) | Out-Null
            $apkMap[$label] = $apk
        }
        $lbStatus.Text = "$($apks.Count) APK(s) encontrados en: $carpeta"
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Cargar inicial
    Cargar-APKs $apkRoot

    # ---- Evento: cambiar carpeta ----
    $btnCarpeta.Add_Click({
        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        $fb.Description = "Selecciona carpeta raiz de APKs"
        $fb.SelectedPath = $apkRoot
        if ($fb.ShowDialog() -ne "OK") { return }
        $script:_apkRoot = $fb.SelectedPath
        $lbDir.Text = "Carpeta: $($script:_apkRoot)"
        Cargar-APKs $script:_apkRoot
        # Guardar preferencia
        try {
            $p2 = @{ ApkFolder = $script:_apkRoot } | ConvertTo-Json
            Set-Content $prefsPath $p2 -Encoding UTF8
        } catch {}
    })
    $script:_apkRoot = $apkRoot

    $btnTodos.Add_Click({
        for ($i=0; $i -lt $clb.Items.Count; $i++) { $clb.SetItemChecked($i, $true) }
    })
    $btnNinguno.Add_Click({
        for ($i=0; $i -lt $clb.Items.Count; $i++) { $clb.SetItemChecked($i, $false) }
    })
    $btnCerrar.Add_Click({ $frmApk.Close() })

    # ---- Instalar seleccionados ----
    $btnInstalar.Add_Click({
        $seleccionados = @()
        for ($i=0; $i -lt $clb.Items.Count; $i++) {
            if ($clb.GetItemChecked($i)) { $seleccionados += $clb.Items[$i] }
        }
        if ($seleccionados.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Selecciona al menos un APK.","Aviso","OK","Warning") | Out-Null
            return
        }

        $btnInstalar.Enabled = $false; $btnInstalar.Text = "INSTALANDO..."
        $bar.Value = 0
        $total = $seleccionados.Count; $ok = 0; $fail = 0

        AdbLog ""
        AdbLog "  Instalando $total APK(s)..."

        for ($i=0; $i -lt $seleccionados.Count; $i++) {
            $label = $seleccionados[$i]
            $apkFile = $apkMap[$label]
            $pct = [int](($i / $total) * 100)
            $bar.Value = $pct
            $lbStatus.Text = "[$($i+1)/$total] Instalando: $($apkFile.Name)"
            [System.Windows.Forms.Application]::DoEvents()

            AdbLog "  [$($i+1)/$total] $($apkFile.Name)"
            $rc = & adb install -r "$($apkFile.FullName)" 2>&1
            $exito = "$rc" -imatch "Success"
            if ($exito) {
                AdbLog "    [OK] Instalado correctamente"
                $ok++
            } else {
                $rcStr = "$rc"
                if ($rcStr -match "INSTALL_FAILED_[A-Z_]+") { $motivo = $Matches[0] -replace "INSTALL_FAILED_","" } else { $motivo = $rcStr.Trim() }
                AdbLog "    [!] Fallo: $motivo"
                $fail++
            }
            [System.Windows.Forms.Application]::DoEvents()
        }

        $bar.Value = 100
        $lbStatus.Text = "Listo: $ok OK / $fail fallidos"
        AdbLog ""
        AdbLog "  Resultado: $ok instalados, $fail fallidos"
        AdbLog "=============================================="

        $btnInstalar.Enabled = $true; $btnInstalar.Text = "INSTALAR SELECCIONADOS"
        [System.Windows.Forms.MessageBox]::Show(
            "Instalacion completada.`n`nInstalados : $ok`nFallidos   : $fail",
            "INSTALAR APKs", "OK", "Information") | Out-Null
    })

    # Guardar ruta actual como preferencia al abrir
    try {
        $pSave = @{ ApkFolder = $apkRoot } | ConvertTo-Json
        Set-Content $prefsPath $pSave -Encoding UTF8
    } catch {}

    $frmApk.ShowDialog() | Out-Null

    $btn.Enabled = $true; $btn.Text = "INSTALAR APKs"
})

# ---- INSTALAR MAGISK (seleccion v24 / v27 con autodeteccion por modelo) ----
$btnsA2[4].Add_Click({
    $btn = $btnsA2[4]
    $btn.Enabled = $false; $btn.Text = "INSTALANDO..."
    $Global:logAdb.Clear()
    AdbLog "=============================================="
    AdbLog "   INSTALAR MAGISK  -  RNX TOOL PRO"
    AdbLog "   $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    AdbLog "=============================================="
    AdbLog ""

    if (-not (Check-ADB)) {
        AdbLog "[!] No hay dispositivo ADB conectado."
        AdbLog "    Habilita Depuracion USB y reconecta el equipo."
        $btn.Enabled = $true; $btn.Text = "INSTALAR MAGISK"; return
    }

    $instModel  = (& adb shell getprop ro.product.model  2>$null).Trim()
    $instSerial = (& adb get-serialno 2>$null).Trim()
    AdbLog "[+] Dispositivo : $instModel  ($instSerial)"
    AdbLog ""
    [System.Windows.Forms.Application]::DoEvents()

    $isLegacyModel = $false
    foreach ($leg in $script:MAGISK_LEGACY_MODELS) {
        if ($instModel.Trim().ToUpper() -eq $leg.ToUpper()) { $isLegacyModel = $true; break }
    }
    $autoSelIdx = if ($isLegacyModel) { 0 } else { 1 }
    $autoLabel  = if ($isLegacyModel) { "v24 (legacy detectado: $instModel)" } else { "v27 (recomendado)" }
    AdbLog "[*] Autodeteccion : Magisk $autoLabel"
    AdbLog ""

    $dlgForm = New-Object Windows.Forms.Form
    $dlgForm.Text = "Seleccionar version de Magisk"
    $dlgForm.ClientSize = New-Object System.Drawing.Size(380, 175)
    $dlgForm.BackColor = [System.Drawing.Color]::FromArgb(28,28,28)
    $dlgForm.FormBorderStyle = "FixedDialog"; $dlgForm.StartPosition = "CenterScreen"
    $dlgForm.MaximizeBox = $false; $dlgForm.MinimizeBox = $false; $dlgForm.TopMost = $true

    $lblDev = New-Object Windows.Forms.Label
    $lblDev.Text = "Dispositivo: $instModel"; $lblDev.Location = New-Object System.Drawing.Point(14,12)
    $lblDev.Size = New-Object System.Drawing.Size(352,16); $lblDev.ForeColor = [System.Drawing.Color]::FromArgb(160,160,160)
    $lblDev.Font = New-Object System.Drawing.Font("Segoe UI",8); $dlgForm.Controls.Add($lblDev)

    $lblSel = New-Object Windows.Forms.Label
    $lblSel.Text = "Version de Magisk a instalar:"; $lblSel.Location = New-Object System.Drawing.Point(14,34)
    $lblSel.Size = New-Object System.Drawing.Size(352,18); $lblSel.ForeColor = [System.Drawing.Color]::Cyan
    $lblSel.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $dlgForm.Controls.Add($lblSel)

    $cmbVer = New-Object Windows.Forms.ComboBox
    $cmbVer.Location = New-Object System.Drawing.Point(14,58); $cmbVer.Size = New-Object System.Drawing.Size(352,26)
    $cmbVer.DropDownStyle = "DropDownList"; $cmbVer.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $cmbVer.ForeColor = [System.Drawing.Color]::Cyan
    $cmbVer.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    @("Magisk v24  (legacy - A21s / A13 / A51 5G / kernel antiguo)","Magisk v27  (ultima version - recomendado)") |
        ForEach-Object { $cmbVer.Items.Add($_) | Out-Null }
    $cmbVer.SelectedIndex = $autoSelIdx; $dlgForm.Controls.Add($cmbVer)

    if ($isLegacyModel) {
        $lblNote = New-Object Windows.Forms.Label
        $lblNote.Text = "  Modelo legacy -> v24 preseleccionada"; $lblNote.Location = New-Object System.Drawing.Point(14,84)
        $lblNote.Size = New-Object System.Drawing.Size(352,15); $lblNote.ForeColor = [System.Drawing.Color]::FromArgb(255,180,0)
        $lblNote.Font = New-Object System.Drawing.Font("Segoe UI",7.5); $dlgForm.Controls.Add($lblNote)
    }

    $btnOk = New-Object Windows.Forms.Button
    $btnOk.Text = "INSTALAR"; $btnOk.Location = New-Object System.Drawing.Point(14,128)
    $btnOk.Size = New-Object System.Drawing.Size(170,34); $btnOk.FlatStyle = "Flat"
    $btnOk.ForeColor = [System.Drawing.Color]::Cyan; $btnOk.BackColor = [System.Drawing.Color]::FromArgb(20,40,55)
    $btnOk.FlatAppearance.BorderColor = [System.Drawing.Color]::Cyan
    $btnOk.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK; $dlgForm.Controls.Add($btnOk)

    $btnCan = New-Object Windows.Forms.Button
    $btnCan.Text = "CANCELAR"; $btnCan.Location = New-Object System.Drawing.Point(196,128)
    $btnCan.Size = New-Object System.Drawing.Size(170,34); $btnCan.FlatStyle = "Flat"
    $btnCan.ForeColor = [System.Drawing.Color]::Gray; $btnCan.BackColor = [System.Drawing.Color]::FromArgb(35,35,35)
    $btnCan.FlatAppearance.BorderColor = [System.Drawing.Color]::Gray
    $btnCan.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $btnCan.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $dlgForm.Controls.Add($btnCan)
    $dlgForm.AcceptButton = $btnOk; $dlgForm.CancelButton = $btnCan
    $dlgResult = $dlgForm.ShowDialog()

    if ($dlgResult -ne [System.Windows.Forms.DialogResult]::OK) {
        AdbLog "[~] Cancelado."; $btn.Enabled = $true; $btn.Text = "INSTALAR MAGISK"; return
    }

    $selIdx  = $cmbVer.SelectedIndex
    $verLabel = if ($selIdx -eq 0) { "v24" } else { "v27" }
    $apkName  = if ($selIdx -eq 0) { "magisk24.apk" } else { "magisk27.apk" }
    AdbLog "[+] Version : Magisk $verLabel  |  APK: $apkName"
    AdbLog ""

    $apkPath = $null
    foreach ($c in @(
        (Join-Path $script:TOOLS_DIR $apkName),
        (Join-Path $script:SCRIPT_ROOT $apkName),
        (Join-Path $script:SCRIPT_ROOT "tools\$apkName")
    )) { if (Test-Path $c -EA SilentlyContinue) { $apkPath = $c; break } }

    if (-not $apkPath) {
        AdbLog "[~] $apkName no encontrado - selecciona manualmente..."
        $fdApk = New-Object System.Windows.Forms.OpenFileDialog
        $fdApk.Filter = "APK de Magisk (*.apk)|*.apk|Todos|*.*"
        $fdApk.Title  = "Selecciona Magisk $verLabel APK"
        if ($fdApk.ShowDialog() -ne "OK") { AdbLog "[~] Cancelado."; $btn.Enabled=$true; $btn.Text="INSTALAR MAGISK"; return }
        $apkPath = $fdApk.FileName
    }

    AdbLog "[+] Ruta APK : $apkPath"
    AdbLog "[~] Instalando via adb install -r ..."
    AdbLog ""
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $rc = (& adb install -r "$apkPath" 2>&1) -join "`n"
        foreach ($line in ($rc -split "`n")) { $l=$line.Trim(); if ($l) { AdbLog "  $l" } }
        AdbLog ""
        if ($rc -imatch "Success") {
            AdbLog "[OK] Magisk $verLabel instalado correctamente."
            AdbLog "[~] Abre la app Magisk en el equipo para completar el setup."
            $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  Magisk $verLabel instalado  |  $instModel"
        } elseif ($rc -imatch "INSTALL_FAILED") {
            $motivo = if ($rc -match "INSTALL_FAILED_([A-Z_]+)") { $Matches[1] } else { "revisa el log" }
            AdbLog "[!] Instalacion fallida: $motivo"
        } else { AdbLog "[~] Proceso finalizado (cod desconocido)" }
    } catch { AdbLog "[!] Error: $_" }
    finally { $btn.Enabled = $true; $btn.Text = "INSTALAR MAGISK" }
})

# ---- BUSCAR FIRMWARE SAMSUNG EN SAMFW  (btnsA2[5]) ----
$btnsA2[5].Add_Click({
    $btn = $btnsA2[5]
    $btn.Enabled = $false; $btn.Text = "BUSCANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    $Global:logAdb.Clear()
    AdbLog "=============================================="
    AdbLog "   SAMFW FIRMWARE DOWNLOADER  -  RNX TOOL PRO"
    AdbLog "   $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    AdbLog "=============================================="
    AdbLog ""

    # =========================================================
    # MINI INTERFAZ SAMFW - 2 modos:
    #   A) Auto-identificar desde dispositivo conectado
    #   B) Escribir modelo manualmente
    # =========================================================
    $frmSamFW = New-Object System.Windows.Forms.Form
    $frmSamFW.Text = "SamFW Firmware Downloader - RNX TOOL PRO"
    $frmSamFW.ClientSize = New-Object System.Drawing.Size(560, 400)
    $frmSamFW.BackColor = [System.Drawing.Color]::FromArgb(14,14,22)
    $frmSamFW.FormBorderStyle = "FixedDialog"
    $frmSamFW.StartPosition = "CenterScreen"
    $frmSamFW.TopMost = $true

    # Header
    $lbHdr = New-Object Windows.Forms.Label
    $lbHdr.Text = "  SAMFW FIRMWARE DOWNLOADER"
    $lbHdr.Location = New-Object System.Drawing.Point(0,0)
    $lbHdr.Size = New-Object System.Drawing.Size(560,34)
    $lbHdr.BackColor = [System.Drawing.Color]::FromArgb(0,120,200)
    $lbHdr.ForeColor = [System.Drawing.Color]::White
    $lbHdr.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $lbHdr.TextAlign = "MiddleLeft"
    $frmSamFW.Controls.Add($lbHdr)

    # ---- SECCION A: Auto-identificar ----
    $pnlAuto = New-Object Windows.Forms.Panel
    $pnlAuto.Location = New-Object System.Drawing.Point(10,44)
    $pnlAuto.Size = New-Object System.Drawing.Size(538,160)
    $pnlAuto.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $pnlAuto.BorderStyle = "FixedSingle"
    $frmSamFW.Controls.Add($pnlAuto)

    $lbAutoTitle = New-Object Windows.Forms.Label
    $lbAutoTitle.Text = "  MODO 1: Auto-identificar (requiere dispositivo conectado por ADB)"
    $lbAutoTitle.Location = New-Object System.Drawing.Point(0,0)
    $lbAutoTitle.Size = New-Object System.Drawing.Size(538,26)
    $lbAutoTitle.BackColor = [System.Drawing.Color]::FromArgb(0,80,140)
    $lbAutoTitle.ForeColor = [System.Drawing.Color]::White
    $lbAutoTitle.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $lbAutoTitle.TextAlign = "MiddleLeft"
    $pnlAuto.Controls.Add($lbAutoTitle)

    # Labels for device info
    $lbAutoModel = New-Object Windows.Forms.Label
    $lbAutoModel.Text = "Modelo  : --"
    $lbAutoModel.Location = New-Object System.Drawing.Point(14,34)
    $lbAutoModel.Size = New-Object System.Drawing.Size(510,18)
    $lbAutoModel.ForeColor = [System.Drawing.Color]::Lime
    $lbAutoModel.Font = New-Object System.Drawing.Font("Consolas",9)
    $pnlAuto.Controls.Add($lbAutoModel)

    $lbAutoCSC = New-Object Windows.Forms.Label
    $lbAutoCSC.Text = "CSC     : --"
    $lbAutoCSC.Location = New-Object System.Drawing.Point(14,54)
    $lbAutoCSC.Size = New-Object System.Drawing.Size(510,18)
    $lbAutoCSC.ForeColor = [System.Drawing.Color]::Lime
    $lbAutoCSC.Font = New-Object System.Drawing.Font("Consolas",9)
    $pnlAuto.Controls.Add($lbAutoCSC)

    $lbAutoBuild = New-Object Windows.Forms.Label
    $lbAutoBuild.Text = "Build   : --"
    $lbAutoBuild.Location = New-Object System.Drawing.Point(14,74)
    $lbAutoBuild.Size = New-Object System.Drawing.Size(510,18)
    $lbAutoBuild.ForeColor = [System.Drawing.Color]::FromArgb(180,180,180)
    $lbAutoBuild.Font = New-Object System.Drawing.Font("Consolas",8)
    $pnlAuto.Controls.Add($lbAutoBuild)

    $lbAutoUrl = New-Object Windows.Forms.Label
    $lbAutoUrl.Text = "URL     : --"
    $lbAutoUrl.Location = New-Object System.Drawing.Point(14,94)
    $lbAutoUrl.Size = New-Object System.Drawing.Size(510,18)
    $lbAutoUrl.ForeColor = [System.Drawing.Color]::Cyan
    $lbAutoUrl.Font = New-Object System.Drawing.Font("Consolas",7.5)
    $pnlAuto.Controls.Add($lbAutoUrl)

    $btnAutoDetect = New-Object Windows.Forms.Button
    $btnAutoDetect.Text = "AUTO IDENTIFICAR"
    $btnAutoDetect.Location = New-Object System.Drawing.Point(14,122)
    $btnAutoDetect.Size = New-Object System.Drawing.Size(160,30)
    $btnAutoDetect.FlatStyle = "Flat"
    $btnAutoDetect.ForeColor = [System.Drawing.Color]::Lime
    $btnAutoDetect.FlatAppearance.BorderColor = [System.Drawing.Color]::Lime
    $btnAutoDetect.BackColor = [System.Drawing.Color]::FromArgb(15,35,15)
    $btnAutoDetect.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $pnlAuto.Controls.Add($btnAutoDetect)

    $btnAutoOpen = New-Object Windows.Forms.Button
    $btnAutoOpen.Text = "IR A SAMFW"
    $btnAutoOpen.Location = New-Object System.Drawing.Point(184,122)
    $btnAutoOpen.Size = New-Object System.Drawing.Size(130,30)
    $btnAutoOpen.FlatStyle = "Flat"
    $btnAutoOpen.ForeColor = [System.Drawing.Color]::White
    $btnAutoOpen.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0,120,200)
    $btnAutoOpen.BackColor = [System.Drawing.Color]::FromArgb(0,60,120)
    $btnAutoOpen.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btnAutoOpen.Enabled = $false
    $pnlAuto.Controls.Add($btnAutoOpen)

    # Variables for auto-detected URL
    $script:SamFW_AutoURL = ""

    $btnAutoDetect.Add_Click({
        $btnAutoDetect.Enabled = $false; $btnAutoDetect.Text = "LEYENDO..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            function SamFW-Prop2($prop) {
                $r = & adb shell getprop $prop 2>$null
                if ($r -is [array]) { return ($r -join "").Trim() }
                return "$r".Trim()
            }
            $sfModel2   = SamFW-Prop2 "ro.product.model"
            $sfBrand2   = (SamFW-Prop2 "ro.product.brand").ToUpper()
            $sfBuild2   = SamFW-Prop2 "ro.build.display.id"
            $sfBoot2    = SamFW-Prop2 "ro.boot.bootloader"
            $sfCSC2 = SamFW-Prop2 "ro.csc.sales_code"
            if (-not $sfCSC2) { $sfCSC2 = SamFW-Prop2 "ro.csc.country.code" }
            if (-not $sfCSC2) { $sfCSC2 = SamFW-Prop2 "ro.product.csc" }

            if (-not $sfModel2) {
                $lbAutoModel.Text = "Modelo  : [Sin dispositivo ADB]"
                $lbAutoModel.ForeColor = [System.Drawing.Color]::OrangeRed
            } elseif ($sfBrand2 -notmatch "SAMSUNG") {
                $lbAutoModel.Text = "Modelo  : $sfModel2  [$sfBrand2] - Solo Samsung"
                $lbAutoModel.ForeColor = [System.Drawing.Color]::OrangeRed
            } else {
                $lbAutoModel.Text = "Modelo  : $sfModel2"
                $lbAutoModel.ForeColor = [System.Drawing.Color]::Lime
                $lbAutoCSC.Text  = "CSC     : $(if($sfCSC2){$sfCSC2}else{'NO DETECTADO'})"
                $lbAutoBuild.Text = "Build   : $sfBuild2  |  Boot: $sfBoot2"
                $sfURL2 = if ($sfCSC2) { "https://samfw.com/firmware/$sfModel2/$sfCSC2" } else { "https://samfw.com/firmware/$sfModel2" }
                $lbAutoUrl.Text = "URL     : $sfURL2"
                $script:SamFW_AutoURL = $sfURL2
                $btnAutoOpen.Enabled = $true
                AdbLog "[+] Auto-detecto: $sfModel2 | CSC: $sfCSC2 | Build: $sfBuild2"
                AdbLog "[+] URL: $sfURL2"
            }
        } catch {
            $lbAutoModel.Text = "Error: $_"
            $lbAutoModel.ForeColor = [System.Drawing.Color]::Red
        }
        $btnAutoDetect.Enabled = $true; $btnAutoDetect.Text = "AUTO IDENTIFICAR"
    })

    $btnAutoOpen.Add_Click({
        if ($script:SamFW_AutoURL) {
            try { Start-Process $script:SamFW_AutoURL; AdbLog "[OK] Navegador abierto: $($script:SamFW_AutoURL)" }
            catch { AdbLog "[!] Error: $_" }
        }
    })

    # ---- SECCION B: Busqueda manual por modelo ----
    $pnlManual = New-Object Windows.Forms.Panel
    $pnlManual.Location = New-Object System.Drawing.Point(10,216)
    $pnlManual.Size = New-Object System.Drawing.Size(538,140)
    $pnlManual.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $pnlManual.BorderStyle = "FixedSingle"
    $frmSamFW.Controls.Add($pnlManual)

    $lbManualTitle = New-Object Windows.Forms.Label
    $lbManualTitle.Text = "  MODO 2: Buscar por modelo (sin telefono conectado)"
    $lbManualTitle.Location = New-Object System.Drawing.Point(0,0)
    $lbManualTitle.Size = New-Object System.Drawing.Size(538,26)
    $lbManualTitle.BackColor = [System.Drawing.Color]::FromArgb(80,50,0)
    $lbManualTitle.ForeColor = [System.Drawing.Color]::White
    $lbManualTitle.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $lbManualTitle.TextAlign = "MiddleLeft"
    $pnlManual.Controls.Add($lbManualTitle)

    $lbManModel = New-Object Windows.Forms.Label
    $lbManModel.Text = "Modelo Samsung:"
    $lbManModel.Location = New-Object System.Drawing.Point(14,36)
    $lbManModel.Size = New-Object System.Drawing.Size(110,20)
    $lbManModel.ForeColor = [System.Drawing.Color]::LightGray
    $lbManModel.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $pnlManual.Controls.Add($lbManModel)

    $txtManModel = New-Object Windows.Forms.TextBox
    $txtManModel.Location = New-Object System.Drawing.Point(130,34)
    $txtManModel.Size = New-Object System.Drawing.Size(160,24)
    $txtManModel.BackColor = [System.Drawing.Color]::FromArgb(30,30,45)
    $txtManModel.ForeColor = [System.Drawing.Color]::White
    $txtManModel.BorderStyle = "FixedSingle"
    $txtManModel.Font = New-Object System.Drawing.Font("Consolas",9,[System.Drawing.FontStyle]::Bold)
    $txtManModel.Text = "SM-"
    $pnlManual.Controls.Add($txtManModel)

    $lbManCSC = New-Object Windows.Forms.Label
    $lbManCSC.Text = "CSC (opcional):"
    $lbManCSC.Location = New-Object System.Drawing.Point(14,66)
    $lbManCSC.Size = New-Object System.Drawing.Size(110,20)
    $lbManCSC.ForeColor = [System.Drawing.Color]::LightGray
    $lbManCSC.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $pnlManual.Controls.Add($lbManCSC)

    $txtManCSC = New-Object Windows.Forms.TextBox
    $txtManCSC.Location = New-Object System.Drawing.Point(130,64)
    $txtManCSC.Size = New-Object System.Drawing.Size(80,24)
    $txtManCSC.BackColor = [System.Drawing.Color]::FromArgb(30,30,45)
    $txtManCSC.ForeColor = [System.Drawing.Color]::Cyan
    $txtManCSC.BorderStyle = "FixedSingle"
    $txtManCSC.Font = New-Object System.Drawing.Font("Consolas",9)
    $txtManCSC.Text = ""
    $pnlManual.Controls.Add($txtManCSC)

    $lbManHint = New-Object Windows.Forms.Label
    $lbManHint.Text = "Ej: SM-A546B / CSC: ZTO, OXA, EUX, CHC..."
    $lbManHint.Location = New-Object System.Drawing.Point(14,90)
    $lbManHint.Size = New-Object System.Drawing.Size(510,16)
    $lbManHint.ForeColor = [System.Drawing.Color]::FromArgb(100,100,120)
    $lbManHint.Font = New-Object System.Drawing.Font("Segoe UI",7.5)
    $pnlManual.Controls.Add($lbManHint)

    $btnManOpen = New-Object Windows.Forms.Button
    $btnManOpen.Text = "BUSCAR EN SAMFW"
    $btnManOpen.Location = New-Object System.Drawing.Point(300,34)
    $btnManOpen.Size = New-Object System.Drawing.Size(150,56)
    $btnManOpen.FlatStyle = "Flat"
    $btnManOpen.ForeColor = [System.Drawing.Color]::FromArgb(255,180,0)
    $btnManOpen.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,180,0)
    $btnManOpen.BackColor = [System.Drawing.Color]::FromArgb(35,28,0)
    $btnManOpen.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $pnlManual.Controls.Add($btnManOpen)

    $btnManOpen.Add_Click({
        $manModel = $txtManModel.Text.Trim().ToUpper()
        $manCSC   = $txtManCSC.Text.Trim().ToUpper()
        if (-not $manModel -or $manModel -eq "SM-") {
            [System.Windows.Forms.MessageBox]::Show("Ingresa un modelo Samsung (ej: SM-A546B)","Modelo requerido","OK","Warning") | Out-Null
            return
        }
        $manURL = if ($manCSC) { "https://samfw.com/firmware/$manModel/$manCSC" } else { "https://samfw.com/firmware/$manModel" }
        AdbLog "[+] Busqueda manual: $manModel | CSC: $(if($manCSC){$manCSC}else{"(todos)"})" 
        AdbLog "[+] URL: $manURL"
        try { Start-Process $manURL; AdbLog "[OK] Navegador abierto" }
        catch { AdbLog "[!] Error: $_" }
    })

    # Boton cerrar
    $btnClose = New-Object Windows.Forms.Button
    $btnClose.Text = "CERRAR"
    $btnClose.Location = New-Object System.Drawing.Point(200,366)
    $btnClose.Size = New-Object System.Drawing.Size(160,28)
    $btnClose.FlatStyle = "Flat"
    $btnClose.ForeColor = [System.Drawing.Color]::Gray
    $btnClose.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(70,70,70)
    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(25,25,35)
    $btnClose.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $btnClose.Add_Click({ $frmSamFW.Close() })
    $frmSamFW.Controls.Add($btnClose)

    AdbLog "[i] Mini interfaz SamFW abierta"
    AdbLog "    Modo 1: conecta el telefono por ADB y usa AUTO IDENTIFICAR"
    AdbLog "    Modo 2: escribe el modelo manualmente para buscar sin telefono"
    AdbLog "    SamFW requiere cuenta gratuita para descargar."

    $frmSamFW.ShowDialog() | Out-Null

    $Global:lblStatus.Text = "  RNX TOOL PRO v2.3  |  SamFW Downloader  |  samfw.com"
    $btn.Enabled = $true; $btn.Text = "SAMFW FIRMWARE"
})