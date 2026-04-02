#version 420

// original https://www.shadertoy.com/view/XdKyWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Rotation matrix, it does a big impact, as usual.
const mat2 m = mat2( 1.40,  1.20, -1.20,  1.40 );

// Strangely simple noise, which gives us that checker
// pattern, if i understood right.
float noise( in vec2 x )
{
    return cos(1.5 * x.x) * sin(1.5 * x.y);
}

// Four octave FBM.
float fbm4( vec2 p )
{
    float f = 0.0;
    f += 0.5000 * noise( p ); p = m * p * 2.02;
    f += 0.2500 * noise( p ); p = m * p * 2.03;
    f += 0.1250 * noise( p ); p = m * p * 2.01;
    f += 0.0625 * noise( p );
    return f / 0.9375;
}

// Six octave FBM.
float fbm6( vec2 p )
{
    float f = 0.0;
    f += 0.500000 * (0.5+0.5*noise( p )); p = m * p * 2.02;
    f += 0.250000 * (0.5+0.5*noise( p )); p = m * p * 2.03;
    f += 0.125000 * (0.5+0.5*noise( p )); p = m * p * 2.01;
    f += 0.062500 * (0.5+0.5*noise( p )); p = m * p * 2.04;
    f += 0.031250 * (0.5+0.5*noise( p )); p = m * p * 2.01;
    f += 0.015625 * (0.5+0.5*noise( p ));
    return f / 0.96875;
}

// Main FBM pattern function.
//
// So actually we have 2 "patterns" here.
// One is sitting in 'o', the other one is 'n'. 
// They are a bit different, but not much because
// they use the same noise. After we got them,
// we can mix it. Keeping this idea we can add more 
// "layers" using different noises and/or more variables.
//
// Feel free to play.
float GetFBM( vec2 q, out vec4 ron)
{
    // Waves motion.
    float ql = length( q );
    q += vec2(0.05 * (2.0 * sin(-time * 2.0 + ql * 1.05)));

    // First point.
    vec2 o;
    o = vec2(0.5 + 0.5 * fbm4( vec2(2.0 * q + vec2(1.2))));

    // Second point.
    vec2 n;
    n.x = fbm6( vec2(4.0 * o + vec2(12.2)));
    n.y = fbm6( vec2(4.0 * o + vec2(14.2)));

    vec2 p = 4.0 * o + 4.0 * n;
    float f = 0.5 + 0.5 * fbm4( p );

    // I have seen that cubic mixing a couple of times
    // is it just gives a nice result, or there is something
    // behind it? Anyone?
    f = mix( f, f * f * f * 3.5, f * abs(n.x) );

    float g = 0.5 + 0.5 * sin(4.0 * p.x) * sin(4.0 * p.y);
    f *= 1.0 - 0.5 * pow( g, 8.0 );
    
    ron = vec4( o, n );

    return f;
}

// Main color mixing function.
vec3 GetColor(vec2 p)
{
    vec4 on = vec4(0.0);
    
    float f = GetFBM(p, on);
    
    vec3 col = vec3(0.0);
    
    col = mix( vec3(0.78, 0.1, 0.4), vec3(0.0, 0.05, 0.11), f );
    col = mix( col, vec3(0.4, 0.4, 0.65), dot(on.zw, on.zw));
    col = mix( col, vec3(0.3, 0.65, 0.3), 0.35 * on.y );
    col = mix( col, vec3(0.2, 0.4, 0.85), 0.5 * smoothstep(1.1, 1.6,abs(on.z) + abs(on.z)));
    
    return col * col * 7. * 0.4545;
}

void main(void)
{
       vec2 p = (2. * gl_FragCoord.xy - resolution.xy ) / resolution.y;
    
    // Zoom level.
    p*= 2.;

    glFragColor = vec4( GetColor( p ), 1.0 );
}
