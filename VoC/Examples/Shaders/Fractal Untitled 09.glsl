#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float ball(vec3 p)
{
return length(p)-1.0;        
}
vec4 mul4(vec4 a,vec4 b)
{
    return vec4(cross(a.xyz,b.xyz)+a.w*b.xyz+b.w*a.xyz,a.w*b.w-dot(a.xyz,b.xyz));    
}
vec3 rot(vec3 p,vec3 dir,float ang)
{
    float cosha=cos(ang*0.5),sinha=sin(ang*0.5);
//    dir=normalize(dir);
    vec4 rot=vec4(sinha*dir,cosha);
    vec4 q=mul4(rot,vec4(p,0.0));
    rot.xyz=-rot.xyz;
    q=mul4(q,rot);
    return q.xyz;    
}
vec2 InvBall(vec2 pos,vec2 circlePos,float r,inout float dr)
{
    vec2 pc=pos-circlePos;
    float k=r*r/dot(pc,pc);
    dr*=k;
    pos=k*pc+circlePos;
    return pos;    
}
const int max_iterations=15;

const int polygen=6;
const float pi=3.1415926535897932384626433832795;
 float edgelen=3.;
vec2 c[2*polygen+2];
float r[2*polygen+2];
float de(vec2 pos)
{
    float pn=pi/float(polygen);
    float sinang=sin(pn),cosang=cos(pn);    
    c[0]=vec2(0.0,0.0);
    r[0]=0.5*edgelen*(1.0/sinang-1.0);    
    for(int i=0;i<polygen;i++){
        float ang=2.0*float(i)*pn;
        c[i+1]=0.5*edgelen/sinang*vec2(cos(ang),sin(ang));
        r[i+1]=0.5*edgelen;
    }

    float b=(sinang*sinang+cosang)/cosang/cosang;
    float outedge=(b+sqrt(b*b-1.0))*edgelen;
    for(int i=0;i<polygen;i++){
        float ang=2.0*float(i)*pn+pn;
        c[polygen+i+1]=0.5*outedge/sinang*vec2(cos(ang),sin(ang));
        r[polygen+i+1]=0.5*outedge;
    }
    c[2*polygen+1]=vec2(0.0,0.0);
    r[2*polygen+1]=0.5*(outedge/sinang+outedge);
    
    float iteration=0.0,dr=1.0;
    bool transformed;
    for(int n=0;n<max_iterations;n++){
        transformed=false;
        for(int i=0;i<2*polygen+1;i++)if(length(pos-c[i])<r[i]){
            pos=InvBall(pos,c[i],r[i],dr);
            pos=2.0*clamp(pos,vec2(-outedge,-outedge),vec2(outedge,outedge))-pos;
            iteration+=1.0;
            transformed=true;
            break;
        }
        if(!transformed)break;        
    }    
    return length(pos.x)/dr;
}
const int iterations=10;
float R=4.0;
vec2 dist(vec3 pos,vec3 dir, out vec3 tn,out vec3 tf)
{
    float d1=0.0,td1=0.0,d2=0.0,td2=0.0;
    float delta=dot(dir,pos)*dot(dir,pos)-(dot(pos,pos)-R*R);
    if(delta<0.0)return vec2(-100.0);
    float t1=-dot(dir,pos)-sqrt(delta),t2=-dot(dir,pos)+sqrt(delta);
    tn=pos+t1*dir,tf=pos+t2*dir;
    vec2 p1=vec2(atan(tn.y,length(tn.xz))/pi*2.0,atan(tn.z,tn.x)/pi*2.+0.5)*R,p2=vec2(atan(tf.y,length(tf.xz))/pi*2.0,atan(tf.z,tf.x)/pi*2.+0.5)*R;
    return vec2(de(p1),de(p2));    
}
void main( void ) {

    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec3 pos =vec3(8.0*surfacePos,12.0),dir=vec3(0.0,0.0,-1.0),tn,tf,light=normalize(vec3(0.2,0.5,0.8)),rotx=normalize(vec3(1.0,0.5,0.2));
    pos=rot(pos,rotx,0.2*time);
    dir=rot(dir,rotx,0.2*time);
    light=rot(light,rotx,0.2*time);
    vec2 c=dist(pos,dir,tn,tf);
    if(c.x>0.0){
    c=smoothstep(0.0,0.01,c);
    vec2 cc=smoothstep(0.99,0.0,c);
    float color=dot(vec2(dot(tn,light)/length(tn-vec3(0.0,0.0,10)),dot(-tf,light)/length(tf-vec3(0.0,0.0,10.))),c);
    float col=dot(vec2(dot(tn,light)/length(tn-vec3(0.0,0.0,10)),dot(-tf,light)/length(tf-vec3(0.0,0.0,10.))),cc);
    glFragColor = vec4( vec3( 2.0*col, 2.0*col, color ), 1.0 );
    }
    else glFragColor=vec4(0.0);

}
