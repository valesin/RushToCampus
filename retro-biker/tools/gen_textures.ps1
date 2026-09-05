# Procedurally generates clean pixel-art tile textures (real alpha, no baked
# backgrounds) for the dynamic platforms. Pure System.Drawing / GDI+ so it runs
# reliably under Windows PowerShell 5.1, matching build_player_frames.ps1.
param([Parameter(Mandatory = $true)][string]$Dir)

$cs = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.IO;

public class TexGen {
    static SolidBrush B(int r,int g,int b){ return new SolidBrush(Color.FromArgb(255,r,g,b)); }
    static Pen P(int w,int r,int g,int b){ return new Pen(Color.FromArgb(255,r,g,b), w); }

    static Bitmap New(int w,int h){
        var bmp = new Bitmap(w,h,PixelFormat.Format32bppArgb);
        using(var g=Graphics.FromImage(bmp)){ g.Clear(Color.Transparent); }
        return bmp;
    }
    static Graphics Gfx(Bitmap b){
        var g=Graphics.FromImage(b);
        g.SmoothingMode = SmoothingMode.None;
        g.InterpolationMode = InterpolationMode.NearestNeighbor;
        g.PixelOffsetMode = PixelOffsetMode.Half;
        return g;
    }

    // Iconic "?" question block.
    static void QBlock(string path){
        int S=64; var bmp=New(S,S);
        using(var g=Gfx(bmp)){
            g.FillRectangle(B(60,32,4),0,0,S,S);              // dark frame
            g.FillRectangle(B(250,172,30),3,3,S-6,S-6);       // body
            g.FillRectangle(B(255,214,96),3,3,S-6,4);         // top bevel
            g.FillRectangle(B(255,214,96),3,3,4,S-6);         // left bevel
            g.FillRectangle(B(200,112,0),3,S-7,S-6,4);        // bottom shadow
            g.FillRectangle(B(200,112,0),S-7,3,4,S-6);        // right shadow
            int[] rx={7,S-15}; int[] ry={7,S-15};
            foreach(int x in rx) foreach(int y in ry){
                g.FillRectangle(B(70,40,0),x,y,8,8);          // rivet
                g.FillRectangle(B(255,222,120),x,y,3,3);      // rivet shine
            }
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            using(var f=new Font("Arial",30,FontStyle.Bold))
            using(var sf=new StringFormat()){
                sf.Alignment=StringAlignment.Center; sf.LineAlignment=StringAlignment.Center;
                g.DrawString("?",f,B(120,68,0),new RectangleF(3,2,S,S),sf);     // shadow
                g.DrawString("?",f,B(255,250,225),new RectangleF(0,-1,S,S),sf); // face
            }
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    // Cracked block that crumbles.
    static void Crumble(string path){
        int S=64; var bmp=New(S,S);
        using(var g=Gfx(bmp)){
            g.FillRectangle(B(48,38,28),0,0,S,S);
            g.FillRectangle(B(156,126,92),3,3,S-6,S-6);
            g.FillRectangle(B(188,158,120),3,3,S-6,4);
            g.FillRectangle(B(188,158,120),3,3,4,S-6);
            g.FillRectangle(B(112,86,60),3,S-7,S-6,4);
            g.FillRectangle(B(112,86,60),S-7,3,4,S-6);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            var pen=P(3,58,44,32);
            g.DrawLines(pen,new Point[]{new Point(32,4),new Point(27,22),new Point(36,38),new Point(30,60)});
            g.DrawLines(pen,new Point[]{new Point(27,22),new Point(12,28)});
            g.DrawLines(pen,new Point[]{new Point(36,38),new Point(54,42)});
            g.DrawLines(pen,new Point[]{new Point(44,6),new Point(48,20)});
            int[,] dots={{16,48},{50,16},{40,52},{20,30}};
            for(int i=0;i<4;i++) g.FillRectangle(B(96,72,52),dots[i,0],dots[i,1],3,3);
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    // Mechanical moving platform with motion chevrons.
    static void Platform(string path){
        int W=96,H=32; var bmp=New(W,H);
        using(var g=Gfx(bmp)){
            g.FillRectangle(B(34,40,55),0,0,W,H);
            g.FillRectangle(B(132,146,170),2,2,W-4,H-4);
            g.FillRectangle(B(192,206,226),2,2,W-4,6);
            g.FillRectangle(B(225,238,252),2,2,W-4,2);
            g.FillRectangle(B(82,92,112),2,H-6,W-4,4);
            int[,] bolt={{7,6},{W-12,6},{7,H-11},{W-12,H-11}};
            for(int i=0;i<4;i++){
                g.FillRectangle(B(48,54,70),bolt[i,0],bolt[i,1],5,5);
                g.FillRectangle(B(200,212,230),bolt[i,0],bolt[i,1],2,2);
            }
            g.SmoothingMode = SmoothingMode.AntiAlias;
            var pen=P(4,95,205,235);
            int[] cx={34,48,62};
            foreach(int x in cx){
                g.DrawLines(pen,new Point[]{new Point(x,9),new Point(x+7,16),new Point(x,23)});
            }
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    // Bouncy trampoline (transparent around the frame/legs).
    static void Trampoline(string path){
        int W=64,H=28; var bmp=New(W,H);
        using(var g=Gfx(bmp)){
            // mat
            g.FillRectangle(B(220,55,55),5,3,53,8);
            g.FillRectangle(B(255,130,130),7,3,49,2);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.DrawRectangle(P(2,40,40,50),5,3,53,8);
            // support bar under mat
            g.SmoothingMode = SmoothingMode.None;
            g.FillRectangle(B(60,60,72),5,11,53,3);
            // legs
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.DrawLine(P(3,60,60,72),12,14,6,25);
            g.DrawLine(P(3,60,60,72),52,14,58,25);
            // feet
            g.SmoothingMode = SmoothingMode.None;
            g.FillRectangle(B(40,40,50),3,24,8,3);
            g.FillRectangle(B(40,40,50),53,24,8,3);
            // springs
            g.SmoothingMode = SmoothingMode.AntiAlias;
            var sp=P(2,175,180,190);
            int[] sx={20,44};
            foreach(int x in sx){
                g.DrawLines(sp,new Point[]{
                    new Point(x,13),new Point(x+5,15),new Point(x,17),
                    new Point(x+5,19),new Point(x,21),new Point(x+5,23)});
            }
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    // Ground/stone tile mapped onto the slope polygons.
    static void SlopeGround(string path){
        int S=32; var bmp=New(S,S);
        using(var g=Gfx(bmp)){
            g.FillRectangle(B(190,112,50),0,0,S,S);
            g.FillRectangle(B(222,150,92),0,0,S,3);            // top highlight
            g.FillRectangle(B(150,82,34),0,S-3,S,3);           // bottom shadow
            var m=B(140,78,32);                                // mortar
            g.FillRectangle(m,0,10,S,2);
            g.FillRectangle(m,0,21,S,2);
            g.FillRectangle(m,15,3,2,7);
            g.FillRectangle(m,7,12,2,9);
            g.FillRectangle(m,23,12,2,9);
            g.FillRectangle(m,15,23,2,9);
            int[,] dots={{5,6},{26,7},{11,16},{20,26}};
            for(int i=0;i<4;i++) g.FillRectangle(B(168,96,42),dots[i,0],dots[i,1],2,2);
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    // Row of metal spikes mounted on a base.
    static void Spike(string path){
        int S=64; var bmp=New(S,S);
        using(var g=Gfx(bmp)){
            g.SmoothingMode = SmoothingMode.AntiAlias;
            for(int i=0;i<4;i++){
                int cx=i*16+8;
                var body=new Point[]{ new Point(cx-8,54), new Point(cx+8,54), new Point(cx,5) };
                g.FillPolygon(B(200,205,215), body);
                g.DrawLine(P(2,238,240,248), cx-7,53, cx,7);   // left highlight
                g.DrawLine(P(2,130,136,150), cx+7,53, cx,7);   // right shadow
                g.DrawLine(P(1,86,92,106), cx-8,54, cx,5);     // outline
                g.DrawLine(P(1,86,92,106), cx+8,54, cx,5);
            }
            g.SmoothingMode = SmoothingMode.None;
            g.FillRectangle(B(88,94,106),0,52,S,12);           // metal base
            g.FillRectangle(B(150,156,168),0,52,S,2);          // base top highlight
            g.FillRectangle(B(58,62,72),0,S-3,S,3);            // base shadow
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    public static string GenAll(string dir){
        QBlock(Path.Combine(dir,"block.png"));
        Crumble(Path.Combine(dir,"crumble.png"));
        Platform(Path.Combine(dir,"platform.png"));
        Trampoline(Path.Combine(dir,"bounce.png"));
        SlopeGround(Path.Combine(dir,"slope.png"));
        Spike(Path.Combine(dir,"spike.png"));
        return "block.png crumble.png platform.png bounce.png slope.png spike.png written to " + dir;
    }
}
'@

Add-Type -TypeDefinition $cs -ReferencedAssemblies System.Drawing
[TexGen]::GenAll($Dir)
