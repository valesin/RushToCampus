# Trims fully/near-transparent margins off a PNG so the image bounds equal the
# artwork's opaque bounding box. Run AFTER strip_bg.ps1. Result: the texture IS
# the art, so in-engine sizing/colliders map directly to what you see.
#
# Usage: powershell -File trim_png.ps1 -InPath in.png [-OutPath out.png] [-AlphaThresh 16]
param(
    [Parameter(Mandatory = $true)][string]$InPath,
    [string]$OutPath = $InPath,
    [int]$AlphaThresh = 16
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

$minX = $w; $minY = $h; $maxX = -1; $maxY = -1
for ($y = 0; $y -lt $h; $y++) {
    $row = $y * $stride
    for ($x = 0; $x -lt $w; $x++) {
        if ($bytes[$row + ($x * 4) + 3] -ge $AlphaThresh) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

if ($maxX -lt 0) { "$InPath : fully transparent, not trimmed"; $bmp.Dispose(); return }

$cw = $maxX - $minX + 1
$ch = $maxY - $minY + 1
$crop = [System.Drawing.Bitmap]::new($cw, $ch, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$cg = [System.Drawing.Graphics]::FromImage($crop)
$srcRect = [System.Drawing.Rectangle]::new($minX, $minY, $cw, $ch)
$dstRect = [System.Drawing.Rectangle]::new(0, 0, $cw, $ch)
$cg.DrawImage($bmp, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
$cg.Dispose()
$bmp.Dispose()
$crop.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$crop.Dispose()

$ratio = [Math]::Round($cw / $ch, 3)
"$([System.IO.Path]::GetFileName($OutPath)) : trimmed ${w}x${h} -> ${cw}x${ch} (w/h ratio $ratio)"
