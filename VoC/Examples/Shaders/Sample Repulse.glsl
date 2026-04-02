#version 420

// original https://neort.io/art/bqlfbv43p9f48fkiqip0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define ColorChangeSpeed 2.80
#define Color1 vec3(1.0, 0.35, 0.1)
#define Color2 vec3(0.0, 0.3, 1.0)
#define beat 2.1

float rand(float n)
{
    return fract(sin(n) * 43758.5453123);
}

vec2 rand2(in vec2 p)
{
    return fract(vec2(sin(p.x * 591.32 + p.y * 154.077), cos(p.x * 391.32 + p.y * (floor(time*beat)))));
}

float noise1(float p)
{
    float fl = floor(p);
    float fc = fract(p);
    return mix(rand(fl), rand(fl + 1.0), fc);
}

float voronoi(in vec2 x)
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    
    vec2 res = vec2(8.0);
    for(int j = -1; j <= 1; j ++)
    {
        for(int i = -1; i <= 1; i ++)
        {
            vec2 b = vec2(i, j);
            vec2 r = vec2(b) - f + rand2(p + b);
            
            // chebyshev distance, one of many ways to do this
            float d = max(abs(r.x), abs(r.y));
            
            if(d < res.x)
            {
                res.y = res.x;
                res.x = d;
            }
            else if(d < res.y)
            {
                res.y = d;
            }
        }
    }
    return res.y - res.x;
}

float fBm( vec2 uv, float lacunarity, float gain )
{
    float sum = 0.0;
    float amp = 15.0;
    
    for( int i = 0; i < 3; ++i )
    {
        sum += ( voronoi( uv ) ) * amp;
        amp *= gain;
        uv *= lacunarity;
    }
    
    return sum;
}

vec3 render( vec2 pos )
{
    
    vec3 c = vec3( 0, 0, 0 );
    
    float noiseFactor = fBm( pos, 0.01, 0.1);
    
    for( float i = 1.0; i < 2.0+1.0; ++i )
    {
        float csn = cos( time * 1.9 * (i/2.0) + noiseFactor ) * 2.5;
        csn *= fract(time*beat);
        float ssn = sin(time * 8.0   * (i/2.0) + noiseFactor ) * 0.3;
        ssn *= fract(time*beat);
        vec2 base = vec2( csn , ssn );
        
        float t = sin( time * 2.3 * i ) * 0.5 + 0.5;
        float Size = mix( 2.26, 1.82, t );
        float d = clamp( sin( length( pos - base )  + Size ), 0.0, Size);
        
        float t2 = sin( time * ColorChangeSpeed * i ) * 0.5 + 0.5;
        vec3 color = mix( Color1, Color2, t2 );
        color *= 4.0;
        c += color * pow( d, 2.5 );
    }
    
    return c;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 -1.0;
    uv.x *= resolution.x/resolution.y;
    uv *= 1.5;
    vec3 col = render( sin( abs(uv) ) );

    glFragColor = vec4(col, 1.0);
}
