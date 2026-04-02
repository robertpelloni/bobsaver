#version 420

// original https://www.shadertoy.com/view/3tdGR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159265359
#define frand(p) fract(sin(p)*43758.5453123)
#define rand(p) (256.*fract( sin( dot( floor(p) , vec2(1.1,31.7)) ) *43758.5453123 ))

struct Ray
{
    vec3 o, d;
};
struct WaveInfo
{
    float rotationLimit, angleLimiter, waveScalar, waveHeight, wavePeak, timeScalar;
};

WaveInfo info = WaveInfo(10.0, 0.2, 30.0, 4.0, 0.3, 4.0);

float saturatedDot( in vec3 a, in vec3 b )
{
    return max( dot( a, b ), 0.0 );   
}

vec3 YxyToXYZ( in vec3 Yxy )
{
    float Y = Yxy.r;
    float x = Yxy.g;
    float y = Yxy.b;

    float X = x * ( Y / y );
    float Z = ( 1.0 - x - y ) * ( Y / y );

    return vec3(X,Y,Z);
}

vec3 XYZToRGB( in vec3 XYZ )
{
    // CIE/E
    mat3 M = mat3
    (
         2.3706743, -0.9000405, -0.4706338,
        -0.5138850,  1.4253036,  0.0885814,
          0.0052982, -0.0146949,  1.0093968
    );

    return XYZ * M;
}

vec3 YxyToRGB( in vec3 Yxy )
{
    vec3 XYZ = YxyToXYZ( Yxy );
    vec3 RGB = XYZToRGB( XYZ );
    return RGB;
}

void calculatePerezDistribution( in float t, out vec3 A, out vec3 B, out vec3 C, out vec3 D, out vec3 E )
{
    A = vec3(  0.1787 * t - 1.4630, -0.0193 * t - 0.2592, -0.0167 * t - 0.2608 );
    B = vec3( -0.3554 * t + 0.4275, -0.0665 * t + 0.0008, -0.0950 * t + 0.0092 );
    C = vec3( -0.0227 * t + 5.3251, -0.0004 * t + 0.2125, -0.0079 * t + 0.2102 );
    D = vec3(  0.1206 * t - 2.5771, -0.0641 * t - 0.8989, -0.0441 * t - 1.6537 );
    E = vec3( -0.0670 * t + 0.3703, -0.0033 * t + 0.0452, -0.0109 * t + 0.0529 );
}

vec3 calculateZenithLuminanceYxy( in float t, in float thetaS )
{
    float chi           = ( 4.0 / 9.0 - t / 120.0 ) * ( pi - 2.0 * thetaS );
    float Yz            = ( 4.0453 * t - 4.9710 ) * tan( chi ) - 0.2155 * t + 2.4192;

    float theta2     = thetaS * thetaS;
    float theta3     = theta2 * thetaS;
    float T          = t;
    float T2          = t * t;

    float xz =
      ( 0.00165 * theta3 - 0.00375 * theta2 + 0.00209 * thetaS + 0.0)     * T2 +
      (-0.02903 * theta3 + 0.06377 * theta2 - 0.03202 * thetaS + 0.00394) * T +
      ( 0.11693 * theta3 - 0.21196 * theta2 + 0.06052 * thetaS + 0.25886);

    float yz =
      ( 0.00275 * theta3 - 0.00610 * theta2 + 0.00317 * thetaS + 0.0)     * T2 +
      (-0.04214 * theta3 + 0.08970 * theta2 - 0.04153 * thetaS + 0.00516) * T +
      ( 0.15346 * theta3 - 0.26756 * theta2 + 0.06670 * thetaS + 0.26688);

    return vec3( Yz, xz, yz );
}

vec3 calculatePerezLuminanceYxy( in float theta, in float gamma, in vec3 A, in vec3 B, in vec3 C, in vec3 D, in vec3 E )
{
    return ( 1.0 + A * exp( B / cos( theta ) ) ) * ( 1.0 + C * exp( D * gamma ) + E * cos( gamma ) * cos( gamma ) );
}

vec3 calculateSkyLuminanceRGB( in vec3 s, in vec3 e, in float t )
{
    vec3 A, B, C, D, E;
    calculatePerezDistribution( t, A, B, C, D, E );

    float thetaS = acos( saturatedDot( s, vec3(0,1,0) ) );
    float thetaE = acos( saturatedDot( e, vec3(0,1,0) ) );
    float gammaE = acos( saturatedDot( s, e )           );

    vec3 Yz = calculateZenithLuminanceYxy( t, thetaS );

    vec3 fThetaGamma = calculatePerezLuminanceYxy( thetaE, gammaE, A, B, C, D, E );
    vec3 fZeroThetaS = calculatePerezLuminanceYxy( 0.0,    thetaS, A, B, C, D, E );

    vec3 Yp = Yz * ( fThetaGamma / fZeroThetaS );

    return YxyToRGB( Yp );
}
vec3 skyGenerate(float t, vec3 rd)
{
   vec3 sunDir = normalize( vec3( sin(t * 0.125) * cos(t * 0.25), cos(t * 0.25), sin(t * 0.25) * sin(t * 0.125) ) );
    return (calculateSkyLuminanceRGB( sunDir, rd, 2.5))/25.0;
}

//------perlin noise-------

float smooth_(vec2 p){
    float corners = (rand(vec2(p.x-1.0,p.y-1.0))+rand(vec2(p.x+1.0,p.y-1.0))+rand(vec2(p.x-1.0,p.y+1.0))+rand(vec2(p.x+1.0,p.y+1.0)))/16.0;
    float sides = (rand(vec2(p.x+1.0,p.y))+rand(vec2(p.x-1.0,p.y))+rand(vec2(p.x,p.y+1.0))+rand(vec2(p.x,p.y-1.0)))/8.0;
    float center = rand(vec2(p.x,p.y))/4.0;
    return corners + sides + center;                                                           
}
float lin_inter(float x, float y, float s)
{
    return x + s * (y-x);
}

float smooth_inter(float x, float y, float s)
{
    return lin_inter(x, y, s * s * (3.0-2.0*s));
}
float noiseSample(vec2 uv)
{
    float ix = floor(uv.x), iy = floor(uv.y);
    float x_frac = fract(uv.x);
    float y_frac = fract(uv.y);
    float s = smooth_(vec2(ix,iy))/256.0;
    float t = smooth_(vec2(ix+1.0,iy))/256.0;
    float u = smooth_(vec2(ix,iy+1.0))/256.0;
    float v = smooth_(vec2(ix+1.0,iy+1.0))/256.0;
    float low = smooth_inter(s, t, x_frac);
    float high = smooth_inter(u, v, x_frac);
    return smooth_inter(low, high, y_frac);
}
float lerp(float a, float b, float t)
{
    return a*t + b*(1.-t);
}

float perlin2d(vec2 uv, float freq, int depth)
{
    uv *= freq;
    float amp = 2.0;
    float fin = 0.0;
    float div = 0.0;

    int i;
    for(i=0; i<depth; i++)
    {
        div += amp;
        fin += noiseSample(uv) * amp;
        amp /= 2.0;
        uv.x *= 2.0;
        uv.y *= 2.0;
    }

    return fin/div;
}
   
//------wave------

vec2 Rotate2d(vec2 position, float theta)
{
    float dx = position.x * cos(theta) - position.y * sin(theta);
    float dy = position.x * sin(theta) + position.y * cos(theta);
    return vec2(dx, dy);
}
//info goes (rotation noise scale, rotation noise wave angle, wave scalar, time scalar)
float wave(vec2 uv, WaveInfo info, int n)
{
    float sum = 0.0;
    vec2 q = vec2(0.0);
    float m = 0.0;
    float noise = sin(info.rotationLimit);
    float nf = float(n);
    vec2 timeAngle = vec2(time * info.angleLimiter, time * (1.0-info.angleLimiter));
    uv += timeAngle * info.timeScalar;
    for(int i = 0; i < n; ++i)
    {
        ++m;
        noise = sin(noise * 4700002.123456789);
        vec2 edit = uv;
        edit += timeAngle * 3.0 * (info.timeScalar/m); //move sub waves
        vec2 rotated = Rotate2d(edit, pi * info.rotationLimit * ((noise * info.angleLimiter) / m)); //random rotation
        
        rotated *= m/info.waveScalar;
        
        float trig = mix(sin(rotated.y), cos(2.0*rotated.x), info.angleLimiter);
        noise = sin(noise * 4700002.123456789);
        float value = mix(-abs(trig) + 1.0, trig, noise * info.wavePeak);
        
        sum += value * value;
    }
    sum /= m;
    return sum * (info.waveHeight);
}
float waveFoam(vec3 p, WaveInfo info)
{
    vec2 timeAngle = 4.0*vec2(time * info.angleLimiter, time * (1.0-info.angleLimiter));
    float ylimit = max(10.0*((1.0 - 1.0/(p.y + 1.0))-0.7), 0.0);
    return ylimit * perlin2d(p.xz + timeAngle, 10.0, 10);
}

//------march------

float map(vec3 p)
{
    p = p - vec3(0, 1.0, 0);
    float ocean = wave(p.xz, info, 20);
    return dot(p, vec3(0, 1.0, 0)) - ocean;
}
vec3 normal (vec3 p)
{
 const float eps = 0.0001;
 
 return normalize
 ( vec3
     ( map(p + vec3(eps, 0, 0) ) - map(p - vec3(eps, 0, 0)),
       map(p + vec3(0, eps, 0) ) - map(p - vec3(0, eps, 0)),
      map(p + vec3(0, 0, eps) ) - map(p - vec3(0, 0, eps))
     )
 );
}
float march(Ray ray)
{
    float cd = 0.0, fd = 0.0;
    for(int i = 0; i < 500; ++i)
    {
        cd = map(ray.o + ray.d * fd);
        fd += cd;
        if(fd > 500.0)
            return 0.0;
        if(cd < 0.0001)
            return fd;
    }
    return 0.0;
}

float getao (vec3 pos, vec3 normal)
{
    return clamp(map(pos+normal*0.2)/0.2, 0.0, 1.0);
}
float scatter(float l, Ray ray)
{
    float total = 0.0;
    ray.o = ray.o + ray.d * (l + 0.1);
    for(int i = 0; i < 50; ++i)
    {
        float dist = map(ray.o + ray.d * total);
        total += dist;
        if(dist >= -0.01)
            return total;
    }
}

//------ray gen------

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}
mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

//------main------

void main(void)
{
    vec2 sinTime = vec2(sin(time), cos(time));
    
    vec3 viewDir = rayDirection(90.0, resolution.xy);
    vec3 eye = vec3(10.0, 7.0, 10.0);
    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 7.0, 0.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    Ray ray = Ray(eye, worldDir);
    
    vec3 sun = normalize(vec3(sinTime, 0.0));
    
    float l = march(ray);
    vec3 n = vec3(0);
    vec3 c = vec3(0);
    
    if(l != 0.0)
    {
        vec3 p = eye + worldDir * (l - 0.005);
        n = normal(p);
        float ao = getao(p, n);
        float sss = scatter(l, ray);
        vec3 col = vec3(0.3, 0.6, 0.8) * exp(sss*3.0);
        float ndot = max(dot(n,sun), 0.0);
        vec3 refl = normalize(reflect(ray.d, n));
        vec3 samplesky = skyGenerate(time, refl);
        float foam = waveFoam(p, info);
        c = foam + ao * col * samplesky;
    }
    else
        c = skyGenerate(time, ray.d);
    // Output to screen
    glFragColor = vec4(c,1.0);
}
