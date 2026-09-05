# Paints the collectible pickup sprites (coin, heart) as 48x48 PNGs with real
# alpha. Animation (spin / pulse / bob) is done in code via tweens, so one frame
# each is enough. Pure System.Drawing / GDI+.
param([Parameter(Mandatory = $true)][string]$Dir)

$cs = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public class PickupGen {
    static SolidBrush B(int a,int r,int g,int b){ return new SolidBrush(Color.FromArgb(a,r,g,b)); }
    static SolidBrush B(int r,int g,int b){ return new SolidBrush(Color.FromArgb(255,r,g,b)); }
    static Pen P(int w,int r,int g,int b){ return new Pen(Color.FromArgb(255,r,g,b), w); }

    static Bitmap New(){ return new Bitmap(48,48,PixelFormat.Format32bppArgb); }

    static void Coin(string path){
        var bmp=New();
        using(var g=Graphics.FromImage(bmp)){
            g.SmoothingMode=SmoothingMode.AntiAlias;
            g.FillEllipse(B(180,140,20),2,2,44,44);       // dark rim
            g.FillEllipse(B(245,200,60),5,5,38,38);       // coin body
            g.FillEllipse(B(255,225,120),11,9,26,28);     // sheen (offset up-left)
            g.DrawEllipse(P(2,205,160,35),13,13,22,22);   // inner ring detail
            g.FillEllipse(B(230,255,255,255),15,12,9,7);  // bright highlight
            // little 4-point sparkle, top-right
            g.FillPolygon(B(255,255,255), new Point[]{
                new Point(33,12),new Point(35,16),new Point(39,18),new Point(35,20),
                new Point(33,24),new Point(31,20),new Point(27,18),new Point(31,16)});
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    static void Heart(string path){
        var bmp=New();
        using(var g=Graphics.FromImage(bmp)){
            g.SmoothingMode=SmoothingMode.AntiAlias;
            var dark=B(150,20,35); var red=B(232,48,62); var hi=B(255,170,180);
            // dark outline pass (slightly larger)
            g.FillEllipse(dark,6,6,20,20);
            g.FillEllipse(dark,22,6,20,20);
            g.FillPolygon(dark,new Point[]{ new Point(6,18), new Point(42,18), new Point(24,45) });
            // red fill (inset)
            g.FillEllipse(red,8,8,18,18);
            g.FillEllipse(red,22,8,18,18);
            g.FillPolygon(red,new Point[]{ new Point(8,19), new Point(40,19), new Point(24,42) });
            // highlight on the left lobe
            g.FillEllipse(hi,12,11,8,6);
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    public static string GenAll(string dir){
        Coin(Path.Combine(dir,"coin.png"));
        Heart(Path.Combine(dir,"heart.png"));
        return "coin.png + heart.png written to " + dir;
    }
}
'@

Add-Type -TypeDefinition $cs -ReferencedAssemblies System.Drawing
[PickupGen]::GenAll($Dir)
