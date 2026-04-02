#version 420

// original https://www.shadertoy.com/view/4lcXWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define TAU 6.28318530718

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float cells = 8.0;
    
    vec2 local = fract( uv * cells );
    vec2 global = floor( uv * cells );
    
    float v;
    float o = 0.25;
    
    vec3 c1 = vec3(0.9, 0.35, 0.3);
    vec3 c2 = vec3(0.0, 0.1, 0.3);
    vec3 c3 = vec3(0.9, 0.9, 0.8);
    vec3 c4 = vec3(0.9, 0.95, 0.95);
    
    float s1 = o - 0.01;
    float s2 = o + 0.01;
    float s3 = 1.0 - o - 0.01;
    float s4 = 1.0 - o + 0.01;

    if( mod( global.y, 2.0) != 0.0) {
        if( mod( global.x, 2.0) == 0.0 ) {
            v = smoothstep(s1, s2, abs(o + local.y - local.x))
              - smoothstep(s3, s4, abs(o + local.y - local.x));
        } else {
            v = smoothstep(s1, s2, abs(o + (local.y + local.x) - 1.0))
              - smoothstep(s3, s4, abs(o + (local.y + local.x) - 1.0));        
        }
    } else {
        if( mod( global.x, 2.0) == 0.0 ) {
            v = smoothstep(s1, s2, abs(o + 1.0 - (local.y + local.x)))
              - smoothstep(s3, s4, abs(o + 1.0 - (local.y + local.x)));
        } else {
            v = smoothstep(s1, s2, abs(o + local.x - local.y))
              - smoothstep(s3, s4, abs(o + local.x - local.y));
        }
        
    }
    
    float w = step( 0.5, (sin( 3.0 * cells * uv.x * TAU) + 1.0) / 2.0 );
    float x = step( 0.5, (sin( 1.5 * cells * uv.x * TAU) + 1.0) / 2.0 );
    
    float b = w > 0.0 ? v : 1.0 - v;
    
    
    
    vec3 c = x > 0.0 ? mix( c1, c3, sin(time * 0.19) )  : mix( c2, c4, sin(time * 0.13));
    
    glFragColor = vec4(c + b,1.0);
}
