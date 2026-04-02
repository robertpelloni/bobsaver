#version 420

// original https://www.shadertoy.com/view/3tcBWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LIGHTSTEP 20.0
#define CHEEKRADIUS 0.3
#define TRANSLUCENT 1
#define OPAQUE 0
#define AMBIENTCOLOR vec3(0.1, 0.2, 0.4)

//    Simplex 3D Noise 
//    by Ian McEwan, Ashima Arts
//
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

float hash13(vec3 p3) 
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void rotX(inout vec3 z, float s, float c) 
{
   z.yz = vec2(c*z.y + s*z.z, c*z.z - s*z.y);
}

void rotY(inout vec3 z, float s, float c) 
{
   z.xz = vec2(c*z.x - s*z.z, c*z.z + s*z.x);
}

void rotZ(inout vec3 z, float s, float c) 
{
   z.xy = vec2(c*z.x + s*z.y, c*z.y - s*z.x);
}

void rotX(inout vec3 z, float a) 
{
   rotX(z, sin(a), cos(a));
}
void rotY(inout vec3 z, float a) 
{
   rotY(z, sin(a), cos(a));
}

void rotZ(inout vec3 z, float a) 
{
   rotZ(z, sin(a), cos(a));
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float sdRoundBox( vec3 p, vec3 b, float r ) 
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdRoundCone( vec3 p, float r1, float r2, float h )
{
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

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

float sdEllipsoid( vec3 p, vec3 r )
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

float sdTriPrism( vec3 p, vec2 h )
{
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float opSmoothUnion( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

float opSmoothSubtraction( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

float opSmoothIntersection( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); 
}
    
float opUnion( float d1, float d2 ) { return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float body(in vec3 z)
{    
    float d1 = 1e+8;
    z.y += 0.57;
    
    vec3 armPos = z;
    armPos.x = abs(armPos.x);
    armPos.x -= 0.35;
    rotX(armPos, -0.3 * z.y);
    rotZ(armPos, 0.7 * z.y + 0.2);
    float arm = sdEllipsoid(armPos, vec3(0.08, 0.5, 0.15));
    d1 = opSmoothUnion(d1, arm, 0.1);
        
    float torso = sdRoundCone(z - vec3(0.0, -0.1, 0.0), 0.34, 0.2, 0.5);
    d1 = opUnion(d1, torso);
    z.y -= 0.3;
    float box = sdBox(z, vec3(0.5, 0.2, 0.5));
    float d2 = opSmoothUnion(arm, torso, 0.05);
    
    return opUnion(d1, d2);
}

float head(vec3 z)
{
    z.y *= 1.32;
    z.y -= 0.56;
    return sdRoundCone(z, 0.68, 0.59, 0.12) - 0.1;
}

float cheek(vec3 z)
{
    z.x = abs(z.x);
    z += vec3(-0.5, -0.27, 0.48);
    float eyeballs = sdSphere(z, CHEEKRADIUS);
    return eyeballs;
}

float horn(vec3 z)
{
    rotX(z, 0.1);
    rotZ(z, 0.4);
    float horn = sdCone(z - vec3(0.0, 1.32, 0.0), vec2(0.3, 0.7), 0.6);
    return horn;
}

float eyelids(vec3 z)
{
    z.x = abs(z.x);
    z.yz += vec2(-0.5, 0.58);
    z.x += z.y * 0.05 - 0.15;
    float d = sdSphere(z, 0.217);
    z.y += 0.24;
    float box = sdBox(z, vec3(0.3));
    return opSubtraction(box, d);
}

float eyes(vec3 z)
{
    z.x = abs(z.x);
    z.xyz += vec3(-0.15, -0.5, 0.58);
    z.x += z.y * 0.05;
    float eyeballs = sdSphere(z, 0.2);
    return eyeballs;
}

float pupils(vec3 z)
{
    z.x = abs(z.x);
    z.yz += vec2(-0.53, 0.76);
    z.x += z.y * 0.05 - 0.15;
    z.z *= 1.6;
    float pupils = sdSphere(z, 0.055);
    return pupils;
}

float highlights(vec3 z)
{
    z.x = abs(z.x - 0.02);
    z.y -= 0.53;
    z.xz += vec2(z.y * 0.05 - 0.15, 0.78);
    float eyeballs = sdSphere(z, 0.005);
    return eyeballs;
}

float eyebrows(vec3 z)
{
    z.yz += (-0.07, -0.04) * (sign(z.x) + 1.0) * 0.5;
    z.x = abs(z.x);
    rotZ(z, -z.x * 0.5);
    rotY(z, -z.x);
    z += vec3(-0.06, sin((z.x-0.06) * 50.0) * 0.05 - 0.77, 0.65);
    return sdBox(z, vec3(.04,1.2*(0.023-smoothstep(-0.01, 0.12, z.x*0.1)),.01));
}

float mouth(vec3 z)
{
    z.yz += vec2(1.3, -0.24);
    rotZ(z, z.x * 0.5 + 0.1);
    float shape = sdBox(z, vec3(0.27,0.001,0.7));
    return shape;
}

float mouthColor(vec3 z){
    z.yz += vec2(-0.24, 1.3);
    rotZ(z, z.x * 0.5 + 0.1);
    float shape = sdBox(z, vec3(0.4,0.05,0.9));
    return shape;
}

float teeth(vec3 z){
    z.yz += vec2(-0.21, 0.72);
    rotY(z, -z.x * 0.8);
    rotZ(z, z.x * 3.0 + 0.06);
    return sdRoundBox(z, vec3(0.1,0.04,0.002), 0.02);
}

vec3 getColor(float d){
    vec3 c1 = vec3(0.5, 0.99, 0.65);
    vec3 c2 = vec3(0, 0, 2);
    float a = smoothstep(0.0, 0.3, d);
    return mix(c1, c2, a);
}

void setColor(inout int material, in vec3 z, inout vec3 color)
{
    float dist = 1e+8;
    vec3 headColor = vec3(0.5, 0.99, 0.65);
    vec3 cheekColor = vec3(0.8, 0.6, 0.4);
    float body = body(z);
    if(dist > body)
    {
        material = 1;
        color = headColor;
        dist = body;
    }
    float cheek = cheek(z);
    if(dist > cheek)
    {
        material = 1;
        color = vec3(mix(headColor, cheekColor, smoothstep(CHEEKRADIUS*0.005, CHEEKRADIUS, -cheek * 1.2) ));
        dist = cheek;
    }    
    float head = head(z);
    float teeth = teeth(z);
    if(dist > head)
    {
        material = 1;
        color = headColor;
        dist = head;
    }
    float horn = horn(z);
    if(dist > horn)
    {
        material = 1;
        color = headColor;
        dist = horn;
    }
    float eyes = eyes(z);
    if(dist > eyes)
    {
        material = 0;
        color = vec3(1.0, 1.0, 0.8);
        dist = eyes;
    }
    float eyelids = eyelids(z);
    if(dist > eyelids)
    {
        material = 0;
        color = vec3(173.0, 215.0, 228.0)/255.0;
        dist = eyelids;
    }
    float eyebrows = eyebrows(z);
    if(dist > eyebrows)
    {
        material = 0;
        color = vec3(0.2, 0.1, 0.2);
        dist = eyebrows;
    }
    float pupils = pupils(z);
    if(dist > pupils)
    {
        material = 0;
        float highlights = highlights(z);
        if(dist > highlights)
        {
            color = vec3(1.0);
        }
        else
        {
            color = vec3(0.2, 0.1, 0.2);
        }
        dist = pupils;
    }

    float mouthColor = mouthColor(z);
    if(dist > mouthColor)
    {
        if(dist > teeth)
        {
            color = vec3(1.0);
            material = 0;
        }
        else
        {
            color = vec3(mix(headColor, headColor * 0.05, smoothstep(0.0, 0.1, -mouthColor) ));
            material = 1;
        }
        dist = mouthColor;
    }
    if(dist > teeth)
    {
        material = 0;
        color = vec3(218.0, 237.0, 236.0)/255.0;
        dist = teeth;
    }
}

float DE(in vec3 z)
{
    vec3 color = vec3(0.0);
    float d = body(z);
    
    float head = head(z);
    d = opSmoothUnion(d, head, 0.16);
    float horn = horn(z);
    d = opSmoothUnion(d, horn, 0.2);
    float eyes = eyes(z);
    d = opUnion(d, eyes);
    float eyelids = eyelids(z);
    d = opUnion(d, eyelids);
    float eyebrows = eyebrows(z);
    d = opUnion(d, eyebrows);
    float pupils = pupils(z);
    d = opUnion(d, pupils);
    float mouth = mouth(z);
    d = opSmoothSubtraction(mouth, d, 0.05);
    float teeth = teeth(z);
    d = opUnion(teeth, d);
    return d;
}

vec3 getNormal(vec3 p)
{
    vec2 ep = vec2(1e-4, 0);
    return normalize(vec3(
        DE(p + ep.xyy) - DE(p - ep.xyy),
        DE(p + ep.yxy) - DE(p - ep.yxy),
        DE(p + ep.yyx) - DE(p - ep.yyx)
        ));
}

vec3 scatteringCoeff = vec3(0.9, 0.4, 0.08);

float getDensity(vec3 rayPos)
{
    return clamp(-DE(rayPos) * 20.0, 0.0, 1.0) * smoothstep(1.6, -1.0, rayPos.y) * 3.0;
}

vec3 lightFunc(vec3 rayPos, vec3 lightDir, float lightLength)
{
    vec3 lightRayPos = rayPos;
    float div = lightLength/LIGHTSTEP;
    
    vec3 col = vec3(1.0);
    for(float s = 0.0; s < lightLength; s+=div)
    {
        lightRayPos += lightDir * div;
        float density = getDensity(lightRayPos);
        col *= exp(-density * div * scatteringCoeff * 12.0);
    }
    return col;
}

float HenyeyGreenstein( float sundotrd, float g) 
{
   float gg = g * g;
   return (1. - gg) / pow( 1. + gg - 2. * g * sundotrd, 1.5);
}

// Little tweak of Himalayas, Created by Reinder Nijhoff 2018
// https://www.shadertoy.com/view/MdGfzh
void marchVolume(inout vec3 col, vec3 rayPos, vec3 rayDir, vec3 cameraPos, vec3 lightPos, inout float T)
{
    float deltaStep = 0.007;
    vec3 volumeCol = vec3(0.0);
    vec3 transmittance = vec3(1.0);
    for(int i = 0; i < 40; i++)
    {
        rayPos += rayDir * deltaStep;
        float density = getDensity(rayPos);
        if(density == 0.0)
        {
            break;
        }
        
        vec3 lightDir = lightPos - rayPos;
        float lightLength = length(lightPos - rayPos);
        lightDir = normalize(lightDir);
        
        float sundotrd = dot(rayDir, -lightDir);
                
        float scattering =  mix( HenyeyGreenstein(sundotrd, 0.5),
                                HenyeyGreenstein(sundotrd, -0.2), 0.5 );
        vec3 S = 0.8 * density * (AMBIENTCOLOR + scattering * lightFunc(rayPos, lightDir, lightLength)) * scatteringCoeff;
        vec3 sampleExtinction = max(vec3(1e-4), density * scatteringCoeff);
        vec3 dTrans = exp(-sampleExtinction * deltaStep * 1e+2);
        vec3 Sint = (S - S * dTrans) / sampleExtinction;
        volumeCol += transmittance * Sint; 
        transmittance *= dTrans;
    }
    col *= abs(volumeCol);
    T = transmittance.z;
}

void marchSDF(inout int material, inout vec3 surfaceCol, inout vec3 rayPos, vec3 rayDir, vec3 cameraPos, vec3 lightPos, inout float T){
    float trvlDist = 0.0;
    for(int i = 0; i < 32; i++){
        float dist = DE(rayPos);
        if(dist < 1e-3){
            rayPos += rayDir * 1e-4;
            vec3 lightDir = normalize(lightPos - rayPos);
            vec3 N = getNormal(rayPos);
            float ldotn = (dot(lightDir, N) + 1.0) * 0.5;
            setColor(material, rayPos, surfaceCol);
            if(material == 0){
                T = 0.0;
                surfaceCol *= ldotn * ldotn + AMBIENTCOLOR;
            }
            return;
        }
        trvlDist += dist;
        rayPos = cameraPos + rayDir * trvlDist;
    }
}

//background cloud from patu
//https://www.shadertoy.com/view/4tVXRV
vec3 clouds(vec3 rd) {
    vec3 c1 = vec3(0.2, 0.4, 1.0);
    vec3 c2 = vec3(0.9, 0.2, 0.86);
    float newTime = time * 0.5;
    vec2 uv = rd.xz / (rd.y + 0.6);
    uv.x *= 0.2;
    float noise = 
        snoise(
            vec3(uv.yx * 1.4 + vec2(newTime, 0.), newTime) 
        );
    
    float a = smoothstep(0.0, 1.0, noise);
    return mix(c1, c2, a);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy/resolution.xy - 0.5) * 2.0;
    uv.x *= resolution.x/resolution.y;
    
    float mousePosition = 3.0;//(mouse.x*resolution.x/resolution.x - 0.5) * 2.0 * 3.0;

    vec3 cameraPos = vec3(sin(mousePosition), 0.1, cos(mousePosition)) * 5.0;
    vec3 cameraFront = normalize(-cameraPos);
    vec3 cameraRight = cross(vec3(0.0, 1.0, 0.0), cameraFront);
    vec3 cameraUp = cross(cameraFront, cameraRight);
    
    vec3 rayDir = normalize(cameraFront * 3.0 + cameraRight * uv.x + cameraUp * uv.y);
    vec3 rayPos = cameraPos;

    float newTime = time * 1.2;
    vec3 lightPos = vec3(sin(newTime), cos(newTime * 1.2), cos(newTime * 0.5));
    
    vec3 surfaceCol = vec3(0.0);
    vec3 backgroundCol = clouds(rayDir);
    int material = 0;
    
    float T = 1.0;
    marchSDF(material, surfaceCol, rayPos, rayDir, cameraPos, lightPos, T);
    if (material == TRANSLUCENT){
        marchVolume(surfaceCol, rayPos, rayDir, rayPos, lightPos, T);
    }
    
    vec3 finalCol = mix(surfaceCol, backgroundCol, T);
    
    glFragColor = vec4(pow(finalCol, vec3(1.0/2.2)), 1.0);
}
