#version 420

// original https://www.shadertoy.com/view/XdXXzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592;

float col=0.;

float sine(float v){
    return (sin((v-0.5)*PI)+1.)/2.;
}

float unsine(float v){
    float modulator = floor(mod(v+0.5,2.));
    return abs(sin(v*PI))*(modulator*-2.+1.)/2.+modulator;
}

vec2 bounce(vec2 v){
    //vec2 c = vec2(0.3,0.2);
    
    float t = time/5.;
    
    vec2 c = vec2(sin(t*1.7),cos(t));
    float r = 1.;
    
    vec2 d = v-c;
    vec2 tv = normalize(d)*r;
    float ratio = clamp(((r-length(d))/r),0.,1.);
    ratio = sine(ratio*8.);
    //ratio*=10.
    
    
    float force=0.2;
    
    //if(ratio>=1.) ratio=0.;
    ratio*=float(ratio<1.);
    
    v+=tv*ratio*force;
        
    col=ratio;
    
    return v;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy / resolution.y)-resolution.xy/resolution.y;
    
    uv=bounce(uv);
    
    float sq=50.;
    float r=0.5;
    
    float ang = (atan(uv.x,uv.y)/PI+1.)*12.;
    
    float v = (length(uv))*sq+ang;
    float it = mod(v/2.-clamp(0.,1.,mod(time,2.))-floor(time/2.),6.);
    
    vec3 color = vec3(sine(v));
    
    float colorintensity=length(uv);
    
    vec3 rco = vec3(0.);
    
    rco.r = -abs(it-0.5)+0.5;
    rco.g = -abs(it-1.5)+0.5;
    rco.b = -abs(it-2.5)+0.5;
    
    rco = clamp(rco,-0.4,1.);
    
    color*=rco+vec3(1.-colorintensity);
    
    //color += vec3(col);
    //vec3 color = vec3(col);
    
    glFragColor = vec4(color,1.0);
}
