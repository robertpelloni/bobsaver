#version 420

// original https://www.shadertoy.com/view/3s3XDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define CS(a) vec2(cos(a), sin(a))

float h11(float x)
{
    return fract(sin(x*x*2.2)*824.324)*2. -1.;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    vec2 muv = (mouse*resolution.xy.xy - .5*resolution.xy)/resolution.y;
    
    
       vec2 puv = vec2(length(uv), atan(uv.y, uv.x));
    
    vec2 noise = puv.x*vec2(cos(puv.y + cos(puv.x*20. + time)*.7),
                            sin(puv.y + sin(puv.x*20. + time)*.7));
    vec2 noise2 = vec2(cos(uv.y*16. + time)*.15,
                       sin(uv.x*9.+ time)*.2);
    
    
       uv += mix(noise, noise2, sin(time*.4)*.5 + .5);
    
    float w = 0.4;
    uv*=w*5.;
    float r = 5.*smoothstep(-.9, 1.5, -.8+ abs(.2 - length(mod(uv*1.0, w) - w/2.)));
    float g = 5.*smoothstep(-.9, 1.5, -.8+ abs(.2 - length(mod(uv*1.05, w) - w/2.)));
    float b = 5.*smoothstep(-.9, 1.5, -.8+ abs(.2 - length(mod(uv*1.10, w) - w/2.)));
    
    // Time varying pixel color
    vec3 col = 5.*vec3(r, g, b);

    // Output to screen
    glFragColor = vec4(col,1.0);
    
    //glFragColor = vec4(h11(gl_FragCoord.x ), 0., 0.,0.);
}
