# ---- Extender timer para detectar fastboot ----
# Se agrega un segundo timer liviano (3s) que no interfiere con el ADB timer
$script:FB_LAST_DETECTED = $false
$timerFb          = New-Object Windows.Forms.Timer
$timerFb.Interval = 3000
$timerFb.Add_Tick({
    $modoTxt = $Global:lblModo.Text
    # No correr si ya estamos en otro modo confirmado (ADB activo o Download)
    if ($modoTxt -imatch "ADB|DOWNLOAD") { return }
    $fbExe = Get-FastbootExe
    if (-not $fbExe) { return }
    try {
        # DEBE usar & operator — ProcessStartInfo no hereda handles USB del driver
        $argsFb = "devices" -split "\s+" | Where-Object { $_ -ne "" }
        $resFb  = & $fbExe $argsFb 2>&1
        $out2   = if ($resFb -is [array]) { ($resFb | ForEach-Object { "$_" }) -join "`n" } else { "$resFb" }
        $hasFb  = $out2 -match "\tfastboot"
        if ($hasFb -and -not $script:FB_LAST_DETECTED) {
            $script:FB_LAST_DETECTED = $true
            $serial2 = ($out2 -split "\t")[0].Trim()
            $Global:lblADB.Text      = "ADB         : FASTBOOT"
            $Global:lblADB.ForeColor = [System.Drawing.Color]::Yellow
            $Global:lblModo.Text     = "MODO        : FASTBOOT"
            $Global:lblModo.ForeColor= [System.Drawing.Color]::Yellow
            $Global:lblSerial.Text   = "SERIAL      : $serial2"
            $Global:lblStatus.Text   = "  RNX TOOL PRO v2.3  |  FASTBOOT  |  $serial2"
        } elseif (-not $hasFb -and $script:FB_LAST_DETECTED) {
            $script:FB_LAST_DETECTED = $false
            $Global:lblADB.Text      = "ADB         : DESCONECTADO"
            $Global:lblADB.ForeColor = [System.Drawing.Color]::Orange
            $Global:lblModo.Text     = "MODO        : -"
            $Global:lblModo.ForeColor= [System.Drawing.Color]::LightGray
        }
    } catch {}
})
$timerFb.Start()

#==========================================================================
# TIMER + SHOW
#==========================================================================
$timer          = New-Object Windows.Forms.Timer
$timer.Interval = 2500   # 2.5s - suficiente para no solapar jobs ADB
$timer.Add_Tick({
    # No correr en Download Mode ni en Fastboot Mode (interferiria con el sidebar)
    $modoTxt = $Global:lblModo.Text
    if ($modoTxt -imatch "DOWNLOAD|FASTBOOT") { return }
    Get-DeepDeviceStatus
})
$timer.Start()

# Limpiar jobs al cerrar la ventana
$form.Add_FormClosing({
    $timer.Stop()
    $timerFb.Stop()
    if ($script:FB_LEER_TIMER) { $script:FB_LEER_TIMER.Stop(); $script:FB_LEER_TIMER.Dispose() }
    if ($script:ADB_JOB) {
        Stop-Job  -Job $script:ADB_JOB -ErrorAction SilentlyContinue
        Remove-Job -Job $script:ADB_JOB -Force -ErrorAction SilentlyContinue
    }
    $timerFb.Stop()
    Get-Job -ErrorAction SilentlyContinue | Remove-Job -Force -ErrorAction SilentlyContinue
    # Escribir cierre de sesion en el log
    try {
        Write-RNXLog -Level "INFO" -Message "=========================================="
        Write-RNXLog -Level "INFO" -Message "  SESION CERRADA: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        Write-RNXLog -Level "INFO" -Message "=========================================="
    } catch {}
})

$form.ShowDialog()