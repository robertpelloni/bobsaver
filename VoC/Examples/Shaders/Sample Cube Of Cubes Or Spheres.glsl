#version 420

// original https://www.shadertoy.com/view/csf3WN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 32
#define MAX_DIST 20.
#define PI 3.14159265359
float smin( float a, float b, float k )
{
float h = max( k-abs(a-b), 0.0 )/k;
return min( a, b ) - h*h*h*k*(1.0/6.0);
}
float smax(float a, float b, float k){ return -smin(-a,-b,k);}
float e(float x){
return x < 0.5 ? 4.*pow(x,3.): 1. - pow(-2. * x + 2., 3.) / 2.;
}
float sphSDF(vec3 p, vec3 c, float r){ return length(p-c)-r;}
float cubeSDF(vec3 p, vec3 c, float s){
vec3 q = abs(p-c) - s;
return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
mat3 camera(vec3 cameraPos, vec3 lookAtPoint) {
    vec3 cd = normalize(lookAtPoint - cameraPos);
    vec3 cr = normalize(cross(vec3(0, 1, 0), cd));
    return mat3(-cr, normalize(cross(cd, cr)), -cd);
}
vec2 rot(vec2 p,vec2 c,float ang){
    return (p-c)*mat2(cos(ang), -sin(ang), sin(ang), cos(ang))+c;
}
float distanceToScene(in vec3 p){
    float fd=MAX_DIST;
    float side=.45;
    float gap=.21;
    float timeInt=5.;
    float spe=2.*PI*e(fract(time/timeInt));
    float spe2=2.*PI*e(fract(time/timeInt/2.));
    for(float i=-1.;i<1.1;i+=1.){
        for(float j=-1.;j<1.1;j+=1.){
            vec3 cubeP=p;
            if(j<-.5)cubeP.xz=rot(cubeP.xz,vec2(0.,0.),spe);
            else if(j<.5)cubeP.xz=rot(cubeP.xz,vec2(0.,0.),spe*2.);
            else cubeP.xz=rot(cubeP.xz,vec2(0.,0.),spe*3.);
            for(float k=-1.;k<1.1;k+=1.){
                vec3 cubeP1=cubeP;
                vec3 s=vec3( i*(2.*side+gap),j*(2.*side+gap),k*(2.*side+gap)    );
                cubeP1.xy=rot(cubeP1.xy,s.xy,spe);
                cubeP1.yz=rot(cubeP1.yz,s.yz,spe);
                cubeP1-=sin(spe/2.)*.5;
                float d=cubeSDF(cubeP1,s,side-.8*side*sin(spe2/2.) );
                float f=sphSDF(cubeP1,s,side-.8*side*sin(spe/2.) );
                d=smin(f,d,.2);
                fd=min(fd,d);
            }
        }
    }
    return fd;
}
float  marchRay(vec3 rayO, vec3 rayD,inout bool boundary){
    float dis=0.;
    float prevD=10.;
    float d;
    vec3 p=rayO+rayD*dis;
    for(int i=0;i<STEPS;i++){
        p = rayO+rayD*dis;
        d=distanceToScene(p);
        if(abs(d)<.001 || dis>MAX_DIST)break;
        dis+=d;
        if(d<0.1&&d/prevD>1.){
            boundary=true;
            return d;
        }
        prevD=d;
    }
    return dis;
}
void main(void)
{
    vec2 uv =(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    vec3 rayO = vec3(4., 4., 4.);//camera pos
    vec3 lookPoint = vec3(0.,0.,0.);//where to look
    float zoom=1.;
    
    vec3 rayD= camera(rayO, lookPoint) * normalize(vec3(uv, -zoom)); // ray direction

    vec3 col=vec3(0.);
    bool boundary=false;
    float dis=marchRay(rayO,rayD,boundary);
    if(boundary)col=vec3(smoothstep(  0.6,1., 1.-(dis-0.001)/(0.1-0.001) ) );
    glFragColor = vec4(col,1.0);
}
