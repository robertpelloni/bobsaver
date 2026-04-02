#version 420

// original https://www.shadertoy.com/view/4syyRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Just another generative piece of 'art' (lol), for FBM and noise training purpose.

// "replace this by something better" (IQ said).
// and i'm really not yet sure what is 'better'.
// Better means faster? Or better distribution? 
vec2 hash( vec2 x )  
{
    const vec2 k = vec2( 0.318653, 0.3673123 );
    x = x * k + k.yx;
    
    // Earlier version, too noisy now. You have to lower
    // values on 72 and 79 and 88 to get ~ initial result.
    // It was not such big as if you uncomment this now, but
    // really a lot more than smooth version. 
    
    // So smoothstepping a noise is cool if you can improve 
    // a picture after it, without adding more. Nice!
    
    //return -1.0 + 2.0 * fract( 16.0 * k * fract( x.x * x.y * (x.x + x.y)));
    
    // A bit smoother version, with less jitter.
    return smoothstep(0.0, 1.15, -1.0 + 2.0 * fract( 16.0 * k * fract( x.x * x.y * (x.x + x.y))));
}

// Simple 2D gradient noise taken from you know where: https://www.shadertoy.com/view/XdXGW8
// Thx IQ :)
float noise2D( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

// Rotation matrix, it does a big impact, as usual.
const mat2 m = mat2( 1.20,  1.00, -1.00,  1.20 );

// Four octave FBM.
float fbm4( vec2 p )
{
    float f = 0.0;
    f += 0.5000 * noise2D( p ); p = p * 2. * m;
    f += 0.2500 * noise2D( p ); p = p * 2. * m;
    f += 0.1250 * noise2D( p ); p = p * 2. * m;
    f += 0.0625 * noise2D( p );
    return f;
}

// Six octave FBM.
float fbm6( vec2 p )
{
    float f = 0.0;
    f += 0.500000 * (0.5 + 0.5 * noise2D( p )); p = m * p * 2.;
    f += 0.250000 * (0.5 + 0.5 * noise2D( p )); p = m * p * 2.;
    f += 0.125000 * (0.5 + 0.5 * noise2D( p )); p = m * p * 2.;
    f += 0.062500 * (0.5 + 0.5 * noise2D( p )); p = m * p * 2.;
    f += 0.031250 * (0.5 + 0.5 * noise2D( p )); p = m * p * 2.;
    f += 0.015625 * (0.5 + 0.5 * noise2D( p ));
    return f;
}

float GetFBM( vec2 q, out vec4 ron)
{
    // Waves motion.
    float ql = length( q.y );
    q += 0.05 * (0.5 + 0.5 * sin(time + ql * 1.05));

    // First point.
    vec2 o;
    
    // Vice versing fbm's addition for points gives nice result.
    o = vec2(fbm4(q + fbm6( vec2(2.0 * q + vec2(6.)))));

    // Second point.
    vec2 n;
    n = vec2(fbm6(q + fbm4( vec2(4.0 * o + vec2(2.)))));

    // Sum of points with increased sharpness. 
    vec2 p = 4.0 * o + 8.0 * n;
    float f = 0.5 + 0.5 * fbm6( p );

    // I have seen that cubic mixing a couple of times
    // is it just gives a nice result, or there is something
    // behind it? Anyone?
    f = mix( f, f * f * f * 3.5, f * abs(n.y));

    // Really just a magic which i've seen in IQ's https://www.shadertoy.com/view/lsl3RH.
    float g = 0.5 + 0.5 * sin(5.0 * p.x) * sin(5.0 * p.y);
    f *= 1.0 - 0.55 * pow( g, 16.0 ) * f;
    
    ron = vec4( o, n );

    return f;
}

// Main color mixing function.
vec3 GetColor(vec2 p)
{
    vec4 on = vec4(0.0);
    
    float f = GetFBM(p, on);
    
    vec3 col = vec3(0.0);
    
    col = mix( vec3(0.78, 0.0, 0.56), vec3(0.0, 0.0, 0.11), f );
    col = mix( col, vec3(0.2, 0.85, 0.85), dot(on.xy, on.zw));
    col = mix( col, vec3(0.1, 0.79, 0.88), 1.2 * smoothstep(0.8, 1.6, abs(on.z) + abs(on.z)));
    
    return col * 6. * 0.4545;
}

void main(void)
{
    // Aspect ratio - UV normalization.
       vec2 p = (2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
    
    // Zoom level.
    p*= 4.;

    glFragColor = vec4( GetColor( p ), 1.0 );
}
