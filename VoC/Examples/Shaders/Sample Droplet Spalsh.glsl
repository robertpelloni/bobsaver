#version 420

// original https://www.shadertoy.com/view/Ndl3R2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define  MAX_DIST 100.0
#define SURFACE_DIST 0.01

//rotate2D from the art of code youTube
mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

//smooth min from the art of code
float smin(float a, float b, float k) {
    
    float h = clamp(0.5 + 0.5*(b - a)/k, 0.0, 1.0);

    return mix( b, a, h ) - k*h*(1.0-h);
}

float random (in vec2 _uv) {
    return fract(sin(dot(_uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

//from iquilez.org - distance functions
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

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0.0, 1.0);
    
    vec3 c = a + t*ab;
    float d = length(p-c) - r;
    return d;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    
    vec3 c = a + t*ab;
    
    float x = length(p-c)-r;
    float y = (abs(t-0.5)-0.5)*length(ab); 
    float e = length(max(vec2(x, y), 0.0));
    float i = min(max(x, y), 0.0);

    return e + i;
}

float sdSphere(vec3 p, vec3 s, float r) {
    float d = length(p-s.xyz)-r;
    return d;
}

float sdTorus(vec3 p, vec2 r) {
    float x = length(p.xz) - r.x;
    float d = length(vec2(x, p.y)) - r.y;
    return d;
}

float GetDist(vec3 p){
    
    //hide main drop return
    float s0Active = 0.0;
    if (sign(sin(time)) == -1.0) {
        s0Active = 0.0;
    }
    else {
        s0Active = 1.0;
    }
    //main drop
    float sphere0Dist = sdSphere(p, vec3(0.0 + (100.0 - 100.0*s0Active), 6.0*(cos(time)), 6.0), 0.3*s0Active);
    
    //surface
    float planeDist = p.y - noise(p.xz)*.03*sin(time*2.) - noise(p.xz*2.)*.01*cos(time*2.); //noise modulation
    
    //splash drops
    float sphere1Dist = sdSphere(p, vec3(0.0, 2.22*sin(time - 1.8),6.0), 0.15*sin(time - 2.0));
    float sphere2Dist = sdSphere(p, vec3(0.0, 3.22*sin(time - 1.8),6.0), 0.25);
    
    //splash cone
    float coneDist = sdCone(p - vec3(0.0,2.0*sin(time - 1.8),6.0), vec2(0.2,1.0), 2.0);
    
    //ripples
    float t0DHeight = min(cos(time - 2.5)-1.0,0.0);
    float torus0Dist = sdTorus(p - vec3(0.0,t0DHeight,6.0), vec2(2.0*sin(time - 2.2),0.35*sin(time)));
    
    float t1DHeight = min(cos(time - 2.75)-1.0,0.0);
    float torus1Dist = sdTorus(p - vec3(0.0,t1DHeight,6.0), vec2(3.0*sin(time - 1.8),0.55*sin(time + 0.25)));
    
    float t2DHeight = min(cos(time - 4.75)-1.0,0.0);
    float torus2Dist = sdTorus(p - vec3(0.0,t2DHeight,6.0), vec2(2.0*sin(time - 4.75),0.35*sin(time - 4.75)));
    
    //combine!
    float boolUnion = smin(coneDist, planeDist, .5);
    boolUnion = smin(boolUnion, sphere1Dist, .75);
    boolUnion = smin(boolUnion, sphere2Dist, .2);
    boolUnion = smin(boolUnion, torus0Dist, .5);
    boolUnion = smin(boolUnion, torus1Dist, .5);
    boolUnion = smin(boolUnion, torus2Dist, .5);
    
    float d = smin(boolUnion, sphere0Dist, .2);
    
    //test:
    //d = min(torus2Dist, sphere0Dist);
    
    return d;
}

float RayMarch(vec3 ro, vec3 rd){
    float dO = 0.0;
    
    for (int i=0; i<MAX_STEPS; i++){
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if (dO>MAX_DIST || dS<SURFACE_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.01, 0.0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
        
    return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(3.0*sin(time*.1), 4.0, 3.0*cos(time*.1));
    vec3 l = normalize(lightPos - p);
    vec3 n = GetNormal(p); 
    
    float dif = dot(n, l);
    float d = RayMarch(p+n*SURFACE_DIST*2.0, l);
    if (d<length(lightPos-p)) dif *= 0.1;
    
    return dif;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0.0);
   
    //Camera
    //ray origin
    vec3 ro = vec3(0.0, 2.0, 0.0);
    //ray direction
    vec3 rd = normalize(vec3(uv.x,uv.y,1.0));
    
    float d = RayMarch(ro, rd);
    
    vec3 p = ro + rd * d;
    
    float dif = GetLight(p);
    
    vec3 diffuse = vec3(0.0);
    if (d<MAX_DIST) {
        diffuse = vec3(0.5,0.75,0.9);
        col = vec3(dif) * diffuse + GetNormal(p).zxy*.1; //a little hacky shading with normals
    }
    else {
        diffuse = vec3(0.5,0.75,1.0)/3.;
        col = diffuse;
    }
    
    glFragColor = vec4(col,1.0);
}
