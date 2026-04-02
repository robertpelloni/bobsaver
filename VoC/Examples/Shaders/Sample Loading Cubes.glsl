#version 420

// original https://www.shadertoy.com/view/WdGfzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// recreation of https://www.reddit.com/r/LoadingIcons/comments/ib3ero/cubes/
// a couple things to note: for the rotation, the camera rotates instead of the cube so I can just 
// map the point I hit on the onto the origianl uv for raymarching a second time without having to 
// reverse any of the rotation. Also, if you look at the bottom left corner of the top cube, you can 
// see the cube slightly change at the  loop point. This is beacuse the map of hit point to the uv for 
// raymarching the second time is done by hand by with hardcoded variable -- I dont feel like figuring
// out what they actal mathamattically correct values are.
#define pi acos(-1.)

mat2 rot(float a){
    float s=sin(a),c=cos(a);
    return mat2(c,-s,s,c);
}

float sdBox(vec3 p,vec3 s){
    p=abs(p)-s;
    return length(max(p,0.))+min(max(p.x,max(p.y,p.z)),0.);
}
float a(float o,float t){
    if(t>o*pi){
        if(t<(o+1.)*pi)
        return cos(t-o*pi)*.5+.5;
        return 0.;
    }
    return 1.;
}
float ar(float o,float t){
    if(t>o*pi){
        if(t<(o+1.)*pi)
        return-cos(t-o*pi+pi)*.25+.25;
        return.0;
    }
    return.5;
}

float map(vec3 p,float t){
    float d;
    p=abs(p);
    p.y-=a(0.,t);
    p.x-=a(1.,t);
    p.z-=a(2.,t);
    p-=1.;
    
    return sdBox(p,vec3(1));
}
float march(vec3 ro,vec3 rd,float t){
    float r;
    for(int i=0;i<100;i++){
        vec3 p=ro+rd*r;
        float dS=map(p,t);
        r+=dS;
        if(r>100.||abs(dS)<.001)break;
    }
    
    return r;
}

vec3 normal(vec3 p,float t){
    float d=map(p,t);
    vec2 e=vec2(.001,0);
    
    vec3 n=d-vec3(
        map(p-e.xyy,t),
        map(p-e.yxy,t),
        map(p-e.yyx,t)
    );
    
    return normalize(n);
}
void camera(inout vec3 ro,inout vec3 rd){
    ro.yz*=rot(.197*pi);
    rd.yz*=rot(.197*pi);
    ro.xz*=rot(.25*pi);
    rd.xz*=rot(.25*pi);
}
void main(void) {
    float t=mod(time*4.,6.*pi);
    vec2 uv=gl_FragCoord.xy/resolution.xy;
    uv-=.5;
    uv/=1.5;
    uv.x/=resolution.y/resolution.x;
    uv/=1.+.5*t/(6.*pi);
    
    vec3 ro=vec3(uv*20.,-50.),
    rd=vec3(0.,0.,1.),
    col=vec3(1.);
    camera(ro,rd);
    
    ro.xz*=rot(ar(3.,t)*pi);
    ro.yx*=rot(ar(4.,t)*pi);
    ro.xz*=rot(ar(5.,t)*pi);
    rd.xz*=rot(ar(3.,t)*pi);
    rd.yx*=rot(ar(4.,t)*pi);
    rd.xz*=rot(ar(5.,t)*pi);
    
    float r=march(ro,rd,t);
    
    if(r<100.){
        vec3 p=ro+rd*r;
        vec3 n=normal(p,t);
        
        col=vec3(.717,.854,.972)*(n.y<-.1?1.:0.);
        col+=vec3(.843,.949,.874)*(n.x<-.1?1.:0.);
        col+=vec3(.933,.631,.776)*(n.z>.1?1.:0.);
        
        if(n.x>.5||n.y>.5||n.z<-.5){
            if(n.x>.5){
                p.zy-=vec2(-2.,2.);
                uv=vec2(p.z,(p.zy*rot(.147*pi)).y);
                uv*=2.;
                uv.x/=1.158;
                uv.y*=1.11;
            }
            if(n.y>.5){
                uv=p.xz*rot(-.25*pi);
                uv.y+=2.793;
                uv.y*=sqrt(2.);
                uv.x*=2.4;
                uv+=.04;
            }
            if(n.z<-.5){
                p-=2.;
                uv=vec2(p.x,(p.xy*rot(-.147*pi)).y);
                uv*=2.;
                uv.x/=1.158;
                uv.y*=1.11;
            }
            uv*=.614;
            col=vec3(1.);
            ro=vec3(uv.xy,-50.);
            rd=vec3(0.,0.,1.);
            camera(ro,rd);
            r=march(ro,rd,0.);
            
            if(r<100.){
                vec3 p=ro+rd*r;
                vec3 n=normal(p,0.);
                
                col=vec3(.717,.854,.972)*(n.z<-.1?1.:0.);
                col+=vec3(.843,.949,.874)*(n.x>.1?1.:0.);
                col+=vec3(.933,.631,.776)*(n.y>.1?1.:0.);
            }
        }
        
    }
    
    glFragColor=vec4(col,1.);
}
