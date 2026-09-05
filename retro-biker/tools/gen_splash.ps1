# Paints the menu splash background (a cheerful platformer scene) as a 640x360
# PNG. Pure System.Drawing / GDI+, same pipeline as gen_textures.ps1. The title
# text is NOT baked in — it is drawn by the Godot UI on top so it stays crisp.
param([Parameter(Mandatory = $true)][string]$OutPath)

$cs = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public class SplashGen {
    static SolidBrush B(int r,int g,int b){ return new SolidBrush(Color.FromArgb(255,r,g,b)); }
    static SolidBrush Ba(int a,int r,int g,int b){ return new SolidBrush(Color.FromArgb(a,r,g,b)); }
    static Pen P(int w,int r,int g,int b){ return new Pen(Color.FromArgb(255,r,g,b), w); }

    static void Cloud(Graphics g,int x,int y){
        var w=Ba(238,255,255,255);
        g.FillEllipse(w,x,y,60,34);
        g.FillEllipse(w,x+28,y-12,52,42);
        g.FillEllipse(w,x+58,y,60,34);
        g.FillEllipse(w,x+18,y+8,86,28);
    }
    static void QBlock(Graphics g,int x,int y,int s){
        int pad=Math.Max(2,s/11);
        g.FillRectangle(B(60,32,4),x,y,s,s);
        g.FillRectangle(B(250,172,30),x+pad,y+pad,s-2*pad,s-2*pad);
        g.FillRectangle(B(255,214,96),x+pad,y+pad,s-2*pad,pad);
        g.FillRectangle(B(200,112,0),x+pad,y+s-2*pad,s-2*pad,pad);
        using(var f=new Font("Arial",s*0.5f,FontStyle.Bold))
        using(var sf=new StringFormat()){
            sf.Alignment=StringAlignment.Center; sf.LineAlignment=StringAlignment.Center;
            g.DrawString("?",f,B(255,250,225),new RectangleF(x,y-1,s,s),sf);
        }
    }
    static void Platform(Graphics g,int x,int y){
        int w=72,h=18;
        g.FillRectangle(B(34,40,55),x,y,w,h);
        g.FillRectangle(B(132,146,170),x+2,y+2,w-4,h-4);
        g.FillRectangle(B(192,206,226),x+2,y+2,w-4,4);
        var pen=P(3,95,205,235);
        for(int i=0;i<3;i++){ int cx=x+20+i*14; g.DrawLines(pen,new Point[]{new Point(cx,y+5),new Point(cx+6,y+9),new Point(cx,y+13)}); }
    }
    static void Pipe(Graphics g,int x,int y){
        int gw=56;
        g.FillRectangle(B(60,170,70),x+6,y+20,gw-12,360-(y+20));
        g.FillRectangle(B(120,210,120),x+10,y+20,8,360-(y+20));
        g.FillRectangle(B(40,140,55),x+gw-16,y+20,8,360-(y+20));
        g.FillRectangle(B(60,170,70),x,y,gw,22);
        g.FillRectangle(B(120,210,120),x+4,y+3,gw-8,6);
        g.DrawRectangle(P(2,30,100,45),x,y,gw,22);
    }
    static void Spikes(Graphics g,int x,int y){
        for(int i=0;i<5;i++){
            int cx=x+i*16+8;
            var pts=new Point[]{ new Point(cx-8,y), new Point(cx+8,y), new Point(cx,y-22) };
            g.FillPolygon(B(205,210,220), pts);
            g.DrawLine(P(2,150,156,168), cx+7,y-1, cx,y-20);
            g.DrawLine(P(1,90,96,110), cx-8,y, cx,y-22);
        }
        g.FillRectangle(B(90,96,108),x,y,80,6);
    }
    static void Player(Graphics g,int x,int y){
        g.FillEllipse(B(40,110,225),x,y-46,40,46);
        g.FillEllipse(B(80,150,250),x+4,y-44,30,20);
        g.FillEllipse(B(255,255,255),x+7,y-34,11,13);
        g.FillEllipse(B(255,255,255),x+22,y-34,11,13);
        g.FillEllipse(B(20,20,30),x+11,y-30,5,7);
        g.FillEllipse(B(20,20,30),x+26,y-30,5,7);
        g.FillEllipse(B(30,40,60),x+2,y-8,16,10);
        g.FillEllipse(B(30,40,60),x+22,y-8,16,10);
    }

    public static string Make(string path){
        int W=640,H=360;
        var bmp=new Bitmap(W,H,PixelFormat.Format32bppArgb);
        using(var g=Graphics.FromImage(bmp)){
            g.SmoothingMode=SmoothingMode.AntiAlias;
            using(var sky=new LinearGradientBrush(new Rectangle(0,0,W,H),Color.FromArgb(91,184,255),Color.FromArgb(207,238,255),LinearGradientMode.Vertical))
                g.FillRectangle(sky,0,0,W,H);
            g.FillEllipse(Ba(70,255,240,180),470,6,156,156);
            g.FillEllipse(B(255,236,150),506,28,86,86);
            g.FillEllipse(B(255,248,205),520,40,58,58);
            Cloud(g,52,70); Cloud(g,250,34); Cloud(g,452,58);
            // rolling hills
            g.FillEllipse(B(150,210,120),-60,250,300,320);
            g.FillEllipse(B(150,210,120),360,238,360,340);
            g.FillEllipse(B(110,190,95),100,300,300,220);
            g.FillEllipse(B(110,190,95),410,300,320,220);
            // ground
            g.FillRectangle(B(122,80,45),0,330,W,30);
            g.FillRectangle(B(98,176,72),0,322,W,10);
            // props
            Platform(g,56,250); QBlock(g,80,210,30);
            QBlock(g,520,220,34);
            Pipe(g,556,298);
            Player(g,150,322);
            Spikes(g,224,330);
        }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
        return "splash.png written: " + path;
    }
}
'@

Add-Type -TypeDefinition $cs -ReferencedAssemblies System.Drawing
[SplashGen]::Make($OutPath)
