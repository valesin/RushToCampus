# Crops a PNG to the bounding box of its LARGEST connected opaque region,
# discarding stray disconnected specks/lines the background-strip left behind.
# Run AFTER strip_bg.ps1. Uses 8-connectivity over alpha >= AlphaThresh.
#
# Usage: powershell -File blob_crop.ps1 -InPath in.png [-OutPath out.png] [-AlphaThresh 128]
param(
    [Parameter(Mandatory = $true)][string]$InPath,
    [string]$OutPath = $InPath,
    [int]$AlphaThresh = 128
)

Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::new($InPath)
$w = $src.Width
$h = $src.Height
$bmp = [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.DrawImage($src, 0, 0, $w, $h)
$gfx.Dispose()
$src.Dispose()

$rect = [System.Drawing.Rectangle]::new(0, 0, $w, $h)
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$len = $stride * $h
$bytes = New-Object byte[] $len
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $len)
$bmp.UnlockBits($data)

# Opaque mask (one bool per pixel), indexed p = y*w + x.
$n = $w * $h
$opaque = New-Object bool[] $n
for ($y = 0; $y -lt $h; $y++) {
    $row = $y * $stride
    $pr = $y * $w
    for ($x = 0; $x -lt $w; $x++) {
        if ($bytes[$row + ($x * 4) + 3] -ge $AlphaThresh) { $opaque[$pr + $x] = $true }
    }
}

$visited = New-Object bool[] $n
$stack = New-Object System.Collections.Generic.Stack[int]
$bestSize = 0; $bMinX = 0; $bMaxX = 0; $bMinY = 0; $bMaxY = 0

for ($s = 0; $s -lt $n; $s++) {
    if ($visited[$s] -or -not $opaque[$s]) { continue }
    $stack.Push($s) | Out-Null
    $size = 0; $minX = $w; $maxX = -1; $minY = $h; $maxY = -1
    while ($stack.Count -gt 0) {
        $p = $stack.Pop()
        if ($visited[$p]) { continue }
        $visited[$p] = $true
        $x = $p % $w
        $y = [int]($p / $w)
        $size++
        if ($x -lt $minX) { $minX = $x }
        if ($x -gt $maxX) { $maxX = $x }
        if ($y -lt $minY) { $minY = $y }
        if ($y -gt $maxY) { $maxY = $y }
        $x0 = [Math]::Max(0, $x - 1); $x1 = [Math]::Min($w - 1, $x + 1)
        $y0 = [Math]::Max(0, $y - 1); $y1 = [Math]::Min($h - 1, $y + 1)
        for ($ny = $y0; $ny -le $y1; $ny++) {
            $nr = $ny * $w
            for ($nx = $x0; $nx -le $x1; $nx++) {
                $q = $nr + $nx
                if (-not $visited[$q] -and $opaque[$q]) { $stack.Push($q) | Out-Null }
            }
        }
    }
    if ($size -gt $bestSize) { $bestSize = $size; $bMinX = $minX; $bMaxX = $maxX; $bMinY = $minY; $bMaxY = $maxY }
}

if ($bestSize -le 0) { "$InPath : no opaque region found"; $bmp.Dispose(); return }

$cw = $bMaxX - $bMinX + 1
$ch = $bMaxY - $bMinY + 1
$crop = [System.Drawing.Bitmap]::new($cw, $ch, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$cg = [System.Drawing.Graphics]::FromImage($crop)
$srcRect = [System.Drawing.Rectangle]::new($bMinX, $bMinY, $cw, $ch)
$dstRect = [System.Drawing.Rectangle]::new(0, 0, $cw, $ch)
$cg.DrawImage($bmp, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
$cg.Dispose()
$bmp.Dispose()
$crop.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$crop.Dispose()

$ratio = [Math]::Round($cw / $ch, 3)
"$([System.IO.Path]::GetFileName($OutPath)) : largest blob ${bestSize}px -> crop ${cw}x${ch} (w/h ratio $ratio)"
