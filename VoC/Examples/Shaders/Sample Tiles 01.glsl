#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PITCH 3.
#define POWER 130.

vec3 rotX(vec3 p,float a){return vec3(p.x,p.y*cos(a)-p.z*sin(a),p.y*sin(a)+p.z*cos(a));}
vec3 rotY(vec3 p,float a){return vec3(p.x*cos(a)-p.z*sin(a),p.y,p.x*sin(a)+p.z*cos(a));}
vec3 rotZ(vec3 p,float a){return vec3(p.x*cos(a)-p.y*sin(a), p.x*sin(a)+p.y*cos(a), p.z);}
float line(vec2 p,vec2 l){return pow(1.-length(p-l),POWER);}
float map(vec2 p){float c=line(p,vec2(p.x,floor(p.y*PITCH+.5)/PITCH))+line(p,vec2(floor(p.x*PITCH+.5)/PITCH,p.y))-1e-10;return clamp(c,0.,1.);}

void main(void){
    vec2 p=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y);
    vec3 l=vec3(p.x+1.,p.y-2.,2.5);    //light pos
    vec3 ln=normalize(l);
    float t=time*.05;
    float si=sin(t),co=cos(t);
    mat2 m=mat2(co,-si,si,co);
    p*=m;
    p.x+=time*.7;

    vec3 col=vec3(.5,.4,.1);

    float v=map(p);
    if(v>.3){
        col=vec3(.1,.1,.1);
    }else{
        float dx=map(p+vec2(0.01,0.)),dy=map(p+vec2(0.,0.01));
        vec3 n=rotZ(normalize(vec3(v-dx,v-dy,.2)),-t);
        v=pow(clamp(dot(ln,n),0.,1.),8.);
        col+=v;
    }

    glFragColor = vec4(col,1);
}
