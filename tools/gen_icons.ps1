Add-Type -AssemblyName System.Drawing

$src = "C:\Users\f0r058h\Downloads\icono_sin_fondo.ico"
$resRoot = "C:\Users\f0r058h\Projects\cozy_love\android\app\src\main\res"

$icon = New-Object System.Drawing.Icon($src, 256, 256)
$srcBmp = $icon.ToBitmap()
Write-Host "Source frame: $($srcBmp.Width)x$($srcBmp.Height)"

$densities = [ordered]@{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($d in $densities.Keys) {
    $size = $densities[$d]
    $dir = Join-Path $resRoot $d
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $outBmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($outBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($srcBmp, 0, 0, $size, $size)
    $g.Dispose()
    $outPath = Join-Path $dir "ic_launcher.png"
    $outRound = Join-Path $dir "ic_launcher_round.png"
    $outBmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $outBmp.Save($outRound, [System.Drawing.Imaging.ImageFormat]::Png)
    $outBmp.Dispose()
    Write-Host "Wrote $d @ ${size}x${size}"
}

$srcBmp.Dispose()
$icon.Dispose()
Write-Host "Done."
