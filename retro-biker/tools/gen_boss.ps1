# Paints the Critter King boss frames (walk x2, charge, hurt) as 96x96 PNGs with
# real alpha. Feet sit at the canvas bottom so the enemy feet-at-origin convention
# (see critter.gd) places him on the ground. Pure System.Drawing / GDI+.
param([Parameter(Mandatory = $true)][string]$Dir)

$cs = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public class BossGen {
    static SolidBrush B(int r,int g,int b){ return new SolidBrush(Color.FromArgb(255,r,g,b)); }
    static Pen P(int w,int r,int g,int b){ return new Pen(Color.FromArgb(255,r,g,b), w); }

    // frame: 0 walk0, 1 walk1, 2 charge, 3 hurt
    static void King(Graphics g, int frame){
        var foot=B(70,45,25);
        if(frame==1){ g.FillEllipse(foot,30,83,18,13); g.FillEllipse(foot,50,83,18,13); }
        else { g.FillEllipse(foot,22,83,18,13); g.FillEllipse(foot,58,83,18,13); }
        // body: a tall rounded dome. No crown — the smooth head must read as a
        // safe place to stomp, not a spiky hazard. Raised so the visible head top
        // lines up with the collision box (the player lands on the head, not above it).
        g.FillEllipse(B(70,40,20),12,10,72,80);
        g.FillEllipse(B(150,95,55),16,14,64,74);
        g.FillEllipse(B(185,130,85),26,20,44,26);
        g.FillEllipse(B(205,165,120),34,52,28,26);
        // eyes
        g.FillEllipse(B(255,255,255),32,40,16,18);
        g.FillEllipse(B(255,255,255),48,40,16,18);
        if(frame==3){
            var xp=P(2,30,25,25);
            g.DrawLine(xp,34,42,46,56); g.DrawLine(xp,46,42,34,56);
            g.DrawLine(xp,50,42,62,56); g.DrawLine(xp,62,42,50,56);
        } else {
            int dy = (frame==2)?44:48;
            g.FillEllipse(B(25,20,20),37,dy,7,9);
            g.FillEllipse(B(25,20,20),53,dy,7,9);
        }
        // angry brows
        var brow=P(6,60,33,15);
        int by=(frame==2)?38:36;
        g.DrawLine(brow,31,by-3,48,by+4);
        g.DrawLine(brow,65,by-3,48,by+4);
        // mouth
        if(frame==2){
            g.FillEllipse(B(150,40,40),40,62,16,16);
            g.FillRectangle(B(255,255,255),40,62,16,4);
        } else if(frame==3){
            g.FillEllipse(B(120,35,35),42,64,12,10);
        } else {
            g.DrawArc(P(3,70,40,20),38,64,20,12,180,180);
        }
    }

    static void Frame(string path,int frame){
        var bmp=new Bitmap(96,96,PixelFormat.Format32bppArgb);
        using(var g=Graphics.FromImage(bmp)){ g.SmoothingMode=SmoothingMode.AntiAlias; King(g,frame); }
        bmp.Save(path,ImageFormat.Png); bmp.Dispose();
    }

    public static string GenAll(string dir){
        Frame(Path.Combine(dir,"boss_walk1.png"),0);
        Frame(Path.Combine(dir,"boss_walk2.png"),1);
        Frame(Path.Combine(dir,"boss_charge.png"),2);
        Frame(Path.Combine(dir,"boss_hurt.png"),3);
        return "boss_walk1/2 + boss_charge + boss_hurt written to " + dir;
    }
}
'@

Add-Type -TypeDefinition $cs -ReferencedAssemblies System.Drawing
[BossGen]::GenAll($Dir)
