#version 420

// original https://www.shadertoy.com/view/3sBXRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x, resolution.y) * 2.;

    vec2 uva = vec2(atan(uv.x, uv.y), length(uv)*5.);
    
    float n = 5.;
    
    //if (mouse*resolution.xy.z > 0.)
        n = floor(mouse.x*resolution.x/resolution.x * 20.) - 10.;
    
    float t = time;
    
    float st = 0.2;
    
    //if (mouse*resolution.xy.z > 0.)
        st = mouse.y*resolution.y/resolution.y;
        
    uva.x += uva.y * st;

    float lim = mix(1., 20., sin(t * 0.2) * 0.5 + 0.5);
    
    uva.y *= smoothstep(uva.y-lim, uva.y, sin(uva.x * floor(n))*0.5+0.5);
    
    uva.x /= 6.28318 / n;
    
    uva = abs(fract(uva)-0.5);
    uva.y += 0.5;
    
    glFragColor.x = 1.4-max(abs(uva.x)+uva.y,-uva.y);
    glFragColor.y = 1.4-length(uva);
    glFragColor.z =  1.4-max(abs(uva.x),abs(uva.y));
    glFragColor.w = 1.0;
}
