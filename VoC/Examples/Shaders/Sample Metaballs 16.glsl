#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdtSDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(vec2 positionFragment,vec2 positionObject,float radius){
    return length(positionFragment-positionObject) - radius;
}

void main(void)
{
    //from -1 to 1
    vec2 pos=( 2.*gl_FragCoord.xy - resolution.xy )/resolution.y;
    
    //smooth factor
    float e=0.5;
    
    vec3 col=vec3(0.);
    for(int i=0;i<9;i+=1){
        float r=radians(float(i+1)*360.*time*.1);
        vec2 circlePosition=vec2(cos(r),sin(r))*.5;
        //red or green or blue
        col[i%3]+=smoothstep(-e,e,-circle(pos,circlePosition,0.25));
    }
    
    //isolate
    col=step(0.5,col);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
