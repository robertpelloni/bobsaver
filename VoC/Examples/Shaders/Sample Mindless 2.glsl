#version 420

// original https://www.shadertoy.com/view/WdV3Wz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand (vec2 p)
{
    return fract(sin(dot(p.xy,vec2(12389.1283,8941.1283)))*12893.128933);
}

float noise(in vec2 v)
{
    vec2 i=floor(v);
    vec2 f = fract(v);
    
    float a = rand(i);
    float b = rand(i+vec2(1,0));
    float c = rand(i+vec2(0,1));
    float d = rand(i+vec2(1,1));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y;
}

float fbm(vec2 p)
{
    float ret = 0.;
    float amp = .4;
    int oct = 8;
    for(int i=0;i<oct;i++)
    {
        ret+=amp*noise(time+20.*p);
        p*=2.;
        amp*=.5;
    }
    
    return ret+.15;
}

float map(in vec3 p)
{    
    return length(p)-1.+cos(sin(time-p.y*20.)/5.+sin(time-p.z*20.)/5.+sin(time-p.x*20.)/5.);
}

void main(void)
{
    vec2 p = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

   
    float time = time/4.;
    vec3 ro = vec3(sin(time)*2.,1.,cos(time));
    vec3 ta = vec3(0.0,0.,0.);
    vec3 ww = normalize(ta-ro);
    vec3 uu =normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = normalize(cross(uu,ww));
        
       vec3 rd = normalize(p.x*uu+p.y*vv+2.*ww);
    vec3 pos = ro;
    float m = 1000.0;
    float t = 0.0;
    for(int i=0;i<128;i++)
    {
        pos = ro+rd*t;
        
           float h = map(pos);
        m= min(m,h);
        if(h<.00001)break;
        
        t+=h/30.;
    }
    
    
    float d = 400.;
    vec3 col =vec3(m)*vec3(fbm(pos.xy/d),fbm(pos.yz/d),fbm(pos.zx/d))*(2.5-(length(p)-.1));
    glFragColor = vec4(pow(col,vec3(1.5)),1.0);
}
