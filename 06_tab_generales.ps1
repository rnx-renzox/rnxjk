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

$grpG1 = New-GBox $tabGen "ARCHIVOS / FIRMWARE"      $GX_PAD $GX_Y1  $GX_GW $GX_GH1 "Red"
$grpG2 = New-GBox $tabGen "PARCHEO DE PARTICIONES"  $GX_PAD $GX_Y2B $GX_GW $GX_GH2 "Cyan"
$grpG3 = New-GBox $tabGen "TALLER / GESTION"        $GX_PAD $GX_Y3B $GX_GW $GX_GH3 "Magenta"

$GL1=@("ORGANIZAR FIRMWARE","RENOMBRAR ARCHIVOS","EXTRAER FIRMWARE","VERIFICAR CHECKSUM")
$GL2=@("OEMINFO MDM HONOR","MODEM MI ACCOUNT","EFS SAMSUNG SIM 2","PERSIST MI ACCOUNT",
       "ACTIVAR RESET / MISC MOTOROLA","FLASH PARTICION IMG")
$GL3=@("CREAR FICHA CLIENTE","ADMIN CLIENTES","GENERAR REPORTE","ABRIR CARPETA TRABAJO")

$btnsG1=Place-Grid $grpG1 $GL1 "Red"     2 $GX_BTW $GX_BTH $GX_PPX $GX_PPY $GX_GGX $GX_GGY
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
# BLOQUE 1 - ARCHIVOS / FIRMWARE
#==========================================================================

# ---- [0] ORGANIZAR FIRMWARE ----
$btnsG1[0].Add_Click({
    $btn = $btnsG1[0]; $btn.Enabled=$false; $btn.Text="ORGANIZANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        GenLog ""
        GenLog "=============================================="
        GenLog "  ORGANIZAR FIRMWARE - RNX TOOL PRO v2"
        GenLog "=============================================="
        GenLog "[~] Selecciona la carpeta con los firmwares..."

        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        $fb.Description = "Selecciona carpeta con firmwares"
        if ($fb.ShowDialog() -ne "OK") { GenLog "[~] Cancelado."; return }

        $source = $fb.SelectedPath
        $dest   = Join-Path $source "Organizados"
        New-Item $dest -ItemType Directory -Force | Out-Null
        GenLog "[+] Carpeta origen : $source"
        GenLog "[+] Carpeta destino: $dest"
        GenLog ""

        # ---- FILTRO DE VINCULACION A CELULARES ----
        # Solo se mueven archivos cuyo nombre contenga referencia a dispositivo movil
        $vinculacionPattern = "imei|sn|serial|sm-|xt\d|redmi|poco|xiaomi|miui|samsung|galaxy|motorola|moto|oppo|vivo|realme|tecno|itel|huawei|honor|oneplus|pixel|iphone|nokia|lg |htc|sony|xperia|\d{15}"

        # Cargar TODOS los archivos relevantes (firmware + partes NV/EFS)
        $allFiles = Get-ChildItem $source -Recurse -File |
                    Where-Object { $_.FullName -notlike "*\Organizados\*" }

        # Extensiones de firmware movil estandar
        $fwExts = "zip|rar|tgz|gz|7z|img|tar|md5|ffu|qcn|bin|lz4|ext4|erofs|sparse"

        $files = $allFiles | Where-Object { $_.Extension -imatch "\.($fwExts)$" }

        if ($files.Count -eq 0) { GenLog "[!] No se encontraron archivos de firmware."; return }
        GenLog "[+] $($files.Count) archivos candidatos."
        GenLog ""

        $movidos = 0; $duplicados = 0; $omitidos = 0
        $procesados = [System.Collections.Generic.HashSet[string]]::new()

        # ================================================================
        # FASE 1: GRUPOS ESPECIALES - NV/EFS con correlacion horaria (+-5 min)
        # ================================================================
        GenLog "[FASE 1] Detectando grupos NV/EFS por correlacion horaria..."

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
            GenLog "  [GRUPO] $carpetaNombre ($($grp.Count) archivos)"

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
                GenLog "    -> $($gf.Name)"
                $movidos++
            }
            [System.Windows.Forms.Application]::DoEvents()
        }

        # ================================================================
        # FASE 2: ARCHIVOS ESPECIALES (.ffu, .qcn)
        # ================================================================
        GenLog ""
        GenLog "[FASE 2] Detectando .ffu y .qcn..."

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
                GenLog "  [$(($ext).ToUpper() -replace '.')] $($file.Name) -> $(Split-Path $destEsp -Leaf)"
                $movidos++
            }
        }

        # ================================================================
        # FASE 3: FIRMWARE GENERAL - con filtro de vinculacion
        # ================================================================
        GenLog ""
        GenLog "[FASE 3] Organizando firmware por marca/modelo..."

        foreach ($file in ($files | Where-Object { -not $procesados.Contains($_.FullName) })) {
            $name = $file.Name.ToLower()

            # Filtro de vinculacion: si no hay match a dispositivo movil, skip
            if ($name -notmatch $vinculacionPattern) {
                GenLog "  [SKIP] $($file.Name) - sin referencia a dispositivo movil"
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
                GenLog "  [DUP] $($file.Name) -> $([System.IO.Path]::GetFileName($target))"
            }

            Move-Item $file.FullName $target -Force
            $procesados.Add($file.FullName) | Out-Null
            $rel = "$brand$(if($modelo){`"/$modelo`"})"
            GenLog "  [OK] $($file.Name) -> $rel"
            $movidos++
            [System.Windows.Forms.Application]::DoEvents()
        }

        GenLog ""
        GenLog "=============================================="
        GenLog "  RESUMEN ORGANIZAR FIRMWARE"
        GenLog "=============================================="
        GenLog "  Movidos     : $movidos"
        GenLog "  Duplicados  : $duplicados (renombrados _v2, _v3...)"
        GenLog "  Omitidos    : $omitidos (sin vinculacion a celular)"
        GenLog "  Destino     : $dest"
        GenLog "=============================================="

        $abrir = [System.Windows.Forms.MessageBox]::Show(
            "Firmware organizado.`n`nMovidos  : $movidos`nOmitidos : $omitidos`n`nAbrir carpeta destino?",
            "LISTO", "YesNo", "Information")
        if ($abrir -eq "Yes") { Start-Process explorer.exe $dest }

    } catch { GenLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="ORGANIZAR FIRMWARE" }
})

# ---- [1] RENOMBRAR ARCHIVOS ----
$btnsG1[1].Add_Click({
    $btn = $btnsG1[1]; $btn.Enabled=$false; $btn.Text="RENOMBRANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        GenLog ""
        GenLog "=============================================="
        GenLog "  RENOMBRAR ARCHIVOS - RNX TOOL PRO"
        GenLog "=============================================="
        GenLog "[~] Selecciona carpeta con archivos a renombrar..."

        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        $fb.Description = "Selecciona carpeta para renombrar archivos"
        if ($fb.ShowDialog() -ne "OK") { GenLog "[~] Cancelado."; return }

        $files = Get-ChildItem $fb.SelectedPath -File
        if ($files.Count -eq 0) { GenLog "[!] No hay archivos en la carpeta."; return }
        GenLog "[+] $($files.Count) archivos encontrados."
        GenLog ""

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
            GenLog "  [OK] $($file.Name)"
            GenLog "       -> $nuevo"
            $renombrados++
            [System.Windows.Forms.Application]::DoEvents()
        }

        GenLog ""
        GenLog "  Renombrados : $renombrados"
        GenLog "  Sin cambios : $sin_cambios"
        GenLog "=============================================="

    } catch { GenLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="RENOMBRAR ARCHIVOS" }
})

# ---- [2] EXTRAER FIRMWARE ----
$btnsG1[2].Add_Click({
    $btn = $btnsG1[2]; $btn.Enabled=$false; $btn.Text="EXTRAYENDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        GenLog ""
        GenLog "=============================================="
        GenLog "  EXTRAER FIRMWARE - RNX TOOL PRO v2"
        GenLog "=============================================="

        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "Firmware (*.zip;*.rar;*.7z;*.tgz;*.tar;*.gz;*.tar.md5;*.md5)|*.zip;*.rar;*.7z;*.tgz;*.tar;*.gz;*.md5|Todos|*.*"
        $fd.Title  = "Selecciona archivo de firmware a extraer"
        if ($fd.ShowDialog() -ne "OK") { GenLog "[~] Cancelado."; return }

        $archPath = $fd.FileName
        $archName = [System.IO.Path]::GetFileName($archPath)
        $archSz   = [math]::Round((Get-Item $archPath).Length / 1MB, 2)
        $ext      = [System.IO.Path]::GetExtension($archPath).ToLower()
        $base     = [System.IO.Path]::GetFileNameWithoutExtension($archPath) -replace "\.tar$",""

        $dest = Join-Path ([System.IO.Path]::GetDirectoryName($archPath)) ($base + "_extraido")
        New-Item $dest -ItemType Directory -Force | Out-Null

        GenLog "[+] Archivo : $archName ($archSz MB)"
        GenLog "[+] Destino : $dest"
        GenLog "[~] Preparando extraccion..."

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
                GenLog "[OK] ZIP extraido (PowerShell nativo)"

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

                    if ($proc.ExitCode -ne 0) { GenLog "[!] 7z salio con codigo $($proc.ExitCode)" }
                    else { GenLog "[OK] Extraccion completada con 7z" }
                } finally {
                    try { Remove-Item $logFile -Force -EA SilentlyContinue } catch {}
                }

                # Manejo TAR interno (tgz / tar.md5)
                if ($isTar) {
                    $innerTar = Get-ChildItem $dest -Recurse -File |
                                Where-Object { $_.Extension -imatch "\.(tar)$" } | Select-Object -First 1
                    if ($innerTar) {
                        GenLog "[~] TAR interno: $($innerTar.Name) - extrayendo imgs/..."
                        $ui.LblStatus.Text = "TAR interno: $($innerTar.Name)"
                        $ui.Bar.Value = 50; [System.Windows.Forms.Application]::DoEvents()
                        $destInner = Join-Path $dest "imgs"
                        New-Item $destInner -ItemType Directory -Force | Out-Null
                        & $7z x "$($innerTar.FullName)" "-o$destInner" -y 2>&1 | Out-Null
                        $ui.Bar.Value = 100; $ui.LblPct.Text = "100%"
                        [System.Windows.Forms.Application]::DoEvents()
                        GenLog "[OK] TAR interno extraido en: imgs/"
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
                    GenLog "[OK] Extraido con tar nativo"
                } else {
                    GenLog "[!] No se encontro 7z.exe ni tar."
                    GenLog "[~] Coloca 7z.exe en .\tools\ o instala 7-Zip"
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
        GenLog ""
        GenLog "  Archivos extraidos : $archivos"
        GenLog "  Carpeta            : $dest"
        GenLog "=============================================="

        $abrir = [System.Windows.Forms.MessageBox]::Show(
            "Extraccion completada.`n$archivos archivos.`n`nAbrir carpeta?",
            "EXTRAIDO", "YesNo", "Information")
        if ($abrir -eq "Yes") { Start-Process explorer.exe $dest }

    } catch { GenLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="EXTRAER FIRMWARE" }
})
# ---- [3] VERIFICAR CHECKSUM ----
$btnsG1[3].Add_Click({
    $btn = $btnsG1[3]; $btn.Enabled=$false; $btn.Text="CALCULANDO..."
    [System.Windows.Forms.Application]::DoEvents()
    try {
        GenLog ""
        GenLog "=============================================="
        GenLog "  VERIFICAR CHECKSUM - RNX TOOL PRO"
        GenLog "=============================================="

        $fd = New-Object System.Windows.Forms.OpenFileDialog
        $fd.Filter = "Todos los archivos|*.*"
        $fd.Title  = "Selecciona archivo para verificar checksum"
        if ($fd.ShowDialog() -ne "OK") { GenLog "[~] Cancelado."; return }

        $archPath = $fd.FileName
        $archName = [System.IO.Path]::GetFileName($archPath)
        $archSz   = [math]::Round((Get-Item $archPath).Length / 1MB, 2)

        GenLog "[+] Archivo : $archName ($archSz MB)"
        GenLog "[~] Calculando MD5..."
        $md5  = (Get-FileHash $archPath -Algorithm MD5).Hash
        GenLog "[~] Calculando SHA256..."
        $sha256 = (Get-FileHash $archPath -Algorithm SHA256).Hash
        GenLog "[~] Calculando SHA1..."
        $sha1 = (Get-FileHash $archPath -Algorithm SHA1).Hash

        GenLog ""
        GenLog "  MD5    : $md5"
        GenLog "  SHA1   : $sha1"
        GenLog "  SHA256 : $sha256"
        GenLog ""

        # Opcion de comparacion
        Add-Type -AssemblyName Microsoft.VisualBasic
        $esperado = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Pega el hash esperado para comparar (opcional):`n(MD5, SHA1 o SHA256 - deja vacio para saltar)",
            "COMPARAR HASH", "")

        if ($esperado -and $esperado.Trim() -ne "") {
            $esperado = $esperado.Trim().ToUpper()
            $coincide = ($esperado -eq $md5) -or ($esperado -eq $sha1) -or ($esperado -eq $sha256)
            if ($coincide) {
                GenLog "  VERIFICACION : [OK] HASH CORRECTO - Archivo integro"
                [System.Windows.Forms.MessageBox]::Show(
                    "HASH VERIFICADO`n`nEl archivo es integro y coincide con el hash esperado.",
                    "OK", "OK", "Information") | Out-Null
            } else {
                GenLog "  VERIFICACION : [ERROR] HASH NO COINCIDE - Archivo puede estar corrupto"
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
        GenLog "  Log guardado : $([System.IO.Path]::GetFileName($logPath))"
        GenLog "=============================================="

    } catch { GenLog "[!] Error: $_" }
    finally  { $btn.Enabled=$true; $btn.Text="VERIFICAR CHECKSUM" }
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