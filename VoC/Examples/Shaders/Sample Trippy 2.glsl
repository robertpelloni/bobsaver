#version 420

// original https://www.shadertoy.com/view/WtjfRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(x,y,z) smoothstep(x,y,z)
#define PI (3.1415)

// UTIL FUNCTIONS //////////////////////////////////////

// https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 inverseColor(vec3 col)
{
    return vec3(1.0-col.r,1.0-col.g,1.0-col.b);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rand(float c){
    vec2 co = vec2(c,c);
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float xor(float a,float b)
{
    return a*(1.0-b)+b*(1.0-a);
}

vec3 xor(vec3 a,vec3 b)
{
    return vec3(xor(a.x,b.x),xor(a.y,b.y),xor(a.z,b.z));
}

// -------------b
// |            |
// |            |
// a-------------
float inRect(vec2 x ,vec2 a, vec2 b)
{
    return x.x > a.x && x.x < b.x && x.y > a.y && x.y < b.y ? 1.0 : 0.0;
}

////////////////////////////////////////

// Wraps uv around tunnel
// https://www.shadertoy.com/view/4djBRm
vec2 tunnel(vec2 uv, float size, float time)
{
    vec2 p  = -1.0 + (2.0 * uv);
    float a = atan(p.y, p.x);
    float r = sqrt(dot(p, p));
    return vec2(a / PI, time + (size / r));
}

vec2 rotate(vec2 uv, float angle)
{
    uv -= 0.5;
    mat2 mat = mat2(vec2(cos(angle), sin(angle)),vec2(-sin(angle), cos(angle)));
    return mat*uv + 0.5;
}

float diamondMask(vec2 uv,float ds,float lb)
{
    vec2 iuv = vec2(1.0-uv.x,1.0-uv.y); // inverse uv
    
    float db1 = S(0.5+ds,0.5+ds-lb,(iuv.x+uv.y)/2.0);
    float db2 = S(0.5+ds,0.5+ds-lb,(uv.x+iuv.y)/2.0);
    float db3 = S(0.5+ds,0.5+ds-lb,(uv.x+uv.y)/2.0);
    float db4 = S(0.5+ds,0.5+ds-lb,(iuv.x+iuv.y)/2.0);
    return min(min(min(db1,db2),db3),db4);
}

float shapeMask(vec2 uv,float layer,float t)
{
    // Rotation
    float rotAngle = 3.0*sin(t*0.5 + 2.0*PI*rand(layer));
    rotAngle = min(PI/2.0,rotAngle);
    rotAngle = max(0.0,rotAngle);
    
    uv = rotate(uv,rotAngle);
    
    // Some variables
       float lt = 0.1; // line thickness
    float lt2 = lt/2.0;
    float lb = 0.01; // line blur
    
    // Vertical line
    float vl = S(0.5-lt2-lb,0.5-lt2,uv.x);
    vl = min(vl,S(0.5+lt2,0.5+lt2-lb,uv.x));
    
    // Horizontal line
    float lta = lt2; // line thickness with AR
    float lba = lb;
    float hl = S(0.5-lta-lba,0.5-lta,uv.y);
    hl = min(hl,S(0.5+lta,0.5+lta-lba,uv.y));
    
    float c = max(hl,vl); // Cross
    
    // Center shape
    float bds = 0.2; // big diamond size
    float sds = bds-lt; // small diamond size
    float bd = diamondMask(uv,bds,lb); // Big diamond
    float sd = diamondMask(uv,sds,lb); // Small diamoind
    float cs = clamp(bd-sd,0.0,1.0); // center shape
    
    float rs = 0.25;//center size
    vec4 cr = vec4(rs,rs,1.0-rs,1.0-rs);  // center rect (a,b)
    float inCenter = inRect(uv,cr.xy,cr.zw);
    
    float m = mix(c+cs,cs,inCenter);
    
    m = clamp(m,0.0,1.0);
    
    return m;
}

vec3 shapeColor(vec2 uv,float t,float layer)
{
    vec3 hsv = vec3(rand(layer)+ 0.3*sin(0.1*t),0.7/(layer/2.0),0.8+0.3*sin(t));
    return hsv2rgb(hsv);
}

vec3 drawLayer(vec2 uv,vec2 suv,float layer, float opacity,float t)
{
    float mask = shapeMask(uv,layer,t);
    vec3 color = shapeColor(suv*layer,t,layer);
    return color*mask*opacity;
}

void main(void)
{
    // Sound data
    int tx = int(0.8*512.0);
    float fft  = 0.0; //texelFetch( iChannel0, ivec2(tx,0), 0 ).x;
    float wave = 0.0; //texelFetch( iChannel0, ivec2(tx,1), 0 ).x;
    
    vec2 suv = gl_FragCoord.xy/resolution.xy; // screen uv
    
    vec2 guv = suv;
    float t = 0.3*time;
       
    guv.x += 0.05*sin(0.3*time);
    guv.y += 0.05*cos(0.3*time);
    
    float dc = sqrt(length(guv-vec2(0.5,0.5))); // distance to center
    
    guv = tunnel(guv,0.1*(1.0+sin(t)),0.2*t-0.5*(1.0+sin(t)));
    
    vec2 uv = 5.0*guv;
    vec2 id = floor(uv);
    uv = fract(uv);
    
    vec3 col = vec3(0.0);
    
    
    for(float i=1.0;i<=4.0;i++)
    {
        vec2 layerUV = fract(uv + rand(i));
        layerUV = fract(layerUV+0.1*time*rand(i));
        //col = xor(col,inverseColor(col)*drawLayer(layerUV,suv,i,2.0/i,time));
        col += inverseColor(col)*drawLayer(layerUV,suv,i,2.0/i,time);
    }
    
    vec3 icol = inverseColor(col);
    float bgMask = S(0.8,0.85,max(max(icol.r,icol.g),icol.b));
       vec3 bgColor = hsv2rgb(vec3(0.7+0.2*sin(t*0.1 + 0.1*wave),0.9,0.8));
    
    
    float fadeEffect = (1.0+sin(0.2*t))/2.0;
    fadeEffect = min(3.0*fadeEffect,1.0);
    
    float distanceShadow = clamp(2.0*dc,0.0,1.0);
    col = mix(bgMask*bgColor,bgMask*bgColor+col,fadeEffect)*distanceShadow;
    
    glFragColor = vec4(col,1.0);
}
