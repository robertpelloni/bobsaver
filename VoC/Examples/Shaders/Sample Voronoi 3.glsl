#version 420

// original https://www.shadertoy.com/view/7lS3Rw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 spin(vec2 uv,float t){
    return vec2(uv.x*cos(t)-uv.y*sin(t),uv.y*cos(t)+uv.x*sin(t));
}

vec2 R22(vec2 p) 
{
    vec3 a = fract(p.xyx * vec3(123.34, 234.34, 345.65));
    a += dot(a, a + 34.45);
    return fract(vec2(a.x*a.y, a.y*a.z));
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float t = time;
   
    float minDist = 10.;
    
    uv *= 5.;
    
    vec3 col = vec3(.0);
    
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    
    for (float y = -1.; y <= 1.; y ++)
    {
        for(float x = -1.; x <= 1.; x++)
        {
        
            vec2 offset = vec2(x,y);
            vec2 n = R22(id + offset);
            vec2 p = offset+sin(n*t)*.5;
            
            float dist = length(gv-p);
            
            if(dist < minDist)
            {
                minDist = dist;
            }
        }
    }
    
    col += smoothstep(1.2, .0, minDist*.4);
    
    glFragColor = vec4(col,1.0);
}
