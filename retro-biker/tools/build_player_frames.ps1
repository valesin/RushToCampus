# Builds the player animation frame set from raw generated images.
# For each frame: (optionally) strip a solid/checkerboard background via
# border flood-fill, crop to the largest opaque blob, then composite every
# frame onto a common canvas (horizontally centered, feet bottom-aligned) so
# they animate without jitter. Runs entirely in compiled C# (fast, reliable
# under Windows PowerShell 5.1 where System.Drawing is available).
param(
    [Parameter(Mandatory = $true)][string[]]$InPaths,
    [Parameter(Mandatory = $true)][string[]]$OutPaths,
    [Parameter(Mandatory = $true)][bool[]]$Strip
)

$cs = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class FrameBuilder {
    class Frame { public byte[] px; public int w; public int h; }

    static byte[] Load(string path, out int w, out int h, out int stride) {
        using (var src = new Bitmap(path)) {
            w = src.Width; h = src.Height;
            using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
                using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, w, h);
                var rect = new Rectangle(0, 0, w, h);
                var data = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
                stride = data.Stride;
                var bytes = new byte[stride * h];
                Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
                bmp.UnlockBits(data);
                return bytes;
            }
        }
    }

    static void StripBg(byte[] px, int w, int h, int stride, int satTol, int minLight) {
        var visited = new bool[w * h];
        var st = new Stack<int>();
        for (int x = 0; x < w; x++) { st.Push(x); st.Push((h - 1) * w + x); }
        for (int y = 0; y < h; y++) { st.Push(y * w); st.Push(y * w + (w - 1)); }
        while (st.Count > 0) {
            int p = st.Pop();
            if (visited[p]) continue;
            visited[p] = true;
            int x = p % w, y = p / w, o = y * stride + x * 4;
            int b = px[o], gg = px[o + 1], r = px[o + 2];
            int mx = Math.Max(r, Math.Max(gg, b)), mn = Math.Min(r, Math.Min(gg, b));
            if (mx - mn > satTol || mx < minLight) continue;
            px[o + 3] = 0;
            if (x > 0) { int n = p - 1; if (!visited[n]) st.Push(n); }
            if (x < w - 1) { int n = p + 1; if (!visited[n]) st.Push(n); }
            if (y > 0) { int n = p - w; if (!visited[n]) st.Push(n); }
            if (y < h - 1) { int n = p + w; if (!visited[n]) st.Push(n); }
        }
    }

    static Frame LargestBlobCrop(byte[] px, int w, int h, int stride, int alphaThresh) {
        var opaque = new bool[w * h];
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
                if (px[y * stride + x * 4 + 3] >= alphaThresh) opaque[y * w + x] = true;
        var visited = new bool[w * h];
        var st = new Stack<int>();
        int bestSize = 0, bMinX = 0, bMaxX = 0, bMinY = 0, bMaxY = 0;
        for (int s = 0; s < w * h; s++) {
            if (visited[s] || !opaque[s]) continue;
            st.Push(s);
            int size = 0, minX = w, maxX = -1, minY = h, maxY = -1;
            while (st.Count > 0) {
                int p = st.Pop();
                if (visited[p]) continue;
                visited[p] = true;
                int x = p % w, y = p / w;
                size++;
                if (x < minX) minX = x; if (x > maxX) maxX = x;
                if (y < minY) minY = y; if (y > maxY) maxY = y;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++) {
                        int nx = x + dx, ny = y + dy;
                        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                        int q = ny * w + nx;
                        if (!visited[q] && opaque[q]) st.Push(q);
                    }
            }
            if (size > bestSize) { bestSize = size; bMinX = minX; bMaxX = maxX; bMinY = minY; bMaxY = maxY; }
        }
        int cw = bMaxX - bMinX + 1, ch = bMaxY - bMinY + 1;
        var f = new Frame { w = cw, h = ch, px = new byte[cw * ch * 4] };
        for (int y = 0; y < ch; y++)
            for (int x = 0; x < cw; x++) {
                int so = (bMinY + y) * stride + (bMinX + x) * 4, dpo = (y * cw + x) * 4;
                f.px[dpo] = px[so]; f.px[dpo + 1] = px[so + 1]; f.px[dpo + 2] = px[so + 2]; f.px[dpo + 3] = px[so + 3];
            }
        return f;
    }

    static void Save(byte[] px, int w, int h, string outPath) {
        using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
            var rect = new Rectangle(0, 0, w, h);
            var data = bmp.LockBits(rect, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            int stride = data.Stride;
            for (int y = 0; y < h; y++)
                Marshal.Copy(px, y * w * 4, IntPtr.Add(data.Scan0, y * stride), w * 4);
            bmp.UnlockBits(data);
            bmp.Save(outPath, ImageFormat.Png);
        }
    }

    public static string Build(string[] inPaths, string[] outPaths, bool[] strip) {
        int satTol = 45, minLight = 95, alphaThresh = 128;
        var frames = new Frame[inPaths.Length];
        for (int i = 0; i < inPaths.Length; i++) {
            int w, h, stride;
            var px = Load(inPaths[i], out w, out h, out stride);
            if (strip[i]) StripBg(px, w, h, stride, satTol, minLight);
            frames[i] = LargestBlobCrop(px, w, h, stride, alphaThresh);
        }
        int canvasW = 0, canvasH = 0;
        foreach (var f in frames) { if (f.w > canvasW) canvasW = f.w; if (f.h > canvasH) canvasH = f.h; }
        var sb = new System.Text.StringBuilder();
        sb.AppendLine("canvas " + canvasW + "x" + canvasH);
        for (int i = 0; i < frames.Length; i++) {
            var f = frames[i];
            var canvas = new byte[canvasW * canvasH * 4];
            int dx = (canvasW - f.w) / 2, dy = canvasH - f.h;
            for (int y = 0; y < f.h; y++)
                for (int x = 0; x < f.w; x++) {
                    int so = (y * f.w + x) * 4;
                    int cx = dx + x, cy = dy + y, dpo = (cy * canvasW + cx) * 4;
                    canvas[dpo] = f.px[so]; canvas[dpo + 1] = f.px[so + 1]; canvas[dpo + 2] = f.px[so + 2]; canvas[dpo + 3] = f.px[so + 3];
                }
            Save(canvas, canvasW, canvasH, outPaths[i]);
            sb.AppendLine(System.IO.Path.GetFileName(outPaths[i]) + " : char " + f.w + "x" + f.h);
        }
        return sb.ToString();
    }
}
'@

Add-Type -TypeDefinition $cs -ReferencedAssemblies System.Drawing
[FrameBuilder]::Build($InPaths, $OutPaths, $Strip)
