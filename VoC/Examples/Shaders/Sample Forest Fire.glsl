#version 420

// original https://www.shadertoy.com/view/ldVGR1

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define timeDelta 0.05
#define PROB_TREE 0.02
#define PROB_FIRE 0.00005
#define FIRE_TIME 1.0
#define GROWTH_TIME 1.0
#define BURN_THRESHOLD 0.7

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    if(frames==1)
    {
        glFragColor = vec4(0.0);
        return;
    }
    
    vec2 uv = gl_FragCoord.xy / ( resolution.xy);
    vec4 current = texture(backbuffer, uv);   
    vec4 outVal = current;

    float prob = abs(rand(vec2(uv.x*time,uv.y*time)));
    
    if(current.x > 0.0)
    {
        outVal.x = max( 0.0, current.x - FIRE_TIME * timeDelta );
    }
    else if(current.y == 0.0 )
    {
        if(prob<PROB_TREE)
        {
            outVal.y = 0.25;
        }
    }
    else if(current.y == 1.0 )
    {
        if(prob<PROB_FIRE)
        {
            outVal.x = 1.0;
            outVal.y = 0.0;
        }
        else
        {
            vec4 neighborUp = texture(backbuffer, ( gl_FragCoord.xy + vec2(0.0,1.0) ) / (resolution.xy));
            vec4 neighborDown = texture(backbuffer, ( gl_FragCoord.xy + vec2(0.0,-1.0) ) / (resolution.xy));
              vec4 neighborLeft = texture(backbuffer, ( gl_FragCoord.xy + vec2(1.0,0.0) ) / (resolution.xy ));
             vec4 neighborRight = texture(backbuffer, ( gl_FragCoord.xy + vec2(-1.0,0.0) ) / (resolution.xy));

            
            if(neighborUp.x > BURN_THRESHOLD || neighborDown.x > BURN_THRESHOLD || neighborRight.x > BURN_THRESHOLD || neighborLeft.x > BURN_THRESHOLD )
            {
                outVal.x = 1.0;
                outVal.y = 0.0;
            }
        }
        
    }
    else if(current.y > 0.0 )
    {
        outVal.y = min(1.0,current.y + GROWTH_TIME * timeDelta );
    }
    
    glFragColor = outVal;
}
