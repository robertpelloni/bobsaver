#version 420

// original https://www.shadertoy.com/view/XtGBDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LEVEL 15U
#define WIDTH ( (1U << LEVEL) )
#define AREA ( WIDTH * WIDTH )

float HilbertIndex( uvec2 Position )
{   
    uvec2 Regions;
    uint Index = 0U;
    for( uint CurLevel = WIDTH/2U; CurLevel > 0U; CurLevel /= 2U )
    {
        uvec2 Region = uvec2(greaterThan((Position & uvec2(CurLevel)), uvec2(0U)));
        Index += CurLevel * CurLevel * ( (3U * Region.x) ^ Region.y);
        if( Region.y == 0U )
        {
            if( Region.x == 1U )
            {
                Position = uvec2(WIDTH - 1U) - Position;
            }
            Position.xy = Position.yx;
        }
    }
    
    return float(Index) / float(AREA);
}

vec4 mirrored(vec4 v)
{
    vec4 Mod = mod(v, 2.0);
    return mix(Mod, 2.0 - Mod, step(1.0, Mod));
}

void main(void)
{
    vec2 UV = gl_FragCoord.xy/resolution.xy;
    UV.x *= resolution.x / resolution.y;
    UV.x -= fract((resolution.x ) / resolution.y) / 2.0;
   
    uvec2 FragCoord = uvec2( UV * float(WIDTH) );
    float Index = HilbertIndex( FragCoord );
    
    Index += time / 12.0;
    vec2 Border = smoothstep(vec2(0.0), vec2(0.0) + vec2(0.01), UV) -
        smoothstep(vec2(1.0) - vec2(0.01), vec2(1.0), UV);
    glFragColor = mirrored(
        vec4(
            Index * 7.0,
            Index * 11.0,
            Index * 13.0,
            1.0
        )
    ) * (Border.x * Border.y);
}
