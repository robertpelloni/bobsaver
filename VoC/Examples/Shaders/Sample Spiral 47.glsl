#version 420

// original https://www.shadertoy.com/view/NsGSDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

float hash21(vec2 p) {
    p = fract(p*vec2(1.34, 435.345));
    p += dot(p, p+34.23);
    return fract(p.x*p.y);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / resolution.y;
    
    uv *= 10.;
    
    float t = time;
    
    float r = length(uv);
    float theta = atan(uv.y, uv.x);
    
    float spiral1 = sin(theta + cos(r - t) * PI * 2.);
    float spiral2 = sin(theta + PI + cos(r - t) * PI * 3.3);
    // halve sin's amplitude (-1:1 -> -.5:.5)
    spiral1 /= 2.;
    spiral2 /= 2.;
    // offset sin (-.5:.5 -> 0:1)
    spiral1 += .5;
    spiral2 += .5;
    // halve again because there is 2 of them
    spiral1 /= 2.;
    spiral2 /= 2.;
    // this sharpen spiral's border
    float sm = smoothstep(.1, .4, spiral1);
    float sm2 = smoothstep(.1, .4, spiral2);
    
    vec3 blue = vec3(0.237, 0.494, 0.686);
    vec3 blue2 = vec3(0.215, 0.801, 0.731);
    vec3 orange = vec3(0.821, 0.619, 0.321);
    
    vec3 color = vec3(orange);
    
    color = mix(color, blue2, sm);
    color = mix(color, blue, sm2);
    
    // vignette
    color = mix(color, blue, smoothstep(2.7, 7.8, r));
    
    float noise = hash21(uv);
    color.r += noise * .13;
    color.g += noise * .14;
    color.b += noise * .18;
    
    color += mod(gl_FragCoord.xy.x, 2.) * .1;
    
    glFragColor = vec4(color, 1.0);
}
