#version 420

// original https://www.shadertoy.com/view/4dcyW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float triagle(float fracttime, float scale, float shift)
{
    return (abs(fracttime * 2.0 - 1.0) - shift) * scale;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv.x += (resolution.y - resolution.x)/resolution.y * 0.5;

    float dist = length(uv-vec2(0.5,0.5));

    float glow = max(0.0, 1.0 - dist * 1.15);
    glow =  glow * glow * glow;  
    float smoth = dist- 0.315;  
    
    float divisions = 6.0;
    float divisionsShift= 0.5;
    float progressTime =  uv.y;
    
    progressTime += 0.5;
        
    
    float pattern = triagle(fract(progressTime* 20.0), 2.0/  divisions, divisionsShift)- (-uv.y + 0.26) * 0.85;
 
 
    float sunOutline = smoothstep( 0.0,-0.015,max(smoth, -pattern)) ;
    glow = min(glow, 0.325);
    
    vec3 inisdeColor = mix(vec3(sunOutline * 4.0, 0.0, sunOutline * 0.2),
                           vec3(sunOutline, sunOutline * 1.1, 0.0), uv.y);
    
    vec3 col = inisdeColor + vec3(glow * 1.5, glow * 0.3, glow * (sin(time)+ 1.0)) * 1.1;

    glFragColor = vec4(col,1.0);
}
