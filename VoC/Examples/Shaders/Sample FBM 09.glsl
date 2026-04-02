#version 420

// original https://www.shadertoy.com/view/Wl2XzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define HASHSCALE1 vec3(.1031)

vec3 hash(vec3 p3)
{
    p3 = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

vec3 noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(    mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                    mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
                mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                    mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

const mat3 m3 = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );
vec3 fbm(in vec3 q)
{
    vec3 f  = 0.5000*noise( q ); q = m3*q*2.01;
    f += 0.2500*noise( q ); q = m3*q*2.02;
    f += 0.1250*noise( q ); q = m3*q*2.03;
    f += 0.0625*noise( q ); q = m3*q*2.04;
#if 1
    f += 0.03125*noise( q ); q = m3*q*2.05; 
    f += 0.015625*noise( q ); q = m3*q*2.06; 
    f += 0.0078125*noise( q ); q = m3*q*2.07; 
    f += 0.00390625*noise( q ); q = m3*q*2.08;  
#endif
    return vec3(f);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec3 col = fbm(float(time) + 1000.0 + vec3(gl_FragCoord.x, gl_FragCoord.y, (gl_FragCoord.x + gl_FragCoord.y) * 0.5) * 0.01);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
