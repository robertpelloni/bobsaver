#version 420

// original https://www.shadertoy.com/view/tljSWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define BLACK_COL vec3(16,22,26)/255.
#define WHITE_COL vec3(235,241,245)/255.

#define rand1(p) fract(sin(p* 78.233)* 43758.5453) 

void main(void)
{    
    vec2 ouv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;

    float sf = .05 + abs(ouv.y);
    
    float m = 0.;
    for(float n=-1.; n<=1.; n+=1.){
        vec2 uv = ouv * vec2(1., 1. + .025*n) * (2. + sin(time*.25)*.2);
        uv.y+=time*.1;

        uv = uv * 15.;
        vec2 gid = floor(uv);
        vec2 guv = fract(uv) - .5;
        
        for(float y=-1.; y<=1.; y+=1.){
            for(float x=-1.; x<=1.; x+=1.){
                vec2 iuv = guv + vec2(x,y);    
                vec2 iid = gid - vec2(x,y);  

                float angle = rand1(iid.x*25. + iid.y * 41.)*10. +
                    (time * (rand1(iid.x*10. + iid.y * 60.) + 1.5));

                float ca = cos(angle);
                float sa = sin(angle);
                iuv *= mat2(ca, -sa, sa, ca);

                float size = rand1(iid.x*50. + iid.y*25.)*.2+.5;
                float weight = size*.02;                
                
                float swp = size - weight;                                                               
                float m1 = smoothstep(abs(iuv.x), abs(iuv.x) + sf, swp) 
                    * smoothstep(abs(iuv.y), abs(iuv.y) + sf, swp);

                swp = size + weight;                                
                float m2 = smoothstep(abs(iuv.x), abs(iuv.x) + sf, swp) 
                    * smoothstep(abs(iuv.y), abs(iuv.y) + sf, swp);
                
                float rr = rand1(iid.x*128. + iid.y*213.);
                m1 *= rr > .075 ? 1.0 : (1.-rr*5.);

                m += clamp(m2 - m1, 0., 1.);
            }
        } 
    }            
        
    vec3 col = mix(BLACK_COL, WHITE_COL, m);    
    
    glFragColor = vec4(col, 1.);
}
