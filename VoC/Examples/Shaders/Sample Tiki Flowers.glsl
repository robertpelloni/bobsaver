#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/sssSWS

uniform int frames;
uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Tumbling Boxes | pjkarlik
    Simple multi-tap grid using some hashed
    heights/rotations to give a random feel
     
    
*/

#define R            resolution
#define M            mouse*resolution.xy
#define T            time
#define S            smoothstep
#define PI          3.1415926
#define PI2         6.2831853

#define MIN_DIST    .0001
#define MAX_DIST    40.

//globals//
float glow=0.;

float hash21(vec2 p){ return fract(sin(dot(p, vec2(27.609, 57.583)+date.z))*43758.5453); }
float vmax(vec3 p){ return max(max(p.x,p.y),p.z); }
mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

//@iqhttps://iquilezles.org/www/articles/palettes/palettes.htm
vec3 hue(float t){ 
    vec3 c = vec3(.95, .7, .8),
         d = vec3(0.749,0.251,0.400);
    
    return .45 + .45*cos( PI2*(c*t+d) ); 
}

float box(vec3 p, vec3 b ) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}
float box( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
float box( in vec2 p, in vec2 b, in vec4 r )
{
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}
float opx( in vec3 p, float d, in float h )
{
    vec2 w = vec2( d, abs(p.z) - h );
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}
//http://mercury.sexy/hg_sdf/
void modPolar(inout vec2 p, float rep) 
{
    float angle = 2.*PI/rep;
    float a = atan(p.y, p.x) + angle*.5;
    float c = floor(a/angle);
    a = mod(a,angle) - angle*.5;
    p = vec2(cos(a), sin(a))*length(p);
} 

vec3 hit,hitPoint;
vec2 mid,gid;
float gi=0.,si=0.,shsh,ghsh;

vec2 map(vec3 q3, float sg){
    q3.z =abs(q3.z+.5)-1.5;
   // q3.z += .5;
    q3.y += T*.3;
    // @Shane multi tap grid
    // https://www.shadertoy.com/view/WtffDS
                                
    const vec2 l = vec2(1.);
    const vec2 s = l*2.;        
    vec2 res = vec2(1e5,0.);
    vec2 p,
         ip,
         id = vec2(0),
         ct = vec2(0);
    const vec2[4] ps4 = vec2[4](vec2(-.5, .5), vec2(.5),   vec2(.5, -.5), vec2(-.5));

    for(int i = 1; i<4; i++){
        ct = ps4[i]/2. - ps4[0]/2.;    
        p = q3.xy - ct*s;                    
        ip = floor(p/s) + .5;                
        p -= (ip)*s;                        
        vec2 idi = (ip + ct)*s;    

        float hx = hash21(idi);
        float pt = (.1+hx)*1.15;     
    
        float tt = pt*1.45;
        vec3 qz = vec3(p.x,p.y,q3.z-(pt*2.));
     
        qz.xy*=rot(pt*T);
        qz.zy*=rot(-pt*T);
        
        float pets =round((hx*8.)+2.);
        modPolar(qz.xy,pets);
        float dt = length(qz.y);
        
        float ball=length(qz)-(l.x*.08);
        
        if(ball<res.x) {
            res = vec2(ball, 2.);
            if(sg==1.)  glow += .0001/(.0000075+ball*ball);
        }
        
        float wadjust = sin(qz.x*5.);
        qz.z -= length(qz.xy)*.3;
        float lx = l.x*.65;
        float fanx= box(qz,vec3(lx,.00+.105*wadjust,smoothstep(.01,.35,.00+.035*wadjust)));
        float ff= box(qz.xy,vec2(lx,.00+.065*wadjust));
        ff=abs(ff-.03)-.025;
        float fan = opx(qz,ff,.025);
        if(fan<res.x) {
            res = vec2(fan*.8, 1.);
            mid=idi;
            hit=qz;
            shsh=hx;
            si=pets;
        }
        if(fanx<res.x) {
            res = vec2(fanx*.8, 1.);
            mid=idi;
            hit=qz;
            shsh=hx*2.;
            si=pets;
        }
        
    }

    return res;
}

vec2 marcher(vec3 ro, vec3 rd, float sg, int maxsteps) {
    float d = 0.;
    float m = 0.;
    int thresh =int(maxsteps/2);
    for(int i = 0;i<maxsteps;i++){
        vec2 t = map(ro+rd*d, sg);
        if(abs(t.x)<MIN_DIST*d||d>MAX_DIST) break;
        d += i< 32 ? t.x*.4 :  t.x;
        m  = t.y;
    }
    return vec2(d,m);
}

// Tetrahedron technique @Shane
vec3 normal(vec3 p, float t)
{
    const vec2 h = vec2(1.,-1.)*.5773;
    vec3 n = vec3(0);
    vec3[4] e4 = vec3[4](h.xyy, h.yyx, h.yxy, h.xxx);
    
    for(int i = min(0, frames); i<4; i++){
        n += e4[i]*map(p + e4[i]*t*MIN_DIST,0.).x;
            if(n.x>1e8) break; // Fake non-existing conditional break.
    }
    return normalize(n);
}

vec3 color(float m)
{
    vec3 h = vec3(.5);
    if(m==1.){
        h=gi<3.? vec3(0.337,0.525,0.357):hue(ghsh);
        vec2 uv = hitPoint.xy;
        float d = length(uv)-.025;
        float gw = cos(atan(uv.y,uv.x)*gi)*.1+.1;
        d +=smoothstep(.05,.75,gw);

        if(gi>6.){
            d=abs(abs(abs(abs(d)-.5)-.1)-.05)-.015;
        }else{
            d=abs(abs(abs(d)-.35)-.1)-.015;
        }
        d=smoothstep(.016,.015,d);
        if(gi>3.) h = mix(h,hue(1.-ghsh),d);
    }
    return h;
}

vec3 background(vec2 uv)
{
    vec3 C =mix(vec3(0.506,0.796,0.894),vec3(0.733,0.953,0.588),uv.y*1.5);
    float d = length(uv*1.5)-.055;
    return mix(C,vec3(0.949,0.682,0.110),1.-d); 
}

void main(void) {

    vec2 uv = (2.*gl_FragCoord.xy-R.xy)/max(R.x,R.y);
    vec3 C = vec3(0);
    vec3 FC = background(uv);

    vec3 ro = vec3(0,0,6.5);
    vec3 rd = normalize(vec3(uv,-1));
    
    // mouse //
    float x = 0;//M.xy==vec2(0) ? 0.:-(M.y/R.y*.125-.0625)*PI;
    float y = 0;//M.xy==vec2(0) ? 0.:-(M.x/R.x*.125-.0625)*PI;
    mat2 rx =rot(x);
    mat2 ry =rot(y);
    ro.zy*=rx;rd.zy*=rx;
    ro.xz*=ry;rd.xz*=ry;
    // mouse //
    
    vec2 t = marcher(ro,rd,1.,128);
    float d = t.x;
    float m = t.y;
    hitPoint=hit;
    gid=mid;
    ghsh=shsh;
    gi=si;
            
    if(d<MAX_DIST)
    {
        vec3 p = ro + rd * d;
        vec3 n = normal(p,d);
        const vec3 lpos =vec3(5,4,8);
        vec3 l = normalize(lpos-p);
        
        vec3 h = color(m);

        float diff = clamp(dot(n,l),0.,1.);

        float shdw = 1.0;
        vec3 light = normalize(lpos-p);
        for( float t=.01; t < 32.;)
        {
            float h = map(p + light*t,0.).x;
            if( h<MIN_DIST ) { shdw = 0.; break; }
            shdw = min(shdw, 25.*h/t);
            t += h * .75;
            if( shdw<MIN_DIST || t>64. ) break;
        }
        
        diff = mix(diff,diff*shdw,.75);

        C+=diff*h;
    }
    // Output to screen

    C += glow;    
    C = mix( C, FC, 1.-exp(-.00065*t.x*t.x*t.x));
    C = clamp(C,vec3(0),vec3(1));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
