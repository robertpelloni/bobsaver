#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backBuffer;

out vec4 glFragColor;

// based on the tuto here : http://www.karlsims.com/rd.html

vec2 cell(vec2 fragCoord, vec2 pixel)
{  
    vec2 uv = fract((fragCoord + pixel) / resolution);
    return texture2D(backBuffer, uv).rg;
}

vec2 laplacian2D(vec2 fragCoord) 
{
    float st = 1.;
    return 
        cell(fragCoord, vec2(0., -st)) * .2 +
        cell(fragCoord, vec2(0., st)) * .2 +
        cell(fragCoord, vec2(st, 0.)) * .2 +
        cell(fragCoord, vec2(-st, 0.)) * .2 +
        cell(fragCoord, vec2(-st, -st)) * .05 +
        cell(fragCoord, vec2(-st, st)) * .05 +
        cell(fragCoord, vec2(st, -st)) * .05 +
        cell(fragCoord, vec2(st, st)) * .05 -
        cell(fragCoord, vec2(0., 0.));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution;
    
    if(time<1. || mouse.x < .01 || mouse.y > .99)
    {
    glFragColor = vec4(1,0,0,1);
    vec2 uvc = (gl_FragCoord.xy*2.-resolution)/min(resolution.x,resolution.y);
        if (abs(length(uvc)-.5)<0.1)
            glFragColor += vec4(1)*max(0., -.5+cos(atan(uvc.x, uvc.y)*61.));
    }
    else
    {
        vec2 diffusionCoef = vec2(1,.5);
        float feedCoef = 0.055 + max(0., cos(time))*0.001/(0.000001+distance(mouse, uv));
        float killCoef = 0.061;
        
        vec2 ab = cell(gl_FragCoord.xy, vec2(0,0));
        vec2 lp = laplacian2D(gl_FragCoord.xy);
        
        float reaction = ab.x * ab.y * ab.y;
        vec2 diffusion = diffusionCoef * lp;
        float feed = feedCoef * (1. - ab.x);
        float kill = (feedCoef + killCoef) * ab.y;
        
        ab += diffusion + vec2(feed - reaction, reaction - kill);
        
        glFragColor = vec4(ab,0.0,1.0);
    }
}
