#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tGfzG

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**

    unlocking Oz |  @pjkarlik
    
    Playing between some folding/fractal formulas.
    this is more a tuned version and fades between
    two stylistic approaches.
    
*/

#define R           resolution
#define T           time
#define M           mouse*resolution.xy
#define S           smoothstep

#define PI          3.1415926535
#define PI2         6.2831853070

#define MAX_DIST    75.
#define MIN_DIST    .001

#define hue(a) .425 + .45 * cos(PI2 * a * vec3(1.15,.65,.35) * vec3(.95,.98,.985))
#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec3 g_hp,s_hp;
float g_hsh,s_hsh,ga1,ga2,ga3,ga4,ga5,ga6,orbits;
vec3 travelSpeed;

//thebookofshaders timing functions
float lstep(float b, float r, float t) {
    return clamp((t - b) / (r - b), 0.0, 1.0);
}
//domain rep
vec3 pMod(inout vec3 p, vec3 s) {
    vec3 hs = s*.5;
    vec3 c = floor((p + hs)/s);
    p = mod(p + hs, s) - hs;
    return c;
}
// Fract formulas 
void bt(inout vec4 p, float s, float f, float m) {
    p.xy = abs(p.xy + f) - abs(p.xy - f) - p.xy;
    float rr = dot(p.xyz, p.xyz);
    if (rr < m){
        if(m==0.0) m=0.000001;
        p /= m;
    }else{
        if (rr<1.0) p /= rr;
    }
    p *= s;
}
void cx(inout vec4 p, float s, float k1, float k2, float k3) {
    vec3 cx = vec3(k1, k2, k3);
    if (p.x < p.y) p.xy = p.yx;
    p.x = -p.x;
    if (p.x > p.y) p.xy = p.yx;
    p.x = -p.x;
    if (p.x < p.z) p.xz = p.zx;
    p.x = -p.x;
    if (p.x > p.z) p.xz = p.zx;
    p.x = -p.x;
    p.xyz = p.xyz*s - (s - 1.0)*cx;
    p.w *= abs(float(s));
}
void gl(inout vec4 p, float k1, float k2, float k3, float k4) {
    p = abs(p);
    if (p.x<p.y) p.xy = p.yx;
    if (p.x<p.z) p.xz = p.zx;
    if (p.y<p.z) p.yz = p.zy;
    p.xyz = p.xyz*k1 - vec3(k2, k3, k4)*(k1 - 1.0);
    if (p.z<-0.5*k4*(k1 - 1.0)) p.z += k4*(k1 - 1.0);
    p.w *= abs(k1);

}
float perlin(vec3 p) {
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p);
    p = fract(p);
    p = p * p * (3. - 2. * p);
    vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
    float dx = 43758.5453;
    h = mix(fract(sin(h) * dx), fract(sin(h + s.x) * dx), p.x); 
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

vec2 sdform(in vec3 pos) {
    vec4 P = vec4(pos.xzy, 1.0);
    cx(P, .455, 1., .75, 1.0);
    float orbits = abs(length(P.z)/P.w)*.15;
    for(int i = 0; i < 5; i++) {
        gl(P, 2., .5, 2., .2);
        orbits = max(abs(length(P.y)/P.w)*1.25,orbits);   
    }
    for(int i = 0; i < 2; i++) {
        bt(P, 1.85, 3.25, 0.25);  
    }
    float ln = .55*(length(vec2(P.x,P.y))-1.5)/P.w;
    return vec2(ln,log2(P.w/orbits*.005)); 
}
//for domain and movement
float fft = 1.4;
vec2 map (in vec3 p) {
    vec2 res = vec2(MAX_DIST,0.);
    float k = 11.0/dot(p,p); 
    p *= k;
    p.y+=.05;
    p+=travelSpeed;
    vec3 id = pMod(p,vec3(fft));
    vec2 f = sdform(p);
    if(f.x<res.x) {
        res = vec2(f.x,1.);
        g_hsh = f.y;
        g_hp = p;
    }
 
    float mul = 1.0/k;
    float d = res.x* mul / 1.2;
    return vec2(d,res.y);
}

vec2 marcher( in vec3 ro, in vec3 rd, int maxstep) {
    float t = 0.,m = 0.;
    for( int i=0; i<maxstep; i++ ) {
        vec2 d = map(ro + rd * t);
        m = d.y;
        if(abs(d.x)<MIN_DIST*t||t>MAX_DIST) break;
        t += i < 64 ? d.x*.25 :  d.x *.95;
    }
    return vec2(t,m);
}

// @Shane Tetrahedral normal function.
vec3 getNormal(in vec3 p, float t) {
    // This is an attempt to improve compiler time by contriving a break.
    const vec2 h = vec2(1.,-1.)*.5773;
    vec3 n = vec3(0);
    vec3[4] e4 = vec3[4](h.xyy, h.yyx, h.yxy, h.xxx);
    for(int i = min(0, frames); i<4; i++){
        n += e4[i]*map(p + e4[i]*t*MIN_DIST).x;
            if(n.x>1e8) break; // Fake non-existing conditional break.
    } 
    return normalize(n);
}
vec3 getSpec(vec3 p, vec3 n, vec3 l, vec3 ro) {
    vec3 spec = vec3(0.);
    float strength = 0.75;
    vec3 view = normalize(p - ro);
    vec3 ref = reflect(l, n);
    float specValue = pow(max(dot(view, ref), 0.), 32.);
    return spec + strength * specValue;
}
//@Shane AO
float calcAO(in vec3 p, in vec3 n){
    float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
        float hr = (float(i) + .4)*.0765; 
        float d = map(p + n*hr).x;
        occ += (hr - d)*sca;
        sca *= .9;
        if(sca>1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

vec3 getColor(float m) {
    vec3 h = vec3(1);
    float mnum = mod(floor(s_hsh*4.),6.);
    if(m==1.) h = hue(25.+12.*sin(mnum*.25));
    return h;
}

void main(void) {
    //@Fabrice dithered motion blur
    //time = time + texelFetch(iChannel1,ivec2(F)%1024,0).r * timeDelta;

// change speed here
    float tm = mod(time*1.15, 32.);

    float v1 = lstep(0.0, 2.0, tm);
    float a1 = lstep(2.0, 4.0, tm);
    
    float v2 = lstep(4.0, 6.0, tm);
    float a2 = lstep(6.0, 8.0, tm);
    
    float v3 = lstep(8.0, 10.0, tm);
    float a3 = lstep(10.0, 12.0, tm);
    
    float v4 = lstep(12.0, 14.0, tm);
    float a4 = lstep(14.0, 16.0, tm);
    
    float v5 = lstep(16.0, 18.0, tm);
    float a5 = lstep(18.0, 20.0, tm);
    
    float v6 = lstep(20.0, 22.0, tm);
    float a6 = lstep(22.0, 24.0, tm);
    
    float v7 = lstep(24.0, 26.0, tm);
    float a7 = lstep(26.0, 28.0, tm);
    
    float v8 = lstep(28.0, 30.0, tm);
    float a8 = lstep(30.0, 32.0, tm);
    
    float degy = mix(0., fft/4.,v1+a1+v2+a2+v3+a3+v4+a4+v5+a5+v6+a6+v7+a7+v8+a8);
    float degs = mix(0., fft/2.,v1+v2+v3+v4-v5-v6-v7-v8);
    float degx = mix(0., fft/2.,a1+a2+a3-a4-a5+a6+a7-a8);

    //vec3(degx,degy,degs);
    travelSpeed = vec3(degs,degx,degy);
    
    vec2 U = (2.*gl_FragCoord.xy.xy-R.xy)/max(R.x,R.y);

    float wv = 1.1+1.*sin(time*.2+U.x*.4);

    vec3 ro = vec3(0.,0.,4.8),
         lp = vec3(0,.0,0);

    vec3 cf = normalize(lp-ro),
         cp = vec3(0.,1.,0.),
         cr = normalize(cross(cp, cf)),
         cu = normalize(cross(cf, cr)),
         c = ro + cf * .675,
         i = c + U.x * cr + U.y * cu,
         rd = i-ro;

    vec3 C = vec3(0);
    vec3 FC= vec3(0.020,0.020,0.020);

    vec2 ray = marcher(ro,rd,228);
    s_hp=g_hp;
    s_hsh=g_hsh;
    
    wv=smoothstep(0.,1.25,wv);
    FC = mix(vec3(.9),vec3(.009),pow(wv,5.2));
    
    if(ray.x<MAX_DIST) {
        vec3 p = ro+ray.x*rd,
             n = getNormal(p,ray.x); 

        vec3 lpos = vec3(.2,.2,4.82);
        vec3 ll = normalize(lpos);
        
        vec3 h = getColor(ray.y);
        vec3 h2 = hue( floor(mod( 115.+52.*sin( s_hsh),4.))  );
        vec3 spec = getSpec(p,n,ll,ro);
        float ao = calcAO(p,n);
  
        vec3 aospec= vec3(ao+spec);

        C = mix(h,aospec,pow(wv,5.2));
        
        vec3 pp = reflect(s_hp,n);
        vec3 dn = vec3(perlin(floor(s_hp*100.)*1.25));
        if(dn.x<.3) dn+=perlin(floor(s_hp*400.)*.5);
        if(dn.x>.8) dn+=perlin(floor(s_hp*400.)*.35);
        float fn = pow(length(sin(pp)*.95+2.),2.);
        C = mix(C,C+vec3(dn/fn)*h2,pow(wv,5.2));

    } else {
        C = FC;
    }

    C = mix( C, FC, 1.-exp(-.135*ray.x*ray.x*ray.x));
    glFragColor = vec4(pow(C, vec3(0.4545)),1.0);
}
