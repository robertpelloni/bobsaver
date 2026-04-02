#version 420

// original https://www.shadertoy.com/view/WlXfWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/************************************************************************************************
*
* SDF code: 
* from blackle - That's Six-Dimensional Gravy - (https://www.shadertoy.com/view/3lKGRm)
*
* HAIR code: 
* from pronce - 2D Fur and hair textures - (https://www.shadertoy.com/view/ttjyRc)
*
* TRIPLANAR code from:
* Improved Triplanar Mapping from tux (https://www.shadertoy.com/view/lsj3z3)
* Stochastic Triplanar Sampling from miloyip (https://www.shadertoy.com/view/3lS3Rm)
* noise-preserving triplanar from  FabriceNeyret2  (https://www.shadertoy.com/view/3l2SDd)
* taken from Industrial Complex  from  Shane  (https://www.shadertoy.com/view/MtdSWS)
* N-Planar Texturing from pastasfuture (https://www.shadertoy.com/view/4sccRl)
*
************************************************************************************************/

#define ROTATE
#define SLICE
#define PI 3.14159265

#define R(x) fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453)

// global parameters
float HAIR_LENGTH = 20.0;
float TOUSLE = 0.15;
float BORDER = 1.5;

float noise (vec2 st){
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = R(i);
    float b = R((i + vec2(1.0, 0.0)));
    float c = R((i + vec2(0.0, 1.0)));
    float d = R((i + vec2(1.0, 1.0)));

    vec2 u = smoothstep(0.,1.,f);

    return (mix(a, b, u.x) +
            (c - a) * u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y) * 2.0 - 1.0;
}

float fbm(vec2 x){
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < 5; ++i) {
        v += a * noise(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// generate a hair patch, which is essentially just some fbm noise 
// stretched along one axis based on the rotation value a.
// to mimic tousling of the hair a random offset is added to the 
// rotation. the hair length is derived from the actual stretch
float hairpatch(vec2 u, vec2 o, float a){

    a += sin(R(o) * 5.0) * TOUSLE;
    vec2 d = vec2(1.0 / HAIR_LENGTH, .5);
    float s = sin(a); float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    u=m*u;
  
    float h = (fbm((u + o) * d * 70.0) + 1.0) / 2.0;
     
    h = smoothstep(0.0, 2.2, h);

    return max(0.0, 1.0 - min(1.0, 1.0 - h));
}

// as the hair is organized in patches, each patch has some
// smooth falloff since patches are blended together dynamically
float hair(vec2 u, vec2 d, float w, float a){
    float hr = 0.0;
    u *= w * 4.0;
    u += d;
    vec2 hp = fract(u) - vec2(0.5);
    float h = hairpatch(hp, floor(u), a);
    return pow(h * max(1.-length(hp) * BORDER, 0.0),1.0 / 3.0);
}

// mix 9 hair patches together in order to simulate an overlapping effect
float hairtexture(vec2 uv, float scale, float angle){
    vec2 offsets[9] = vec2[9](vec2(0.), vec2(.5), vec2(-.5),
                              vec2(.5,0.), vec2(-.5,0.),
                              vec2(0.,.5), vec2(0.,-.5),
                              vec2(.5,-.5), vec2(-.5,.5));

    float f = 0.0;

    for(int i = 0; i < 9; i++){
        f = max(f, hair(uv, offsets[i], scale, angle));
    } 
    
    return smoothstep(0.0, 1.0, f);
}

vec3 hyena(vec2 uv){
    HAIR_LENGTH = 20.0;
    TOUSLE = 0.15;
    BORDER = 1.5;
    
    float angle = (fbm(uv) + 2.0) * PI;
    float f = hairtexture(uv, 1.0f, angle);
    
    // apply color look and use fbm to create darker patches
    vec3 col = mix(vec3(0.4, 0.3, 0.25) * f * mix(2.0, 4.0, fbm(uv * 8.0)), vec3(1.0), pow(f, 4.0));
    
    return col;
}

vec3 leopard(vec2 uv){
    HAIR_LENGTH = 15.0;
    TOUSLE = 0.15;
    BORDER = 1.5;
    
    float angle = (fbm(uv)-2.0) * PI * 0.25;
    float f = hairtexture(uv, 1.0, angle);
    
    //generate a map that mixes between the black and yellow patches
    float patches = min(1.0, sin(fbm(uv * 2.0) * 3.0 * PI));
    
    // apply both colors to the patches
    vec3 col = mix(max(vec3(0.0), vec3(0.55, 0.37, 0.05) * f * mix(1.0, 4.0, patches)), 
                   vec3(1.0), 
                   pow(f, 4.0));
    
    return col;
}

vec3 woman(vec2 uv){
    HAIR_LENGTH = 2000.0;
    TOUSLE = 0.1;
    BORDER = 1.25;
    
    float angle = (fbm(uv * 0.25)) * PI;
    float f = hairtexture(uv * 0.5, 1.0, angle);
    
    // just mix in some blond strains
    vec3 col = mix(vec3(0.8, 0.5, 0.0) * f * mix(2.0, 1.0, fbm(uv)), vec3(1.05, 0.92, 0.9), pow(f, 4.0) * 2.0);
    
    return col;
}

#define HAIR_FUNK(U) leopard(U)
//#define HAIR_FUNK(U) hyena(U)
//#define HAIR_FUNK(U) woman(U)

// Wyman, Chris, and Morgan McGuire. "Hashed alpha testing." 
// Proceedings of the 21st ACM SIGGRAPH Symposium on Interactive 3D Graphics and Games. ACM, 2017.
float hash(vec2 p) {
   return fract(1.0e4 * sin(17.0 * p.x + 0.1 * p.y) * (0.1 + abs(sin(13.0 * p.y + p.x))));
}

float hash3D(vec3 p) {
   return hash(vec2(hash(p.xy), p.z));
}

float psin(float a) {
  return 0.5 + 0.5*sin(a);
}

vec3 smin(vec3 a, vec3 b, float k) {
  vec3 h = max(k-abs(a-b),0.)/k;
  return min(a,b)-h*h*h*k/6.;
}

float obj(vec3 p) {

    vec3 p1 = p;
    #ifdef SLICE
        vec3 p2 = vec3(asin(sin(time )),0,0);
    #else
        vec3 p2 = vec3(1,0,0);
    #endif

    #ifdef ROTATE
        mat3 r11 = mat3(-0.33,-0.55,0.29,0.18,-0.055,0.24,-0.11,-0.42,-0.83);
        mat3 r12 = mat3(-0.42,0.13,0.26,0.8,-0.13,0.06,-0.088,0.68,-0.29);
        mat3 r22 = mat3(-0.67,-0.47,0.23,-0.07,-0.54,0.17,0.4,-0.24,0.46);
        mat3 r21 = mat3(0.54,-0.29,0.31,-0.17,0.57,0.73,-0.22,-0.047,0.25);
    #else    
        mat3 r11 = mat3(1);
        mat3 r12 = mat3(0);
        mat3 r21 = mat3(0);
        mat3 r22 = mat3(1);
    #endif

    vec3 l1s = r11*p1 + r12*p2;
    vec3 l2s = r21*p1 + r22*p2;

    vec3 l1 = smin(1.-sqrt(l1s*l1s+.1),vec3(.5),.2);
    vec3 l2 = smin(1.-sqrt(l2s*l2s+.1),vec3(.5),.2);

    
    float cage = sqrt(dot(l1,l1)+dot(l2,l2))-.9;
    return cage;
}

float scene(vec3 p) {
    //mix the object with a smaller, space-repeated copy of itself for a more interesting surface texture
    return mix(obj(p), obj(asin(sin(p*6.)*.8))/6.,.3);
}

vec3 norm(vec3 p) {
    mat3 k = mat3(p,p,p)-mat3(0.01);
    return normalize(scene(p) - vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}

vec3 tex3D( in vec3 pos, in vec3 normal ){
    return  HAIR_FUNK( pos.yz )*abs(normal.x)+ 
            HAIR_FUNK( pos.xz )*abs(normal.y)+ 
            HAIR_FUNK( pos.xy )*abs(normal.z);
}

vec3 norm2(vec3 p){
    vec3 P = vec3(-.05, .05, 0) * 0.005;

    vec3 N = normalize(scene(p+P.xyy)*P.xyy+scene(p+P.yxy)*P.yxy+
                  scene(p+P.yyx)*P.yyx+scene(p+P.xxx)*P.xxx);
    
    vec3 B = vec3(tex3D(p+P.xzz,N).r,tex3D(p+P.zxz,N).r,
                  tex3D(p+P.zzx,N).r)-tex3D(p,N).r;
    B = (B-N*dot(B,N));

    return normalize(N+B*5.0);
}

vec3 triplanar(vec3 P, vec3 N){   
    
    vec3 Nb = max(abs(N)- vec3(0.0, 0.1, 0.0), 0.0);

    float b = (Nb.x + Nb.y + Nb.z);
    Nb /= vec3(b);
    
    vec3 c0 = HAIR_FUNK(P.xy).rgb * Nb.z;
    vec3 c1 = HAIR_FUNK(P.yz).rgb * Nb.x;
    vec3 c2 = HAIR_FUNK(P.xz).rgb * Nb.y;
    
    return c0 + c1 + c2;
}

vec3 triplanarB(vec3 P, vec3 N){
    vec3 signs = sign(N);
        
    vec3 weights = max(abs(N) - vec3(0.0, 0.4, 0.0), 0.0);
    weights /= max(max(weights.x, weights.y), weights.z);
    float sharpening = 10.0;
    weights = pow(weights, vec3(sharpening, sharpening, sharpening));
    weights /= dot(weights, vec3(1.0, 1.0, 1.0));
    
    float anglep = 3.14159265/4.0;

    float cosp = cos(anglep);
    float sinp = sin(anglep);
    
    // Set up the 3 planar projections that we will be using
    // first plane is rotated around z compensating for the sign of the normal
    vec3 p1t = vec3(0.0, 0.0, 1.0);
    vec3 p1b = vec3(-signs.x * cosp, sinp, 0.0);

    // second plane is just the xz plane
    vec3 p2t = vec3(0.0, 0.0, 1.0);
    vec3 p2b = vec3(1.0, 0.0, 0.0);
    
    /// third plane is rotated around x also compensating for the sign of the normal
    vec3 p3t = vec3(1.0, 0.0, 0.0);
    vec3 p3b = vec3(0.0, sinp, -signs.z * cosp);
    
    // Perform the uv projection on to each plane
    vec2 uvp1 = vec2(dot(P, p1t), dot(P, p1b));
    vec2 uvp2 = vec2(dot(P, p2t), dot(P, p2b));
    vec2 uvp3 = vec2(dot(P, p3t), dot(P, p3b));

    vec3 texCol = HAIR_FUNK(uvp1) * weights.x +
          HAIR_FUNK(uvp2) * weights.y +
          HAIR_FUNK(uvp3) * weights.z;

    return texCol;
}

vec3 triplanarC(vec2 P, vec3 N){
    vec3 NN = vec3(P, sqrt(1.0 - dot(P, P)));

    vec3 a = max(vec3(0.0), abs(NN) - sqrt(3.0)/3.0);
    vec3 w = a / (a.x + a.y + a.z);
    

    vec2 g; // maximum projection
    if (w.x > w.y && w.x > w.z)
        g = NN.yz;
    else if (w.y > w.z)
        g = NN.xz;
    else
        g = NN.xy;

    float pixDeriv = length(vec2(length(dFdx(NN)), length(dFdy(NN))));
    float pixScale = 1.0 / pixDeriv;

    float h = hash3D(floor(NN * pixScale));
    
    vec2 t;
    if (w.z > h)
        t = NN.xy;
    else if (w.z + w.y > h)
        t = NN.xz;
    else
        t = NN.yz;

    //
    return 
        HAIR_FUNK(t) * w.z + 
        HAIR_FUNK(t) * w.y + 
        HAIR_FUNK(t) * w.x;
    //return textureGrad(iChannel0, t, dFdx(g), dFdy(g));
}

vec3 triplanarD(vec3 P, vec3 N){
    vec3 c = max(abs(N)- vec3(0.0, 0.4, 0.0), 0.0);

    
    vec3 O = c.z*HAIR_FUNK(P.xy) +  c.x*HAIR_FUNK(P.yz) +  c.y*HAIR_FUNK(P.xz);
    O +=  c.z*HAIR_FUNK(P.xy)+ c.x*HAIR_FUNK(P.yz)+ c.y*HAIR_FUNK(P.xz)  / (c.x+c.y+c.z);
    O += .5+ ( c.z*(HAIR_FUNK(P.xy)-.5) + c.x*(HAIR_FUNK(P.yz)-.5) + c.y*(HAIR_FUNK(P.xz)-.5) ) / length(c);

    return O.rgb;
}

// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 triplanarE(vec3 p, vec3 n){
    
    n = max(abs(n) - .2, 0.001);
    n /= dot(n, vec3(1));
    vec3 tx = HAIR_FUNK(p.zy).xyz;
    vec3 ty = HAIR_FUNK(p.xz).xyz;
    vec3 tz = HAIR_FUNK(p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;
}

void main(void)
{
     vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5)/resolution.y;
    
    vec2 mouse = (mouse*resolution.xy.xy/resolution.xy*2.0-1.0)*2.;
    mouse.x += time/6.;
    mouse.y += time/10.;

    mat3 rot_x = mat3( cos(-mouse.x), sin(-mouse.x), 0.0,
                      -sin(-mouse.x), cos(-mouse.x), 0.0,
                                0.0,          0.0, 1.0);
    
    mat3 rot_y = mat3( cos(-mouse.y), 0.0, sin(-mouse.y),
                                0.0, 1.0, 0.0,
                      -sin(-mouse.y), 0.0, cos(-mouse.y));
    
    vec3 cam = normalize(vec3(1.5,uv));
    vec3 init = vec3(-11,0,0);

    init*=rot_y*rot_x;
    cam*=rot_y*rot_x;

    vec3 p = init;
    bool hit = false;
    for (int i = 0; i < 300; i++) {
        float dist = scene(p);
        if (dist*dist < 0.00001) { hit = true; break; }
        if (distance(p,init)>200.) break;
        p+=dist*cam;
    }
    
    vec3 n = norm(p);
    
    /////////
    // Use this one for bump mapping but too
    // vec3 n = norm(p);
    ////////

    vec3 r = reflect(cam,n);
    vec3 lightdir = normalize(vec3(1));
    float ao = smoothstep(-.5,2.,scene(p+n*2.))*.9+.1;
    float ro = smoothstep(-.5,2.,scene(p+r*2.));
    float ss = smoothstep(-1.,1.,scene(p+lightdir));
    float spec = length(sin(r*3.)*0.2+0.8)/sqrt(3.);
    float diff = length(sin(n*2.)*0.5+0.5)/sqrt(3.);
    float fres = 1.-abs(dot(n,cam))*.98;

    // TEST 1:
       vec3 col = ao*mix(ss,diff,.5)* triplanar(p * .75, n) +pow(spec,30.)*fres*5.*ro;
    
    // TEST 2:
    //vec3 col = ao*mix(ss,diff,.5)* triplanarD(p * .75, n) * .5 +pow(spec,30.)*fres*5.*ro;
    
    // TEST 3:
    //vec3 col = ao*mix(ss,diff,.5)* triplanarE(p * .75, n) +pow(spec,30.)*fres*5.*ro;
    //col = sqrt(clamp(col, 0., .4));
    
    float bg = length(sin(cam*2.5)*0.6+0.4)/sqrt(3.) ;
      glFragColor = hit ? vec4(sqrt(col), 1.) : vec4(vec3(pow(bg,7.))* vec3(.15, .07, .02), 1.);
}
