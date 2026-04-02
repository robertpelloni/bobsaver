#version 420

// original https://www.shadertoy.com/view/ds2Xzd

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .0005
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define Tri(p,s,a) max(-dot(p,vec2(cos(-a),sin(-a))),max(dot(p,vec2(cos(a),sin(a))),max(abs(p).x-s.x,abs(p).y-s.y)))
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )
#define ZERO (min(frames,0))
#define FS 0.05 // font size
#define FGS FS/5. // font grid size

// thx iq! https://iquilezles.org/articles/distfunctions/
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// thx iq! https://iquilezles.org/articles/distfunctions2d/
float sdRoundedBox( in vec2 p, in vec2 b, in vec4 r )
{
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdCappedCylinderZ( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xy),p.z)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float baseBox(vec3 p, vec3 s, vec4 r){
    float d = sdRoundedBox(p.xy,vec2(s.x,s.y),r);
    d = max(abs(p.z)-s.z,d);
    return d;
}

float charA(vec3 p){
    vec2 prevP = p.xy;
    float d = B(p.xy-vec2(0.0,FGS*4.),vec2(FS,FGS));
    float d2 = B(p,vec2(FS,FGS));
    d = min(d,d2);
    p.x = abs(p.x);
    d2 = B(p.xy-vec2(FGS*4.,0.),vec2(FGS,FS));
    d = min(d,d2);
    d = max(abs(p.z)-0.01,d);
    return d;
}

float charB(vec3 p) {
    vec2 prevP = p.xy;
    p.y = abs(p.y);
    float d = B(p.xy-vec2(0.0,FGS*4.),vec2(FS,FGS));
    p.xy= prevP;
    float d2 = B(p.xy-vec2(-FGS,0.0),vec2(FGS*3.,FGS));
    d = min(d,d2);
    
    d2 = B(p.xy-vec2(-FGS*4.,0.),vec2(FGS,FS));
    d = min(d,d2);
    
    p.y = abs(p.y);
    p.xy-=vec2(FGS*2.,FGS*2.);
    p.xy*=Rot(radians(45.));
    d2 = B(p,vec2(FGS,FGS*3.));
    d = min(d,d2);
    d = max(abs(p.z)-0.01,d);
    return d;
}

float tapeGear(vec3 p){
    p.xy*=Rot(radians(20.*time*2.));
    p.xy = DF(p.xy,2.);
    p.xy -= vec2(0.042);
    float d = B(p.xy*Rot(radians(45.0)),vec2(0.008,0.01));
    d = max(abs(p.z)-0.01,d);
    
    return d;
}

float cassette(vec3 p){
    vec3 prevP = p;
    float d = baseBox(p,vec3(0.49,0.28,0.03),vec4(0.03));
    p.z = abs(p.z)-0.05;
    p.y-=0.06;
    float d2 = baseBox(p,vec3(0.47,0.2,0.03),vec4(0.03));
    d = max(-d2,d);
    
    p = prevP;
    p.y+=0.23;
    d2 = sdBox(p,vec3(0.37,0.06,0.03));
    float a = radians(15.);
    p.x = abs(p.x)-0.35;
    d2 = max(dot(p,vec3(cos(a),sin(a),0.0)),d2);
    d = smin(d,d2,0.03);
    
    p = prevP;
    p.x = abs(p.x);
    d2 = sdCappedCylinderZ(p-vec3(0.18,-0.23,0.0),0.1,0.02);
    d = max(-d2,d);
    d2 = sdCappedCylinderZ(p-vec3(0.27,-0.25,0.0),0.1,0.02);
    d = max(-d2,d);
    
    p = prevP;
    p.z = abs(p.z)-0.04;
    p.y-=0.04;
    d2 = baseBox(p,vec3(0.25,0.07,0.03),vec4(0.07));
    d = max(-d2,d);
    
    p = prevP;
    p.x = abs(p.x);
    d2 = sdCappedCylinderZ(p-vec3(0.18,0.04,0.0),0.1,0.06);
    d = max(-d2,d);
    
    p = prevP;
    p.z = abs(p.z)-0.03;
    p.y-=0.04;
    d2 = baseBox(p,vec3(0.1,0.04,0.03),vec4(0.01));
    d = max(-d2,d);
    
    p = prevP;
    p.x = abs(p.x);
    d2 = tapeGear((p-vec3(0.18,0.04,0.0)) * vec3(sign(prevP.x),1,1));
    d = min(d,d2);
    
    p = prevP;
    d2 = charA(p-vec3(-0.36,0.15,-0.03));
    d = min(d,d2);
    
    p.x*=-1.;
    d2 = charB(p-vec3(0.36,0.15,0.03));
    d = min(d,d2);
    
    return d;
}

vec2 GetDist(vec3 p) {
    p.y-=time*0.3;
    vec3 prevP = p;
    p.x-=time*0.2;
    p.x = mod(p.x,1.0)-0.5;
    p.y = mod(p.y,1.2)-0.6;
    float d = cassette(p);
    
    p = prevP;
    
    p.x+=time*0.2;
    p.x+=0.5;
    p.y += 1.8;
    p.x = mod(p.x,1.0)-0.5;
    p.y = mod(p.y,1.2)-0.6;
    
    p.xz*=Rot(radians(180.));
    float d2 = cassette(p);
    d = min(d,d2);
    return vec2(d,0);
}

vec2 RayMarch(vec3 ro, vec3 rd, float side, int stepnum) {
    vec2 dO = vec2(0.0);
    
    for(int i=0; i<stepnum; i++) {
        vec3 p = ro + rd*dO.x;
        vec2 dS = GetDist(p);
        dO.x += dS.x*side;
        dO.y = dS.y;
        
        if(dO.x>MAX_DIST || abs(dS.x)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).x;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).x,
        GetDist(p-e.yxy).x,
        GetDist(p-e.yyx).x);
    
    return normalize(n);
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

// https://www.shadertoy.com/view/3lsSzf
float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<4; i++ )
    {
        float h = 0.01 + 0.15*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = GetDist( opos ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

vec3 diffuseMaterial(vec3 n, vec3 rd, vec3 p, vec3 col) {
    float occ = calcOcclusion(p,n);
    vec3 diffCol = vec3(0.0);
    vec3 lightDir = normalize(vec3(1,10,-10));
    float diff = clamp(dot(n,lightDir),0.0,1.0);
    float skyDiff = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.0,1.0);
    float bounceDiff = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.0,1.0);
    diffCol = col*vec3(-0.5)*diff*occ;
    diffCol += col*vec3(1.0,1.0,0.95)*skyDiff*occ;
    diffCol += col*vec3(1.)*bounceDiff*occ;
    diffCol += col*pow(max(dot(rd, reflect(lightDir, n)), 0.0), 60.); // spec
        
    return diffCol;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){
    col = diffuseMaterial(n,rd,p,vec3(1.3));
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    vec2 m =  mouse*resolution.xy.xy/resolution.xy;
    
    vec3 ro = vec3(0, 0., -2.);
    //if(mouse*resolution.xy.z>0.){
    //    ro.yz *= Rot(m.y*3.14+1.);
    //    ro.y = max(-0.9,ro.y);
    //    ro.xz *= Rot(-m.x*6.2831);
    //} else {
        float scene = mod(time,15.);
        float rotY = 0.;
        float rotX = 0.;
        if(scene>=5. && scene<10.){
            rotY = -20.;
            rotX = -30.;
        } else if(scene>=10.){
            rotY = -20.;
            rotX = 30.;
        }
        
        ro.yz *= Rot(radians(rotY));
        ro.xz *= Rot(radians(rotX));
    //}
    
    vec3 rd = R(uv, ro, vec3(0,0.0,0), 1.0);
    vec2 d = RayMarch(ro, rd, 1.,MAX_STEPS);
    vec3 col = vec3(.0);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col);
    }
    
    // gamma correction
    col = pow( col, vec3(0.9545) );    

    glFragColor = vec4(col,1.0);
}
