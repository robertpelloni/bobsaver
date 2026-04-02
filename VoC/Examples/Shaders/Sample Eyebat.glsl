#version 420

// original https://www.shadertoy.com/view/7sdcDX

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Raymarching based from https://www.shadertoy.com/view/wdGGz3
#define MAX_STEPS 64
#define MAX_DIST 32.
#define SURF_DIST .001
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define MATERIAL0 0
#define MATERIAL1 1
#define MATERIAL2 2
#define SPEED 7.0
#define ZERO (min(frames,0))

vec2 combine(vec2 val1, vec2 val2 ){
    return (val1.x < val2.x)?val1:val2;
}

// by Dave_Hoskins
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    p = p*mat2(127.1,311.7,269.5,183.3);
    p = -1.0 + 2.0 * fract(sin(p)*43758.5453123);
    return sin(p*6.283);
}

float perlin_noise(vec2 p) {
    vec2 pi = floor(p);
    vec2 pf = p - pi;
    
    // interpolation
    vec2 w = pf * pf * (3.0 - 2.0 * pf);
    
    float f00 = dot(hash22(pi + vec2(0.0, 0.0)), pf - vec2(0.0, 0.0));
    float f01 = dot(hash22(pi + vec2(0.0, 1.0)), pf - vec2(0.0, 1.0));
    float f10 = dot(hash22(pi + vec2(1.0, 0.0)), pf - vec2(1.0, 0.0));
    float f11 = dot(hash22(pi + vec2(1.0, 1.0)), pf - vec2(1.0, 1.0));
    
    // mixing top & bottom edges
    float xm1 = mix(f00, f10, w.x);
    float xm2 = mix(f01, f11, w.x);
    
    // mixing to point
    float ym = mix(xm1, xm2, w.y); 
    
    return ym;
}

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

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

// thx iq! https://iquilezles.org/articles/distfunctions/
float sdCone( in vec3 p, in vec2 c, float h )
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}

float feather(vec3 p) {
    float k = 0.03;
    p.x = abs(p.x);
    p.y+=0.1;
    p.z-=0.1;
    p.xz*=Rot(radians(sin(time*10.0)*10.0));
    p.xy*=Rot(radians(-20.0));
    p.x-=1.2;
    vec3 prevP = p;
    
    // feather
    p.y*=mix(2.0,0.6,smoothstep(-1.0,1.0,p.x));
    float d = sdBox(p,vec3(0.7,0.4,0.01))-0.03;
    
    p = prevP;
    p.x-=0.9;
    p.xy*=Rot(radians(-18.0));
    float d2 = sdBox(p,vec3(0.35,0.6,0.01))-0.03;
    float rad = radians(18.0);
    p.x = abs(p.x)-0.2;
    float mask = dot(p,vec3(cos(rad),sin(rad),0.0));
    d2 = max(mask,d2);
    p = prevP;
    p.x-=0.9;
    p.xy*=Rot(radians(-18.0));
    p.x*=0.8;
    d2 = max(-(length(p-vec3(0.0,-0.7,0.0))-0.3),d2);
    
    d = smin(d,d2,k);
    
    p = prevP;
    p.x-=1.2;
    p.y-=0.2;
    p.xy*=Rot(radians(-50.0));
    d2 = sdBox(p,vec3(0.35,0.6,0.01))-0.03;
    rad = radians(18.0);
    p.x = abs(p.x)-0.2;
    mask = dot(p,vec3(cos(rad),sin(rad),0.0));
    d2 = max(mask,d2);
    p = prevP;
    p.x-=1.2;
    p.y-=0.2;
    p.xy*=Rot(radians(-50.0));
    p.x*=0.8;
    d2 = max(-(length(p-vec3(0.0,-0.7,0.0))-0.3),d2);
    
    d = smin(d,d2,k);
    
    p = prevP;
    d2 = sdCone(p-vec3(0.75,0.85,.0),vec2(0.03,0.12),0.3);
    d = smin(d,d2,k+0.02);
    
    return d*0.6;
}

float tail(vec3 p){
    p.yz*=Rot(radians(sin(-time*3.0)*20.0));
    vec3 prevP = p;
    p = prevP;
    float d = sdRoundedCylinder(p-vec3(.0,-1.0,.0),0.05,0.1,0.3);
    
    p.xy*=Rot(radians(180.0));
    float d2 = sdCone(p-vec3(.0,1.7,.0),vec2(0.05,0.15),0.5);
    d = smin(d,d2,0.2);
    return d;
}

vec2 eyeBat(vec3 p){
    vec3 prevP = p;
    
    // body part
    float d = length(p) - 0.7;
    float rad = radians(abs(sin(time*5.0)*10.0+20.0));
    p.y = abs(p.y)-0.1;
    float d2 = dot(p,vec3(0.0,cos(rad),sin(rad)));
    d2 = max(p.z+0.1,d2);
    d = max(-d2,d);
    
    // horn
    p = prevP;
    p.x = abs(p.x)-0.3;
    p.yz*=Rot(radians(-15.0));
    d2 = sdCone(p-vec3(0.0,1.1,-.1),vec2(0.03,0.15),0.5);
    d = smin(d,d2,0.1);
    
    p = prevP;
    
    // feather
    d2 = feather(p);
    d = smin(d,d2,0.2);
     
    // tail
    d2 = tail(p);
    d = smin(d,d2,0.2);
    
    // eyeball
    d2 = length(p) - 0.68;
    
    return combine(vec2(d,MATERIAL0),vec2(d2,MATERIAL2));
}

vec2 GetDist(vec3 p) {
    vec3 prevP = p;
    p.z-=time*10.0;
    float n = perlin_noise(p.xz*0.3)*3.0;
    p.xy+=n;
    
    float d = -length(p.xy) + 8.0;
    
    p = prevP;
    return combine(eyeBat(p),vec2(d*0.6,MATERIAL1));
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

// https://iquilezles.org/articles/rmshadows
float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
    float h = 1.0;
    for( int i=0; i<48; i++ )
    {
        h = GetDist(ro + rd*t).x;
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        t += clamp( h, 0.025, 1.0 );
        if( h<0.001 ) break;
    }
    return clamp(res,0.0,1.0);
}

vec3 diffuseMaterial(vec3 n, vec3 rd, vec3 p, vec3 col) {
    float occ = calcOcclusion(p,n);
    vec3 diffCol = vec3(0.0);
    vec3 lightDir = normalize(vec3(p.x,p.y,-2));
    float diff = clamp(dot(n,lightDir),0.0,1.0);
    //float shadow = step(RayMarch(p+n*0.3,lightDir,1.0, 15).x,0.9);
    float shadow = softshadow(p,rd,0.05, 32.0);
    float skyDiff = clamp(0.5+0.5*dot(n,vec3(0,1,0)),0.0,1.0);
    float bounceDiff = clamp(0.5+0.5*dot(n,vec3(0,-1,0)),0.0,1.0);
    diffCol = col*vec3(0.5)*diff*shadow*occ;
    diffCol += col*vec3(0.3,0.7,0.9)*skyDiff*occ;
    diffCol += col*vec3(0.5,0.7,0.5)*bounceDiff*occ;
    diffCol += col*pow(max(dot(rd, reflect(lightDir, n)), 0.0), 20.); // spec

    return diffCol;
}

vec3 tex(vec3 p,vec3 col){
    vec2 uv = p.xy;
    uv*=5.0;
    vec2 grid = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
    float line = min(grid.x, grid.y);
    float gridd = 0.5 - min(line, 1.0);
    return mix(vec3(0.0),vec3(1.0),S(gridd,-0.2));
}

vec3 eyeTex(vec3 p,vec3 col){
    vec2 uv = p.xy;
    uv.x+=sin(time*2.0)*0.2;
    float d = length(uv)-0.35;
    col = mix(vec3(1.0,0.95,0.9),vec3(0.0),S(d,0.0));
    d = length(uv)-0.2;
    col =  mix(col,vec3(0.3),S(d,0.0));
    d = length(uv-vec2(-0.15,0.23))-0.05;
    return mix(col,vec3(2.0),S(d,0.0)); 
}

vec3 reflectMaterial(vec3 p, vec3 rd, vec3 n) {
    vec3 r = reflect(rd,n);   
    vec3 refTex = tex(p,vec3(max(0.55,r.x)))+(r*sin(time)*0.5);
    return refTex;
}

vec3 fractalTex(vec3 p, vec3 col, float deg, float thickness, float b){
    vec2 uv = p.xy;
    uv*=0.2;
    uv = fract(uv)-0.5;
    float dd = 10.0;
    
    for(float i = 0.; i<7.0; i++){
        uv = abs(uv)-(0.01*i)-0.2;
        float rad = radians(50.0*i+deg);
        float n = dot(uv,vec2(sin(rad),cos(rad)));
        dd = min(dd,abs(n)-thickness);
    }
    
    col = mix(col,vec3(0.9,0.5,0.3)+sin(0.5*time+(uv.x+uv.y+p.z)),S(dd,b));
    return col;
}

vec3 materials(int mat, vec3 n, vec3 rd, vec3 p, vec3 col){

    if(mat == MATERIAL0){
        float perl = perlin_noise(p.xy*3.5)*0.1;
        float nn = hash12(p.xy*8.0)*0.3;
        col = mix(vec3(0.3,0.4,0.3),vec3(0.2,0.3,0.2),p.y);
        col = fractalTex(p*1.2,col,10.0,0.01,-0.01)*0.5;
        col = diffuseMaterial(n,rd,p,col+perl+nn);
    } else if(mat == MATERIAL1) {
        float nn = hash12(p.xy*8.0)*0.3;
        col = reflectMaterial(p,rd,n)*vec3(0.6,0.3,0.0);
        col = diffuseMaterial(n,rd,p,col+nn)+fractalTex(p,col,time*10.0,0.025,-0.03)*0.5;
    } else if(mat == MATERIAL2){
        col = eyeTex(p,col);
        col = diffuseMaterial(n,rd,p,col);
    }
    
    float dd = abs(length(p.xy)-0.1)-0.0001;
    col *= 1.0 + 0.5*cos(200.0*dd);
    
    return col;
}

// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e),0.0,1.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float t = time*SPEED;
    vec3 ro = vec3(0,0.0,-5.0);
 
    vec2 m =  mouse*resolution.xy.xy/resolution.xy;
    //if(mouse*resolution.xy.z>0.){
    //    ro.yz *= Rot(m.y*3.14+1.);
    //    ro.y = max(3.0,ro.y);
    //    ro.xz *= Rot(-m.x*6.2831);
    //} else {
        if(mod(time,30.0)<15.0){
            ro.xz *= Rot(radians(sin(time*0.5)*30.0));
        } else {
            ro.yz *= Rot(radians(sin(time*0.5)*30.0));
        }
    //}
 
    vec3 rd = R(uv, ro, vec3(0,0.0,0), 1.0);
    vec2 d = RayMarch(ro, rd, 1.,MAX_STEPS);
    vec3 col = vec3(1.0);
    
    if(d.x<MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        int mat = int(d.y);
        col = materials(mat,n,rd,p,col);
        col *= exp( -0.000005*d.x*d.x*d.x*d.x );//fog
    } else {
        col = vec3(0.0);
    }
    
    // gamma correction
    col = pow( col, vec3(0.9545) );    
    
    col = ACESFilm(col);
    
    glFragColor = vec4(col,1.0);
}
