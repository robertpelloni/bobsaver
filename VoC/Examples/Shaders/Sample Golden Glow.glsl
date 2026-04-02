#version 420

// original https://www.shadertoy.com/view/mlfczB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define THRESHOLD 0.02
#define MAX_DISTANCE 8.0

#define RAY_STEPS 30

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+10.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float noise(vec3 v)
  { 
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

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
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
  vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
  }

/*
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = ((p.xy+vec2(37.0,17.0)*p.z) + f.xy);
    vec2 rg = textureLod( iChannel0, (uv + 0.5)/256.0, 0.0).yx;
    return mix( rg.x, rg.y, f.z );
}
*/

float map(in vec3 p, in float t)
{
    vec3 q = p + 0.1*vec3(0.2, -2.0, 2.2)*-t;
    float f;
    f = 0.500*noise( q ); q = q*2.0;
    f += 0.295*noise( q ); q = q*2.0;
    f += 0.205*noise( q ); q = q*2.0;
    //f += 0.0625*noise( q ); q = q*2.0;
    //f += 0.03125*noise( q ); q = q*2.0;
    //f += 0.015625*noise( q );
    return 0.5+0.5*f;
}

// camera rotation
mat3 rotationXY( vec2 angle ) {
    // pitch
    float cp = cos( angle.x );
    float sp = sin( angle.x );
    // yaw
    float cy = cos( angle.y );
    float sy = sin( angle.y );

    return mat3(
        cy     , 0.0, -sy,
        sy * sp,  cp,  cy * sp,
        sy * cp, -sp,  cy * cp
    );
}

float scene(vec3 p)
{
    mat3 mp = rotationXY(vec2(-0.15, 0.25*3.14159)) * rotationXY(vec2(3.14159*0.25-0.8, 0.0));
    float c = length(max(abs(mp*p*mat3(1.2, 0.1, -0.2, 0.1, 0.7, -0.2, 0.1, 0.1, -0.9) - (-0.4)*-1.*vec3(0.5, .05, 1.15)) - vec3(1.35), 0.0)) - 0.05;
    float b = min(length(p-vec3(-2.5, -0.8+0.2*sin(3.0*time), 0.5))-(1.2+0.*cos(time)), (map(p*0.2, time*1.1)*-.35+.9+1.0*p.y));
    return min(c, b);
}

vec3 normal(vec3 p, float d)
{
    mat3 mp = rotationXY(vec2(-0.15, 0.25*3.14159)) * rotationXY(vec2(3.14159*0.25-0.8, 0.0));
    float c = length(max(abs(mp*p*mat3(1.2, 0.1, -0.2, 0.1, 0.5, -0.2, 0.1, 0.1, -0.9) - (-0.4)*-1.*vec3(0.5, .05, 1.15)) - vec3(1.35), 0.0)) - 0.05;
    float e = 0.05;
    float dx = scene(vec3(e, 0.0, 0.0) + p) - d;
    float dy = scene(vec3(0.0, e, 0.0) + p) - d;
    float dz = scene(vec3(0.0, 0.0, e) + p) - d;
    vec3 n = vec3(0.0);
    if (c < 0.1) {
        vec3 v = mp*p*mat3(1.2, 0.1, -0.2, 0.1, 0.5, -0.2, 0.1, 0.1, -0.9);
        if ((int(fract(v.z*v.x*1.0) > 0.5) ^ int(fract(v.y*2.) > 0.5)) == 0) {
           p *= 4.0;
           n = 0.002*vec3(noise(p), noise(p + vec3(1.0, 0.0, 0.0)), noise(p + vec3(0.0, 1.0, 0.0)));
        }
    }
    return normalize(vec3(dx, dy, dz) + n);
}

vec3 shadeBg(vec3 nml, int bounces)
{
    vec2 aspect = vec2(resolution.x/resolution.y, 1.0);
    vec2 uv = (2.0 * gl_FragCoord.xy / resolution.xy - 1.0) * aspect;
    vec3 bgLight = normalize(vec3(
        0.0, // cos(time*0.2/0.954929658551372)*4.0, 
        0.0, // sin(time/1.1936620731892151)*3.0 - 4.0, 
        -1.0 // sin(time*0.2/0.954929658551372)*8.0
    ));
    vec3 sun = vec3(2.0, 1.8, 0.85);
    float bgDiff = dot(nml, vec3(0.0, -1.0, 0.0));
    float sunPow = dot(nml, bgLight);
    float sp = max(sunPow, 0.0);
    vec3 bgCol = max(0.0, bgDiff)*2.0*vec3(0.6, 0.7, 0.70);
    bgCol += max(0.0, -bgDiff)*vec3(0.4, 0.55, 0.37);
    bgCol += vec3(0.7, 0.5, 0.27)*((0.5*pow(1.0-abs(bgDiff), 5.0)*(5.0-dot(uv,uv))));
    bgCol += sun*(0.5*pow( sp, 4.0)+pow( sp, 256.0));
    bgCol += vec3(0.5, 0.2, 0.15)*(pow( sp, 32.0) + pow( sp, abs(bgLight.y)*128.0));
    bgCol += vec3(1.3,1.1,0.9) * ((1.0-pow(abs(bgDiff), 0.6)) * 1.0); // * map(-nml) * map(-nml*nml.y));
    float f = 0.0; //sin(time+atan(nml.y, nml.x) * 20.0)*sin(-time+atan(nml.z*nml.y, nml.x) * 20.0) > 0.0 ? 1.0 : 0.0;
    if (bounces > 0) {
      bgCol *= max(0.62, f+pow(0.95*sin(0.5*time+45.0*dot(nml, vec3(-0.3, 0.0, 1.0))*max(0.0, bgDiff)), 4.0));
    } else {
      bgCol *= 0.72;
    }
    bgCol *= (1.0+(nml.y))*0.6+0.5*map(4.0*nml.yzy*(bgDiff), time * 1.1)*(1.0-max(0.0, bgDiff));
    return pow(max(vec3(0.0), bgCol), vec3(1.9));
}

void main(void)
{
    vec2 aspect = vec2(resolution.x/resolution.y, 1.0);
    if (resolution.x < resolution.y) {
        aspect = vec2(1.0, resolution.y / resolution.x);
    }
    vec2 uv = (2.0 * gl_FragCoord.xy / resolution.xy - 1.0) * aspect;
    vec3 d = normalize(vec3(uv, 1.0));
    vec3 p = vec3(uv*-2.0, -6.5) + d*3.6;
    vec3 o = vec3(1.0);
    int bounces = 0;
    for (int i=0; i<RAY_STEPS; i++) {
        float dist = scene(p);
        if (dist < THRESHOLD) {
            bounces++;
            vec3 nml = normal(p, dist);
            mat3 mp = rotationXY(vec2(-0.15, 0.25*3.14159)) * rotationXY(vec2(3.14159*0.25-0.8, 0.0));
            float c = length(max(abs(mp*p*mat3(1.2, 0.1, -0.2, 0.1, 0.5, -0.2, 0.1, 0.1, -0.9) - (-0.4)*-1.*vec3(0.5, .05, 1.15)) - vec3(1.35), 0.0)) - 0.1;
            if (c < 0.1) {
                vec3 v = mp*p*mat3(1.2, 0.1, -0.2, 0.1, 0.5, -0.2, 0.1, 0.1, -0.9);
                if ((int(fract(v.z*v.x*1.0) > 0.5) ^ int(fract(v.y*2.) > 0.5)) == 0) {
                  o *= vec3(0.3);
                }
            }
            d = reflect(d, nml);
            p += (23.0*THRESHOLD) * d;
        }
        if (dist > MAX_DISTANCE) {
            break; 
        }
        p += dist * d;
    }
    glFragColor = vec4( 1.0 - exp(-1.0 * o * shadeBg(-d, bounces)), 1.0 );
}