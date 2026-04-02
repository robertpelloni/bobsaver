#version 420

// original https://www.shadertoy.com/view/Dlj3zd

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

float dot2( in vec2 v ) { return dot(v,v); }

// thx iq! https://iquilezles.org/articles/distfunctions2d/
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

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdCappedCylinderX( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.yz),p.x)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdCappedCylinderY( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdCappedCylinderZ( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xy),p.z)) - vec2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// thx iq! https://iquilezles.org/articles/distfunctions/
// tweaked as the center aligned horizontal capsule. 
float sdHorizontalCapsule( vec3 p, float w, float r )
{
      p.x-= clamp( p.x, -w*0.5, w*0.5 );
      return length( p ) - r;
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdCappedCone( vec3 p, float h, float r1, float r2 )
{
  vec2 q = vec2( length(p.yz), p.x );
  vec2 k1 = vec2(r2,h);
  vec2 k2 = vec2(r2-r1,2.0*h);
  vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
  vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
  float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
  return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float largeLensParts(vec3 p){
    vec3 prevP = p;
    float d = sdBox(p,vec3(0.13,0.13,0.13));
    float a = radians(-70.);
    p.y = abs(p.y)-0.1;
    d = max(-dot(p,vec3(cos(a),sin(a),0.0)),d);
    p = prevP;
    p.z = abs(p.z)-0.1;
    d = max(-dot(p,vec3(cos(a),0.0,sin(a))),d);
    p = prevP;
    d = max(p.x-0.05,d);
    return d;
}

float largeLens(vec3 p){
    vec3 prevP = p;
    float d = largeLensParts(p);
    p*=1.1;
    float d2 = largeLensParts(p-vec3(0.01,0.0,0.0));
    d = max(-d2,d);
    p = prevP;
    d2 = sdCappedCylinderX(p-vec3(-0.1,0.0,0.0),0.035,0.01)-0.02;
    d = min(d,d2);
    return d;
}

float mainLens(vec3 p){
    vec3 prevP = p;
    float d = sdCappedCylinderX(p,0.08,0.02)-0.02;
    float d2 =  sdCappedCylinderX(p-vec3(0.06,0.0,0.05),0.04,0.055);
    d = min(d,d2);
    d2 =  sdCappedCylinderX(p-vec3(0.02,0.04,-0.03),0.03,0.05);
    float mask = sdCappedCylinderX(p-vec3(0.07,0.04,-0.03),0.025,0.01);
    d2 = max(-mask,d2);
    d = min(d,d2);
    d2 =  sdCappedCylinderX(p-vec3(0.03,-0.04,-0.03),0.032,0.05);
    mask = sdCappedCylinderX(p-vec3(0.08,-0.04,-0.03),0.027,0.01);
    d2 = max(-mask,d2);
    d = min(d,d2);
    d2 = sdCappedCylinderX(p-vec3(0.105,0.0,0.05),0.06,0.01);
    d = min(d,d2);
    d2 = largeLens(p-vec3(0.25,0.0,0.05));
    d = min(d,d2);
    return d;
}

float viewFinder(vec3 p){
     vec3 prevP = p;
     float d = sdBox(p,vec3(0.035));
     float d2 = sdCappedCylinderX(p-vec3(-0.03,0.0,0.0),0.025,0.1);
     d = min(d,d2);
     d2 = sdCappedCone(p-vec3(-0.15,0.0,0.0),0.03,0.05,0.03);
     float mask = sdCappedCone(p-vec3(-0.17,0.0,0.0),0.03,0.04,0.02);
     d2 = max(-mask,d2);
     d = min(d,d2);
     return d;
}

float reelParts(vec3 p){
    p.xy*=Rot(radians(time*30.));
    vec3 prevP = p;
    p.z = abs(p.z)-0.04;
    float d = sdCappedCylinderZ(p,0.17,0.01);
    
    p.xy = DF(p.xy,1.25);
    p.xy -= vec2(0.075);
    float mask = sdCappedCylinderZ(p,0.05,0.1);
    d = max(-mask,d);
    
    p = prevP;
    float d2 = sdCappedCylinderZ(p,0.1,0.015)-0.01;
    d = min(d,d2);
    
    return d;
}

float reel(vec3 p){
    vec3 prevP = p;
    
    p.x = abs(p.x);
    float d = reelParts((p-vec3(0.17,0.0,0.0))* vec3(sign(prevP.x),1,1));
    
    p = prevP;
    p.z = abs(p.z)-0.07;
    float d2 = sdBox(p-vec3(0.0,-0.15,0.0),vec3(0.15,0.06,0.02));
    p = prevP;
    float a = radians(30.);
    p.x = abs(p.x)-0.1;
    p.y+=0.1;
    d2 = max(dot(p,vec3(cos(a),sin(a),0.)),d2);
    d = min(d,d2);
    
    return d;
}

float body(vec3 p){
    vec3 prevP = p;
    float d = sdBox(p,vec3(0.185,0.15,0.1))-0.015;
    p.z = abs(p.z)-0.08;
    p.x = abs(p.x);
    p.y = abs(p.y);
    float d2 = length(p-vec3(0.197,0.13,0.))-0.013;
    d = min(d,d2);
    p = prevP;
    d2 = reel(p-vec3(0.0,0.34,0.0));
    d = min(d,d2);
    
    p.x+=0.05;
    p.x = abs(p.x)-0.05;
    d2 = sdCappedCylinderZ(p,0.03,0.13)-0.01;
    d = min(d,d2);
    p = prevP;
    
    p.x-=0.11;
    p.y = abs(p.y)-0.05;
    d2 = sdCappedCylinderZ(p,0.015,0.13)-0.01;
    d = min(d,d2);
    
    return d;
}

float triPods(vec3 p){
    vec3 prevP = p;
    float d = sdCappedCylinderY(p,0.05,0.015)-0.01;
    
    p.x = abs(p.x)-0.02;
    p.xy*=Rot(radians(-30.));
    float d2 = sdCappedCylinderY(p-vec3(0.,-0.12,0.),0.005,0.1)-0.01;
    d = min(d,d2);
    p = prevP;
    p.z = abs(p.z)-0.02;
    p.zy*=Rot(radians(-30.));
    d2 = sdCappedCylinderY(p-vec3(0.,-0.12,0.),0.005,0.1)-0.01;
    d = min(d,d2);
    
    return d;
}

vec2 GetDist(vec3 p) {
    vec3 prevP = p;
    p.y+=0.05;
    float d = body(p);
    float d2 = mainLens(p-vec3(0.24,0.05,0.0));
    d = min(d,d2);
    d2 = viewFinder(p-vec3(-0.23,0.0,0.0));
    d = min(d,d2);
    d2 = triPods(p-vec3(0.0,-0.17,0.0));
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
    for( int i=ZERO; i<3; i++ )
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
    vec3 lightDir = normalize(vec3(1,10,10));
    float diff = clamp(dot(n,lightDir),0.0,1.0);
    float skyDiff = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.0,1.0);
    float bounceDiff = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.0,1.0);
    diffCol = col*vec3(-0.5)*diff*occ;
    diffCol += col*vec3(1.0,1.0,0.95)*skyDiff*occ;
    diffCol += col*vec3(0.95)*bounceDiff*occ;
    diffCol += col*pow(max(dot(rd, reflect(lightDir, n)), 0.0), 60.)*occ; // spec
        
    return diffCol;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){
    col = diffuseMaterial(n,rd,p,vec3(1.));
    return col;
}

float bgItem(vec2 p){
    p*=Rot(radians(90.));
    p.y = abs(p.y)-0.05;
    float d = abs(Tri(p,vec2(0.05),radians(30.)))-0.0001;
    return d;
}

float bg(vec2 p){
    vec2 prevP = p;
    p-=time*0.05;
    p*=0.8;
    p.x = mod(p.x,0.095)-0.0475;
    p.y = mod(p.y,0.055)-0.0275;
    float d = bgItem(p);
    return d;
}

float filmItem(vec2 p, float dir){
    vec2 prevP = p;
    float d = B(p,vec2(2.,0.07));
    
    p.x+=time*0.1*dir;
    p.x = mod(p.x,0.16)-0.08;
    float d2 = B(p,vec2(0.075,0.035));
    d = max(-d2,d);
    p = prevP;
    p.x+=time*0.1*dir;
    p.y = abs(p.y)-0.0525;
    p.x = mod(p.x,0.03)-0.015;
    d2 =  B(p,vec2(0.012));
    d = max(-d2,d);
    return d;
}

float icon0(vec2 p){
    p*=Rot(radians(30.*time));
    vec2 prevP = p;
    float thickness = 0.002;
    float d = abs(length(p)-0.06)-thickness;
    p.x-=0.033;
    p*=Rot(radians(90.));
    float d2 = abs(Tri(p,vec2(0.05),radians(30.)))-thickness;
    d = min(d,d2);
    return d;
}

float icon1(vec2 p){
    p*=Rot(radians(-22.*time));
    vec2 prevP = p;
    p.x*=3.;
    float d = abs(length(p)-0.06)-0.003;
    p = prevP;
    p.y*=3.;
    float d2 = abs(length(p)-0.06)-0.003;
    d = min(d,d2);
    p = prevP;
    p*= Rot(radians(45.));
    p.x*=3.;
    d2 = abs(length(p)-0.06)-0.003;
    d = min(d,d2);
    p = prevP;
    p*= Rot(radians(-45.));
    p.x*=3.;
    d2 = abs(length(p)-0.06)-0.003;
    d = min(d,d2);
    return d;
}

float icon2(vec2 p){
    p*=Rot(radians(25.*time));
    vec2 prevP = p;
    p = DF(p,2.);
    p -= vec2(0.045);
    float d = Tri(p,vec2(0.06),radians(45.));
    return d;
}

float icon3(vec2 p){
    p*=Rot(radians(-15.*time));
    vec2 prevP = p;
    p = DF(p.xy,2.);
    p -= vec2(0.045);
    float d = Tri(p,vec2(0.06),radians(30.));
    p = prevP;
    d = min(abs(length(p)-0.015)-0.002,d);
    return d;
}

float random (vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

float items(vec2 p){
    vec2 prevP = p;
    p*=6.;
    p-=time*0.2;
    vec2 id = floor(p);
    vec2 grd = fract(p)-0.5;
    grd*=0.15;
    float n = random(id);
    float d = 10.;
    if(n<0.1){
        d = icon0(grd);
    } else if(n>=0.1 && n<0.2){
        d = icon1(grd);
    } else if(n>=0.2 && n<0.3){
        d = icon2(grd);
    } else if(n>=0.3&& n<0.4){
        d = icon3(grd);
    }
    return d;
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
    vec3 col = vec3(0.);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col);
    } else {
        col = mix(col,vec3(0.2),S(bg(uv),0.0));
        col = mix(col,vec3(0.4),S(items(uv),0.0));
    }
    
    
    uv.y = abs(uv.y);
    
    float dd = filmItem(uv-vec2(0.0,0.43),sign(prevUV.y));
    col = mix(col,vec3(0.9),S(dd,0.0));
    
    /*
    uv = prevUV;
    dd = icon4(uv-vec2(0.6,0.0));
    col = mix(col,vec3(0.9),S(dd,0.0));
    */

    glFragColor = vec4(col,1.0);
}
