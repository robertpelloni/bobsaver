#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3sdSR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define noise(p)  texture( iChannel0, (p) / iChannelResolution[0].xy )
#define MORE_SIMPLE

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    //from -1 to 1
    vec2 pos=( 2.*gl_FragCoord.xy - resolution.xy )/resolution.y;
    
    float noiseCanvas=0.9;//mix(.9,1.,noise(gl_FragCoord.xy).r);
    vec3 col=noiseCanvas*vec3(1.,1.,.9);
    
    for(int i=0;i<9;i+=1){
        float r=radians(float(i+1)*360.*time*.1);
        vec2 circlePosition=vec2(cos(r),sin(r))*.5;
        if(length(pos-circlePosition)<.5){
#ifdef MORE_SIMPLE
            col-=1./12.;
            col[i%3]-=1./12.;
#else
            if(i%3==0){
                //cyan
                col-=vec3(2.,1.,1.)/12.;
            }
            if(i%3==1){
                //magenta
                col-=vec3(1.,2.,1.)/12.;
            }
            if(i%3==2){
                //yellow
                col-=vec3(1.,1.,2.)/12.;
            }
#endif
        }
    }
    // Output to screen
    glFragColor = vec4(col,1.);
}
