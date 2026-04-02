#version 420

// original https://www.shadertoy.com/view/7tBSRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592653 
#define countX 17.
#define petalWidth .4
#define AA 2.

vec3 colMap(float v) {

    v=mod(v, PI+1.3)-.8;    
    return vec3(
        sin(sin(v-.6)),
        sin(sin(v)),
        sin(sin(v+.8))
    );

} 

void main(void)
{
    for(float aa=0.; aa<AA; aa++){
        for(float bb=0.; bb<AA; bb++){

            // Normalized pixel coordinates (from 0 to 1)
            vec2 uv = (gl_FragCoord.xy + vec2(aa,bb)*1./AA)/resolution.xy;

            // Time varying pixel color

            uv-=.5;
            uv.y*=resolution.y/resolution.x;
            uv*=2.;

            float tim=-time*.1;
            float posintim=sin(tim)*.5+.5;
            float dst=length(uv);
            vec2 tuv = vec2(0.,dst);
            vec2 id = vec2(0.);
            float zoomSpeed=tim*.4;
            float angle1=(atan(uv.x,uv.y)/PI*.5+.5)+zoomSpeed;
            float angle2=angle1-2.*zoomSpeed;
            float add=pow(dst, posintim*.7+.1)*countX*petalWidth;
          tuv.x=mod(angle1*countX+add, 1.);
            tuv.y=mod(angle2*countX-add, 1.);
            id.x=ceil(angle1*countX+add);
            id.y=floor(angle2*countX-add);
            float edgeDist = max(max(tuv.x, tuv.y), max(1.-tuv.x, 1.-tuv.y));
            tuv-=.5;
            tuv*=dst*3.;
            float t=log(dst+1.6);
            float v=abs(tuv.x+tuv.y)+pow(tuv.y-tuv.x, 2.);
            v+=posintim *pow(edgeDist,25.);
            vec3 col=vec3(smoothstep(t+.1,t,v) );
            col*=colMap(abs(id.x-id.y)*.4);

            // Output to screen
            glFragColor += vec4(col/(AA*AA),1.0);
        }
    }
}
