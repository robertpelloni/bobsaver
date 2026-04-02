#version 420

// original https://www.shadertoy.com/view/3t3XW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time (time + 16.)

#define mx (10.*mouse*resolution.xy.x/resolution.x)
#define dmin(a,b) (a.x < b.x) ? a : b

#define pi acos(-1.)
/*
float random( vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.1);
}*/

float random(vec2 u){
    return fract(sin(u.y*4125.1 + u.x *125.625)*225.5235);
} 

float noise(vec2 p) {
    vec2 i = ceil(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3. - 2. * f);
       float a = random(i);
    float b = random(i + vec2(1., 0.));
    float c = random(i + vec2(0., 1.));
    float d = random(i + vec2(1., 1.));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float r31(vec3 u){
    return fract(sin(u.y*125.1 + u.x *125.125 + u.z*525.5215)*115.125235);
} 
float valueNoise(vec3 uv){
    vec3 id = floor(uv);
    vec3 fd = fract(uv);
    fd = smoothstep(0.,1., fd);
    
    float ibl = r31(id + vec3(0,-1,0));
    float ibr = r31(id + vec3(1,-1,0));
    float itl = r31(id + vec3(0));
    float itr = r31(id + vec3(1,0,0));
    
    
    float jbl = r31(id + vec3(0,-1,1));
    float jbr = r31(id + vec3(1,-1,1));
    float jtl = r31(id + vec3(0,0, 1));
    float jtr = r31(id + vec3(1,0, 1));
    
    
    float ibot = mix(ibl, ibr, fd.x); 
    float iup = mix(itl, itr, fd.x);
    float jbot = mix(jbl, jbr, fd.x);
    float jup = mix(jtl, jtr, fd.x);
    
    float i = mix(ibot, iup, fd.y);
    float j = mix(jbot, jup, fd.y);
    
    return mix(i, j, fd.z); 
}

float fbm(vec2 p) { 
    float s = .0;
    float m = .0;
    float a = .5;    
    for(int i = 0; i < 6; i++) {
        s += a * noise(p);
        m += a;
        a *= .5;
        p *= 2.;
    }
    return s / m;
}
float fbm(vec3 p){

    float n = 0.;
    p *= 0.1;
    
    float f = valueNoise(p); 
    
    float q = valueNoise(p*1.4);
    float i = valueNoise(p*5.4 + q*2.);
    float z = valueNoise(p*f*1.4);
    
    n += f*1.8 + q*0.5 + z*0.2 + i*0.3;
    //n += f*1.8 + q*0.5 + z*0.5 + i*0.3;
    
    return n;
}
vec3 carToPol(vec3 p) { 
    float r = length(p);
    float the = acos(p.z/r);
    float phi = atan(p.y,p.x);
    return vec3(r,the,phi);
}
#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))

float Noise(vec2 p) {
    vec2 gv = fract(p);
    vec2 id = floor(p);
    
    gv = smoothstep(0.,1.,gv);
    
    float b = mix(random(id+vec2(0,0)), random(id+vec2(1, 0)), gv.x);
    float t = mix(random(id+vec2(0,1)), random(id+vec2(1, 1)), gv.x);
    
    return mix(b, t, gv.y);
}

vec3 colourBackground(vec3 p, vec3 ro, vec3 rd){
    vec3 col = vec3(0.);
    
    vec3 rayNormal = normalize(p - ro);
    // ---- stardust----// uses bounding circle  and polar coordinates
    vec3 q = vec3(0) + rd ;
    q.xz *= rot(-0.4);
    q.zy*= rot(0.5*pi);
    vec3 pC;
    pC = carToPol(q);
    
    //return abs(sin( (pC.x + pC.y ) *20. ))*vec3(1);
    
    pC.y += 0.2;
    float k = fbm(vec2(pC.y, pC.z)); 
    k = abs(k);
    k = pow(k, 5.);
    k *= 4.;
    float k2= fbm(vec2(pC.y, pC.z)*10.4); 
    float k3= fbm(vec2(pC.y, pC.z) + 14.4); 
    vec3 c;
    c.x = k*k2;
    c.y = k*k3;
    c.z = k*(sin(pC.z)*0.5 + 1.);
    
    col += c;
    // ---- stars2 ---- //
    
    vec2 t = vec2(pC.y, pC.z);
    
    
    // ---- stars ---- //
   
    //float nA = Noise(t*200.14);
    float nA = Noise(t*200.14);
    float nB = Noise(t*944.14);
    col += pow(nA*nB, 10.);
    
    
    // ---- sun ---- //
    
    vec3 pSun = vec3 (14,15, 40.);
    float powSun = dot(normalize(pSun - ro)*1.01, rayNormal);
    vec3 sunCol = vec3(40,30, 40)/100.;
    powSun = pow(powSun, 100.) ;
    vec3 fSun = powSun * sunCol;
    fSun.r = pow(fSun.r, 2.);
    fSun.g *= 0.3*powSun*fSun.b;
    //if(length(fSun)>0.1){col = vec3(0.);}
    //col += fSun;
    //col = pC;
    return col;
}
float total;

float mountainNoise = 0.;
float noiseOther = 0.;
vec2 map(vec3 p){
    vec2 d = vec2(10e7);

    p.z -= 2.;
    
    d = dmin(d, vec2(length(p) - 0.1, 2.));
    
    #define mWidth 29.
    #define mountain vec3(0.9,1,0.)
    p.y += 0.;
    p.x += mWidth;
    //float n = fbm(q*2.3);
    //float asdgasd = r31(p*0.1);
    
    float nA = fbm(p.xz*0.2);
    mountainNoise = nA;
    
    float v = valueNoise(vec3(p.xz*0.4, 4.));
    noiseOther = v;

    vec3 q = p;
    q = p;    
    q.xz += time*0.2;
    q.y += time*0.7;
    float n = fbm(q*1.3)*2.;
    
    //d = dmin(d, vec2(dMountains, 3.));
    
    float dGround = p.y + 0.1;
    dGround -= n*0.595;
    dGround -= sin(p.z + p.x*1.4 + n*20.)*0.17;
    dGround -= v*2.;
    d = dmin(d, vec2(dGround, 1.));
    
    //d.x *= 0.4;
    d.x *= (0.24 + smoothstep(0.,1.,total*0.004));
    return d;
}

vec2 march(vec3 ro,vec3 rd,inout vec3 p,inout float t,inout bool hit){
    vec2 d = vec2(10e6);
    //t = 0.99;
    t = 1.1;
    hit = false;
    p = ro + rd*t;
    for(int i = 0;i < 171; i++){
        d = map(p);
        
        total = t;
        if(d.x < 0.004){
            hit = true;
            break;
        }
        t += d.x;
        p = ro + rd*t;
    }
    
    
    return d;
}

vec3 getRd(vec3 ro, vec3 lookAt, vec2 uv){
    vec3 dir = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0,1,0), dir));
    vec3 up = normalize(cross(dir, right));
    return normalize(dir + right*uv.x + up*uv.y);
}
vec3 getNormal(vec3 p){
    vec2 t = vec2(0.001, 0);
    return normalize(map(p).x - vec3(
        map(p - t.xyy).x,
        map(p - t.yxy).x,
        map(p - t.yyx).x
    ));
}

vec3 ACESFilm( vec3 x )
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return max(vec3(.0), min(vec3(1.0), (x*(a*x+b))/(x*(c*x+d)+e) ) );
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    
    vec3 ro = vec3(0);
    
    uv *= 1. + length(uv)*0.4;

    
    ro.z += time;
    ro.y += 4.5;
    vec3 lookAt = ro + vec3(0,0,17);
    lookAt.y = 0.;
    
    vec3 rd = getRd(ro, lookAt, uv);
    rd.xz *= rot(-0.4 + sin(time*0.2)*0.7);
    vec3 p; float t; bool hit;
    
    //rd.xz *= rot(mx*0.1 + 0.1);
    vec2 d = march(ro, rd, p, t, hit);
    vec3 background = colourBackground(p, ro, rd);
    background.g *= 2.8;
    if(hit){
        
        vec3 l = normalize(vec3(-0.2,0.8,-0.6));
        vec3 n = getNormal(p);
        vec3 h = normalize(l - rd);
        vec3 lightCol = vec3(0.7,0.3,0.9)*0.1;
        
        float diff = max(dot(l, n),0.);
        float spec = pow(max(dot(h, n),0.), 5.);
        float fres = pow(1. - max(dot(-rd, n),0.), 5.);
        
        vec3 albedo = vec3(1);
        
        if (d.y == 1.){
            //\ro = p;
            rd = reflect(rd, n);
            background = colourBackground(p, ro, rd);
            background *= 0.3;
            col += background*fres;
            col += background*spec;   
            
        } else if (d.y == 3.){
            //col += 0.6;
            //albedo = vec3(0.4,0.2,0.8)*0.05;
            albedo = vec3(0.16,0.12,0.18)*0.01;
            spec *= pow(spec, 3.);
            col += mix(diff*albedo, (fres + spec)*lightCol, 0.7 - mountainNoise*0.7);
        } else {
            col += mix(diff*albedo, (fres + spec)*lightCol, 0.3);
        }
    } else {
        
        background *= 0.3;
        col += background;
    }
    
    if(!hit){
        //t = 500;
        t = 500.;
        p = ro + rd * 40.;
    }
    
    float tt = t*0.018;
    p.y -= 3.5;
    p.y *= 0.9;
    col = mix(col, vec3(0.), smoothstep(0.,1.,tt*( 0.2*exp(-p.y*1.)) ));
    col *= 0.7;
    
    //col += 0.004;
    col = pow(col, vec3(0.4545));
    col *= 0.7;
    col = ACESFilm(col);
    float md=sin(valueNoise(vec3(p.xz*2., time*0.1)));
    float mdB=sin(valueNoise(vec3(p.xz*0.2, time*0.1)));
    if(!hit){
        col.g *= 1.1 - md*0.3;
        col.r *= 1. + md;
    
    } else {
        col.b *= 1.1 - mdB*0.8;
        col.r *= 1. + mdB;
        col *= 0.8 ;
    }
    
    uv *= 0.7;
    col *= 1. - dot(uv,uv)*0.4;
    
    col *= 2.4;
    
    glFragColor = vec4(col,1.0);
}
