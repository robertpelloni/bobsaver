#version 420

// original https://www.shadertoy.com/view/3lffD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LIGHT_DIR vec3(0.8, 0.2, 1.0)
#define DENSITY_THRESHOLD 0.4
#define DENSITY_MULTIPLIER 2.0
#define STEPS_NUM 100.0
#define CAMERA_DISTANCE 5.0
#define CAMERA_HEIGHT 3.0
#define PI 3.14159265359

vec3 permute(vec3 x) {
  return mod((34.0 * x + 1.0) * x, 289.0);
}

vec3 dist(vec3 x, vec3 y, vec3 z,  bool manhattanDistance) {
  return manhattanDistance ?  abs(x) + abs(y) + abs(z) :  (x * x + y * y + z * z);
}

vec2 worley(vec3 P, float jitter, bool manhattanDistance) {
float K = 0.142857142857; // 1/7
float Ko = 0.428571428571; // 1/2-K/2
float  K2 = 0.020408163265306; // 1/(7*7)
float Kz = 0.166666666667; // 1/6
float Kzo = 0.416666666667; // 1/2-1/6*2

    vec3 Pi = mod(floor(P), 289.0);
     vec3 Pf = fract(P) - 0.5;

    vec3 Pfx = Pf.x + vec3(1.0, 0.0, -1.0);
    vec3 Pfy = Pf.y + vec3(1.0, 0.0, -1.0);
    vec3 Pfz = Pf.z + vec3(1.0, 0.0, -1.0);

    vec3 p = permute(Pi.x + vec3(-1.0, 0.0, 1.0));
    vec3 p1 = permute(p + Pi.y - 1.0);
    vec3 p2 = permute(p + Pi.y);
    vec3 p3 = permute(p + Pi.y + 1.0);

    vec3 p11 = permute(p1 + Pi.z - 1.0);
    vec3 p12 = permute(p1 + Pi.z);
    vec3 p13 = permute(p1 + Pi.z + 1.0);

    vec3 p21 = permute(p2 + Pi.z - 1.0);
    vec3 p22 = permute(p2 + Pi.z);
    vec3 p23 = permute(p2 + Pi.z + 1.0);

    vec3 p31 = permute(p3 + Pi.z - 1.0);
    vec3 p32 = permute(p3 + Pi.z);
    vec3 p33 = permute(p3 + Pi.z + 1.0);

    vec3 ox11 = fract(p11*K) - Ko;
    vec3 oy11 = mod(floor(p11*K), 7.0)*K - Ko;
    vec3 oz11 = floor(p11*K2)*Kz - Kzo; // p11 < 289 guaranteed

    vec3 ox12 = fract(p12*K) - Ko;
    vec3 oy12 = mod(floor(p12*K), 7.0)*K - Ko;
    vec3 oz12 = floor(p12*K2)*Kz - Kzo;

    vec3 ox13 = fract(p13*K) - Ko;
    vec3 oy13 = mod(floor(p13*K), 7.0)*K - Ko;
    vec3 oz13 = floor(p13*K2)*Kz - Kzo;

    vec3 ox21 = fract(p21*K) - Ko;
    vec3 oy21 = mod(floor(p21*K), 7.0)*K - Ko;
    vec3 oz21 = floor(p21*K2)*Kz - Kzo;

    vec3 ox22 = fract(p22*K) - Ko;
    vec3 oy22 = mod(floor(p22*K), 7.0)*K - Ko;
    vec3 oz22 = floor(p22*K2)*Kz - Kzo;

    vec3 ox23 = fract(p23*K) - Ko;
    vec3 oy23 = mod(floor(p23*K), 7.0)*K - Ko;
    vec3 oz23 = floor(p23*K2)*Kz - Kzo;

    vec3 ox31 = fract(p31*K) - Ko;
    vec3 oy31 = mod(floor(p31*K), 7.0)*K - Ko;
    vec3 oz31 = floor(p31*K2)*Kz - Kzo;

    vec3 ox32 = fract(p32*K) - Ko;
    vec3 oy32 = mod(floor(p32*K), 7.0)*K - Ko;
    vec3 oz32 = floor(p32*K2)*Kz - Kzo;

    vec3 ox33 = fract(p33*K) - Ko;
    vec3 oy33 = mod(floor(p33*K), 7.0)*K - Ko;
    vec3 oz33 = floor(p33*K2)*Kz - Kzo;

    vec3 dx11 = Pfx + jitter*ox11;
    vec3 dy11 = Pfy.x + jitter*oy11;
    vec3 dz11 = Pfz.x + jitter*oz11;

    vec3 dx12 = Pfx + jitter*ox12;
    vec3 dy12 = Pfy.x + jitter*oy12;
    vec3 dz12 = Pfz.y + jitter*oz12;

    vec3 dx13 = Pfx + jitter*ox13;
    vec3 dy13 = Pfy.x + jitter*oy13;
    vec3 dz13 = Pfz.z + jitter*oz13;

    vec3 dx21 = Pfx + jitter*ox21;
    vec3 dy21 = Pfy.y + jitter*oy21;
    vec3 dz21 = Pfz.x + jitter*oz21;

    vec3 dx22 = Pfx + jitter*ox22;
    vec3 dy22 = Pfy.y + jitter*oy22;
    vec3 dz22 = Pfz.y + jitter*oz22;

    vec3 dx23 = Pfx + jitter*ox23;
    vec3 dy23 = Pfy.y + jitter*oy23;
    vec3 dz23 = Pfz.z + jitter*oz23;

    vec3 dx31 = Pfx + jitter*ox31;
    vec3 dy31 = Pfy.z + jitter*oy31;
    vec3 dz31 = Pfz.x + jitter*oz31;

    vec3 dx32 = Pfx + jitter*ox32;
    vec3 dy32 = Pfy.z + jitter*oy32;
    vec3 dz32 = Pfz.y + jitter*oz32;

    vec3 dx33 = Pfx + jitter*ox33;
    vec3 dy33 = Pfy.z + jitter*oy33;
    vec3 dz33 = Pfz.z + jitter*oz33;

    vec3 d11 = dist(dx11, dy11, dz11, manhattanDistance);
    vec3 d12 =dist(dx12, dy12, dz12, manhattanDistance);
    vec3 d13 = dist(dx13, dy13, dz13, manhattanDistance);
    vec3 d21 = dist(dx21, dy21, dz21, manhattanDistance);
    vec3 d22 = dist(dx22, dy22, dz22, manhattanDistance);
    vec3 d23 = dist(dx23, dy23, dz23, manhattanDistance);
    vec3 d31 = dist(dx31, dy31, dz31, manhattanDistance);
    vec3 d32 = dist(dx32, dy32, dz32, manhattanDistance);
    vec3 d33 = dist(dx33, dy33, dz33, manhattanDistance);

    vec3 d1a = min(d11, d12);
    d12 = max(d11, d12);
    d11 = min(d1a, d13); // Smallest now not in d12 or d13
    d13 = max(d1a, d13);
    d12 = min(d12, d13); // 2nd smallest now not in d13
    vec3 d2a = min(d21, d22);
    d22 = max(d21, d22);
    d21 = min(d2a, d23); // Smallest now not in d22 or d23
    d23 = max(d2a, d23);
    d22 = min(d22, d23); // 2nd smallest now not in d23
    vec3 d3a = min(d31, d32);
    d32 = max(d31, d32);
    d31 = min(d3a, d33); // Smallest now not in d32 or d33
    d33 = max(d3a, d33);
    d32 = min(d32, d33); // 2nd smallest now not in d33
    vec3 da = min(d11, d21);
    d21 = max(d11, d21);
    d11 = min(da, d31); // Smallest now in d11
    d31 = max(da, d31); // 2nd smallest now not in d31
    d11.xy = (d11.x < d11.y) ? d11.xy : d11.yx;
    d11.xz = (d11.x < d11.z) ? d11.xz : d11.zx; // d11.x now smallest
    d12 = min(d12, d21); // 2nd smallest now not in d21
    d12 = min(d12, d22); // nor in d22
    d12 = min(d12, d31); // nor in d31
    d12 = min(d12, d32); // nor in d32
    d11.yz = min(d11.yz,d12.xy); // nor in d12.yz
    d11.y = min(d11.y,d12.z); // Only two more to go
    d11.y = min(d11.y,d11.z); // Done! (Phew!)
    return sqrt(d11.xy) * 0.5 + 0.5; // F1, F2

}

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

float voronoifbm(vec3 p, float jitter, bool manhattan, int octaves)
{
    float noiseSum = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++)
    {
        float n = (1.0 - worley(p*frequency, jitter, false).x);
        noiseSum += n*amplitude;
        frequency*=2.0;
        amplitude*=0.5;
    }
    
    return noiseSum;
}

float hash1( float n )
{
    return fract( n*17.0*fract( n*0.3183099 ) );
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    
    float n = p.x + 317.0*p.y + 157.0*p.z;
    
    float a = hash1(n+0.0);
    float b = hash1(n+1.0);
    float c = hash1(n+317.0);
    float d = hash1(n+318.0);
    float e = hash1(n+157.0);
    float f = hash1(n+158.0);
    float g = hash1(n+474.0);
    float h = hash1(n+475.0);

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
}

float fbm(vec3 p, int octaves)
{
    float noiseSum = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++)
    {
        noiseSum += abs(snoise(p*frequency)*amplitude);
        frequency*=2.0;
        amplitude*=0.5;
    }
    
    return 1.0 - noiseSum;
}

struct Ray
{
    vec3 Origin;
    vec3 Direction;
    vec3 Energy;
};

struct RayHit
{
  vec3 Position;
  float Distance;
  float FarDistance;
  vec3 Normal;
  vec2 uv;
  int MaterialId;
};
    
mat2 Rot(float a) 
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}  
    
vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z)
{
    vec3 f = normalize(l-p),
    r = normalize(cross(vec3(0,1,0), f)),
    u = cross(f,r),
    c = p+f*z,
    i = c + uv.x*r + uv.y*u,
    d = normalize(i-p);
    return d;
}

Ray CreateRay(vec3 ro, vec3 rd)
{
    Ray ray;
    ray.Origin = ro;
    ray.Direction = rd;
    ray.Energy = vec3(1.0);
    return ray;
}

RayHit CreateRayHit()
{
    RayHit hit;
    hit.Position = vec3(0.0);
    hit.Distance = -1.;
    hit.FarDistance = -1.;
    hit.Normal = vec3(0.0);
    hit.uv = vec2(0.0);
    return hit;
}
    
void IntersectSphere(Ray ray, inout RayHit hit, vec4 sphere)
{
    //get the vector from the center of this circle to where the ray begins.
    vec3 m = ray.Origin - sphere.xyz;

    //get the dot product of the above vector and the ray's vector
    float b = dot(m, ray.Direction);

    float c = dot(m, m) - sphere.w * sphere.w;

    //exit if r's origin outside s (c > 0) and r pointing away from s (b > 0)
    if(c > 0.0 && b > 0.0)
        return;

    //calculate discriminant
    float discr = b * b - c;

    //a negative discriminant corresponds to ray missing sphere
    if(discr < 0.0)
        return;

    //ray now found to intersect sphere, compute smallest t value of intersection
    float normalMultiplier = 1.0;
    float collisionTime = -b - sqrt(discr);
    
    hit.FarDistance = -b + sqrt(discr);
    if (collisionTime < 0.0)
    {
        collisionTime = -b + sqrt(discr);
        normalMultiplier = -1.0;
    }    

    //Check if the hitted point is closer to the camera
    if (collisionTime < hit.Distance || hit.Distance == -1.0)
    {
        // return the time t that the collision happened, as well as the surface normal
        vec3 p = ray.Origin + ray.Direction * collisionTime;
        // calculate the normal, flipping it if we hit the inside of the sphere
        vec3 normal = normalize((ray.Origin+ray.Direction*collisionTime) - sphere.xyz) * normalMultiplier;
        
        hit.Distance = collisionTime;
        hit.Position = p;
        hit.Normal = normal;
        
        //Calculate uv coordinates at hit point
        vec3 d = normalize(p - sphere.xyz);
        float u = 0.5 + atan(d.z, d.x)/ 2.0*PI;
        float v = 0.5 - asin(d.y)/PI;
        hit.uv = vec2(u,v);
        
        hit.MaterialId = 1;
    }    
}

Ray CreateCameraRay(vec2 uv)
{
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    
    vec3 ro = vec3(0, CAMERA_HEIGHT, -CAMERA_DISTANCE);
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.);
    
    return CreateRay(ro, rd);
}

RayHit Trace(Ray ray)
{
    RayHit hit = CreateRayHit();
    IntersectSphere(ray, hit, vec4(vec3(0.0, 0.0, 0.0), 5.0));
    return hit;
}

float SampleDensity(vec3 pos)
{
    //voronoifbm(pos, 1.0, false, 1);
   pos.y -= time;
   float n =  fbm((pos * 0.2), 3);
   
   float density = max(0.0, n - DENSITY_THRESHOLD) * DENSITY_MULTIPLIER;
   return density;
}

vec3 Shade(RayHit hit, Ray ray, float transmitance)
{
    vec3 LightDir = normalize(LIGHT_DIR);
    
    float dif = clamp(dot(hit.Normal, LightDir), 0.0, 1.0);
    vec3 reflection = normalize(2.0 * dif * hit.Normal - LightDir);
    float specular = pow(clamp(dot(reflection, -ray.Direction), 0.0, 1.0), 32.0) * dif;
    
    vec3 col = vec3(0.7) * (1.0 - transmitance);
    return 0.1 + col * dif + specular;
}

void main(void)
{
    // Coordinates from -1 to 1
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0.0);
    
    Ray ray = CreateCameraRay(uv);
    
    RayHit hit = Trace(ray);
    
    float CloseDst = hit.Distance;
    float FarDst = hit.FarDistance;
    
    float TravelledDst = 0.0;
    float StepSize = FarDst / STEPS_NUM;
    float dstLimit = FarDst;
    
    float TotalDensity = 0.0;
    
    while (TravelledDst < dstLimit)
    {
        vec3 rayPos = ray.Origin + normalize(ray.Direction) * (CloseDst + TravelledDst);
        TotalDensity += SampleDensity(rayPos) * StepSize;
        TravelledDst += StepSize;
    }
    
    float transmitance = exp(-TotalDensity);
    
    if (hit.Distance > 0.0)
    {
        col = vec3(0.7) * (1.0 - transmitance);//Shade(hit, ray, transmitance);
    }
    
    
    
    //col = vec3(voronoifbm(vec3(uv.x*5.0, uv.y*5.0, 0.0), 1.0, false, 4));

    // Output to screen
    glFragColor = vec4(col, 1.0);
}
