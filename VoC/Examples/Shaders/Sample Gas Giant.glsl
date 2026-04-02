#version 420

// original https://www.shadertoy.com/view/XdyyRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Rotation matrix, it does a big impact, as usual.
const mat2 m = mat2( 1.40,  1.00, -1.00,  1.40 );

// Time simplification and easier overall speed control.
#define time time * 0.35

vec2 hash( vec2 x )  
{
    const vec2 k = vec2( 0.318653, 0.3673123 );
    x = x * k + k.yx;
    return smoothstep(0.0, 1.35, -1.0 + 2.0 * fract( 16.0 * k * fract( x.x * x.y * (x.x + x.y))));
}

// 2D gradient noise
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

float r(float n)
{
     return fract(cos(n*72.42)*173.42);
}

vec2 r(vec2 n)
{
     return vec2(r(n.x*63.62-234.0+n.y*84.35),r(n.x*45.13+156.0+n.y*13.89)); 
}

float worley2D(in vec2 n)
{
    float dis = 2.0;
    for (int y= -1; y <= 1; y++) 
    {
        for (int x= -1; x <= 1; x++) 
        {
            // Neighbor place in the grid
            vec2 p = floor(n) + vec2(x,y);

            float d = length(r(p) + vec2(x, y) - fract(n));
            if (dis > d)
            {
                 dis = d;   
            }
        }
    }
    
    return 1.0 - dis;
}

// Four octave worley FBM.
float fbm4( vec2 p )
{
    float f = 0.0;
    f += 0.5000 * worley2D( p ); p = p * 2. * m;
    f += 0.2500 * worley2D( p ); p = p * 2. * m;
    f += 0.1250 * worley2D( p ); p = p * 2. * m;
    f += 0.0625 * worley2D( p );
    return f;
}

// Six octave perlin FBM.
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

float GetFBM( vec2 q, out vec4 ron, out vec2 rk)
{
    // Base motion.
    float ql = length( q * m );
    q += 0.05 * (0.5 + 0.5 * sin(time + ql * 1.05));

    // First layer.
    vec2 o;
    
    // Vice versing fbm's addition for points gives nice result.
    o = vec2(fbm4(q + fbm6( vec2(2.0 * q + vec2(6.)))));

    // Second layer.
    vec2 n;
    n = vec2(fbm6(q + fbm4( vec2(2.0 * o + vec2(2.)))));
    
    // Third layer.
    vec2 k;
    
    // Line movement.
    k = sin(0.25 * q.x - time) * vec2(fbm4(q * fbm4( vec2(2.0 * n + vec2(2.)))));
    
    // Sum of points with increased sharpness. 
    vec2 p = 4.0 * o + 6.0 * n + 8.0 * k ;
    float f = 0.5 + 0.5 * fbm6( p ) ;

    // I have seen that cubic mixing a couple of times
    // is it just gives a nice result, or there is something
    // behind it? Anyone?
    f = mix( f, f * f * f * 3.5, f * abs(n.y));

    f *= 1.0 - 0.55 * pow( f, 8.0 );
    
    ron = vec4( o, n );
    rk = vec2(k);

    return f;
}

// Main color mixing function.
vec3 GetColor(vec2 p)
{
    vec4 on = vec4(0.0);
    vec2 k = vec2(0.0);
    
    float f = GetFBM(p, on, k);
    
    vec3 col = vec3(0.0);
    
    // Our 'background' bluish color.
    col = mix( vec3(0.18, 0.45, 0.86), vec3(0.0, 0.0, 0.41), f );
    
    // Dark orange front layer.
    col = mix( col, vec3( 0.91, 0.55, 0.0), dot(on.xy, on.zw));
    
    // Touch of cyan.
    col = mix( col, vec3(0.0, 0.33, 0.62), 0.2 * smoothstep(0.8, 1.6, abs(k.x) + abs(k.y)));
    
    return col * col * 7. * 0.4545;
}

void main(void)
{
    // Aspect ratio - UV normalization.
       vec2 p = (2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
    
    // Zoom level.
    p*= 4.;
    
    vec3 col = GetColor( p );

    glFragColor = vec4( col, 1.0 );
}
