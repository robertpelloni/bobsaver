#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Original code:
Clown.glsl
https://www.shadertoy.com/view/4tGGW1
*/

#define MAX_BLUR 12
#define STAR_SCALE 1.75
#define STAR_SPEED 1.8
#define CLOWN_SCALE 2.0
#define CLOWN_SPIN -0.2
#define CLOWN_SPEED 0.1

#define CLOWN_SIZE vec2(32,32)

//Run length encoding helpers 
#define L(v,l) if(i >= addr){data = v;}addr+=l;
#define P(v)   if(i >= addr){data = v;}addr++;

//Palette index definition.
#define PAL(i,r,g,b,a) if(idx == i){return vec4(r,g,b,a)/255.0;}

float pi = acos(-1.0); // atan(1.0)*4.0;
float tau = radians(360.0); // atan(1.0)*8.0;

//2D rotation matrix from angle.
mat2 Rotate(float a)
{
     return mat2(cos(a),sin(a),-sin(a),cos(a));
}

//Clown sprite palette
vec4 ClownPalette(int idx)
{
    PAL(0x00, 0x00, 0x00, 0x00, 0x00) PAL(0x01, 0x00, 0x01, 0x00, 0xFF);
    PAL(0x02, 0x16, 0x00, 0xFF, 0xFF) PAL(0x03, 0xA4, 0x04, 0x05, 0xFF);
    PAL(0x04, 0xB0, 0x03, 0x00, 0xFF) PAL(0x05, 0xC4, 0x00, 0x00, 0xFF);
    PAL(0x06, 0x00, 0x39, 0x59, 0xFF) PAL(0x07, 0xDE, 0x00, 0x04, 0xFF);
    PAL(0x08, 0xFD, 0x00, 0x00, 0xFF) PAL(0x09, 0xCF, 0x00, 0x97, 0xFF);
    PAL(0x0A, 0x0A, 0x53, 0x82, 0xFF) PAL(0x0B, 0x3A, 0x3F, 0xE1, 0xFF);
    PAL(0x0C, 0x08, 0x5F, 0x98, 0xFF) PAL(0x0D, 0x54, 0x55, 0x53, 0xFF);
    PAL(0x0E, 0x9D, 0x2E, 0xFF, 0xFF) PAL(0x0F, 0xFF, 0x26, 0x33, 0xFF);
    PAL(0x10, 0xFF, 0x30, 0x97, 0xFF) PAL(0x11, 0x2B, 0x75, 0xA2, 0xFF);
    PAL(0x12, 0xE3, 0x6B, 0x08, 0xFF) PAL(0x13, 0xF4, 0x7E, 0x14, 0xFF);
    PAL(0x14, 0x6E, 0x97, 0xB1, 0xFF) PAL(0x15, 0xF9, 0x89, 0x8C, 0xFF);
    PAL(0x16, 0xA1, 0xA3, 0xA0, 0xFF) PAL(0x17, 0xF4, 0x97, 0x36, 0xFF);
    PAL(0x18, 0xFF, 0x99, 0x34, 0xFF) PAL(0x19, 0xF5, 0xB6, 0x71, 0xFF);
    PAL(0x1A, 0x00, 0xFF, 0xFF, 0xFF) PAL(0x1B, 0xD8, 0xCB, 0xCC, 0xFF);
    PAL(0x1C, 0xFF, 0xC9, 0x95, 0xFF) PAL(0x1D, 0xFF, 0xBF, 0xFD, 0xFF);
    PAL(0x1E, 0xFF, 0xFF, 0x01, 0xFF) PAL(0x1F, 0xF9, 0xFC, 0xF8, 0xFF);
    
    return vec4(0);
}

//Run length encoded 32x32 clown sprite.
vec4 Clown(vec2 uv)
{
    vec2 size = CLOWN_SIZE;
    uv = floor(uv * size);
    
    if(all(greaterThanEqual(uv, vec2(0))) && all(lessThan(uv, size)))
    {
        uv.y = size.y - uv.y - 1.0;
        int i = int(uv.y * size.x + uv.x);
        int data = 0;
        int addr = 0;
        
        L(0,41)L(19,3)L(0,7)L(19,3)L(0,18)L(19,6)L(0,3)L(19,6)L(0,16)L(19,6)L(27,5)L(19,6)L(0,15)L(19,4);
        L(18,2)P(27)P(30)P(31)P(30)P(27)L(18,2)L(19,4)L(0,16)P(19)L(18,3)L(27,2)P(2)P(30)P(2)L(27,2)L(18,3);
        P(19)L(0,18)L(18,3)P(27)P(31)P(30)P(31)P(30)P(31)P(27)L(18,3)L(0,21)P(22)P(27)P(31)P(21)P(15)P(21);
        P(31)P(27)P(23)L(0,22)P(22)P(0)L(27,2)P(31)P(21)P(31)L(27,2)L(0,24)P(22)P(0)P(23)L(27,3)P(23)L(0,25);
        P(20)P(3)P(29)L(25,3)P(29)P(3)P(20)L(0,22)P(20)P(17)P(29)P(3)L(31,3)P(3)P(29)P(17)P(20)L(0,20)P(3);
        P(8)P(17)P(10)P(29)P(3)P(31)P(3)P(29)P(10)P(17)P(8)P(3)L(0,18)P(3)L(29,2)P(17)P(12)L(3,5)P(12)P(17);
        L(29,2)P(3)L(0,17)P(3)L(8,2)P(17)P(10)P(13)L(8,4)P(10)P(17)L(8,2)P(3)L(0,16)P(3)P(29)L(3,2)P(17);
        P(12)P(13)L(29,4)P(12)P(17)L(3,2)P(29)P(3)L(0,15)P(3)P(8)P(3)P(0)P(17)P(10)L(8,5)P(10)P(17)P(0)P(3);
        P(8)P(3)L(0,15)L(3,3)P(0)P(17)P(10)L(29,5)P(10)P(17)P(0)L(3,3)L(0,15)P(23)P(28)P(25)P(23)P(17)P(10);
        L(8,4)P(1)P(10)P(17)P(23)P(25)P(28)P(23)L(0,15)P(23)P(28)L(25,2)P(12)L(29,4)P(1)P(26)P(1)P(12)L(25,3);
        P(23)L(0,15)P(23)P(25)P(28)P(23)P(3)P(17)P(10)L(6,3)P(10)P(17)P(3)P(23)L(25,2)P(23)L(0,14)L(3,2);
        L(23,2)P(7)L(8,5)L(1,3)P(8)P(7)L(23,2)L(3,2)L(0,13)P(3)P(8)L(7,2)L(8,11)L(7,2)P(8)P(3)L(0,13)P(3);
        L(8,2)L(7,5)P(5)L(7,4)P(5)L(7,3)P(8)P(3)L(0,13)P(3)L(8,2)L(7,2)L(5,4)L(7,3)P(5)L(4,2)P(5)P(7)P(8);
        P(3)L(0,14)L(3,2)L(5,4)L(4,7)L(5,2)L(3,2)L(0,16)L(3,3)L(4,4)P(3)P(4)P(5)L(3,5)L(0,19)L(3,10)L(0,23);
        L(3,4)P(0)L(3,4)L(0,17)L(3,4)P(0)L(3,2)L(30,2)P(3)P(0)P(3)L(30,2)L(3,2)P(0)L(3,4)L(0,10)P(3)P(11);
        P(14)P(9)P(16)L(3,2)P(15)P(24)P(30)P(3)P(0)P(3)P(30)P(24)P(15)L(3,2)P(16)P(9)P(14)P(11)P(3)L(0,8);
        L(3,12)P(0)L(3,12)L(0,4);
        
        return ClownPalette(data);
    }
    
    return vec4(0);
}

//Overly complicated starfield effect.
vec4 StarPlane(vec2 uv, float dens, int blur)
{
    dens = 1.0 - dens;
    vec2 res = resolution.xy; 
    uv = floor(uv * res);
    
    vec4 acc = vec4(0.0);
    
    for(int i = -MAX_BLUR;i <= MAX_BLUR;i++)
    {
        if(i >= -blur && i <= blur)
        {
vec4 n = acc;             // vec4 n = step(dens, texture2D(iChannel1, (uv + vec2(i,0))/res));

        
            acc += n * (cos(pi * float(i) / float(blur + 1)) * 0.5 + 0.5);
        }
    }
    
    return acc;
}

vec4 StarField(vec2 uv)
{
    vec4 scroll = STAR_SPEED * vec4(1.0, 0.25, 0.11, 0.0625) * time;
    scroll = floor(scroll * resolution.x)/resolution.x;
    
    float s = 0.0;
    
    s += StarPlane(uv / STAR_SCALE + vec2(scroll.x,0), 0.001, 12).r * 1.00;
    s += StarPlane(uv / STAR_SCALE + vec2(scroll.y,0), 0.001, 6).g * 0.75;
    s += StarPlane(uv / STAR_SCALE + vec2(scroll.z,0), 0.005, 3).b * 0.50;
    s += StarPlane(uv / STAR_SCALE + vec2(scroll.w,0), 0.005, 2).a * 0.25;
    
    return vec4(vec3(s), 1.0);
}

void main(void)
{
    vec2 res = resolution.xy / resolution.y;
    vec2 uv = gl_FragCoord.xy / resolution.y;
    uv -= res/2.0;
    
    vec4 color = vec4(0,0,0,1);
    
    vec2 cluv = uv;
    
    cluv.x -= mix(0.4, -res.x*0.75, 1.0/(1.0 + time * CLOWN_SPEED));
    cluv.y -= 0.1 * sin(time * 0.2);
    cluv *= Rotate(time * CLOWN_SPIN);
    cluv *= CLOWN_SCALE;
    cluv += 0.5;
    
    vec4 stars = StarField(uv);
    vec4 clown = Clown(cluv);
    
    color.rgb = mix(color.rgb, stars.rgb, stars.a);
    color.rgb = mix(color.rgb, clown.rgb, clown.a);    
    
    glFragColor = vec4(color);
}
