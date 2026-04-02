#version 420

//--- Kancolle BG (Hex) v2.0 ---
// by Catzpaw 2016

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//mouse speed
#define MICKEY 8.

//map settings
#define SEED   173.
#define SCALE  0.06
#define COMPLEX 7.
#define TONES   4.
#define GAMMA  0.90
#define GAIN  -0.60

//color settings
#define HUE 0.22
#define SATURATION 0.
#define BRIGHTNESS 0.

//hex settings
#define HEXSIZE 0.1000
#define BORDER  0.1200
#define SPACING 1.0000

//utilities
vec3 hsv2rgb(vec3 hsv){return ((clamp(abs(fract(hsv.x+vec3(0.,2./3.,1./3.))*2.-1.)*3.-1.,0.,1.)-1.)*hsv.y+1.)*hsv.z;}
float hash(vec2 p){return fract(sin(SEED+p.x*69.1+p.y*95.7)*6.5);}
vec2 hash2(vec2 p){return vec2(hash(p*154.7),hash(73.3*p.yx+22.2))-.5;}

//2d perlin noise
vec2 acc=vec2(1,0);
vec2 noise2(vec2 v){vec2 p=floor(v);vec2 f=fract(v);f=f*f*(3.-2.*f);
    vec2 n=mix(mix(hash2(p),hash2(p+acc.xy),f.x),mix(hash2(p+acc.yx),hash2(p+acc.xx),f.x),f.y);return n;}
vec2 pnoise(vec2 v){vec2 n=vec2(0);float s=1.;v*=SCALE;
    for(int i=0;i<4;i++){n+=abs(noise2(v)+.5 )*s;v*=2.;s*=.5;}return n;}

//hex map
float tone(vec2 v){return floor(clamp(pow(pnoise(v*COMPLEX).x,1./GAMMA)+GAIN,0.,1.)*TONES)/TONES;}
float shift(inout vec2 v){float s=mod(floor(v.y),2.)/2.;v=vec2(v.x+s,v.y);return s;}
vec3 hex(vec2 uv){
    uv.y*=1.1547;
        vec2 g=uv,f=uv,p;
    float s=shift(g);
    shift(f);
    f=fract(f);
        float k=2.,d,c,v;
    for(float x=-1.;x<=0.;x++)
    for(float y=-1.;y<=1.;y++){
        p=vec2(x,y);
        if(s==0.)v=tone(floor(g+p+vec2(abs(y),0)));
        else v=tone(floor(g+p));
        p.x+=abs(y)/2.;
        p+=.5-f;
        p=abs(p);
        d=max(p.x*2.,p.y*1.5+p.x);
        if(k>d){c=v;k=d;}
    }
    return hsv2rgb(vec3(c+HUE,c*SATURATION,clamp(c+BRIGHTNESS,0.,1.)))*smoothstep(abs(1.-k*SPACING)*10.,0.,BORDER);
}

void main(void){
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y);
    uv+=(time*0.02-.5)*MICKEY;
    uv/=HEXSIZE;
    vec3 finalColor=hex(uv);
    glFragColor=vec4(finalColor,1);
}
