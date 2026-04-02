#version 420

// original https://www.shadertoy.com/view/WlGSD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(float x){
    return fract(sin(x)*1e3);
}

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float noise(float st) {
    float i = floor(st);
    float f = fract(st);

    float u = f*f*(3.0-2.0*f);

    float n = mix(random(i), random(i +1.0), u );
    
    return n ;
}

float noise2(vec2 st) {
    vec2 i = floor(st+time*0.5);
    vec2 f = fract(st+time*0.5);

    vec2 u = f*f*(3.0-2.0*f);

    float n = mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
    return n *0.1 +0.5 ;
}

vec3 box(vec2 st, float s){
    st *= s;
    vec2 uvf = fract(st);
    vec2 uvi = floor(st);
    
    float l = step(0.1,uvf.x);
    float l2 = step(0.1,uvf.y);
    float l3 = step(0.1,1.0-uvf.x);
    float l4 = step(0.1,1.0-uvf.y);
    
    float pct = l*l2*l4;
    float pct1 = l2*l3*l4;
    float pct2 =  l*l2*l3*l4;
    return vec3(pct, pct1, pct2);
}

vec3 index(vec2 st, float s){
    st *= s;
    vec2 uvf = fract(st);
    vec2 uvi = floor(st);
    float index = uvi.x + (uvi.y * s) ;
    vec2 uv = vec2(index) ;
    return  vec3(uvi.x*1.0, uvi.y*1.0,index) ;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec2 line(vec2 uv, float a, float offset, float totalline){
    float a1 = 1.0- step (a, mod(uv.y+offset, totalline));
    float a2 = 1.0- step (a, mod(uv.x+offset, totalline));
    return vec2(a1,a2);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    uv *= 0.8;
   

    //uv += noise2(uv);
    uv.y += sin( ((uv*rotate2d(0.5)).x-time*0.5)*3.14*1.5) *0.03 ;
    uv *=rotate2d(0.3);
    
    vec3 color = vec3(0.1);
    
    

    //tile;
    float s = 64.0;
    vec3 index = index(uv,s);
    vec2 uv2 = index.xy;
    
    
    
   
    vec3 colorD = vec3(230,0,18)/255.0;
    vec3 colorE = vec3(25,223,215)/255.0;
    vec3 colorB = vec3(25,223,192)/255.0;
    vec3 colorC = vec3(223,223,120)/255.0;
    vec3 g1 = vec3(0.1,0.1,0.1);
    vec3 g2 = vec3(0.4,0.4,0.4);
    vec3 g3 = vec3(0.9,0.9,0.9);
    vec3 g4 = vec3(0.8,0.8,0.8);
    vec3 b = vec3(0.518,0.756,0.930);
    b = vec3(0.18,0.18,0.2730);
    
    float bace = step(1.0, mod(index.z, 3.0));
    vec3 bgc = vec3(bace) ;
    
    
    
    
    
    float total = 64.;
    
    vec2 l1 = line(index.xy, 2.0, 8.0, total);
    vec3 border = g4* l1.x*bace;
    vec3 sto = g4*l1.y *(1.0-bace);
    
    vec2 l2 = line(index.xy, 2.0, 16.0, total);
    border += colorC*l2.x*bace;
    sto += colorC* l2.y *(1.0-bace);
    
     vec2 l3 = line(index.xy, 2.0, 24.0, total);
    border += g4*l3.x*bace;
    sto += g4* l3.y *(1.0-bace);
    
     vec2 l4 = line(index.xy, 32.0, 0.0, total);
    border += colorD*l4.x*bace;
    sto += colorD* l4.y *(1.0-bace);
    
    vec2 l5 = line(index.xy, 32.0, 32.0, total);
    border += g1*l5.x*bace;
    sto += g1* l5.y *(1.0-bace);
    
    vec2 l6 = line(index.xy, 2.0, 50.0, total);
    border -= g3*l6.x*bace;
    sto -= g3* l6.y *(1.0-bace);
    
    
    
    float pat = box(uv,s).x *step(2.0, mod(index.z-2.0, 3.0));
    pat += box(uv,s).y *step(2.0, mod(index.z-0.0, 3.0));
    pat += box(uv,s).z *step(2.0, mod(index.z-1.0, 3.0));
    
    
    color = border+sto;
    color *= vec3(pat);
    
    
    
    

    // Output to screen
    glFragColor = vec4(color,1.0);
}

