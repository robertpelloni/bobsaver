#version 420

// original https://www.shadertoy.com/view/3lyGRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//rotate function from https://wgld.org/d/glsl/g017.html
vec3 rotate(vec3 p, float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

void main(void)
{
    //from -1 to 1
    vec2 pos2d=( 2.*gl_FragCoord.xy - resolution.xy )/resolution.y;
    
    vec3 pos=vec3(pos2d,0.);
    float length2dSquared=dot(pos2d,pos2d);
    if(length2dSquared<=1.){
        pos.z=sqrt(1.0-length2dSquared);
    }else{
        discard;
    }
    pos=rotate(pos,time,vec3(0.,1.,0.));
    
    float t=(1.+sqrt(5.))/2.;
    vec3 planes[12];
    planes[0]=normalize(vec3(-1.,+t,0.));
    planes[1]=normalize(vec3(+1.,+t,0.));
    planes[2]=normalize(vec3(-1.,-t,0.));
    planes[3]=normalize(vec3(+1.,-t,0.));

    planes[4]=normalize(vec3(0.,-1.,+t));
    planes[5]=normalize(vec3(0.,+1.,+t));
    planes[6]=normalize(vec3(0.,-1.,-t));
    planes[7]=normalize(vec3(0.,+1.,-t));
    
    planes[8]=normalize(vec3(+t,0.,-1.));
    planes[9]=normalize(vec3(+t,0.,+1.));
    planes[10]=normalize(vec3(-t,0.,-1.));
    planes[11]=normalize(vec3(-t,0.,+1.));
    
    vec3 colorR=vec3(1.,0.,0.);
    vec3 colorG=vec3(0.,1.,0.);
    vec3 colorB=vec3(0.,0.,1.);
    vec3 colorC=vec3(0.,1.,1.);
    vec3 colorM=vec3(1.,0.,1.);
    vec3 colorY=vec3(1.,1.,0.);
    vec3 colors[12];
    colors[0]=colorR;
    colors[1]=colorG;
    colors[2]=colorG;
    colors[3]=colorR;

    colors[4]=colorB;
    colors[5]=colorC;
    colors[6]=colorC;
    colors[7]=colorB;

    colors[8]=colorM;
    colors[9]=colorY;
    colors[10]=colorY;
    colors[11]=colorM;
    
    int nearestIndex=0;
    float nearestCos=-1.;
    for(int i=0;i<12;i++){
        float c=dot(pos,planes[i]);
        if(nearestCos<c){
            nearestIndex=i;
            nearestCos=c;
        }
    }
    glFragColor=vec4(colors[nearestIndex]*nearestCos*nearestCos,1.);
    
}
