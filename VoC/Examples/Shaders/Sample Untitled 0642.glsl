#version 420

// original https://www.shadertoy.com/view/sdXSW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Daily Shader | 007 4/14/2012 @byt3_m3chanic
//
// You know I love me some truchets

#define R   resolution
#define M   mouse*resolution.xy
#define T   time
#define PI  3.14159265359
#define PI2 6.28318530718

#define MAX_DIST    100.
#define MIN_DIST    .001
float hash21(vec2 p)
{
    return fract(sin(dot(p,vec2(23.343,43.324)))*3434.3434);
}
// rotation
mat2 rot(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}
void getMouse(inout vec3 p)
{
    float x = 0.;
    float y = 0.;
 
    p.zy*=rot(x);
    p.xz*=rot(y);
}

const vec3 c = vec3(0.989,0.977,0.989),
           d = vec3(0.925,0.722,0.435);    
vec3 hue(float t){ 
    return .45 + .45*cos(232.+PI2*t*(c*d)); 
}
float vmax(vec3 p)
{
    return max(max(p.x,p.y),p.z);
}
float box(vec3 p, vec3 b)
{
    vec3 d = abs(p) - b;
    return length(max(d,vec3(0))) + vmax(min(d,vec3(0)));
}
float cap( vec3 p, vec2 hr )
{
  p.y -= clamp( p.y, 0.0, hr.x );
  return length( p ) - hr.y;
}
mat2 trs;//precal
float sdTorus( vec3 p, vec2 t, float a ) 
{
  if(a>0.)
  {
  p.xy *= trs;
  p.yz *= trs;
  }
  vec2 q = vec2(length(p.xy)-t.x,p.z);
  return length(q)-t.y;
}
vec2 mod2(inout vec3 p, float scale)
{
    float hlf = scale*.5;
    vec2 id=floor((p.xy+hlf)/scale);
    p.xy = mod(p.xy+hlf,scale)-hlf;
    return id;
}
//@iq
float smin( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
    }
// commonly used var
vec3 hit,hitPoint;
vec2 id,tileId;
mat2 turn;
float travelspeed,zIndex,zid;
// sdf scene
const float size = 3.;
const float hlf = size*.5;
const float sp  = 13.;
const float hsp = sp*.5;
vec2 map(vec3 p)
{
    p.z-=travelspeed;

    zid = floor((p.z+hsp)/sp)-.5;
    p.xy*=rot(zid*.2);
    p.z = mod(p.z+hsp,sp)-hsp;

    vec2 res = vec2(1e5,0.);

    float d = 1e5, t = 1e5;
    vec3 q = p;
    vec3 s = p-vec3(hlf,hlf,-hlf);
    vec2 cid = mod2(q,size);
    vec2 sid = mod2(s,size);
    float ht = hash21(cid+zid); 

    // truchet build parts
    float thx = (.08+.055*sin(p.y*1.25) ) *size;
    if(ht>.5) q.x *= -1.;

    float ti = min(
      sdTorus(q-vec3(hlf,hlf,0),vec2(hlf,thx),0.),
      sdTorus(q-vec3(-hlf,-hlf,0),vec2(hlf,thx),0.)
    );

    // truchet
    if(ti<res.x) {
        res = vec2(ti,2.);
        hit = q;
        id = cid;
    }

    vec2 bfm = vec2(hlf*.825,hlf+.1);

    vec3 nq = cid!=vec2(0) ? q-vec3(0,0,.5) : q;
    float b = box(nq,bfm.xxy);

    b = min(box(q,bfm.yxx),b);
    b = min(box(q,bfm.xyx),b);

    float c = box(q,vec3(hlf)*.925);
    float di = max(c,-b);

    float sp = cap(s.xzy,vec2(3.25,.75));
    di=smin(di,sp,.15);

    // box
    if(di<res.x) {
        res = vec2(di,3.);
        hit = q;
        id = cid;
    }
    
    return res;
}

vec3 normal(vec3 p, float t)
{
    float e = t*MIN_DIST;
    vec2 h = vec2(1.,-1.)*.5773;
    return normalize( h.xyy*map( p + h.xyy*e).x + 
                      h.yyx*map( p + h.yyx*e).x + 
                      h.yxy*map( p + h.yxy*e).x + 
                       h.xxx*map( p + h.xxx*e).x );
}

vec2 marcher(vec3 ro, vec3 rd, int maxsteps){
    float d = 0.;
    float m = 0.;
    for(int i=0;i<maxsteps;i++){
        vec2 ray = map(ro + rd * d);
        if(abs(ray.x)<MIN_DIST*d||d>MAX_DIST) break;
        d += i<64 ? ray.x*.45 : ray.x;
        m  = ray.y;
    }
    return vec2(d,m);
}

float getDiff(vec3 p, vec3 n, vec3 lpos)
{
    vec3 l = normalize(lpos-p);
    float dif = clamp(dot(n,l),.0,1.) * 1.5;
    
    float shadow = marcher(p + n * .01, l, 92).x;
    if(shadow < length(p -  lpos)) dif *= .15;
    return dif;
}

vec3 getColor(float m) 
{
    vec3 h = vec3(.1);
    if(m==1.)
    {
        float mt = floor(time);
        vec2 ud = floor(hitPoint.xz*.6)-.5;
        vec3 f  = fract(hitPoint*.3)-.5;
        float hs = hash21(mt+ud*.2);
        h  = (f.x*f.z>0.) ? vec3(.059) : hue(hs+zIndex); 
    }
    if(m==2.)
    {   
        hitPoint/=size;
        float dir = mod(tileId.x + tileId.y,2.) * 2. - 1.;  
        vec2 cUv = hitPoint.xy-sign(hitPoint.x+hitPoint.y+.001)*.5;
        float angle = atan(cUv.x, cUv.y);
        float a = sin( dir * angle * 2. + time * .75);
        a = abs(a)-.45;a = abs(a)-.35;
        vec3 nz = hue(floor(a*6.5)+zIndex*2.);
        h = mix(nz, vec3(0), smoothstep(.01, .02, a));  
    }
    if(m==3.)
    {
        float hs = hash21(vec2(zIndex*1.4));
        h  = hue(hs)*.35; 
    }
    return h;
}

void main(void)
{
    vec2 F = gl_FragCoord.xy;
    vec4 O = glFragColor;
    //time = time + texture(iChannel1,F/8.).r * timeDelta;//@Fabrice
    travelspeed = time*.75;
    trs = rot(PI*4.5);
    turn = rot(-.1);
    //
    vec3 C, FC = vec3(.01);
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    
    vec3 ro = vec3(0,0,6);
    vec3 rd = normalize(vec3(uv,-1));

    ro.xy*=turn;
    rd.xy*=turn;
    vec2 ray = marcher(ro,rd,164);
    
    float d = ray.x, m = ray.y;  
    hitPoint=hit; tileId=id, zIndex= zid;
    
    if(d<MAX_DIST)
    {
        vec3 p = ro+rd*d;
        vec3 n = normal(p,d);
        vec3 lpos = vec3(0.,0.1,5.5);

        // shade & shadow
        float diff = getDiff(p,n,lpos);
        // coloring
        vec3 h = getColor(m);
        //specular 
        vec3 view = normalize(p-ro);
        vec3 ref = reflect(normalize(lpos), n);
        float spec =  0.85 * pow(max(dot(view, ref), 0.), 64.);
        
        C = h * diff+spec;

        // refleckt
        if(h.x<.001 &&h.y<.001 &&h.z<.001 || m==3.)
        {
            vec3 rr=reflect(rd,n); 
            ray = marcher(p+n*.001,rr, 128);
            
            float d2 = ray.x, m2 = ray.y;  
            hitPoint=hit; tileId=id, zIndex= zid;
            
            if(d2<MAX_DIST){
                p += rr*rd;
                n = normal(p,d2);
    
                // shade - just diffusion
                diff = clamp(dot(n,normalize(lpos-p)),0.,1.);
                // coloring
                vec3 h2 = getColor(m2);
                //specular 
                view = normalize(p-ro);
                ref = reflect(normalize(lpos), n);
                spec =  0.85 * pow(max(dot(view, ref), 0.), 64.);
                
                float fact = m2==3. ? .45 : .75;
                C += min(vec3(1.),C+((h2*diff+spec)*fact));
                C = mix( FC, C, 1.-exp(-.0075*d2*d2)); 

                // refleckt
                if(h.x<.001 &&h.y<.001 &&h.z<.001)
                {
                    rr=reflect(rr,n); 
                    ray = marcher(p+n*.001,rr, 92);
                    
                    float d3 = ray.x, m3 = ray.y;   
                    hitPoint=hit;tileId=id, zIndex= zid;
                    
                    if(d3<MAX_DIST){
                        p += rr*rd;
                        n = normal(p,d3);

                        // shade - just diffusion
                        diff = clamp(dot(n,normalize(lpos-p)),0.,1.);
                        // coloring
                        vec3 h3 = getColor(m3);
                        fact = .5;
                        C = min(vec3(1.),C+((h3*diff)*fact));
                        C = mix( C, FC, 1.-exp(-.00125*d3*d3));

                    } else {
                       C = FC;
                    }
                }
            } else {
               C = FC;
        }
        }
    } else {
        C = FC;
    }

    // standard fog based on distance
    C = mix( C, FC, 1.-exp(-.00125*d*d*d));      
    // gamma correction
    O = vec4(pow(C, vec3(0.4545)),1.0);

    glFragColor=O;
}
