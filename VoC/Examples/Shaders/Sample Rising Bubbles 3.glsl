#version 420

// original https://www.shadertoy.com/view/tdVGR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co) { 
    return fract(sin(dot(co.xy , vec2(12.9898, 78.233))) * 43758.5453);
} 

void main(void)
{
    vec2 ouv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.x;
    
    float fCol = 0.;
    float t = time * 0.25;
    
    float total = 7.;
    for(float i=1.; i<total; i+=1.){
        float iTotal = i/total;
        float niTotal = 1. - i/total;
                
        vec2 uv = ouv * (10. + i*1.) - vec2(0., t*(1.-i/total));
        vec2 id = floor(uv) + vec2(i*1000.);
        uv = fract(uv) - 0.5;
        
        for(float y=-1.; y<=1.; y+=1.){
            for(float x=-1.; x<=1.; x+=1.){   
                
                vec2 iuv = uv + vec2(x,y);    
                vec2 iid = id - vec2(x,y);  
                
                if(rand(iid * 200.) > .25){
                    iuv.x += rand(iid)-.5;
                    iuv.y += rand(vec2(rand(iid)))-.5;        

                    float l = length(iuv * (niTotal)*1.5);  
                    float size = rand(iid*5.)*.1 + .25 - .1;
                    float force = rand(iid*10.)*.5+.5;
                    fCol += 
                        smoothstep(l, l + (iTotal)*.25, size) *                         
                        niTotal *
                        force;        
                }                         
            }
        }        
    }
      
    glFragColor = vec4(fCol);
}
