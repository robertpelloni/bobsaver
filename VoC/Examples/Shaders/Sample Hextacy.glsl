#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/MtKczG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Just fooling around with IQ's hexagon function
// Orion Elenzil 2018

#define PI    (3.14159265359)
#define TWOPI (2.0 * PI)

// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// { 2d cell id, distance to border, distnace to center )
vec4 hexagon( vec2 p ) 
{
    vec2 q = vec2( p.x*2.0*0.5773503, p.y + p.x*0.5773503 );
    
    vec2 pi = floor(q);
    vec2 pf = fract(q);

    float v = mod(pi.x + pi.y, 3.0);

    float ca = step(1.0,v);
    float cb = step(2.0,v);
    vec2  ma = step(pf.xy,pf.yx);
    
    // distance to borders
    float e = dot( ma, 1.0-pf.yx + ca*(pf.x+pf.y-1.0) + cb*(pf.yx-2.0*pf.xy) );

    // distance to center    
    p = vec2( q.x + floor(0.5+p.y/1.5), 4.0*p.y/3.0 )*0.5 + 0.5;
    float f = length( (fract(p) - 0.5)*vec2(1.0,0.85) );        
    
    return vec4( pi + ca - cb*ma, e, f );
}

// 2d cell ID, distance to border, distance to center
vec4 square(vec2 p) {
    p = p * 0.71;
    
    vec2 pi = floor(p + vec2(0.5));
    vec2 pf = fract(p);
    
    
    float e = 2.0 * min(abs(pf.x - 0.5), abs(pf.y - 0.5));
    // i've clearly chosen the wrong coordinate system somewhere
    float f = 1.0 * length(fract(p - vec2(0.5)) - vec2(0.5));
    return vec4(pi, e, f);   
}

vec4 shape(vec2 p) {
    if (int(time / 5.0) % 2 == 0) {
        return hexagon(p);
    }
    else {
        return square(p);
    }
}

mat2 rot(float theta) {
    float s = sin(theta);
    float c = cos(theta);
    return mat2(c, -s, s, c);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= vec2(0.5);
    uv.x /= resolution.y / resolution.x;
    vec2 uvPlain = uv;
    float t = time * 0.01;
    uv.x += cos(t) * 20.0;
    uv.y += sin(t) * 20.0;
    uv *= 4.0;
    
    vec4 h = shape(uv);
    float q0 = float(abs(int(h.y * h.x)) % 5 - 1);
    q0 += q0 >= 0.0 ? 1.0 : 0.0;
    
    uv = h.xy + uv * q0 * 0.7;
    h = shape(uv);
    

    // Time varying pixel color
    vec3 col = vec3(1.0);
    float q1 = float(int(h.y * h.x) % 10 - 3);
    float q2 = smoothstep(-0.5, 0.5, sin((h.z * 25.0 + (q1 * 2.0 - 1.0) * -time * 0.7)));
    q2 = q1 == 0.0 ? q2 : 1.0 - q2;
    q2 = q2 * 0.25 + 0.5;
    col *= q2;
    if (h.z > 0.3) {
        col.x *= h.w * 5.0 - q1 * 0.2;
    }
    
    for (int n = 2; n >= 0; --n) {
        vec2 uvVignette = uvPlain * vec2(2.0, 2.0);
        uvVignette *= 1.0 - (float(n) / 7.6);
        uvVignette *= rot(time * 0.1 * (n % 2 == 0 ? -1.0 : 1.0));
        h = shape(uvVignette);
        if (h.x == h.y && h.x == 0.0) {
            if (n == 0) {
                col *= smoothstep(0.0, 0.2, h.z);
            }
            float fn = float(n);
            col += smoothstep(0.02 / (fn + 1.0), 0.0, abs(h.z - 0.03)) * 
                (vec3(0.3) + 0.4 *
                 vec3(sin(time + float(n) + TWOPI * 0.0 / 3.0),
                      sin(time + float(n) + TWOPI * 1.0 / 3.0),
                      sin(time + float(n) + TWOPI * 2.0 / 3.0)));
        }
        else {
            col *= 0.6;
            vec3 grad = vec3(dFdx(h.z), dFdy(h.z), 0.0);
            grad.z = (grad.x + grad.y) * 0.5;
            col.zyx += grad * 10.0;
        }
    }
    
    if (h.x == h.y && h.x == 0.0) {
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
