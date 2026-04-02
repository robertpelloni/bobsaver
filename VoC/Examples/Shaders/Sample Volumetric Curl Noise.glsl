#version 420

// original https://www.shadertoy.com/view/ttSczc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define minDist 0.001
#define maxDist 5.
#define surfaceRefraction 0.9
#define curlStepRefraction 0.9

#define curlFreq 1.

vec2 mouse2;

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

uniform vec4 bgColor;
in vec2 uv;

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

void transformSpace(inout vec3 pos) {
    pR(pos.xz, -time*0.5);
    pR(pos.xy, sin(time*0.5)*0.5);    
}

float map(in vec3 pos) {
    transformSpace(pos);

    float dist = sdBox(pos, vec3(0.25));
    return dist;
}

vec3 curl(vec3 pos) {
    vec3 eps = vec3(1., 0., 0.);
    vec3 res = vec3(0.);

    float yxy1 = snoise(pos + eps.yxy);
    float yxy2 = snoise(pos - eps.yxy);
    float a = (yxy1 - yxy2) / (2. * eps.x);

    float yyx1 = snoise(pos + eps.yyx);
    float yyx2 = snoise(pos - eps.yyx);
    float b = (yyx1 - yyx2) / (2. * eps.x);

    res.x = a - b;

    a = (yyx1 - yyx2) / (2. * eps.x);

    float xyy1 = snoise(pos + eps.xyy);
    float xyy2 = snoise(pos - eps.xyy);
    b = (xyy1 - xyy2) / (2. * eps.x);

    res.y = a - b;

    a = (xyy1 - xyy2) / (2. * eps.x);
    b = (yxy1 - yxy2) / (2. * eps.x);

    res.z = a - b;

    return res;
}

float march(in vec3 camPos, in vec3 rayDir) {

    float dist = minDist;

    for (int i = 0; i < 25; i++) {
        vec3 p = camPos + rayDir * dist;
        float res = map(p);
        if (res <= minDist) break;
        dist += res;
        if (dist >= maxDist) break;
    }

    return dist;
}

vec3 volumeMarch(in vec3 pos, in vec3 rayDir) {

    transformSpace(pos);

    const int numSteps = 10;
    float dist = minDist;
    float stepSize = 0.05;
    
    vec3 col = vec3(0.);
    float freq = 4. + (mouse2.x-0.5) * curlFreq;
    
    for (int i = 0; i < numSteps; i++) {
        vec3 p = pos + rayDir * dist;
        float res = map(p);
        dist += stepSize;
        
        // the curl noise function animated wrt the current color and time
        vec3 c = curl(p*freq + sin(col+time)*0.1);
        
        // refract the ray dir with the current noise sample
        rayDir = refract(rayDir, c, curlStepRefraction);
        
        // accumulate the color
        col += c;
    }
    //col = texture(gradientTex, vec2(mod(length(col)*2. + _Time/6.28318, 1.), 0.)).rgb;
    return col;
}

vec3 calcNormal(in vec3 pos) {
    vec3 eps = vec3(0.001, 0.0, 0.0);
    return normalize(vec3(map(pos + eps) - map(pos - eps),
                     map(pos + eps.yxz) - map(pos - eps.yxz),
                     map(pos + eps.yzx) - map(pos - eps.yzx)));
}

vec4 render(in vec3 camPos, in vec3 rayDir) {

    float dist = march(camPos, rayDir);
    vec3 fPos = camPos + rayDir * dist;
    vec3 nor = calcNormal(fPos);
    rayDir = refract(rayDir, nor, surfaceRefraction);
    vec3 col = volumeMarch(fPos, rayDir) * (-.25-dot(rayDir, nor));

    col = pow(col, vec3(1.25));
    col = mix(col, bgColor.rgb, clamp(dist/maxDist, 0.0, 1.0));
    return vec4(col, dist);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    mouse2 = mouse.xy*resolution.xy.xy / resolution.xy;
    vec4 color = vec4(0.);
    vec2 uv_c = uv * 2. - 1. ;
    uv_c.x *= resolution.x/resolution.y;
    vec3 ray = normalize (vec3(1., 0., 0.) * uv_c.x +
                          vec3(0., 1., 0.) * uv_c.y +
                          vec3(0., 0., 1.) * 2.5);

    vec3 camPos = vec3(0., 0., -1.);
    
    color += vec4(render(camPos, ray));

    glFragColor = color;
}
