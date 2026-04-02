#version 420

// original https://www.shadertoy.com/view/wlVyWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 lightDir=vec3(-0.57,0.57,0.57);

float distFuncCube(vec3 p){
    vec3 q=abs(p);
    return length(max(q-vec3(1.0,0.1,0.5),0.0));
}

float distFuncSphere(vec3 p){
    float s=0.5;
    return length(p)-s;
}

float distFunc(vec3 p){
    p=mod(p,0.8)-0.4;
    float d3=distFuncCube(p);
    float d4=distFuncSphere(p);

    return min(d3,d4);//OR

}

vec3 genNormal(vec3 p){
    float d=0.0001;
    return normalize(vec3(
        distFunc(p+vec3(d,0.0,0.0))-distFunc(p+vec3(-d,0.0,0.0)),
        distFunc(p+vec3(0.0,d,0.0))-distFunc(p+vec3(0.0,-d,0.0)),
        distFunc(p+vec3(0.0,0.0,d))-distFunc(p+vec3(0.0,0.0,-d))
        ));
}

void main(void) {
    vec2 p=(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

    vec3 cPos=vec3(sin(time)*0.6,0.5,time*0.3);
    vec3 cDir=vec3(0.0,0.0,-1.0);
    vec3 cUp=vec3(0.0,1.0,0.0);
    vec3 cSide=cross(cDir,cUp);
    float targetDepth=1.0;

    vec3 ray=normalize(cSide*p.x+cUp*p.y+cDir*targetDepth);

    float tmp,dist;
    tmp=0.0;
    vec3 dPos=cPos;

    float emission=0.0;

    for(int i=0;i<48;i++){
        dist=distFunc(dPos);
        tmp+=dist;
        dPos=cPos+tmp*ray;
        emission+=exp(abs(dist)*-0.2);
    }

    vec3 color;

    if(abs(dist)<0.001){
        vec3 normal=genNormal(dPos);
        float diff=clamp(dot(lightDir,normal),0.1,1.0);
        color=0.02*emission*vec3(sin(time),1.0,cos(time))*diff;
    }else{
        color=vec3(0.0);
    }
    glFragColor=vec4(color,1.0);
}

