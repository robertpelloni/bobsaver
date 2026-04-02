#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wsl3D2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define getBit(num,bit)float( num>>bit & 1)

const int[] barrela = int[](0,8194,8194,8194,8194,8194,8194,8194,8194,0);
const int[] barrelb = int[](4088,4100,16385,8188,24573,24573,8188,16385,4100,4088);
const int[] barrelc = int[](0,4088,8188,16385,0,0,16385,8188,4088,0);

const int[] dunka = int[](16777200,14,2017,16515523,16515552,15730624,2494208,1013760,1044480,516096,3719168,491520,196608);
const int[] dunkb = int[](0,0,129024,198204,26128,116736,12709888,12615680,3145728,7864320,458752,0,0);
const int[] dunkc = int[](0,16777200,16646174,63488,235520,929792,1572864,3145728,4194304,0,0,0,0);

const int[] oila = int[](0,0,0,3508,0,0,0,0,0,0,0,0,0,0,0,0);
const int[] oilb = int[](16384,8192,8192,8192,8192,32766,8192,11996,10968,11992,8192,32766,8192,8192,8192,16384);
const int[] oilc = int[](49151,24574,24574,21066,24574,0,24574,20770,21798,20774,24574,0,24574,24574,24574,49151);

const int[] oilFire0a = int[](7356,6604,10716,2405,4814,1048,64,4);
const int[] oilFire0b = int[](4248,4296,8644,0,4290,1048,64,0);
const int[] oilFire1a = int[](3292,7900,6340,96,8288,96,1088,0);
const int[] oilFire1b = int[](1176,5256,6208,32,8288,96,1088,0);

const int[] enemy0a = int[](1008,1564,3078,6147,6291,6291,6146,11270,3100,3688,2992,4912,1632,5184,128,2048);
const int[] enemy0b = int[](0,480,1016,1804,1540,1540,1548,824,992,402,64,16384,4,256,0,0);
const int[] enemy0c = int[](0,0,0,240,360,360,496,192,0,0,0,0,0,0,0,0);
const int[] enemy1a = int[](496,2044,1550,3078,3222,3222,3076,1548,3928,5104,9632,48,144,8,8720,0);
const int[] enemy1b = int[](0,0,496,920,776,776,824,496,160,0,4,4096,8192,32,0,0);
const int[] enemy1c = int[](0,0,0,96,96,96,192,0,0,0,0,0,0,0,0,0);

const int[] princess0a = int[](46,3196,6652,16380,8188,16380,32764,32766,4094,1016,30,255,496,10744,8184,16368,4092,6398,12799,510,255,126);
const int[] princess0b = int[](0,0,124,1472,7964,7292,12796,26620,4088,1016,28,252,496,504,456,384,0,0,0,0,0,0);
const int[] princess0c = int[](0,124,384,572,224,9088,19968,6146,6,0,2,3,0,0,48,112,124,62,91,30,0,0);
const int[] princess1a = int[](3584,7176,12,0,0,0,0,0,0,0,0,0,0,20480,15360,31744,7936,12672,25408,960,510,252);
const int[] princess1b = int[](0,0,3600,16382,14397,903,4080,4088,2040,2032,7164,3096,2032,1008,912,768,0,0,0,0,0,0);
const int[] princess1c = int[](0,0,12768,16384,1986,7288,12,0,4,28684,0,0,0,0,96,224,248,124,182,60,0,0);

const int[] mario0a = int[](0,0,7792,8184,8184,1536,0,32,0,0,0,0,0,1020,480,0);
const int[] mario0b = int[](240,16608,24576,24576,24576,480,2016,1984,0,3614,1224,1168,960,0,0,0);
const int[] mario0c = int[](0,0,0,0,0,6168,2076,8,508,480,823,878,48,0,0,0);
const int[] mario1a = int[](0,0,1592,8184,4088,2032,368,448,384,0,0,0,0,0,2040,960);
const int[] mario1b = int[](7168,14336,14342,6,6,2,1548,7736,7776,0,7228,2448,2336,1920,0,0);
const int[] mario1c = int[](0,0,0,0,0,24576,28803,24583,3,1016,960,1646,1756,96,0,0);

const int[] kongL0a = int[](393088,188096,90944,0,0,32768,32786,32781,16408,8207,4225,2366,183,191,287,42,0,0,7,60,96,192,192,131303,65663,455,254406,1536206,1998855,1955843,503808,122880);
const int[] kongL0b = int[](131072,73984,40064,32736,32752,32760,32749,32754,16359,8176,3966,1729,3912,3904,3808,8149,16383,65535,262136,524224,2097028,4194094,8388356,8257280,8322944,4129336,3932216,2654256,94232,139276,16391,3);
const int[] kongL0c = int[](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,27,17,59,24,0,0,1,1,0,0,0,0);
const int[] kongL1a = int[](0,0,8318976,7798784,3670016,0,262217,262162,262249,262175,196855,49659,92,60,92,248,3584,4096,8255,524512,262400,197120,33280,25407,4600,1855,1842,882,61,24,0,0);
const int[] kongL1b = int[](0,0,65536,585728,522240,1048448,262070,262125,262038,262112,65288,15876,16291,131011,262051,524039,1044991,1044479,1040320,524032,261666,64887,31778,7168,3591,192,192,128,194,103,63,31);
const int[] kongL1c = int[](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,31,221,136,477,192,0,0,8,13,0,0,0,0);

const int[] kongR0a = int[](0,0,1983,119,14,0,4784144,2359312,4915216,8126480,7831648,7324032,1900544,1966080,1900544,1015808,14336,1024,8258048,229384,16400,8288,8320,8282880,1033216,8286208,2519040,2580480,6160384,786432,0,0);
const int[] kongR0b = int[](0,0,64,1928,4080,65528,3604448,6029280,3473376,262112,556928,1064448,6487552,6422464,6488032,7372784,8374264,8387576,130552,32752,2244576,7823232,2236160,7168,7354368,98304,98304,32768,2195456,7536640,8257536,8126464);
const int[] kongR0c = int[](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8126464,6127616,557056,6144000,98304,0,0,524288,5767168,0,0,0,0);
const int[] kongR1a = int[](65488,114080,90944,0,0,128,2359424,5767296,786688,7864832,4228096,4081664,7766016,8290304,8142848,2752512,0,0,7340032,1966080,196608,98304,98304,7569440,8323136,7454720,3261408,3770228,7340220,6295004,1776,960);
const int[] kongR1b = int[](32,16960,40064,261888,524032,1048320,6029056,2621184,7601664,523264,4159488,4304896,620544,96256,243712,5635072,8388096,8388480,1048544,131056,1114108,3833854,1081343,32735,65471,925822,917534,393354,788288,1573408,7340288,6291456);
const int[] kongR1c = int[](0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6291456,7077888,4456448,7208960,786432,0,0,4194304,4194304,0,0,0,0);

// I wanted to move this function to the define function but something wrong. I'll take a look later.
float SpriteNxN(int sprite,vec2 p, int wmax)
{
    float bounds = float(all(lessThan(p,vec2(wmax,1))) && all(greaterThanEqual(p,vec2(0,0))));
    return getBit(sprite,int((float(wmax-1) - p.x)+p.y)) * bounds;
}

vec3 Block(vec3 col, vec2 uv, vec2 p)
{
    int wmax = 16;
    float dc = SpriteNxN(65535,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(65535,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(33667,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(50886,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(27756,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(14392,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(65535,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(65535,floor(uv-p),wmax);
    col = mix(col,vec3(0.894, 0.000, 0.341),dc );
    return col;
}

vec3 Lader(vec3 col, vec2 uv, vec2 p)
{
    int wmax = 8;
    uv.y = mod(uv.y,8.0);
    float dc = SpriteNxN(129,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(129,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(129,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(255,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(129,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(129,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(129,floor(uv-p),wmax);
    p.y += 1.0; dc += SpriteNxN(255,floor(uv-p),wmax);
    col = mix(col,vec3(0.0,1.0,1.0),dc );
    return col;
}

vec3 Barrel(vec3 col, vec2 uv, vec2 p)
{
    int wmax = 15;
    float h = 9.0;
    float dc = SpriteNxN(barrela[0],floor(uv-p),wmax);
    for(int i = 1; i<10; i++){
        p.y += 1.0; dc += SpriteNxN(barrela[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(0,0,0.7372549),dc );
    
    p.y -= h;
    dc = SpriteNxN(barrelb[0],floor(uv-p),wmax);
    for(int i = 1; i<10; i++){
        p.y += 1.0; dc += SpriteNxN(barrelb[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(0.6588235,0.0627451,0),dc );
        
    p.y -= h;
    dc = SpriteNxN(barrelc[0],floor(uv-p),wmax);
    for(int i = 1; i<10; i++){
        p.y += 1.0; dc += SpriteNxN(barrelc[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(1,0.627451,0.2666667),dc );
    
    return col;
}

vec3 DunkSB(vec3 col, vec2 uv, vec2 p)
{
    int wmax = 24;
    float h = 12.0;
    float dc = SpriteNxN(dunka[0],floor(uv-p),wmax);
    for(int i = 1; i<13; i++){
        p.y += 1.0; dc += SpriteNxN(dunka[i],floor(uv-p),wmax);
    }    
    col = mix(col,vec3(0.6588235,0.0627451,0),dc );
    
    p.y -= h;
    dc = SpriteNxN(dunkb[0],floor(uv-p),wmax);
    for(int i = 1; i<13; i++){
        p.y += 1.0; dc += SpriteNxN(dunkb[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(0.8941177,0,0.345098),dc );
        
    p.y -= h;
    dc = SpriteNxN(dunkc[0],floor(uv-p),wmax);
    for(int i = 1; i<13; i++){
        p.y += 1.0; dc += SpriteNxN(dunkc[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(1.0),dc );
    
    return col;
}

vec3 Oil(vec3 col, vec2 uv, vec2 p)
{
    int wmax = 16;
    float h = 15.0;
    float dc = SpriteNxN(oila[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(oila[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(0.9058824,0,0.3529412),dc );
    
    p.y -= h;
    dc = SpriteNxN(oilb[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(oilb[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(0,0.9058824,0.8392157),dc );
        
    p.y -= h;
    dc = SpriteNxN(oilc[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(oilc[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(0,0.3411765,0.9686275),dc );
    
    return col;
}

vec3 OilFire(vec3 col, vec2 uv, vec2 p)
{    
    int frame = mod(time,0.3) >= 0.15? 0 : 1;
    
    int wmax = 16;
    float h = 7.0;
    float dc = SpriteNxN(frame == 0?oilFire0a[0]:oilFire1a[0],floor(uv-p),wmax);
    for(int i = 1; i<8; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?oilFire0a[i]:oilFire1a[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(0.9686275,0.2196078,0),dc );
    
    p.y -= h;
    dc = SpriteNxN(frame == 0?oilFire0b[0]:oilFire1b[0],floor(uv-p),wmax);
    for(int i = 1; i<8; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?oilFire0b[i]:oilFire1b[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(1,0.8745098,0.6470588),dc );
    return col;
}

vec3 Enemy(vec3 col, vec2 uv, vec2 p)
{    
    int frame = mod(time,0.2) >= 0.1? 0 : 1;
    
    int wmax = 15;
    float h = 15.0;
    float dc = SpriteNxN(frame == 0?enemy0a[0]:enemy1a[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?enemy0a[i]:enemy1a[i],floor(uv-p),wmax);
    }    
    col = mix(col,vec3(0.972549, 0.2196078, 0),dc );
    
    p.y -= h;
    dc = SpriteNxN(frame == 0?enemy0b[0]:enemy1b[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?enemy0b[i]:enemy1b[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(1.0, 0.8784314, 0.6588235),dc );
        
    p.y -= h;
    dc = SpriteNxN(frame == 0?enemy0c[0]:enemy1c[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?enemy0c[i]:enemy1c[i],floor(uv-p),wmax);
    }
    col = mix(col,vec3(1.0),dc );
    return col;
}

vec3 Princess(vec3 col, vec2 uv, vec2 p)
{
    int frame = mod(time,1.0) >= 0.5? 0 : 1;
    
    int wmax = 15;
    float h = 21.0;
    float dc = SpriteNxN(frame == 0?princess0a[0]:princess1a[0],floor(uv-p),wmax);
    for(int i = 1; i<22; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?princess0a[i]:princess1a[i],floor(uv-p),wmax);
    } 
    col = mix(col,vec3(1,0.627451,0.2666667),dc );
    
    p.y -= h;
    dc = SpriteNxN(frame == 0?princess0b[0]:princess1b[0],floor(uv-p),wmax);
    for(int i = 1; i<22; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?princess0b[i]:princess1b[i],floor(uv-p),wmax);
    } 
    col = mix(col,vec3(0.972549,0.4705882,0.972549),dc );
        
    p.y -= h;
    dc = SpriteNxN(frame == 0?princess0c[0]:princess1c[0],floor(uv-p),wmax);
    for(int i = 1; i<22; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?princess0c[i]:princess1c[i],floor(uv-p),wmax);
    } 
    col = mix(col,vec3(1.0),dc );
    return col;
}

vec3 Mario(vec3 col, vec2 uv, vec2 p, vec3 bcol)
{
    int frame = mod(time,0.6) >= 0.3? 0 : 1;
    
    int wmax = 15;
    float h = 15.0;
    float dc = SpriteNxN(frame == 0?mario0a[0]:mario1a[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?mario0a[i]:mario1a[i],floor(uv-p),wmax);
    } 
    col = mix(col,bcol,dc );
    
    p.y -= h;
    dc = SpriteNxN(frame == 0?mario0b[0]:mario1b[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?mario0b[i]:mario1b[i],floor(uv-p),wmax);
    } 
    col = mix(col,vec3(0,0,0.7372549),dc );
        
    p.y -= h;
    dc = SpriteNxN(frame == 0?mario0c[0]:mario1c[0],floor(uv-p),wmax);
    for(int i = 1; i<16; i++){
        p.y += 1.0; dc += SpriteNxN(frame == 0?mario0c[i]:mario1c[i],floor(uv-p),wmax);
    } 
    col = mix(col,vec3(0.9411765,0.8156863,0.6901961),dc );
    return col;
}

vec3 Kong(vec3 col, vec2 uv, vec2 p, int type)
{
    int frame = mod(time,1.0) >= 0.5? 0 : 1;
    
    int wmax = 23;
    float h = 31.0;
    float dc = SpriteNxN(type == 0?(frame == 0?kongL0a[0]:kongL1a[0]):(frame == 0?kongR0a[0]:kongR1a[0]),floor(uv-p),wmax);
    for(int i = 1; i<32; i++){
        p.y += 1.0; dc += SpriteNxN(type == 0?(frame == 0?kongL0a[i]:kongL1a[i]):(frame == 0?kongR0a[i]:kongR1a[i]),floor(uv-p),wmax);
    } 
    col = mix(col,vec3(0.9411765,0.8156863,0.6901961),dc );
    
    p.y -= h;
    dc = SpriteNxN(type == 0?(frame == 0?kongL0b[0]:kongL1b[0]):(frame == 0?kongR0b[0]:kongR1b[0]),floor(uv-p),wmax);
    for(int i = 1; i<32; i++){
        p.y += 1.0; dc += SpriteNxN(type == 0?(frame == 0?kongL0b[i]:kongL1b[i]):(frame == 0?kongR0b[i]:kongR1b[i]),floor(uv-p),wmax);
    } 
    col = mix(col,vec3(0.6588235,0.0627451,0),dc );
        
    p.y -= h;
    dc = SpriteNxN(type == 0?(frame == 0?kongL0c[0]:kongL1c[0]):(frame == 0?kongR0c[0]:kongR1c[0]),floor(uv-p),wmax);
    for(int i = 1; i<32; i++){
        p.y += 1.0; dc += SpriteNxN(type == 0?(frame == 0?kongL0c[i]:kongL1c[i]):(frame == 0?kongR0c[i]:kongR1c[i]),floor(uv-p),wmax);
    }
    col = mix(col,vec3(1.0),dc );
    return col;
}

float reverseAnimate(float t, float d) {
    float scene = mod(time,t);
    float res = scene<(t*0.5) ? scene*(d/(t*0.5)) : d-((scene-(t*0.5))*(d/(t*0.5)));
    return res;
}

void main(void)
{
    vec2 dotSize = vec2(256,128); // debug:vec2(64,32)
    vec3 col = vec3(0.0); // bg color
    vec2 uv = ( gl_FragCoord.xy /resolution.xy ) * dotSize; // N x N pixel resolution
    vec2 uvRef = uv;
    
    // dunk sb bg
    uvRef.y -= time*6.0;
    uvRef.y = mod(uvRef.y,13.0);
    uvRef.x = mod(uvRef.x,24.0);
    col = DunkSB(col,uvRef, vec2(0.0,0.0));
    col = col*0.25;
    uvRef = uv;
    
    // draw block
    uvRef.x = mod(uvRef.x,16.0);
    col = Block(col,uvRef, vec2(0.0,0.0));
    uvRef = uv;
    
    if(uvRef.x>=16.0 && uvRef.x<240.0){
        uvRef.x = mod(uvRef.x,16.0);
        col = Block(col,uvRef, vec2(0.0,29.0));
    }
    uvRef = uv;
        
    if(uvRef.x>=48.0 && uvRef.x<208.0){
        uvRef.x = mod(uvRef.x,16.0);
        col = Block(col,uvRef, vec2(0.0,58.0));
    }
    uvRef = uv;
            
    if(uvRef.x>=80.0 && uvRef.x<176.0){
        uvRef.x = mod(uvRef.x,16.0);
        col = Block(col,uvRef, vec2(0.0,87.0));
    }
    uvRef = uv;
    
    // draw lader
    if(uvRef.y>=8.0 && uvRef.y<29.0){
        col = Lader(col,uvRef, vec2(20.0,0.0));
        col = Lader(col,uvRef, vec2(228.0,0.0));
    }
    if(uvRef.y>=37.0 && uvRef.y<58.0){
        col = Lader(col,uvRef, vec2(52.0,0.0));
        col = Lader(col,uvRef, vec2(196.0,0.0));
    }
    if(uvRef.y>=66.0 && uvRef.y<87.0){
        col = Lader(col,uvRef, vec2(84.0,0.0));
        col = Lader(col,uvRef, vec2(164.0,0.0));
    }
        
    // draw enemy
    col = Enemy(col,uvRef, vec2(20.0+reverseAnimate(10.0,200.0),37.0));
    col = Enemy(col,uvRef, vec2(52.0+reverseAnimate(8.0,132.0),66.0));
    
    // draw kong
    vec2 kpos = vec2(105.0,95.0);
    col = Kong(col,uvRef, vec2(kpos.x,kpos.y),0);
    col = Kong(col,uvRef, vec2(23.0+kpos.x,kpos.y),1);
    
    // draw princess
    col = Princess(col,uvRef, vec2(156.0,95.0));
    
    // draw oil
    col = OilFire(col,uvRef, vec2(84.0,111.0));
    col = Oil(col,uvRef, vec2(84.0,95.0));

    // draw mario or luigi
    col = Mario(col,uvRef, vec2(mod(time,5.12)*50.0,8.0),mod(time,10.24)<5.12 ? vec3(0.972549,0.2196078,0):vec3(0.272549,0.9196078,0));
    
    // draw barrel or dunk sb
    float xstep = mod(time,2.0)*80.0;
    if(mod(time,4.0)<2.0){
        col = Barrel(col,uvRef, vec2(120.0,95.0-xstep));
    } else {
        col = DunkSB(col,uvRef, vec2(120.0,95.0-xstep));
    }
    
    // result
    glFragColor = vec4(col,1.0);
}
