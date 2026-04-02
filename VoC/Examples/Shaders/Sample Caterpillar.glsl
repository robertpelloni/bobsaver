#version 420

// original https://www.shadertoy.com/view/WdcfDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// SylvainLC 2020 
//
// I measure the difference between an hobbyist (me) and a CG professional like Shadertoy's top contributors.
// But the more important is to learn and have fun isn't it ?
// So thanks to IQ, Bigwings, Shane, Fabrice and you all guys ! 
// You are so good at teaching modeling, colors, lighing, fractals all these magic procedural technics ... 
// many thanks for your great tutorials and demos !

// This started from the idea to copy Fabrice"s Crawl shader
// https://www.shadertoy.com/view/3d3fRr
// But using IQ 2D Joints 
// https://www.shadertoy.com/view/WldGWM
// The Kawaii face is based on the BigWings tutorial to make a smiley face.
// https://www.youtube.com/watch?v=ZlNnrpM0TRg
// My personal notebook https://hackmd.io/@NmkGBTybRuKG4gBXN_rlmA/SkE6XqmDw

#define PI acos(-1.)
#define TAU 6.283185

#define SMALL_ANGLE 0.01
#define MAX_ANGLE .7*PI
#define MIN_ANGLE .1*PI
#define SEGMENTS 4

#define S(a, b, t) smoothstep(a, b, t)
#define B(a, b, blur, t) S(a-blur, a+blur, t)*S(b+blur, b-blur, t)
#define sat(x) clamp(x, 0., 1.)

mat2 Rot(float a) {
    float s=sin(a);
    float c=cos(a);
    return mat2(c, -s, s, c);
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,233.53));
    p += dot(p, p+23.234);
    return fract(p.x*p.y);
}

float remap01(float a, float b, float t) {
    return sat((t-a)/(b-a));
}

float remap(float a, float b, float c, float d, float t) {
    return sat((t-a)/(b-a)) * (d-c) + c;
}

vec2 within(vec2 uv, vec4 rect) {
    return (uv-rect.xy)/(rect.zw-rect.xy);
}

float sdArc( in vec2 p, in vec2 sca, in vec2 scb, in float ra, float rb )
{
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

vec4 Antenna(vec2 uv,float blur,float side,float time) {
    vec3 col=vec3(0);
    float d=length(uv);
    float a=1.-S(-blur,blur,d-0.06);
    float l=0.5;
    float bend=3.14*.25+0.2*sin(time*3.0);
    float r=l/bend;
    vec2 sc=vec2(sin(bend),cos(bend));
    vec2 start = uv-vec2(r,0.0);
    float d2=sdArc(start,sc,sc,r,0.03);
    a=max(a,1.-S(-blur,blur,d2));
    vec2 offset = start*Rot(2.*bend)+vec2(r,0.0);
    float d3=length(offset);
    a=max(a,1.-S(-blur,blur,d3-0.1));
    return vec4(col,a);    
}

vec4 Mouth(vec2 uv, float blur,float time) {
    vec3 col=vec3(1.0,0.5,0.5)*.7;
    uv.y *= 2.9;
    uv.y-=uv.x*uv.x*(0.8+0.3*sin(time*3.0));
    float d=length(uv);
    float a=1.-S(-blur,blur,d-.8);
    float td=length(uv-vec2(0.0,-0.5));
    col = mix(col,col*1.5, 1.0-S(.4,.6,td));            
    return vec4(col,a);
}

vec4 Eye(vec2 uv, float blur, float side) {
    vec3 col=vec3(0);
    float d=length(uv);
    float a=1.-S(-blur,blur,d-.5);
    float d2=length(uv-vec2(-0.1*side,0.15));
    col = mix(col,vec3(1.),1.-S(-blur,blur,d2-0.15));
    float d3=length(uv-vec2(0.1*side,-0.15));
    col = mix(col,vec3(1.),1.-S(-blur,blur,d3-0.07));
    return vec4(col,a);
}

vec4 Head(vec2 uv,float blur,float time) {
    vec3 green = vec3(.29,.99,.3);
    float side = sign(uv.x);
    uv.x=abs(uv.x);
    float d=length(uv);
    vec3 col = green*S(0.5,0.48,d);
    float a = 1.-S(-blur,blur,d-.5);
    float edgeShade = remap01(.10,.5,d);
    edgeShade*=edgeShade;
    col *= 1.-.5*edgeShade;
    float cheeks = length(uv-vec2(0.35,-0.2));
    col+= vec3(1.0,0.0,0.0) * S(0.15,0.0,cheeks);
    float factor = 3.0;
    vec4 eye = Eye((uv-vec2(0.2,0.05))*factor,blur*factor,side);
    col = mix(col,eye.rgb,eye.a);
    factor = 3.0;
    vec4 mouth = Mouth((uv-vec2(0.0,-0.30))*factor,blur*factor,time);
    col = mix(col,mouth.rgb,mouth.a);
    return vec4(col,a);    
}

// Shane https://www.shadertoy.com/view/llSyDh
// Dot pattern. Play with it !!!
float dots(in vec2 p){
    p = abs(fract(p) - .5);
    return length(p); // Circles.
    // return (p.x + p.y)/1.5 + .035; // Diamonds.
    // return max(p.x, p.y) + .03; // Squares.
    // return max(p.x*.866025 + p.y*.5, p.y) + .01; // Hexagons.
    // return min((p.x + p.y)*.7071, max(p.x, p.y)) + .08; // Stars.
}

// I got ideo of animations system from this Shader.
// PixelPhil https://www.shadertoy.com/view/3tKGDW    
// All the parametters for an animation pose
struct KeyFrame
{
    float[SEGMENTS] a;  // bending angle of each segment, element 0 is the head
    float[SEGMENTS] l;  // length of each segment
    bool headFirst;       // compute from fixed tail or fixed head
};
    
// Linear interpolation between two animation frames  NOT used here because c is out only
void mixKeyFrame(KeyFrame a, KeyFrame b, float ratio, out KeyFrame c)
{
    ratio = ratio*ratio*(3.0-2.0*ratio); // Thanks iq :D
    for ( int i=0 ; i <SEGMENTS ; i++ ) {
        c.a[i]    = mix(a.a[i],b.a[i],ratio);
    }
}    

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// and many more here:   http://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
// Joint:                https://www.shadertoy.com/view/WldGWM
vec3 sdJoint2DSphere( in vec2 p, in float l, in float a, float w)
{
    // parameters
    vec2  sc = vec2(sin(a),cos(a));
    float ra = 0.5*l/a;
    
    // recenter
    p.x -= ra;
    
    // reflect
    vec2 q = p - 2.0*sc*max(0.0,dot(sc,p));

    // distance
    float u = abs(ra)-length(q);
    float d = (q.y<0.0) ? length( q+vec2(ra,0.0) ) : abs(u);

    // parametrization (optional)
    float s = ( a > 0.) ? 1. : -1.;
    float v = ra*atan(s*p.y,-s*p.x);
    u = u*s;
    if( v<0.0 )
    {
        if( s*p.x>0.0 ) { v = abs(ra)*6.283185 + v; }
        else { v = p.y; u = q.x + ra; }
    }
    
    return vec3( d-w, u, v );
}

// manage if near perfectly straight 
vec3 sdJoint2DSphere2( in vec2 p, in float l, in float an, float w)
{
    if ( length(p) > l+2.*w ) return vec3(length(p)-(l+w),0.,0.);
    return abs(an) < SMALL_ANGLE ? 
        vec3( length(vec2(p.x,p.y - clamp(p.y,0.0,l)))-w, p.x, p.y ) : 
        sdJoint2DSphere( p, l,  an, w);
}

vec3 sdJoint2DFlat( in vec2 p, in float l, in float a, float w)
{
    // parameters
    vec2  sc = vec2(sin(a),cos(a));
    float ra = 0.5*l/a;
    
    // recenter
    p.x -= ra;
    
    // reflect
    vec2 q = p - 2.0*sc*max(0.0,dot(sc,p));

    // distance
    float u = abs(ra)-length(q);
    float d = max(length( vec2(q.x+ra-clamp(q.x+ra,-w,w), q.y) )*sign(-q.y),abs(u) - w);

    // parametrization (optional)
    float s = ( a > 0.) ? 1. : -1.;
    float v = ra*atan(s*p.y,-s*p.x);
    u = u*s;
    
    return vec3( d, u, v );
}

// manage if near perfectly straight 
vec3 sdJoint2DFlat2( in vec2 p, in float l, in float an, float w)
{
    return abs(an) < SMALL_ANGLE ? vec3( sdBox(vec2(p.x,p.y-l*.5),vec2(w,l*.5)), p.x, p.y ) : 
        sdJoint2DFlat( p, l,  an, w);
}

// https://www.iquilezles.org/www/articles/checkerfiltering/checkerfiltering.htm
// https://www.shadertoy.com/view/XlcSz2 - just Magic
float checker( in vec2 p )
{
    // filter kernel
    vec2 w = fwidth(p) + 0.01;  
    // analytical integral (box filter)
    vec2 i = 2.0*(abs(fract((p-0.5*w)/2.0)-0.5)-abs(fract((p+0.5*w)/2.0)-0.5))/w;
    // xor pattern
    return 0.5 - 0.5*i.x*i.y;                  
}

vec2 getNextSeg2(float l, float an) {
    vec2 p=vec2(0);
    float ra = -l/an;
    p.x-=ra; // to be honest I didn't really understood how it works but it works
    p+=ra*vec2(cos(an),-sin(an));
    return p;
}

// manage limit case
vec2 getNextSeg(float l, float an) {
    return abs(an) < SMALL_ANGLE ? 
        vec2(0.,l) : 
        getNextSeg2( l,  an);
}

// The caterpillar start in initial position and is pushing on its tail.
void PushingAnim(inout KeyFrame kf,float time)
{
    time = fract(time);
    time = time*time*(3.-2.*time);
    float a = mix(MAX_ANGLE,MIN_ANGLE,time);
    float delta = .2*smoothstep(0.,1.0,sin(time*PI));
    kf.a[0] = -a-delta;
    kf.a[1] = a;
    kf.a[2] = a;
    kf.a[3] = -a-delta;
    kf.headFirst = false;
}

// The caterpillar start in extended position and is pulling on its head.
void PullingAnim(inout KeyFrame kf,float time) {
    time = fract(time);
    time = time*time*(3.-2.*time);
    float a = mix(MIN_ANGLE,MAX_ANGLE,time);
    float delta = .2*smoothstep(0.,1.0,sin(PI*time));
    kf.a[0] = a+delta;
    kf.a[1] = -a;
    kf.a[2] = -a;
    kf.a[3] = a-delta*sin(time*PI*5.); // tail moving like a dog
    kf.headFirst = true;
}

// The caterpillar makes a trick
void FunAnim(inout KeyFrame kf,float time) {
    time = fract(time/8.);
    // time = time*time*(3.-2.*time);
    KeyFrame kfa;
    kfa.a[0] = -MAX_ANGLE;
    kfa.a[1] = MAX_ANGLE;
    kfa.a[2] = MAX_ANGLE;
    kfa.a[3] = -MAX_ANGLE;
    KeyFrame kfb;
    kfb.a[0] = -PI/3.+sin(time*TAU*4.);
    kfb.a[1] = PI/2.2+.5*cos(time*TAU*4.);
    kfb.a[2] = PI/2.-.2*sin(time*TAU*4.);
    kfb.a[3] = -PI/1.5-.1*cos(time*TAU*4.);
    float ratio = 2.*(time-.5);
    ratio*=ratio; // many squares here
    ratio = ratio*ratio*(3.0-2.0*ratio); // Thanks iq :D
    for ( int i=0 ; i <SEGMENTS ; i++ ) {
        kf.a[i]    = mix(kfb.a[i],kfa.a[i],ratio);
    }
    // mixKeyFrame(kfb,kfa,ratio*ratio,kf); // here this fonction causes the issue in my case because out only
    kf.headFirst = false;
//    kf.l[1]+=(0.15-0.15*cos(time*TAU));
    kf.l[2]+=(0.15-0.15*cos(time*TAU));
    kf.l[3]+=(0.15-0.15*cos(time*TAU));
}

// The caterpillar grows
void LongAnim(inout KeyFrame kf,float time) {
    time = fract(time*.25);
    time = time*time*(3.-2.*time);
    // time = time*time*(3.-2.*time);
    kf.a[0] = -MAX_ANGLE-.5*sin(time*PI*5.); // head moving like a dog;
    kf.a[1] = MAX_ANGLE-.5*sin(2.*time*PI);
    kf.a[2] = MAX_ANGLE-.5*sin(time*PI);
    kf.a[3] = -MAX_ANGLE;
    kf.headFirst = false;
    kf.l[1]+=(0.15-0.15*cos(.001+time*TAU));
    kf.l[2]+=(0.15-0.15*cos(.001+time*TAU));
}

vec2 huv=vec2(0);

vec3 sdCaterpillar(vec2 p, float time, vec2 m) {
    vec3 duv = vec3(1.);
    float l=.25; 
    float w = .05+m.y*.05;
    KeyFrame kf;
    kf.l[0] = l;
    kf.l[1] = l+.3*(m.x+.5);
    kf.l[2] = l+.3*(m.x+.5);
    kf.l[3] = l;  
    float akeys=12.;
    float anid = mod(floor(time),akeys); // animation id
    float atime = anid+fract(time);
    vec2 start = vec2(-0.4,w); // starting position
    vec2 q = (p-start); 
    float totl = kf.l[0]+kf.l[1]+kf.l[2]+kf.l[3]; // total length
    float stride = totl*(getNextSeg(1.,MIN_ANGLE).y-getNextSeg(1.,MAX_ANGLE).y); // this means you should start at well know position
    if ( anid < 1. ) { // first step
        PushingAnim(kf,atime);
        q.x-=-stride*2.;
    } else if ( anid < 2.  ) {
        PullingAnim(kf,atime);
        q.x-=-stride*2.;
        q.x-=totl*getNextSeg(1.,MIN_ANGLE).y;
    } else if ( anid < 3. ) { // second step
        PushingAnim(kf,atime);
        q.x-=-stride;
    } else if ( anid < 4.  ) {
        PullingAnim(kf,atime);
        q.x-=-stride;
        q.x-=totl*getNextSeg(1.,MIN_ANGLE).y;
    } else if ( anid < 12.  ) FunAnim(kf,atime-4.);
        else if ( anid < 16. ) LongAnim(kf,atime-8.);
    // panning the camera
    q.x-=2.*stride*smoothstep(4.5,0.,atime);    
    // compute the Caterpillar
    q*=Rot(-PI/2.);
    totl = kf.l[0]+kf.l[1]+kf.l[2]+kf.l[3]; // total length
    if ( kf.headFirst ) {
        // compute from head to tail
        huv=q+vec2(0.,w);
        float ta = kf.a[0]; // total angle
        duv = sdJoint2DSphere2(q,kf.l[0],ta*.5,w);
        float tl=kf.l[0]; // total length
        for ( int i = 1 ; i < 4 ; i++ ) {
            float a = kf.a[i];
            q-=getNextSeg(kf.l[i-1],ta);
            q*=Rot(ta);
            vec3 duv2 = sdJoint2DSphere2(q,kf.l[i],a*.5,w);
            ta=a;
            duv2.z+=tl;
            tl+=kf.l[i];
            duv = (duv.x<duv2.x) ? duv : duv2;
        }
    } else {
        // compute from tail to head more triky and confusing
        float a = kf.a[3];
        q-=getNextSeg(-kf.l[3],a);
        q*=Rot(a);
        duv = sdJoint2DSphere2(q,kf.l[3],-a*.5,w);
        float tl=totl-kf.l[3];
        duv.z += tl; 
        for ( int i = 2 ; i >= 0 ; i-- ) {
            float a = kf.a[i];
            q-=getNextSeg(-kf.l[i],a);
            q*=Rot(a);
            vec3 duv2 = sdJoint2DSphere2(q,kf.l[i],-a*.5,w);
            tl-=kf.l[i];
            duv2.z+=tl;
            duv = (duv.x<duv2.x) ? duv : duv2;
        }
        huv=q+vec2(0.,w);
    }
    duv.y/=w;
    duv.z = duv.z > 0. ? duv.z/(totl/4.) : duv.z/l; // avoid deformation of the head UV
    return duv;
}

void main(void)
{
    float time = time;  
    // normalized pixel coordinates from -.5 to .5
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 campos1=vec3(0.1,-0.2,1.);
    vec3 campos2=vec3(0.6,0.3,1.4);
       vec3 campos = mix(campos1,campos2,S(4.0,8.0,12.0*fract(time/12.))*S(12.0,8.0,12.0*fract(time/12.)));
//    campos=campos1;
    uv/=campos.z;
    uv+=campos.xy;
    
    vec2 m = vec2(0.);
    //if ( mouse*resolution.xy.y > 1. ) {
    //    m = (mouse*resolution.xy.xy-.5*resolution.xy)/resolution.xy;
    //}
    vec3 col = mix(vec3(0.9),vec3(0.15,0.5,0.9),1.-gl_FragCoord.xy.y/resolution.y); // to do create a nice background  !!         
    float f = -.6; // floor
    col=mix(col,vec3(0.1,0.9,0.1)*.4,smoothstep(0.01,0.0,uv.y-f)) ;; 
    vec3 duv=sdCaterpillar(uv-vec2(0.,f),time,m);
    if( duv.x<0.0 ) // coloring inside the Caterpillar
    {
       // col = checker(duv.yz*10.0)*vec3(1);
        vec3 green = vec3(.29,.99,.3);
        vec3 yellow = vec3(.99,.99,.3);
        vec3 bcol = yellow*1.4*smoothstep(0.1,.4,abs(sin(duv.z*TAU*5.)));
        green*=.8+.2*smoothstep(1.,.0,(sin(duv.z*TAU*10.))); // green segments
        col = mix(bcol,green,smoothstep(-.5,-.4,duv.y));
        if ( duv.y > 0.01 ) {
            float c = 2.*dots(vec2(duv.y*.5+.05,4.*duv.z-.3));
            col = mix(col,vec3(0.),smoothstep(.90,.75,c));
            col = mix(col,vec3(1.,.1,.1),smoothstep(.75,.70,c));
            col = mix(col,yellow*1.5,smoothstep(.50,.45,c));
        } 
        col *= mix(1.0,0.5,abs(duv.y)); // shadow
    }  
    // outline
    col = mix( col, vec3(0.0), 1.0-smoothstep(0.0,4.,abs(duv.x*resolution.x)) ); // 3 pixels thanks Bigwigs
    // added eyes and antenna
    {
        float blur = 7.0*3.0/resolution.x;
        vec2 uv=huv-vec2(0.01,-0.01);
        uv=vec2(-uv.y,uv.x)*7.;
        vec4 eye = Head(uv,blur,time);
         col = mix(col, eye.rgb, eye.a);    
        vec4 antenna = Antenna(vec2(abs(uv.x),uv.y)-vec2(0.25,0.40),blur,sign(uv.x),time);
        col = mix(col, antenna.rgb, antenna.a);    

    }
    glFragColor = vec4(col*col, 1.0);
}    
