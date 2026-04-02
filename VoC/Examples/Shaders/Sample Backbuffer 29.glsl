#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define size 2.0

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 px;

vec2 blur(vec2 uv){
    vec2 w=vec2(0.0,0.0);
    float l;
    float s;
    for(float x=-size;x<=size;x++){
        for(float y=-size;y<=size;y++){
            l=x*x+y*y;
            w+=l*texture2D(backbuffer,fract(vec2(x,y)*px+uv)).xy;
            s+=3.0;
        }
    }
    return w/s;
}

void main( void ) {
    px=1.0/resolution;

    vec2 p=gl_FragCoord.xy/resolution;
    if(mouse.x==0.0){
        float d=1.0-clamp(abs(length(p-0.5)-0.03)*25.0,0.0,1.0);
        glFragColor=vec4(d,d,1.0,1.0);
    }else if(distance(mouse,p)<0.01){
        glFragColor=vec4((0.03-distance(mouse,p))/0.03)+texture2D(backbuffer,p);
    }
    else{
        vec2 b=blur(p);
        glFragColor=vec4(abs(0.2*b.y*b.y-b.x),abs(0.2*b.x*b.x-dot(b.xy,b.yx)),1.0,1.0);
    }
}
