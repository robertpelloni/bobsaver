#version 420

// original https://www.shadertoy.com/view/3tycWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 N22(vec2 p){
    vec3 a = fract(p.xyx*vec3(123.34, 234.34, 345.65));
    a+=dot(a, a+34.45);
    return fract(vec2(a.x*a.y, a.y*a.z));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
   
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float m = 0.;//N22(uv).x;
    float t = time;
    
    float minDist = 100.;
    float cellIndex = 0.;
    

        uv *= 3.;
        vec2 gv = fract(uv)-.5;
        vec2 id = floor(uv);
        vec2 cid = vec2(0);
        vec2 mo = vec2(0.0);
        vec2 mp = vec2(0.0);
        for (float y=-1.; y <= 1.;y++){
            for (float x=-1.; x <= 1.;x++){
                vec2 offset = vec2(x, y);
                vec2 n = N22(id+offset);
                vec2 p = offset+sin(n*t)*.5;
                p -= gv;
                float d = length(p);
                if(d < minDist){
                    minDist = d;
                    cid = id+offset;
                    mo = offset;
                    mp = p;
                }
            }
        }
     
        for (float y=-2.; y <= 2.;y++){
            for (float x=-2.; x <= 2.;x++){
                vec2 offset = vec2(x, y);
                vec2 n = N22(id+offset);
                vec2 p = offset+sin(n*t)*.5;
                p -= gv;
                float d = length(mp-p);
                if(d > 0.01){
                    minDist = min(minDist, dot((p+mp), normalize(p-mp)) );
                   
                }
            }
        }
        
          if (minDist<.07) {minDist = smoothstep(0.7, 1., 1.-minDist)*.2; }
            vec3 col = minDist*(exp(minDist*2.0))*vec3(1.0, 0.5, 0.0);
            
           // col = mix(col, vec3(1.0, 0.0, 0.0), smoothstep(0.07, 0.01, minDist));
           
        
    
       
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
