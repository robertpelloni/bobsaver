#version 420

// original https://www.shadertoy.com/view/ltjGRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ss 4
#define pi 3.1415926535897
#define rotation 1.

float round(float v, float d){
    return ceil(v/d-0.5)*d;
}

float checkerboard(vec2 uv){
    vec2 p=mod(uv-vec2(0.5),1.0);
    return mod(step(p.x,0.5)+step(p.y,0.5),2.0);
}

vec2 rot(vec2 uv, float r){
    float cr=cos(r),sr=sin(r);
    return vec2(cr*uv.x-sr*uv.y,sr*uv.x+cr*uv.y);
}

void main(void)
{
    float tv=0.0;
    float t=time*0.67;
    
    for(int xp=0;xp<ss;xp++){
        for(int yp=0;yp<ss;yp++){
    vec2 uv = 2.0*(gl_FragCoord.xy-resolution.xy*0.5+vec2(xp,yp)/float(ss))/resolution.x;
    uv*=4.0;
    
    uv=rot(uv,0.01*rotation*sin(pi*t));
    
    
    uv.x=uv.x-round(uv.y-0.25,0.5)*t;
    float v=checkerboard(uv);
    
    if(abs(round(uv.y,0.5)-uv.y)<0.01) v=0.5;
            tv+=v;
        }
    }
    tv=tv/float(ss*ss);
    glFragColor=vec4(tv,tv,tv,1.0);
}
