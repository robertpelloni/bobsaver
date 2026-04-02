#version 420

// original https://www.shadertoy.com/view/mtsGDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(in vec2 p){
    return fract(sin(dot(p, vec2(21.952, 38.783))) * 67845.8521);
}

// Modified 2D Value noise by iq: https://www.shadertoy.com/view/lsf3WH
float noise(in vec2 p){ 
    p *= .35;
    vec2 f = fract(p);
    vec2 i = floor(p);
    vec2 o = vec2(0.,1.);
    
    return mix( mix( hash(i + o.xx), 
                     hash(i + o.yx), f.x),
                mix( hash(i + o.xy), 
                     hash(i + o.yy), f.x), f.y);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x * 16.;
    float screenScale = length(fwidth(uv));
    
    uv.y += time;
    uv = vec2(uv.x - uv.y, uv.x + uv.y); // "Rotate" UV 45°
    
    vec2 cell = floor(uv);
    float direction = round(noise(cell));
    
    // Offset only in current cell direction.
    vec2 neighborOffset = sign(fract(uv) - .5) * vec2(1. - direction, direction); 
    float neighborDir = round(noise(cell + neighborOffset));

    vec2 clampDir = vec2(max(direction, neighborDir), 1.-min(direction, neighborDir));
    uv = (fract(uv) - .5) * clampDir;
    
    float loopMask = 1. - clamp((abs(length(uv) - .25 ) - .1) / screenScale, 0.,1.);
    vec3 color = mix(vec3(.2,.9,.5), vec3(1.,.2,.6), direction) * loopMask;
    glFragColor = vec4(color, 0.);
}
