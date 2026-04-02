#version 420

// original https://www.shadertoy.com/view/lsV3Rc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision mediump float;
uniform vec4 I;

vec3 Z(vec3 p,float a) {
    return vec3(cos(a)*p.y+sin(a)*p.x,cos(a)*p.x-sin(a)*p.y,p.z);
}

float F(vec3 P) {
    float R=sin((time+P.z)*.03176)*.45+.5,S=3.4312-sin(time*.001);
    vec4 p=vec4(P,1),o=p,s=vec4(S,S,S,abs(S))/R;
    for(int i=0;i<24;i++) {
        if(i==3||i==7||i==11||i==15||i==19||i==23)R=sin(((time+P.z)*.01+float(i)*0.25*sin(time*.00012211154)*3.8)*3.176)*0.45+0.5;
        p.xyz=clamp(p.xyz,-1.,1.)*2.-p.xyz;
        float r2=dot(p.xyz,p.xyz);
        if(r2>1000.)break;
        p=p*clamp(max(R/r2,R),0.,1.)*s+o;
    }
    return((length(p.xyz)-abs(S-1.))/p.w-pow(abs(S),float(1-24)));
}

float D(vec3 p) {
    vec3 c=vec3(10.,10.,8.);
    p=mod(p,c)-.5*c;
    vec3 q=abs(Z(p,p.z*3.1415/10.*4.));
    float d2=max(q.z-10.,max((q.x*0.866025+q.y*0.5),q.y)-.08);
    p=Z(p,p.z*3.1415/10.*(length(p.xy)-3.)*sin(time*.0001)*.8);
    return max(F(p),-d2);
}

vec3 R(vec3 p,vec3 d) {
    float td=0.,rd=0.;
    for(int i=0;i<80;i++) {
        if((rd=D(p))<pow(td,1.5)*.004)break;
        td+=rd;
        p+=d*rd;
    }
    float md=D(p),e=.0025;
    vec3 n=normalize(vec3(D(p+vec3(e,0,0))-D(p-vec3(e,0,0)),D(p+vec3(0,e,0))-D(p-vec3(0,e,0)),D(p+vec3(0,0,e))-D(p-vec3(0,0,e))));
    e*=.5;
    float occ=1.+(D(p+n*.02+vec3(-e,0,0))+D(p+n*.02+vec3(+e,0,0))+D(p+n*.02+vec3(0,-e,0))+D(p+n*.02+vec3(0,e,0))+D(p+n*.02+vec3(0,0,-e))+D(p+n*.02+vec3(0,0,e))-.03)*20.;
    occ=clamp(occ,0.,1.);
    float br=(pow(clamp(dot(n,-normalize(d+vec3(.3,-.9,.4)))*.6+.4, 0.,1.),2.7)*.8+.2)*occ/(td*.5+1.);
    float fog=clamp(1./(td*td*1.8+.4),0.,1.);
    return mix(vec3(br,br/(td*td*.2+1.),br/(td+1.)),vec3(0.,0.,0.),1.-fog);
}

void main(void) {
    vec2 f=gl_FragCoord.xy;
    vec3 d=vec3((f-vec2(resolution/2.))/resolution.y*2.,1.);
    vec3 c=pow(R(vec3(5.,5.,time*.1),normalize(d*vec3(1.,1.,1.-(length(d.xy)*.9)))),vec3(.6,.6,.6));
    //glFragColor=vec4(c,1.);
    glFragColor=vec4(pow(floor(c*vec3(8.,8.,4.)+fract(f.x/4.+f.y/2.)/2.)/(vec3(7.,7.,3.)),vec3(1.5,1.5,1.5)),1.);
}
