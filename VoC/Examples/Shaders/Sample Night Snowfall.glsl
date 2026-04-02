#version 420

// original https://www.shadertoy.com/view/Wll3RS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Try another snow force with values in range [.1, .3]
#define SNOW_FORCE .25
#define INIT_SPEED 60.
#define AMOUNT 5.

float rand(vec2 co) { 
    return fract(sin(dot(co.xy , vec2(12.9898, 78.233))) * 43758.5453);
} 

float snow( vec2 uv, float size, float speed, float timeOfst, float blur, float time)
{       
    vec2 ruv = uv*size  + .05;    
    vec2 id = ceil(ruv) + speed;       
        
    float t = (time + timeOfst)*speed;
        
    ruv.y += t * (rand(vec2(id.x))*0.5+.5)*.1;
    vec2 guv = fract(ruv) - 0.5;
    
    ruv = ceil(ruv);    
    float g = length(guv);
    
    float v = rand(ruv)*0.5;
    v *= step(v, clamp(SNOW_FORCE, .1, .3));
    float m = smoothstep(v,v - blur, g);    
    
    return m;        
}

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;

    float m = 0.;       
    
    float fstep = .1/AMOUNT;
    for(float i=-1.0; i<=0.0; i+=fstep){
        vec2 iuv = uv + vec2(cos(uv.y*2. + i*20. + time*.5)*.1, 0.);
        float size = (i*.5+.5) * 40. + 10.;
        m += snow(iuv + vec2(i*.1, 0.), size, INIT_SPEED + i*5., i*10., .3 + i*.25, time) * abs(1. - i);
    }
    
    vec3 col = vec3(0.5) * m;
        
    glFragColor = vec4(col,1.0);
}
