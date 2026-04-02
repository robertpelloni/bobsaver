#version 420

// original https://www.shadertoy.com/view/DtX3zN

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
#define S(d,b) smoothstep(kw*antialiasing(1.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define Tri(p,s,a) max(-dot(p,vec2(cos(-a),sin(-a))),max(dot(p,vec2(cos(a),sin(a))),max(abs(p).x-s.x,abs(p).y-s.y)))
#define DF(a,b) length(a) * cos( mod( atan(a.y,a.x)+6.28/(b*8.0), 6.28/((b*8.0)*0.5))+(b-1.)*6.28/(b*8.0) + vec2(0,11) )
#define ZERO (min(frames,0))

vec3 RotAnim(vec3 p){
    p.xz*=Rot(radians(5.*time));
    p.xy*=Rot(radians(5.*time));
    return p;
}

vec2 GetDist(vec3 p) {
    vec3 prevP = p;
    p = RotAnim(p);
    float d = length(p)-0.5;
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

float SimpleVesicaDistance(vec2 p, float r, float d) {
    p.x = abs(p.x);
    p.x+=d;
    return length(p)-r;
}

float smallTex(vec2 p){
    float d = abs(B(p,vec2(0.01)))-0.001;
    return d;
}

vec3 topBottomTex(vec3 p, float kw){
    vec2 uv = p.xz;
    uv*=1.2;
    vec2 prevUV2 = uv;
    uv*=Rot(radians(time*-8.));
    vec2 prevUV = uv;
    
    
    vec3 col = vec3(0.);
    
    uv = DF(uv,3.0);
    uv -= vec2(0.18);
    uv*=Rot(radians(45.));
    uv.x*=3.;
    uv*=Rot(radians(45.));
    
    float d = abs(B(uv,vec2(0.1)))-0.005;
    float d2 = abs(B(uv,vec2(0.05)))-0.005;
    d = min(d,d2);
    col = mix(col,vec3(1.),S(d,0.));
    
    uv = prevUV;
    uv*=Rot(radians(15.5));
    uv = DF(uv,3.0);
    uv -= vec2(0.28);
    uv*=Rot(radians(45.));
    uv.x*=3.;
    uv*=Rot(radians(45.));
    d = abs(B(uv,vec2(0.1)))-0.005;
    d2 = abs(B(uv,vec2(0.05)))-0.005;
    d = min(d,d2);
    col = mix(col,vec3(1.),S(d,0.));

    uv = prevUV;
    uv = DF(uv,3.0);
    uv -= vec2(0.35);
    uv*=Rot(radians(45.));
    uv.x*=0.8;
    uv*=Rot(radians(45.));
    d = abs(B(uv,vec2(0.05)))-0.001;
    d2 = abs(B(uv,vec2(0.02)))-0.001;
    d = min(d,d2);
    col = mix(col,vec3(1.),S(d,0.));

    uv = prevUV;
    uv*=Rot(radians(21.));
    uv = DF(uv,3.0);
    uv -= vec2(0.385);
    d = smallTex(uv);
    d = min(d,d2);
    col = mix(col,vec3(1.),S(d,0.));

    uv = prevUV;
    uv*=Rot(radians(9.));
    uv = DF(uv,3.0);
    uv -= vec2(0.385);
    d = smallTex(uv);
    d = min(d,d2);
    col = mix(col,vec3(1.),S(d,0.));
    
    uv = prevUV2;
    uv*=Rot(radians(10.*time));
    uv = DF(uv,2.0);
    uv -= vec2(0.04);
    d = abs(B(uv,vec2(0.025)))-0.002;
    col = mix(col,vec3(1.),S(d,0.));    
    
    return col;
}

vec3 centerTex(vec3 p, float kw){
    vec2 uv = vec2(1.572*atan(p.x,p.z)/6.2832,p.y/3.);
    vec2 prevUV = uv;
    float size = 2.;
    uv*=size;
    
    uv.y+=sin(uv.x*20.)*0.05;
    float d = abs(uv.y)-0.001;
    uv = prevUV;
    uv*=size;
    uv.x+=0.16;
    uv.y+=sin(uv.x*20.)*0.05;
    float d2 = abs(uv.y)-0.001;
    d = min(d,d2);
    
    uv = prevUV;
    uv*=5.;
    uv.y*=1.2;
    uv.x = mod(uv.x,0.392)-0.191;
    uv*=Rot(radians(sin(time*2.)*100.));
    d2 = abs(length(uv)-0.06)-0.005;
    d2 = max(-(abs(uv.x)-0.03),d2);
    d = min(d,d2);
    
    uv = prevUV;
    uv*=5.;
    uv.y*=1.2;
    uv.x = mod(uv.x,0.392)-0.191;
    uv*=Rot(radians(20.*time));
    uv = DF(uv,2.0);
    uv -= vec2(0.08);
    uv*=Rot(radians(45.));
    d2 = abs(Tri(uv,vec2(0.026),radians(45.)))-0.003;
    d = min(d,d2);
    
    uv = prevUV;
    uv*=5.;
    uv.y*=1.2;
    uv.x = mod(uv.x,0.392)-0.191;
    d2 = abs(length(uv)-0.035)-0.003;
    d = min(d,d2);    
    
    uv = prevUV;
    uv*=5.;
    uv.y*=1.2;
    uv.x+=0.2;
    uv.x = mod(uv.x,0.393)-0.1965;
    uv.y = abs(uv.y)-0.15;
    d2 = abs(length(uv)-0.035)-0.003;
    d = min(d,d2);    
    
    uv = prevUV;
    uv*=5.;
    uv.y*=1.2;
    uv.x = mod(uv.x,0.392)-0.191;
    uv.y = abs(uv.y)-0.32;
    d2 = Tri(uv,vec2(0.12),radians(45.));
    float d3 =Tri(uv-vec2(0.0,-0.06),vec2(0.12),radians(45.));
    d2 = max(-d3,d2);
    d = min(d,abs(d2)-0.003);        
    
    
    uv = prevUV;
    uv*=5.;
    uv.y*=1.2;
    uv.x+=0.2;
    uv.x = mod(uv.x,0.393)-0.1965;
    uv.y = abs(uv.y)-0.25;
    uv.y*=-1.;
    d2 = abs(Tri(uv,vec2(0.035),radians(45.)))-0.003;
    d = min(d,d2);        
    
    return mix(vec3(0.0),vec3(1.8),S(d,0.0));
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col, float w){
    col = diffuseMaterial(n,rd,p,vec3(0.01));
    p = RotAnim(p);
    col += centerTex(p,w);
    col += topBottomTex(p,w);
    
    return col;
}

float bgItem1(vec2 p){
    p*=Rot(radians(20.*time));
    vec2 prevP = p;
    p = DF(p,1.25);
    p -= vec2(0.04);
    float d = abs(length(p)-0.055)-0.002;
    p = prevP;
    d = max(-(length(p)-0.02),d);
    p = DF(p,1.25);
    p -= vec2(0.027);
    float d2 = abs(length(p)-0.011)-0.001;
    d = min(d,d2);
    p = prevP;
    d2 = abs(length(p)-0.015)-0.001;
    d = min(d,d2);
    return d;
}

float bgItem2(vec2 p){
    p*=Rot(radians(-20.*time));
    vec2 prevP = p;
    p = DF(p,3.);
    p -= vec2(0.04);
    p*=Rot(radians(45.));
    float d = abs(SimpleVesicaDistance(p,0.095,0.083))-0.001;
    p = prevP;
    d = max(-(length(p)-0.02),d);
    float d2 = abs(length(p)-0.02)-0.001;
    d = min(d,d2);
    return d;
}

float background(vec2 p){
    p*=1.5;
    p.y-=time*0.1;
    vec2 prevP = p;
    p.x-=time*0.1;
    p.x = mod(p.x,0.3)-0.15;
    p.y = mod(p.y,0.5)-0.25;
    float d = bgItem1(p);
    
    p = prevP;
    p.x+=time*0.1;
    p.x+=0.45;
    p.y+=0.25;
    p.x = mod(p.x,0.3)-0.15;
    p.y = mod(p.y,0.5)-0.25;
    
    float d2 = bgItem2(p);
    
    return min(d,d2);
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
        ro.xz *= Rot(radians(time*10.0));
    //}
    
    vec3 rd = R(uv, ro, vec3(0,0.0,0), 1.0);
    vec2 d = RayMarch(ro, rd, 1.,MAX_STEPS);
    vec3 col = vec3(.0);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col,0.5/abs(dot(rd,p)) );
    } else {
        float d = background(uv);
        float kw = 1.0;
        col = mix(col,vec3(0.3),S(d,0.));
    }
    
    // gamma correction
    col = pow( col, vec3(0.4545) );    

    glFragColor = vec4(col,1.0);
}
