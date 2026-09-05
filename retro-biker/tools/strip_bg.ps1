# Strips a baked-in (non-alpha) background from a generated sprite by flood-filling
# from the image border. Any border-connected pixel that is "neutral + light"
# (the transparency-checkerboard grays, or a flat backdrop) becomes fully
# transparent. The subject is preserved because its dark outline stops the fill
# and its interior never connects to the border.
#
# Usage: powershell -File strip_bg.ps1 -InPath in.png [-OutPath out.png] [-SatTol 45] [-MinLight 95]
param(
    [Parameter(Mandatory = $true)][string]$InPath,
    [string]$OutPath = $InPath,
    [int]$SatTol = 45,    # max (maxChannel - minChannel) to count as "neutral gray"
    [int]$MinLight = 95   # min brightest channel to count as "light" background
)

Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::new($InPath)
$w = $src.Width
$h = $src.Height

# Normalize to 32bpp ARGB so we always have an alpha channel.
$bmp = [System.Drawing.Bitmap]::new($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.DrawImage($src, 0, 0, $w, $h)
$gfx.Dispose()
$src.Dispose()

$rect = [System.Drawing.Rectangle]::new(0, 0, $w, $h)
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$len = $stride * $h
$bytes = New-Object byte[] $len
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $len)

$visited = New-Object bool[] ($w * $h)
$stack = New-Object System.Collections.Generic.Stack[int]

# Seed every border pixel.
for ($x = 0; $x -lt $w; $x++) {
    $stack.Push($x) | Out-Null                      # top row (y=0)
    $stack.Push((($h - 1) * $w) + $x) | Out-Null    # bottom row
}
for ($y = 0; $y -lt $h; $y++) {
    $stack.Push($y * $w) | Out-Null                 # left col (x=0)
    $stack.Push(($y * $w) + ($w - 1)) | Out-Null    # right col
}

$cleared = 0
while ($stack.Count -gt 0) {
    $p = $stack.Pop()
    if ($visited[$p]) { continue }
    $visited[$p] = $true

    $x = $p % $w
    $y = [int]($p / $w)
    $o = ($y * $stride) + ($x * 4)   # B,G,R,A

    $b = $bytes[$o]; $g = $bytes[$o + 1]; $r = $bytes[$o + 2]
    $mx = [Math]::Max($r, [Math]::Max($g, $b))
    $mn = [Math]::Min($r, [Math]::Min($g, $b))
    if ((($mx - $mn) -gt $SatTol) -or ($mx -lt $MinLight)) { continue }  # not background -> stop

    $bytes[$o + 3] = 0   # make transparent
    $cleared++

    if ($x -gt 0)        { $n = $p - 1;  if (-not $visited[$n]) { $stack.Push($n) | Out-Null } }
    if ($x -lt $w - 1)   { $n = $p + 1;  if (-not $visited[$n]) { $stack.Push($n) | Out-Null } }
    if ($y -gt 0)        { $n = $p - $w; if (-not $visited[$n]) { $stack.Push($n) | Out-Null } }
    if ($y -lt $h - 1)   { $n = $p + $w; if (-not $visited[$n]) { $stack.Push($n) | Out-Null } }
}

[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $len)
$bmp.UnlockBits($data)
$bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

"$([System.IO.Path]::GetFileName($OutPath)) : ${w}x${h}, cleared $cleared px to transparent"
