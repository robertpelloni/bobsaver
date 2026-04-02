#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wljGRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float globalTime;

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

float noise3D(vec3 p){
    return fract(sin(dot(p ,vec3(12.9898,78.233,128.852))) * 43758.5453)*2.0-1.0;
}

float simplex3D(vec3 p)
{
    float f3 = 1.0/3.0;
    float s = (p.x+p.y+p.z)*f3;
    int i = int(floor(p.x+s));
    int j = int(floor(p.y+s));
    int k = int(floor(p.z+s));
    
    float g3 = 1.0/6.0;
    float t = float((i+j+k))*g3;
    float x0 = float(i)-t;
    float y0 = float(j)-t;
    float z0 = float(k)-t;
    x0 = p.x-x0;
    y0 = p.y-y0;
    z0 = p.z-z0;
    int i1,j1,k1;
    int i2,j2,k2;
    if(x0>=y0)
    {
        if        (y0>=z0){ i1=1; j1=0; k1=0; i2=1; j2=1; k2=0; } // X Y Z order
        else if    (x0>=z0){ i1=1; j1=0; k1=0; i2=1; j2=0; k2=1; } // X Z Y order
        else             { i1=0; j1=0; k1=1; i2=1; j2=0; k2=1; } // Z X Z order
    }
    else 
    { 
        if        (y0<z0) { i1=0; j1=0; k1=1; i2=0; j2=1; k2=1; } // Z Y X order
        else if    (x0<z0) { i1=0; j1=1; k1=0; i2=0; j2=1; k2=1; } // Y Z X order
        else             { i1=0; j1=1; k1=0; i2=1; j2=1; k2=0; } // Y X Z order
    }
    float x1 = x0 - float(i1) + g3; 
    float y1 = y0 - float(j1) + g3;
    float z1 = z0 - float(k1) + g3;
    float x2 = x0 - float(i2) + 2.0*g3; 
    float y2 = y0 - float(j2) + 2.0*g3;
    float z2 = z0 - float(k2) + 2.0*g3;
    float x3 = x0 - 1.0 + 3.0*g3; 
    float y3 = y0 - 1.0 + 3.0*g3;
    float z3 = z0 - 1.0 + 3.0*g3;             
    vec3 ijk0 = vec3(i,j,k);
    vec3 ijk1 = vec3(i+i1,j+j1,k+k1);    
    vec3 ijk2 = vec3(i+i2,j+j2,k+k2);
    vec3 ijk3 = vec3(i+1,j+1,k+1);         
    vec3 gr0 = normalize(vec3(noise3D(ijk0),noise3D(ijk0*2.01),noise3D(ijk0*2.02)));
    vec3 gr1 = normalize(vec3(noise3D(ijk1),noise3D(ijk1*2.01),noise3D(ijk1*2.02)));
    vec3 gr2 = normalize(vec3(noise3D(ijk2),noise3D(ijk2*2.01),noise3D(ijk2*2.02)));
    vec3 gr3 = normalize(vec3(noise3D(ijk3),noise3D(ijk3*2.01),noise3D(ijk3*2.02)));
    float n0 = 0.0;
    float n1 = 0.0;
    float n2 = 0.0;
    float n3 = 0.0;
    float t0 = 0.5 - x0*x0 - y0*y0 - z0*z0;
    if(t0>=0.0)
    {
        t0*=t0;
        n0 = t0 * t0 * dot(gr0, vec3(x0, y0, z0));
    }
    float t1 = 0.5 - x1*x1 - y1*y1 - z1*z1;
    if(t1>=0.0)
    {
        t1*=t1;
        n1 = t1 * t1 * dot(gr1, vec3(x1, y1, z1));
    }
    float t2 = 0.5 - x2*x2 - y2*y2 - z2*z2;
    if(t2>=0.0)
    {
        t2 *= t2;
        n2 = t2 * t2 * dot(gr2, vec3(x2, y2, z2));
    }
    float t3 = 0.5 - x3*x3 - y3*y3 - z3*z3;
    if(t3>=0.0)
    {
        t3 *= t3;
        n3 = t3 * t3 * dot(gr3, vec3(x3, y3, z3));
    }
    return 96.0*(n0+n1+n2+n3);
}

float fbm(vec3 p){
    float f;
    f  = 0.50000*(simplex3D( p )); p = p*2.01;
    f += 0.25000*(simplex3D( p )); p = p*2.02;
    f += 0.12500*(simplex3D( p )); p = p*2.03;
    f += 0.06250*(simplex3D( p )); p = p*2.04;
    f += 0.03125*(simplex3D( p )); p = p*2.05;
    f += 0.015625*(simplex3D( p ));
    return f;
}

uint base_hash(uvec2 p) {
    p = 1103515245U*((p >> 1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    return h32^(h32 >> 16);
}

float g_seed = 0.;

float hash1(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    return float(n)/float(0xffffffffU);
}

vec3 hash3(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    uvec3 rz = uvec3(n, n*16807U, n*48271U);
    return vec3(rz & uvec3(0x7fffffffU))/float(0x7fffffff);
}

vec3 random_in_unit_sphere(inout float seed) {
    vec3 h = hash3(seed) * vec3(2.,6.28318530718,1.)-vec3(1,0,0);
    float phi = h.y;
    float r = pow(h.z, 1./3.);
    return r * vec3(sqrt(1.-h.x*h.x)*vec2(sin(phi),cos(phi)),h.x);
}

struct Ray{vec3 origin, dir;};
struct Plane{ vec3 origin; vec3 normal;};
bool plane_hit(in Ray inray, in Plane plane, out float t) {
    float denom = dot(plane.normal, inray.dir);
    if (denom > 1e-6) {
        vec3 p0l0 = plane.origin - inray.origin;
        t = dot(p0l0, plane.normal) / denom;
        return true;
    }
    return false;
}

#define LAYERS_COUNT 6.0
#define SIZE_MOD 2.0
#define ALPHA_MOD 0.93
#define FRONT_BLEND_DISTANCE 1.0
#define BACK_BLEND_DISTANCE 4.0
#define PARTICLE_SIZE 0.045
#define FOV 1.0

float hash12(vec2 x){
     return fract(sin(dot(x, vec2(43.5287, 41.12871))) * 523.582);   
}

vec2 hash21(float x){
     return fract(sin(x * vec2(24.0181, 52.1984)) * 5081.4972);   
}

vec2 rotate(vec2 point, float angle){
     float s = sin(angle);
    float c = cos(angle);
    return point * mat2(s, c, -c, s);
}

//Random point from [rootUV] to [rootUV + 1.0]
vec2 particleCoordFromRootUV(vec2 rootUV){
    return rotate(vec2(0.0, 1.0), globalTime * 3.0 * (hash12(rootUV) - 0.5)) * (0.5 - PARTICLE_SIZE) + rootUV + 0.5;
}

//particle shape
float particleFromParticleUV(vec2 particleUV, vec2 uv)
{
     return 1.0 - smoothstep(0.0, PARTICLE_SIZE, length(particleUV - uv));   
}

//grid based particle layer
float particlesLayer(vec2 uv, float seed)
{
       uv = uv + hash21(seed) * 10.0;
    vec2 rootUV = floor(uv);
    vec2 particleUV = particleCoordFromRootUV(rootUV);
    float particles = particleFromParticleUV(particleUV, uv);
    return particles;
}

float layerScaleFromIndex(float index)
{
     return log(pow(SIZE_MOD, index));  //Can be optimized by removing pow
}

float layeredParticles(vec2 screenUV, vec3 cameraPos)
{
    screenUV *= FOV;
    float particles = 0.0;
    float alpha = 1.0;
    float previousScale = 0.0;
    float targetScale = 1.0;
    float scale = 0.0;
    
    //Painting layers from front to back
    for (float i = 0.0; i < LAYERS_COUNT; i += 1.0)
    {
        //depth offset
        float offset = fract(cameraPos.z);
        
        //blending back and front
        float blend = smoothstep(0.0, FRONT_BLEND_DISTANCE, i - offset + 1.0);
        blend *= smoothstep(0.0, -BACK_BLEND_DISTANCE, i - offset + 1.0 - LAYERS_COUNT);
        
        float fog = mix(alpha * ALPHA_MOD, alpha, offset) * blend;
        
        targetScale = layerScaleFromIndex(i + 1.0);
        
        //dynamic scale - depends on depth offset
        scale = mix(targetScale, previousScale, offset);
        
        //adding layer
         particles += particlesLayer(screenUV * scale + cameraPos.xy, floor(cameraPos.z) + i) * fog;
        alpha *= ALPHA_MOD;
        previousScale = targetScale;
    }
    
    return particles;
}

const float MAX_TRACE_DISTANCE = 8.;
const int NUM_OF_TRACE_STEPS = 64;
const float EPS = .00001;

float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
    return dot(p, n) + distanceFromOrigin;
}

const float gravity = 2.0;
const float waterTension = .11;

vec2 wave(in float t, in float a, in float w, in float p) {
  float x = t;
  float y = a*sin(t*w + p);
  return vec2(x, y);
}

vec2 dwave(in float t, in float a, in float w, in float p) {
  float dx = 1.0;
  float dy = a*w*cos(t*w + p);
  return vec2(dx, dy);
}

vec2 gravityWave(in float t, in float a, in float k, in float h) {
  float w = sqrt(gravity*k*tanh(k*h));
  return wave(t, a ,k, w*time);
}

vec2 capillaryWave(in float t, in float a, in float k, in float h) {
  float w = sqrt((gravity*k + waterTension*k*k*k)*tanh(k*h));
  return wave(t, a, k, w*time);
}

vec2 gravityWaveD(in float t, in float a, in float k, in float h) {
  float w = sqrt(gravity*k*tanh(k*h));
  return dwave(t, a, k, w*time);
}

vec2 capillaryWaveD(in float t, in float a, in float k, in float h) {
  float w = sqrt((gravity*k + waterTension*k*k*k)*tanh(k*h));
  return dwave(t, a, k, w*time);
}

mat2 mrot(in float a) {
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c);
}

mat2 mtrans(in mat2 m) {
  return mat2(m[0][0], m[1][0], m[0][1], m[1][1]);
}

vec4 sea(in vec2 p, in float ia) {
  float y = 0.0;
  vec3 d = vec3(0.0);

  float k = 2.5;
  float kk = 1.2;
  float a = ia*0.2;
  float aa = 1.0/(kk*kk);

  float h = 10.0;
  
  float angle = 0.0;

  for (int i = 0; i < 3; ++i) {
    mat2 fr = mrot(angle);
    mat2 rr = mtrans(fr);
    vec2 pp = fr*p;
    y += gravityWave(pp.y + float(i), a, k, h).y;
    vec2 dw = gravityWaveD(pp.y + float(i), a, k, h);
    
    vec2 d2 = vec2(0.0, dw.x);
    vec2 rd2 = rr*d2;
    
    d += vec3(rd2.x, dw.y, rd2.y);

    angle += float(i);
    k *= kk;
    a *= aa;
  }

  for (int i = 3; i < 7; ++i) {
    mat2 fr = mrot(angle);
    mat2 rr = mtrans(fr);
    vec2 pp = fr*p;
    y += capillaryWave(pp.y + float(i), a, k, h).y;
    vec2 dw = capillaryWaveD(pp.y + float(i), a, k, h);
    
    vec2 d2 = vec2(0.0, dw.x);
    vec2 rd2 = rr*d2;
    
    d += vec3(rd2.x, dw.y, rd2.y);

    angle += float(i);
    k *= kk;
    a *= aa;
  }
  
  vec3 t = normalize(d);
  vec3 nxz = normalize(vec3(t.z, 0.0, -t.x));
  vec3 nor = cross(t, nxz);

  return vec4(y, nor);
}

float map(vec3 p){
    float h = sea(p.xz * 5. - vec2(1., time * 15.), .75).x;
    return fPlane(p, vec3(0, 1, 0), .15 * h);
}

float march(in vec3 ro, in vec3 rd){
    float h =  EPS * 2.0;
    float t = 0.0;
    float res = -1.0;

    for( int i=0; i< NUM_OF_TRACE_STEPS ; i++ ){
        if( h < EPS || t > MAX_TRACE_DISTANCE ) break;
        h = map( ro+rd*t );
        t += h * .75;
    }
    if( t < MAX_TRACE_DISTANCE ) res = t;
    return res;
}

vec3 calcNormal( in vec3 pos ){
    vec3 eps = vec3( 0.05, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy) - map(pos-eps.xyy),
        map(pos+eps.yxy) - map(pos-eps.yxy),
        map(pos+eps.yyx) - map(pos-eps.yyx) );
    return normalize(nor);
}

// INNER ATMOS PROPIETIES:
    // inner atmos inner strenght
    #define in_inner 0.2
    // inner atmos outer strenght
    #define in_outer 0.2

// OUTER ATMOS PROPIETIES:
    // inner atmos inner strenght
    #define out_inner 0.2 
    // inner atmos outer strenght
    #define out_outer 0.1 // 0.01 is nice too
bool moon(vec3 eye, vec3 worldDir, out float dist, out float clr){
    float time = time;
    clr = 0.;
    if(plane_hit(Ray(eye, worldDir), Plane(vec3(0.), vec3(0., 0., -1.)), dist)){
        vec3 p = eye + worldDir * dist;
        // LIGHT
        vec3 l = normalize(vec3(0., 20., 5.));

        // PLANET
        float r = .5;
        float z_in = sqrt(r*r - p.x*p.x - p.y*p.y);
        float z_out = sqrt(-r*r + p.x*p.x + p.y*p.y);

        // NORMALS
        vec3 norm = normalize(vec3(p.x, p.y, z_in)); // normals from sphere
        vec3 norm_out = normalize(vec3(p.x, p.y, z_out)); // normals from outside sphere
        float e = 0.05; // planet rugosity
        float nx = fbm(vec3(norm.x+e, norm.y,   norm.z  ))*0.5+0.5; // x normal displacement
        float ny = fbm(vec3(norm.x,   norm.y+e, norm.z  ))*0.5+0.5; // y normal displacement
        float nz = fbm(vec3(norm.x,   norm.y,   norm.z+e))*0.5+0.5; // z normal displacement
        norm = normalize(vec3(norm.x*nx, norm.y*ny, norm.z*nz));
        //norm = (norm+1.)/2.; // for normals visualization

        // TEXTURE
        float n = 1.0-(fbm(vec3(norm.x, norm.y, norm.z))*0.5+0.5); // noise for every pixel in planet

        // ATMOS
        float z_in_atm  = (r * in_outer)  / z_in - in_inner;   // inner atmos
        float z_out_atm = (r * out_inner) / z_out - out_outer; // outer atmos
        z_in_atm = max(0.0, z_in_atm);
        z_out_atm = max(0.0, z_out_atm);

        // DIFFUSE LIGHT
        float diffuse = max(0.0, dot(norm, l));
        float diffuse_out = max(0.0, dot(norm_out, l)+0.3); // +0.3 because outer atmosphere stills when inner doesn't

        clr = (n * diffuse + z_in_atm * diffuse + z_out_atm * diffuse_out);
        return true;
    }
    return false;
}

const vec3 BLUE = vec3(72., 152., 206.)/255.;
void main(void) {
    globalTime = fract(time * .5) * 1.5;

    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy) / resolution.y;
    vec3 eye = vec3(0., .25, 3.);
    vec3 viewDir = rayDirection(45., resolution.xy);
    vec3 worldDir = viewMatrix(eye, vec3(0.), vec3(0., 1., 0.)) * viewDir;
    
    float clr = 0.;
    float dist;
    moon(eye, worldDir, dist, clr);
    float hit = march(eye, worldDir);
    if(hit > 0. && hit < dist){
        vec3 pos = eye + worldDir * hit;
        vec3 nrm = calcNormal(pos);
        vec3 reflected = reflect(worldDir, nrm);
        
        float totalClr = 0.;
        for (int i=-1; i<2; i++){
            for (int j=-1; j<2; j++){
                g_seed = float(base_hash(floatBitsToUint(pos.xz + vec2(i, j))))/float(0xffffffffU)+time;
                vec3 rd = normalize(reflected + random_in_unit_sphere(g_seed) * .1);
                float c = 0.;
                moon(pos, rd, dist, c);
                totalClr += c;
            }
        }
        clr = totalClr/9.;
    }
    
    float particles = layeredParticles(uv, eye + vec3(2., 0., time * 2.))
                    * smoothstep(.1, .05, clr);
    clr = max(clr, particles);
    glFragColor = vec4(BLUE * clr, 1.);
}
