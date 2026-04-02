#version 420

// original https://www.shadertoy.com/view/ltyBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec3 p){
    return fract(sin(dot(p.xyz,vec3(12.9898,0.0,78.233)))*36.253);
}
float valueNoise(vec3 p){
    vec3 i=vec3(floor(p.x),p.y,floor(p.z));
    vec3 f=vec3(fract(p.x),p.y,fract(p.z));
    float f1=random(i);
    float f2=random(i+vec3(1.0,0.0,0.0));
    float f3=random(i+vec3(0.0,0.0,1.0));
    float f4=random(i+vec3(1.0,0.0,1.0));
    // f=smoothstep(0.0,1.0,f);
    f=f*f*(3.0-2.0*f);
    return (f1*(1.0-f.x)+f2*f.x)*(1.0-f.z)+(f3*(1.0-f.x)+f4*f.x)*f.z;
}
float octaveValueNoise(vec3 p){
float value=0.0;
float maxValue=0.0;
for(float i=0.0;i<9.0;i++){
    value+=pow(0.5,i)*valueNoise(vec3(p.x*pow(2.0,i),p.y,p.z*pow(2.0,i)));
    maxValue+=pow(0.5,i);
}
return value/maxValue;
}

float mountainDistFunc(vec3 p){
    vec3 pos=vec3(0.0,1.0,0.0);
    vec3 n=normalize(pos);
   return dot(p,n)/5.0+octaveValueNoise(p)/3.0;
}

float distFunc(vec3 p){
    float obj1;
    obj1=mountainDistFunc(p);
    return obj1;
}

vec3 genNormal(vec3 p){
    float d=0.001;
    return normalize(vec3(
        distFunc(p+vec3(d,0.0,0.0))-distFunc(p+vec3(-d,0.0,0.0)),
        distFunc(p+vec3(0.0,d,0.0))-distFunc(p+vec3(0.0,-d,0.0)),
        distFunc(p+vec3(0.0,0.0,d))-distFunc(p+vec3(0.0,0.0,-d))
        ));
}

void main(void) {
    vec2 p = (gl_FragCoord.xy*2.0 - resolution.xy) / min(resolution.x,resolution.y);   
    p*=5.0; 
    vec3 lightPos=vec3(30.0,30.0,0.0);
    vec3 ambientColor=vec3(0.1);
    vec3 cPos=vec3(0.0,0.0,10.0-time/3.0);
    vec3 cDir=vec3(0.0,-0.5,-1.0);
    vec3 cUp=vec3(0.0,1.0,0.0);
    vec3 cSide=cross(cDir,cUp);    
    float targetDepth=1.0;
    vec3 ray=normalize(cSide*p.x+cUp*p.y+cDir*targetDepth);
    float distance=0.0;
    float rLen=0.0;
    vec3 rPos=cPos;
    vec3 color=vec3(242.0/255.0,242.0/255.0,232.0/255.0);
    float maxDist=100.0;
    for(int i=0;i<70;i++){
        distance=distFunc(rPos);
        if(abs(distance)<0.09){
            color=vec3(octaveValueNoise(vec3(rPos.x,0.0,0.0)),octaveValueNoise(vec3(rPos.x,0.0,rPos.z)),octaveValueNoise(vec3(0.0,0.0,rPos.z)));
            vec3 normal=genNormal(rPos);
            color=color*vec3(clamp(dot(lightPos,normal),0.0,1.0))+ambientColor+rLen/30.0;
            break;
        }
        rLen+=distance;
        rPos=cPos+ray*rLen;
        if(rLen>maxDist){
            break;
        }
    }    
    glFragColor=vec4(color,1.0);
}
