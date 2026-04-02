// focus on the cross and green circles will appear where the purple circle disappears

#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/4ddBRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AVOID_DISTORSIONS 1

#define PI 3.14159265359

float circle( vec2 p, vec2 c, float radius) 
{
    
    return sqrt(pow(p.x-c.x, 2.) + pow(p.y-c.y, 2.)) - radius;
        
}

float line( vec2 p, vec2 a, vec2 b, float r )
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

vec2 getCirclePoint(vec2 c, float r, float a)
{
    return c + vec2(sin(a),cos(a)) * r;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
#if AVOID_DISTORSIONS
    vec2 uv = gl_FragCoord.xy/resolution.y;
       uv.x += (resolution.y - resolution.x) 
        / max(resolution.x,resolution.y) ;
#else    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
#endif    

    // Select circle to dissapear
    int cS = int(time*10.) % 12;
    
    
    // Circles
    bool hitCircle = false;
    for(int i = 0; i < 12; i++)
    {
        hitCircle = hitCircle || cS != i && (0. >= circle(uv, 
               getCirclePoint(vec2(.5), .45, float(i)/ 12. *2.*PI + 0.25 ), 0.07));
    }
    
    float l0 = line(uv, vec2(.5, .52),vec2(.5, .48), 0.005);
    float l1 = line(uv, vec2(.52,.5),vec2(.48,.5), 0.005);
    
    if(l0 <=0. || l1 <= 0.)
        glFragColor = vec4(0);
    else if(hitCircle)
        glFragColor = vec4(.85,.59,.85,1.);
    
    else
        glFragColor = vec4(0.6);
}
