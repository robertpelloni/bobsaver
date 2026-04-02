#version 420

// original https://www.shadertoy.com/view/flyBRD

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
#define SPEED 200.
#define ZERO (min(frames,0))

// thx iq! https://iquilezles.org/articles/distfunctions2d/
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

// thx iq! https://iquilezles.org/articles/distfunctions2d/
float sdUnevenCapsule( vec2 p, float r1, float r2, float h )
{
    p.x = abs(p.x);
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(p,vec2(-b,a));
    if( k < 0.0 ) return length(p) - r1;
    if( k > a*h ) return length(p-vec2(0.0,h)) - r2;
    return dot(p, vec2(a,b) ) - r1;
}

float gear(vec2 p){
    p.x+=0.2;
    vec2 prevP = p;
    p*=Rot(radians(90.));
    float h = 0.4;
    float d = abs(sdUnevenCapsule(p-vec2(0.0,-h*0.5),0.05,0.1,h))-0.003;

    p = prevP;
    p.x -=0.2;
    float d2 = length(p)-0.075;
    d = min(d,d2);
    
    p*=Rot(radians(time*SPEED));
    p = DF(p,6.0);
    p -= vec2(0.065);
    d2 = Tri(p*Rot(radians(45.0)),vec2(0.01),radians(45.));
    d = min(d,d2);
    
    p = prevP;
    p.x +=0.2;
    d2 = length(p)-0.028;
    d = min(d,d2);
    
    p*=Rot(radians(time*SPEED));
    p = DF(p,3.0);
    p -= vec2(0.03);
    d2 = Tri(p*Rot(radians(45.0)),vec2(0.01),radians(45.));
    d = min(d,d2);
    
    return d;
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdCappedCylinder( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCappedCylinderX( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.yz),p.x)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCappedCylinderZ( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xy),p.z)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdTorus( vec3 p, vec2 t )
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdLink( vec3 p, float le, float r1, float r2 )
{
    vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
    return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float frontFolk(vec3 p){
    vec3 prevP = p;
    p.xz*=Rot(radians(90.));
    p.yz*=Rot(radians(5.));
    float d = sdLink(p,0.2,0.04,0.01);
    d = max(-p.y-0.15,d);
    float d2 = sdCappedCylinder(p-vec3(0,0.3,0),0.01,0.062);
    d = min(d,d2);
    
    p = prevP;
    
    d2 = sdCappedCylinderZ(p-vec3(0.013,-0.14,0),0.05,0.013);
    d = min(d,d2);
    
    return d;
}

float frame(vec3 p){
    vec3 prevP = p;
    p.xy*=Rot(radians(45.));
    float d = sdCappedCylinder(p-vec3(-0.04,0.23,0.),0.01,0.33);
    p = prevP;
    
    p.xy*=Rot(radians(-10.));
    float d2 = sdCappedCylinder(p-vec3(-0.08,0.22,0.),0.01,0.25);
    d = min(d,d2);
    p = prevP;
    
    p.xy*=Rot(radians(-7.));
    d2 = sdCappedCylinderX(p-vec3(0.165,0.41,0.),0.01,0.26);
    d = min(d,d2);
    p = prevP;
    
    p.z = abs(p.z);
    p.xz*=Rot(radians(7.5));
    d2 = sdCappedCylinderX(p-vec3(-0.25,0.0,-0.005),0.01,0.235);
    d = min(d,d2);
    p = prevP;
    
    p.xz*=Rot(radians(90.));
    p.yz*=Rot(radians(-40.));
    p-=vec3(0.0,-0.16,-0.37);
    d2 = sdLink(p,0.2,0.06,0.01);
    d2 = max(-p.y-0.15,d2);
    d = min(d,d2);
    
    
    d2 = sdCappedCylinder(p-vec3(0,0.31,0),0.01,0.055);
    d = min(d,d2);    
    
    p = prevP;
    d2 = sdCappedCylinderZ(p-vec3(-0.48,0.,0),0.07,0.015);
    d = min(d,d2);    
    
    return d;
}

float tyre(vec3 p, float startDeg){
    p.xy*=Rot(radians(time*(SPEED+100.)+startDeg));
    vec3 prevP = p;
    
    float size = 0.28;
    
    float d = sdCappedCylinderZ(p,0.005,size);
    
    p.y=abs(p.y);
    float mask = abs(sdCappedCylinderZ(p,0.1,0.17))-0.03;
    mask = max(-p.y+0.06,mask);
    d = max(-mask,d);
    
    p = prevP;
    p.yz*=Rot(radians(90.));
    float d2 = sdTorus(p,vec2(size,0.01));
    d = min(d,d2);
    return d;
}

float sheet(vec3 p){
    vec3 prevP = p;
    p.xy*=Rot(radians(-7.));
    float d = sdBox(p,vec3(0.07,0.001,0.01))-0.02;
    return d;
}

float handleBar(vec3 p){
    vec3 prevP = p;
    p.xy*=Rot(radians(-7.));
    float d = sdBox(p,vec3(0.04,0.02,0.02));
    
    p.z = abs(p.z);
    p.z-=0.03;
    float d2 = sdCappedCylinderZ(p-vec3(0.02,0.,0),0.03,0.013);
    d = min(d,d2);
    p.yz*=Rot(radians(12.));
    d2 = sdCappedCylinderZ(p-vec3(0.02,-0.005,0.05),0.03,0.013);
    d = smin(d,d2,0.008);
    p.yz*=Rot(radians(-12.));
    d2 = sdCappedCylinderZ(p-vec3(0.02,0.012,0.11),0.04,0.013);
    d = smin(d,d2,0.008);   
    
    return d;
}

float gearAndPedal(vec3 p){
    vec3 prevP = p;
    
    p.z+=0.04;
    float d = gear(p.xy);
    d = max((abs(p.z)-0.01),d);
    
    p = prevP;
    float d2 = sdCappedCylinderZ(p,0.04,0.05);
    d = min(d,d2);
    
    p.xy*=Rot(radians(time*SPEED));
    vec3 pos = (p-vec3(-0.07,0.0,-0.06));
    d2 = sdBox(pos,vec3(0.07,0.01,0.01));
    d = min(d,d2);
    
    p = prevP;
    float dist = 0.13;
    float a = radians(time*SPEED);
    float x = dist*cos(a)+p.x;
    float y = dist*sin(a)-p.y;
    pos.x = x;
    pos.y = y;
    pos.z = p.z+0.1;
    d2 =  sdBox(pos,vec3(0.04,0.01,0.03));
    d = min(d,d2);
    
    p = prevP;
    p.xy*=Rot(radians(time*SPEED+180.));
    pos = (p-vec3(-0.07,0.0,0.05));
    d2 = sdBox(pos,vec3(0.07,0.01,0.01));
    d = min(d,d2);
    
    p = prevP;
    dist = 0.13;
    a = radians(time*SPEED+180.);
    x = dist*cos(a)+p.x;
    y = dist*sin(a)-p.y;
    pos.x = x;
    pos.y = y;
    pos.z = p.z-0.09;
    d2 =  sdBox(pos,vec3(0.04,0.01,0.03));
    d = min(d,d2);
    
    return d;
}

vec2 GetDist(vec3 p) {
    vec3 prevP = p;
    
    float d = gearAndPedal(p-vec3(-0.08,-0.15,0));
    
    float d2 = frontFolk(p-vec3(0.4,0.0,0));
    d = min(d,d2);

    d2 = tyre(p-vec3(0.41,-0.15,0),45.);
    d = min(d,d2);
    
    d2 = tyre(p-vec3(-0.5,-0.15,0),60.);
    d = min(d,d2);
    
    d2 = frame(p-vec3(0.0,-0.15,0.));
    d = min(d,d2);
    
    d2 = sheet(p-vec3(-0.16,0.32,0.));
    d = min(d,d2);
    
    d2 = handleBar(p-vec3(0.39,0.37,0.));
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
    float shadow = step(RayMarch(p+n*0.3,lightDir,1.0, 15).x,0.9);
    float skyDiff = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.0,1.0);
    float bounceDiff = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.0,1.0);
    diffCol = col*vec3(-0.5)*diff*shadow*occ;
    diffCol += col*vec3(1.0,1.0,0.9)*skyDiff*occ;
    diffCol += col*vec3(0.3,0.3,0.3)*bounceDiff*occ;
    diffCol += col*pow(max(dot(rd, reflect(lightDir, n)), 0.0), 60.)*occ; // spec
        
    return diffCol;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){
    col = diffuseMaterial(n,rd,p,vec3(1.8));
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 prevUV = uv;
    vec2 m =  mouse*resolution.xy.xy/resolution.xy;
    
    vec3 ro = vec3(0, 0, -1.35);
    //if(mouse*resolution.xy.z>0.){
    //    ro.yz *= Rot(m.y*3.14+1.);
    //    ro.y = max(-0.9,ro.y);
    //    ro.xz *= Rot(-m.x*6.2831);
    //} else {
        ro.yz *= Rot(radians(-5.0));
        ro.xz *= Rot(radians(sin(time*0.3)*60.0));
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
