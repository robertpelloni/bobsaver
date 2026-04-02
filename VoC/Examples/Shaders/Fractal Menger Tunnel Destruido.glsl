#version 420

// original https://www.shadertoy.com/view/WsscRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//modificado por jorge flores.p --
//Gracias a ....Created by russ in 2017-03-06
//https://www.shadertoy.com/view/XsfczB
    

const int iter =100;
const float eps = 0.001, far = 20.;
vec3 lDir0 = normalize(vec3(1,2,1)), lDir1 = normalize(vec3(-1,1.0,-2));
vec3 lCol0 = vec3(1,.8,.5), lCol1 = vec3(.6,0.8,1); 

///-------------------------------------
const int MAX_RAY_STEPS = 64;
const float RAY_STOP_TRESHOLD = 0.0001;
const int MENGER_ITERATIONS = 5;
///-------------------------------------

float maxcomp(in vec3 p ) { return max(p.x,max(p.y,p.z));}

float sdBox( vec3 p, vec3 b )
{
  vec3  di = abs(p) - b;
  float mc = maxcomp(di);
  return min(mc,length(max(di,0.0)));
}

float cylUnion(vec3 p){
    float xy = dot(p.xy,p.xy);
    float xz = dot(p.xz,p.xz);
    float yz = dot(p.yz,p.yz);
    return sqrt(min(xy,min(xz,yz))) - 1.;
}

float cylIntersection(vec3 p){
    float xy = dot(p.xy,p.xy);
    float xz = dot(p.xz,p.xz);
    float yz = dot(p.yz,p.yz);
    return sqrt(max(xy,max(xz,yz))) - 1.;
}

//-------------------------------------------

float dsSphere(vec3 center, float r, vec3 point)// basic sphere SDF
{
    // point is point pos in space, center is sphere's center, r is its radius
    return length(point - center) - r;
}

float dsCapsule(vec3 point_a, vec3 point_b, float r, vec3 point_p)//cylinder SDF
{
     vec3 ap = point_p - point_a;
    vec3 ab = point_b - point_a;
    float ratio = dot(ap, ab) / dot(ab , ab);
    ratio = clamp(ratio, 0.0, 1.0);
    vec3 point_c = point_a + ratio * ab;
    return length(point_c - point_p) - r;
}

float dsTorus(vec3 center, float r1, float r2, vec3 point)
{
     float x = length(point.xz - center.xz) - r1;
    float y = point.y - center.y;
    float dist = length(vec2(x,y)) - r2;
    return dist;
}
//--------------------------------------------

//oooooooooooooooooooooooooooooooooooooooooooooooooooo
float sdCross(vec3 p) {
    p = abs(p);
    vec3 d = vec3(max(p.x, p.y),
                  max(p.y, p.z),
                  max(p.z, p.x));
    return min(d.x, min(d.y, d.z)) - (1.0 / 3.0);
}

float sdCrossRep(vec3 p) {
    vec3 q = mod(p + 1.0, 2.0) - 1.0;
    return sdCross(q);
}

float sdCrossRepScale(vec3 p, float s) {
    return sdCrossRep(p * s) / s;    
}

float pathterrain(float x,float z)
{
    // Common height function for path and terrain
    return 
        sin(x*.5 )*1.+cos(z*.3 )*0.3
        +cos(x*3.+z )*0.1+sin(x-z*.2 )*0.2;
}  

float pathterrainv2(float x , float y, float z)
{
    // Common height function for path and terrain
    return 
        sin(x*.5 )*1.+cos(z*.3 )*0.3+y
        +cos(x*3.+z )*0.1+sin(x-z*.2 )*0.2;
}  

//--------------------------
float DE(vec3 p) {
    
    
    float scale = 0.35;
    
    
        
    float dist = pathterrainv2(p.x,p.y,p.z);
    
    for (int i = 0; i < MENGER_ITERATIONS; i++) {
        dist = max(dist, -sdCrossRepScale(p, scale));
        scale *= 3.0;
    }
    return dist;
}

//oooooooooooooooooooooooooooooooooooooooooooooooooooo

vec2 march(vec3 ro, vec3 rd){
    float t=0. , d = far, it = 0.;
    for (int i=0;i<iter;i++){
         t += (d = DE(ro+t*rd));
        if(d<eps || t> far) break;
        it += 1.;
    }
    return vec2(t,it/float(iter));
}

float getShadow(vec3 p, vec3 n, vec3 ld){
    p +=  2. * eps * n;
    float t=0.,d=far;
    for(int i=0;i<50;i++){
        t += (d=DE(p + t*ld));
        if (d<eps || t>3.) break;
    }
    return t<=3. ? 0.1 : 1. ;
}

vec3 getRay(vec3 ro, vec3 look, vec2 uv){
    vec3 f = normalize(look - ro);
    vec3 r = normalize(vec3(f.z,0,-f.x));
    vec3 u = cross (f,r);
    return normalize(f + uv.x * r + uv.y * u);
}

vec3 getNorm(vec3 p){
    vec2 e = vec2(eps, 0);
    return normalize(vec3(DE(p+e.xyy)-DE(p-e.xyy),DE(p+e.yxy)-DE(p-e.yxy),DE(p+e.yyx)-DE(p-e.yyx)));
}

vec3 light(vec3 p, vec3 n){
    vec3 col = vec3(0.01);
    for(int i=0;i<2;i++){
        vec3 ld = (i==0) ? lDir0 : lDir1;
        float diff = max(dot(n, (ld)),0.);
        diff *= getShadow(p, n, ld);
        col += diff * (i==0 ? lCol0 : lCol1);
    }
    return col * .7;
}

void main(void)
{
    
    float time = time * 0.5;
    //float time = time * .06;
    
    
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
  
    
    
    vec3 ro = vec3(0.5, 0.25, 1.5+ 1.0*cos(time)+time*1.2);
    
   
    
    vec3 rd = getRay(ro, vec3(0.), uv);
    vec2 hit = march(ro, rd);
    vec3 p = ro + hit.x*rd;
    
    vec3 col = hit.x<far ? light(p, getNorm(p)) : vec3(.1*(1.-length(uv)));
    
    
    col += pow(hit.y,3.);
    glFragColor = vec4(sqrt(col),1.0);
}
