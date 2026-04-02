#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tl3Wl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

void main(void)
{
        vec2 aspect = resolution.xy / resolution.y;
        vec2 p = ( 20.0 * gl_FragCoord.xy / resolution.y ) - 10.0 * aspect;
        
        float s = 0.0, t = 0.1 * time;
    
        for( int k = 1; k < 9; k++)
        {
            // adapted from Fabrice Neyret's "smoothfloor", https://www.shadertoy.com/view/4t3SD7
            float q = abs(mod(0.5 * t + 5.5, 12.0) - 6.0) - 3.5;
            float mm = floor(q);
            
            mm += smoothstep(0.0, 1.0, 10.0 * (q - mm) - 9.0) + 7.0;
            
            float th = PI * float(k)/mm;
            s += cos((2.5 + 1.5 * cos(2.0 * t)) * dot(p, vec2(cos(th), -sin(th))) + 4.5 * t) * smoothstep(-0.05, 0.0, mm - float(k));
        }
    
        s = ((int(floor(s)) & 1) == 1) ? 1.0 - fract(s): fract(s);
        vec3 col = 0.5 + 0.5 * tanh(1.0 - cos(PI * (2.0 * s + vec3(3, 1, -1)/3.0)));

        glFragColor = vec4( col, 1.0 );
}
