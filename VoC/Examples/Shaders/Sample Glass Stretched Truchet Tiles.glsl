#version 420

// original https://www.shadertoy.com/view/McySDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Glass Stretched Truchet Tiles
    pseudo reflection/refraction test with elongated truchet tile pattern
    
    05/18/24 @byt3_m3chanic

*/

#define R resolution
#define M mouse*resolution.xy
#define T time

#define PI  3.14159265
#define PI2 6.28318530

vec3 hit,hitPoint;

const float sz = 1.5;
const float hf = sz/2.;

vec3 hue(float t) { return .3 + .25*cos(PI2*t*(vec3(.985,.98,.95)+vec3(0.961,0.576,0.220))); }
mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

float hash21( vec2 p ) { return fract(sin(dot(p,vec2(23.43,84.21))) *4832.3234); }
float hash(in float n) {return fract(sin(n)*43.54); }

float box( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.-2.*f);
    float n = p.x + p.y*57.;
    float res = mix(mix( hash(n+  0.1), hash(n+  1.1),f.x),
                    mix( hash(n+ 57.1), hash(n+ 58.1),f.x),f.y);
    return res;
}

//@iq extrude sdf 
float opx(in float d, in float z, in float h){
    vec2 w = vec2( d, abs(z) - h );
      return min(max(w.x, w.y), 0.) + length(max(w, 0.));
}

vec2 map(vec3 p) {  

    vec2 res = vec2(1e5,0);

    vec2 id = floor((p.xz+hf)/sz);
    vec2 uv = mod(p.xz+hf,sz)-hf;

    float m = floor(mod(id.y,3.)+1.);
    float n = floor(mod(id.x,3.)+1.);

    vec2 cd=vec2(mod(id.x,n),mod(id.y,m))*2.-1.;
    
    float tc = .1;
    float hs = hash21(id);
    if(hs>.5) uv.x = -uv.x;
    
    vec2 gx = length(uv-hf)<length(uv+hf) ? vec2(uv-hf) : vec2(uv+hf);

    float d = length(gx)-hf;
    d = abs(d)-tc;
    
    if(cd.x>.5 ) { d = length(uv.y)-tc;}
    if(cd.y>.5 ) { d = length(uv.x)-tc;}
    if(cd.y>.5 && cd.x>.5) { d = 1.; }

    d = min(abs(d)-.01,d);
    
    float fw =  .6+.5*sin(p.x*.825);
          fw += .6+.5*cos(p.z*.755);
          
    d = opx(d , p.y+1.15-fw,fw);

    if(d<res.x) res=vec2(d,1.);
    
    float f = p.y+1.365;
    if(f<res.x) {
        res=vec2(f,3.);
        hit = p;
    }

    return res;
}

vec3 normal(vec3 p, float t, float mindist) {
    float e = mindist*t;
    vec2 h = vec2(1.,-1.);
    return normalize( h.xyy*map( p + h.xyy*e).x + 
                      h.yyx*map( p + h.yyx*e).x + 
                      h.yxy*map( p + h.yxy*e).x + 
                      h.xxx*map( p + h.xxx*e).x );
}

//@Shane AO
float getao(in vec3 p, in vec3 n) {
    float sca = 3., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = float(i + 1)*.05/1.5; 
        float d = map(p + n*hr).x;
        occ += (hr - d)*sca;
        sca *= .9;
        if(sca>1e5) break;
    }
    
    return clamp(1.-occ, 0., 1.);
}

vec3 render(vec3 p, vec3 rd, vec3 ro, float d, float m, inout vec3 n) {
    n = normal(p,d,1.);
    vec3 lpos = vec3(25,35,-25);
    vec3 l = normalize(lpos);

    float diff = clamp(dot(n,l),.1,1.);
 
    float ao = getao(p,n);
    diff = mix(diff,diff*ao,.7);
    
    vec3 h = vec3(.001,.008,.002);

    if(m==3.) {
        const float sc = .5;
        const float f = sc/2.;
        const float sx = sc/3.5;
        float px = 4./R.x;

        vec2 uv = mod(hitPoint.xz+f,sc)-f;
        vec2 id = floor((hitPoint.xz+f)/sc);
        
        float hs = noise((T+id*.35)*.5);
        float d = box(uv,vec2(.001+hs*sx))-.1;

        h = mix(vec3(.65),hue(hs*.5),smoothstep(px,-px,d));
    };
    
    return diff * h;
}

void main(void) {

    vec2 F=gl_FragCoord.xy;

    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    vec3 ro = vec3(0,0,11.5),
         rd = normalize(vec3(uv,-1));

    float x = 0.;
    float y = 0.;
    
    mat2 rx = rot(1.18-x), ry = rot(.3+y+(.2*sin(T*.1)));
    ro.yz *= rx;ro.xz *= ry;
    rd.yz *= rx;rd.xz *= ry;
    
    ro.x += T*.65;
    
    vec3 C = vec3(0);
    vec3  p = ro + rd;
    float atten = 1.,k = 1.,b = 0.,d,m;
    
    // loop inspired/adapted from @blackle
    // https://www.shadertoy.com/view/flsGDH
    for(int i=0;i<225;i++)
    {
        vec3 n=vec3(0);
        vec2 ray = map(p);
        
        m = ray.y;
        d = i<32? ray.x*.25:ray.x*.8;
        p += rd * d *k;

        if (d*d < 1e-6) {
            b++;
            hitPoint = hit;

            C+=render(p,rd,ro,d,ray.y,n)*atten;
            
            if(b>7.)break; // break loop after 7 bounces.
            
            p += rd*1e-1;
            k = sign(map(p).x);

            if(int(F.x)%2 != int(F.y)%2 || m == 3.) {
                atten *= .625;
                rd=reflect(-rd,n);
                p+=n*.1;
            }else{
                atten *= .750;
                rd=refract(rd,n,.92);
            }

        } 
        
        if(distance(p,rd)>ro.x+35.) {break;}
    }

    C = pow(C, vec3(.4545));
    glFragColor = vec4(C,1);
}
