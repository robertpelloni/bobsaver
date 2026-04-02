#version 420

// original https://www.shadertoy.com/view/7dVXRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Creative Commons Licence Attribution-NonCommercial-ShareAlike 
   phreax 2022
*/

#define PI 3.141592
#define TAU PI*2.
#define SQR2 1.4152135
#define ISQR2 1./SQR2
#define SIN(x) (sin(x)*.5+.5)
//#define BUMPMAP

float g_mat = 0.;
float eyeAnim;
float eyeMorph;

mat2 rot(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a));}

float curve(float t, float d) {
  t/=d;
  return mix(floor(t), floor(t)+1., pow(smoothstep(0.,1.,fract(t)), 15.));
}

float rnd(float t) {
    return fract(sin(t * 6974.685) * 347.542);
}

float curveRnd(float t, float d) {
    float g = t / d;
    return mix(rnd(floor(g)), rnd(floor(g) + 1.0), pow(smoothstep(0.0, 1.0, fract(g)), 15.));
}

vec2 moda(vec2 p, float repetitions) {
    float angle = 2.*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    a = mod(a,angle) - angle/2.;
    return vec2(cos(a), sin(a))*length(p);
}

float cylcap( vec2 p2, float p1, float r, float h )
{
  vec2 d = abs(vec2(length(p2),p1)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float box(vec3 p, vec3 r) {
    vec3 d = abs(p) - r;
    return length(max(d, 0.0)) + 
        min(max(d.x, max(d.y, d.z)), 0.0);
}

float sph(vec3 p, float r) {
    return length(p) - r;
}

float tt;

// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// https://iquilezles.org/articles/smin
float smax( float a, float b, float k )
{
    k *= 1.4;
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*h/(6.0*k*k);
}

float substractRound(float a, float b, float r) 
{
    vec2 u = max(vec2(r + a,r - b), vec2(0));
    return min(-r, max (a, -b)) + length(u);
}

float octah( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float expImpulse( float x, float k )
{
    float h = k*x;
    return h*exp(1.0-h);
}

float axes(vec3 p) {
    
    float xz = cylcap(p.xz, p.y, 4., .01);
    float xy = cylcap(p.xy, p.z, 4., .01);
    float yz = cylcap(p.yz, p.x, 4., .01);
    return min(min(xz, xy), yz);
}

float sdEylidCut(vec3 p) {

    p.y = abs(p.y*eyeAnim) + .5;
    float d = length(p.xy) - 1.;
    
    return d;
   // vec2 w = vec2( d, abs(p.z) - .5 );
    //return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

vec2 eye(vec3 p) {

    vec3 q = p;
    q.x *= .8;
    
    float eyeBall = sph(p, .8);
    float eyeLid = sph(q, 1.55);
    
    
    float mat = 1.;
    eyeLid = smax(-sph(p + vec3(0, 0, 1.2), .9), eyeLid, 2.);

    eyeLid = smin(eyeLid, sph(q, .9), .09);

   
    eyeLid = smax(-sdEylidCut(p), eyeLid, .09);
    mat = eyeLid < eyeBall ? 30. : 31.;
    
    float d = min(eyeLid, eyeBall);
    
    d = mix(d, length(p) - .8, eyeMorph);
    
    //d = min(d, axes(p));
    return vec2(mat, d);
}

void transformEye(inout vec3 p, float size) {
       p.y -= 1. + sin(eyeMorph);
       p.z += 1.7;
       p *= size;
}

float map(vec3 p) {

   vec3 bp =p;
   
   float obj =100.;
   
   float flor;
   float wall;
   float eyed;
   vec2 eyev;
   {
     //p.x += 1.;
     //p.y += .1*sin(1.5*p.z)+(.0*sin(tt))*sin(1.6*p.x) + .2*sin(3.*p.y+tt);
     flor = p.y + .5;
   }
   
   {
       p = bp;
       p.x = abs(p.x) -1.5;
       p.x += .2*sin(p.z) + .3*sin(3.*p.y+tt) + .1*sin(10.*p.y+tt);;
       
       wall = box(p, vec3(.2, 3, 1000));
   }
   
   {
       p = bp;
       
       float s = mix(3., 1000., eyeMorph);
       transformEye(p, s);

       eyev = eye(p);
       eyed = eyev.y/s;
   }
   

   if(flor < wall) {
       g_mat = 0.;
   } else {
       g_mat = 1.;
   }

   float d = min(flor, wall);
   
   if(eyed < d) g_mat = eyev.x
   ;
 
   return min(d, eyed);
}

vec3 eyeTex(vec3 p) {
    float s = mix(3., 5., eyeMorph);
    transformEye(p, s); 
    
    vec3 q = p;
    p.xy += .2*vec2(sin(1.5*PI*curve(.8*tt, 1.)), 0.3*cos(2.*tt));
    float r = length(p.xy) + 0.005;
    vec3 col = vec3(.42);
    float a = atan(p.y,p.x);
    
    float iris = 0.3;
    iris = mix(0.3, iris, smoothstep(0.14, 0.25, r));
    iris += iris*3.0*(1.0-smoothstep(0.0,1.0, abs((a+3.14159)-2.5) ));
    //iris *= 0.35+0.4*texture(iChannel0,vec2(-0.005*tt+r/8.,a/6.2831/1.3)).x;
    
    iris *= 1.5;

    col += mix(.0, 1., smoothstep(0.33,0.334,r));
    col += mix( 0., iris, 1.-smoothstep(0.3,0.33,r) );
    col *= smoothstep(0.15,0.16,r);

    col += 0.6*(1.-smoothstep(0.0, 0.04, length(p.xy-vec2(.16))));
    
    // fake occulusion
    q.y = abs(q.y*eyeAnim) + .5;
    float dc = length(q.xy) - 1.;
    float focc = smoothstep(0.1, .2, abs(dc)+.14);
    col *= focc;
    return  mix(col, vec3(1), eyeMorph);
}

float getGrey(vec3 p){ return p.x*0.299 + p.y*0.587 + p.z*0.114; }

// Tri-Planar blending function. Based on an old Nvidia tutorial.
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001); // n = max(abs(n), 0.001), etc.
    n /= (n.x + n.y + n.z );  
    
    p = (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
    
    return p*p;
}

vec3 doBumpMap( sampler2D tex, in vec3 p, in vec3 nor, float bumpfactor){
   
    const float eps = 0.001;
    float ref = getGrey(tex3D(tex,  p , nor));                 
    vec3 grad = vec3( getGrey(tex3D(tex, vec3(p.x-eps, p.y, p.z), nor))-ref,
                      getGrey(tex3D(tex, vec3(p.x, p.y-eps, p.z), nor))-ref,
                      getGrey(tex3D(tex, vec3(p.x, p.y, p.z-eps), nor))-ref )/eps;
             
    grad -= nor*dot(nor, grad);          
                      
    return normalize( nor + grad*bumpfactor );
    
}

vec3 stripesTex(vec2 uv, bool pole, float rows, float t) {
    // Time varying pixel color
    vec3 col = vec3(0);
    
    
    uv *= uv.x;
    uv *= rot(tt*.3);
    uv.y -= .1*tt;

    uv = fract(uv*rows);
    
    float aa = resolution.y * 0.002 * 0.005*t; 
    col += smoothstep(.25 - aa, .25 + aa, length(uv.y-.5));

    return col;
}

float checkersTexture( in vec2 p )
{
    vec2 q = floor(p);
    return mod( q.x+q.y, 2.0 );            // xor pattern
}

vec3 stripesTex2(vec2 uv, float t) {
    vec3 col = vec3(0);
   
    uv.y += mod(.1*tt, 100.);
    uv = fract((pow(uv*.4, vec2(1.0))))-.5;
  
    float aa = resolution.y * 0.002 * 0.005*t; 
    
    col += smoothstep(.5-aa, .5+aa, .5+.5*sin(100.*length(uv)-3.*tt));

    return col;
}

float st;

void cam(inout vec3 p, vec2 m) {
    p.xz *= rot(PI/2.*m.x);
    p.yz *= rot(PI/2.*m.y);
}

vec3 mapTexture(vec3 p, vec3 n, float t) {
    
    vec2 uv;
  
  
    float x = abs(dot(n, vec3(1, 0, 0)));
    float y = abs(dot(n, vec3(0, 1, 0)));
    
    //p.xy = abs(p.xy);
    p.x += sin(.1*tt);
      
    //uv = mix(p.xz, p.yz, pow(x, 10.));
    uv = (p.xz+p.yz)/2.;
    return stripesTex2(uv, t);

}

void main(void)
{
    tt = time;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.x;
    vec2 mouse = (mouse*resolution.xy.xy-.5*resolution.xy)/resolution.x;
    
    vec3 ro = vec3(0, .6, -5),
         rd = normalize(vec3(uv,.7)),
         lp = vec3(0., 4., -3),
         lp2 = vec3(0., 1., -3);

   // cam(ro, mouse);
   // cam(rd, mouse+vec2(.5, 0.25));
   // cam(lp, mouse+vec2(.5, 0.25));
    
    eyeAnim = 1.+29.*0.01/(1.-expImpulse(mod(tt, 3.), 3.));
    
    vec3 col = vec3(0);
    float i, t, d = 0.1;

    vec3 p = ro;
    float mat = 0.;
    
    eyeMorph = SIN(.5*PI+PI*curve(tt, 2.));
    
    for(i=0.; i<150.; i++) {
    
        d = map(p);
        mat = g_mat;
        
        if(d < 0.001 || t > 20.) break;
            
        p += rd*d;
        t += d;
    }
    
    vec2 e = vec2(0.0035, -0.0035);
    
    vec3 lightKeyCol = vec3(1.000,0.996,0.922);
    vec3 eyeLidCol = vec3(0.102,0.357,0.325);
    vec3 baseCol = vec3(1);
    if(d < 0.001) {
        vec3 n = normalize( e.xyy*map(p+e.xyy) + e.yyx*map(p+e.yyx) +
                            e.yxy*map(p+e.yxy) + e.xxx*map(p+e.xxx));
        
        #ifdef BUMPMAP
        if(mat == 0.) {
          
          n = doBumpMap( iChannel1,  vec3(p.xy+skinAnim, p.z), n, 0.04);
        
        }
        #endif
       
        vec3 l = normalize(lp-p);
        float dif = max(dot(n, l), .0);
        float spe = pow(max(dot(reflect(-rd, n), -l), .0),40.);
        
        float difAmb2 =  max(dot(n, normalize(vec3(-lp.xy, lp.z)-p)), 0.);
        col +=  baseCol*dif*lightKeyCol + .4*spe + 0.6*difAmb2*vec3(0.878,0.933,1.000);
          
        if(mat == 0. ) col *= stripesTex2(p.xz*.2, t);  // floor
        if(mat == 1. ) col *= mapTexture(p, n, t);      // walls
        if(mat >= 31.) col *= getGrey(eyeTex(p));       // eye
        //col *= 1.1;
    } else {
        col = vec3(.0);
    }
    

    // Output to screen
    glFragColor = vec4(col, 1.);
}
