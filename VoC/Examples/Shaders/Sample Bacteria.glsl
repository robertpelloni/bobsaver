#version 420

// original https://www.shadertoy.com/view/MsycWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-- 2D Worley noise. -------------------------------------------------------

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

//--------------------------------------------------------------------------

#define MOD3 vec3(.1031,.11369,.13787)

vec3 hash( vec3 p )
{
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

// 3D Gradient noise by Iq.
float noise3D( in vec3 p )
{
    vec3 i = floor( p );
    vec3 f = fract( p );
    
    vec3 u = f*f*(3.0-2.0*f);

    return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                          dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                          dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                          dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                          dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

// Colors.
vec3 GreenCyan = vec3(0.000, 0.964, 0.825);
vec3 AquaBlue = vec3(0.000, 0.478, 0.900);

void main(void)
{
     vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 uv = -1.0 + 2.0 * q;
    uv.x *= resolution.x/resolution.y;
    uv *= 12.;

    float w = 0.85 - 
              (noise3D(vec3(uv.x + time * 0.35, uv.y, 0.45 * time)) + 
               (worley2D(uv * 3.)));
    
    vec3 col = vec3(w);
    
    col = mix(GreenCyan,
              AquaBlue,
              clamp((col * col) * 2.75, 0.0, 1.0));

    // Output to screen
    glFragColor = vec4((col * col), 1.0);
}
