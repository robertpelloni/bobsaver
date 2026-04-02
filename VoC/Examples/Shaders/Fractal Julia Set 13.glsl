#version 420

// original https://www.shadertoy.com/view/NdSGRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITR 100
#define PI 3.1415926

float julia(vec2 uv){
    int j;
    for(int i=0;i<ITR;i++){
        j++;
        vec2 c=vec2(-0.345,0.654);
        vec2 d=vec2(time*0.005,0.0);
        uv=vec2(uv.x*uv.x-uv.y*uv.y,2.0*uv.x*uv.y)+c+d;
        if(length(uv)>float(ITR)){
            break;
        }
    }
    return float(j)/float(ITR);
}

void main(void) {
    vec2 uv=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    uv*=abs(sin(time*0.2));
    float f=julia(uv);

    glFragColor=vec4(vec3(f),1.0);
}
