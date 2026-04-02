#version 420

// original https://www.shadertoy.com/view/3tSXRD

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//A shader in two colors, black and white
//A relaxing walk at night

//comment this out to remove the head bobbing
#define HEAD_BOB

const float SPEED=10.;

//Hashes from David Hoskins at https://www.shadertoy.com/view/4djSRW
float hash11(float p){
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
float hash12(vec2 p){
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash21(float p){
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float pointPointDist(vec3 p, vec3 q){
    return length(p-q);
}
float pointRayDist(vec3 o, vec3 r, vec3 p){
    vec3 a=o-p;
    if(dot(r,-a)<0.){return -1.;}
    return sqrt(dot(a,a)-dot(-a,r)*dot(-a,r));
}
float spherePointDistOnLine(vec3 o, vec3 r, vec3 s) {
     vec3  a = o - s.xyz;
    float b = dot(a,r);
    float c = dot(a,a)-1.;
    float t = b*b - c;
    if( t > 0.0) 
        t = -b - sqrt(t);
    return t;
}
float sphereTime(float id){
    return 40.*hash11(id)+10.+SPEED*time-id;
}

float sphereVertical(float id){
    float st=sphereTime(id)/(.5*SPEED);
    if(st<.5){return 2e20;}
    float t =fract(st);float b=floor(st);
    float ht=max(0.,((100./(10.*b+1.))-2.))*(.5+hash11(id+.1));
    return max(-ht*(t-.5)*(t-.5)+.25*ht,0.);
}

float ripples(float id,float d){
    float st=sphereTime(id)/(.5*SPEED);
    float t =fract(st);float b=floor(st);
    if(t>.5){return 0.;}
    float ht=max(0.,((100./(10.*b+1.))-2.))*(.5+hash11(id+.1));
    float dt=-ht*t+ht/2.;
       return step(.1,dt*2.*(-abs(abs(abs(4.*(d-(2.*t+1.))-2.5)-1.)-1.)+.5)/(4.*(d-(2.*t+1.))+1.));
}

vec3 spherePosition(float id){
    vec2 tg=hash21(id)*vec2(70.,.5);
    return vec3(tg.x-35.,sphereVertical(id),tg.y+id);
}

float trace(vec3 o,vec3 r,vec2 sky){
    float sh=floor(o.z);
    float fDist=-o.y/r.y;
    vec3 gP=fDist*r+o;
    bool hit=false;
    float minHitDist=2e20;
    float minGroundDist=2e20;
    float minGroundID=-1.;
    float minGroundDist1=2e20;
    float minGroundID1=-1.;
    float minGroundDist2=2e20;
    float minGroundID2=-1.;
    for(float i=0.;i<50.;i++){
        vec3 sP=spherePosition(i+sh);
        float hitD=spherePointDistOnLine(o,r,sP);
        if(hitD>0.&&hitD<minHitDist){
            hit=true;
            minHitDist=hitD;
        }
        float d=pointPointDist(gP,sP);
        float st=(sphereTime(i+sh)/(.5*SPEED));
        if(st>.5&&st<7.5){
            if(d<minGroundDist){
                minGroundDist2=minGroundDist1;
                minGroundID2=minGroundID1;
                minGroundDist1=minGroundDist;
                minGroundID1=minGroundID;
                minGroundDist=d;
                minGroundID=i+sh;
            }else if(d<minGroundDist1){
                minGroundDist2=minGroundDist1;
                minGroundID2=minGroundID1;
                minGroundDist1=d;
                minGroundID1=i+sh;
            }else if(d<minGroundDist2){
                minGroundDist2=d;
                minGroundID2=i+sh;
            }
        }
    }
    if(minHitDist>fDist&&r.y<0.){
        return ripples(minGroundID ,length(spherePosition(minGroundID )-gP))
              +ripples(minGroundID1,length(spherePosition(minGroundID1)-gP))
              +ripples(minGroundID2,length(spherePosition(minGroundID2)-gP));
    }else if(hit){
        return 1.;
    }else if(r.y>0.&&hash12(sky.xy-vec2(0.,frames))>.98){
        return 1.;
    }else{
        return 0.;
    }
}

void main(void) {
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    #ifdef HEAD_BOB
        vec3 o = vec3(.2*cos(5.*time),2.+.3*abs(sin(5.*time)),SPEED*time-4.);
    #else
        vec3 o = vec3(0.,2.,SPEED*time-4.);
    #endif
    vec3 r = normalize(vec3(uv,1.));
    glFragColor=vec4(trace(o,r,gl_FragCoord.xy));
}
