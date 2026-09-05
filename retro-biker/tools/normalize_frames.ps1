# Normalizes a set of (already background-stripped) sprite frames onto a single
# common canvas so they can be swapped as animation frames without jitter.
# Each frame's opaque content is cropped to its bounding box, then composited
# horizontally centered and bottom-aligned (feet on the canvas floor) onto a
# canvas sized to the largest frame. Writes each OutPath and reports geometry.
#
# Usage: powershell -File normalize_frames.ps1 -InPaths a.png,b.png -OutPaths a.png,b.png [-AlphaThresh 128]
param(
    [Parameter(Mandatory = $true)][string[]]$InPaths,
    [Parameter(Mandatory = $true)][string[]]$OutPaths,
    [int]$AlphaThresh = 128
)

Add-Type -AssemblyName System.Drawing

$frames = @()  # each: @{ bmp; minX; minY; w; h }

foreach ($p in $InPaths) {
    $src = [System.Drawing.Bitmap]::new($p)
    $w = $src.Width; $h = $src.Height
    $bmp = [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.DrawImage($src, 0, 0, $w, $h)
    $g.Dispose()
    $src.Dispose()   # releases the file lock so we can overwrite it later

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
    $frames += @{ bmp = $bmp; minX = $minX; minY = $minY; w = ($maxX - $minX + 1); h = ($maxY - $minY + 1) }
}

$canvasW = 0; $canvasH = 0
foreach ($f in $frames) {
    if ($f.w -gt $canvasW) { $canvasW = $f.w }
    if ($f.h -gt $canvasH) { $canvasH = $f.h }
}

for ($i = 0; $i -lt $frames.Count; $i++) {
    $f = $frames[$i]
    $canvas = [System.Drawing.Bitmap]::new($canvasW, $canvasH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $cg = [System.Drawing.Graphics]::FromImage($canvas)
    $cg.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $dx = [int](($canvasW - $f.w) / 2)        # horizontally centered
    $dy = $canvasH - $f.h                      # bottom-aligned (feet on the floor)
    $srcRect = [System.Drawing.Rectangle]::new($f.minX, $f.minY, $f.w, $f.h)
    $dstRect = [System.Drawing.Rectangle]::new($dx, $dy, $f.w, $f.h)
    $cg.DrawImage($f.bmp, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $cg.Dispose()
    $canvas.Save($OutPaths[$i], [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    $f.bmp.Dispose()
    "$([System.IO.Path]::GetFileName($OutPaths[$i])) : char $($f.w)x$($f.h) -> canvas ${canvasW}x${canvasH}"
}
