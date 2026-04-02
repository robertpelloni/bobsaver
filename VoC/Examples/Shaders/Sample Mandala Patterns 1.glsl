#version 420

// original https://www.shadertoy.com/view/WlfGWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define WHITE vec3(1.0)
#define BLACK vec3(0.0)
#define RED vec3(1.0, 0.,0.)
#define BLUE vec3(0.,0.,1.)
#define YELLOW vec3(1.,1.,0.)
#define HANADA vec3(39., 146., 195.)/255.0

const float PI = 3.14159265359;

float rand(in vec2 n){
    return fract(sin(dot(n, vec2(12.9898, 78.233)))*43758.5453);
}
float rand(in float n){
    return rand(vec2(n));
}
float noise(in float x){
    float f = fract(x);
    float i = floor(x);
    //return mix(rand(i), rand(i+1.0), f);
    return mix(rand(i), rand(i+1.0), f*f*(3.0-2.0*f));
    //return mix(rand(i), rand(i+1.0), smoothstep(0., 1., f));
}
float noise(in vec2 st){
    vec2 f = fract(st);
    vec2 i = floor(st);
    
    float a = rand(i);
    float b = rand(i + vec2(1.,0.));
    float c = rand(i + vec2(0.,1.));
    float d = rand(i + vec2(1.,1.));
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix(a,b,u.x)+
                (c-a)*u.y*(1.0-u.x) +
                (d-b)*u.x*u.y;
}

mat2 rotate(in float r){
    float c=cos(r), s=sin(r);
    return mat2(c, -s, s, c);
}
float usin(in float x){
    return 0.5+0.5*sin(x);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = (gl_FragCoord.xy*2.0 - resolution.xy)/min(resolution.x, resolution.y);

    float t = 0.2*time;
    for(int i=0;i<5;i++){
        float a = atan(uv.x, uv.y);
        float b = floor(5.0+4.*fract(time*0.25));
        a *= b / (2.0*PI);
        a = abs(fract(a*0.5-b*0.5)*2.0-1.0);
        a *= (2.0*PI)/b;
        uv = length(uv)*vec2(sin(a+t*0.7), cos(a+t*0.8));
        uv -= vec2(0.2+1.8*usin(time*0.3), 0.);
        uv = fract(uv)*2.0-1.0;
    }
    
    float v = noise(uv);
    
    vec3 col1 = mix(RED, YELLOW, usin(time*0.4));
    vec3 col2 = mix(BLACK, HANADA, usin(time*0.9));
    vec3 col = mix(col1, col2, v);
    
    col *= clamp(length(uv), 0., 1.);
    
    uv = (gl_FragCoord.xy*2.0 - resolution.xy)/min(resolution.x, resolution.y);
    col *= exp(-0.8*length(uv));
    col += 1.1*usin(time*0.4)*exp(-1.2*length(uv));
    
    glFragColor = vec4(col,1.0);
}
