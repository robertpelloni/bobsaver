#version 420

// original https://www.shadertoy.com/view/3l3yDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define cellCount 10.
#define cellSize 1./cellCount
#define T (time * 10.)

float drawCircle(vec2 uv, vec2 id, vec2 dir){

    float circleR = 0.2 /cellCount;
    float l = length( (id* cellSize+(cellSize*0.5) - (dir*cellSize*0.25) ) - uv);
    return smoothstep( l*0.9 ,l  ,circleR);
}

vec3 Rand2To3(vec2 id)
{
    float r = dot(id.xx, id.yx*41.2330);
    return vec3( fract(r), fract(r*10.), fract(r*100.));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.yy;

    uv -= vec2(.3333,0);
    
    vec2 id = floor((uv * cellCount));
    if(id.x < 0. || id.x > cellCount-1.){ id= vec2(0);}
    //glFragColor.rgb = vec3( id/cellCount,0);
    glFragColor.rgb = vec3(0);
    
    
    float patternCount = 16.;
    vec2[] movePatterns = vec2[] (  vec2(0,1), vec2(1,1),
                                    vec2(0,1), vec2(-1,0),
                                    vec2(-1,-1), vec2(-1,0),
                                    vec2(-1,1), vec2(0,0),
                                    vec2(0,1), vec2(-1,1),
                                    vec2(-1,0), vec2(0,0),
                                    vec2(1,0), vec2(0,-1),
                                    vec2(-1,0), vec2(-1,1)
                                    );
    
    vec2 moveDir = mix(movePatterns[int(mod( T-1.+patternCount ,patternCount))],  movePatterns[int(mod( T,patternCount))], fract(T));
    //Variation
    moveDir *= 1. - (2.*mod(id+1.,2.));
    
    
    glFragColor.rgb += mix(vec3(0.058, 0.101, 0.349),Rand2To3(id+vec2(1.)) , drawCircle( uv, id, moveDir) );
}
