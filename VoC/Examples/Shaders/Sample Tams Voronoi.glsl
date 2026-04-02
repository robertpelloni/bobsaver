#version 420

// original https://www.shadertoy.com/view/tdXXzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 N22(vec2 p)
{
    vec3 a = fract(p.xyx * vec3(123.34,234.34,345.65));
    a += dot(a, a+34.45);
    return fract(vec2(a.x*a.y, a.y*a.z));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float m = 0.;
    float t = time*.2;
    vec3 col = vec3(0);
    float minDist = 100.;
    float cellIndex = 0.;
    if(false){
    for( float i =0.; i<50.; i++)
    {
        vec2 n = N22(vec2(i));
        vec2 p = sin(n*t);
        
        float d = length(uv-p);
        m += smoothstep(.02,.01,d);
        
        if(d < minDist){
            minDist = d;
            cellIndex = i;
        }
    }
    }
    else{
        uv *= 3.;
        
        vec2 gv = fract(uv)-.5;
        vec2 id = floor(uv);
        vec2 cid = vec2(0);
        for(float y = -1.; y <=1.; y++){
            for(float x = -1.; x <=1.; x++){
                vec2 offs = vec2(x,y);
                
                vec2 n = N22(id + offs);
                vec2 p = offs + sin(n*t)*.5;
                p -= gv;
                float ed = length(p);
                float md = abs(p.x)+abs(p.y);
                float d = mix(ed,md,sin(time *.5+.5));
                
                if(d < minDist){
                    minDist = d;
                    cid = id + offs;
                }
            }
        }
        col = vec3(minDist);
        //col.rg = cid*.1;
    }
    

    glFragColor = vec4(col,1.0);
}
