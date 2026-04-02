#version 420

// original https://www.shadertoy.com/view/ssffRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ***********************************************************************************
// ***********************************************************************************
// *********************************** RANDOM **********************************
// ***********************************************************************************
// ***********************************************************************************

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float random (vec3 st) {
    return fract(sin(dot(st.xyz,
                         vec3(12.9898,78.233, 15.234)))*
        43758.5453123);
}

// ***********************************************************************************
// ***********************************************************************************
// *********************************** PERLIN NOISE **********************************
// ***********************************************************************************
// ***********************************************************************************

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}
float cnoise(vec3 P){
  vec3 Pi0 = floor(P); // Integer part for indexing
  vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
  Pi0 = mod(Pi0, 289.0);
  Pi1 = mod(Pi1, 289.0);
  vec3 Pf0 = fract(P); // Fractional part for interpolation
  vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  vec4 iy = vec4(Pi0.yy, Pi1.yy);
  vec4 iz0 = Pi0.zzzz;
  vec4 iz1 = Pi1.zzzz;

  vec4 ixy = permute(permute(ix) + iy);
  vec4 ixy0 = permute(ixy + iz0);
  vec4 ixy1 = permute(ixy + iz1);

  vec4 gx0 = ixy0 / 7.0;
  vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
  gx0 = fract(gx0);
  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
  vec4 sz0 = step(gz0, vec4(0.0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  vec4 gx1 = ixy1 / 7.0;
  vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
  gx1 = fract(gx1);
  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
  vec4 sz1 = step(gz1, vec4(0.0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
  vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
  vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
  vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
  vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
  vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
  vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
  vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  float n000 = dot(g000, Pf0);
  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
  float n111 = dot(g111, Pf1);

  vec3 fade_xyz = fade(Pf0);
  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x); 
  return 2.2 * n_xyz;
}

vec3 rotateVector(vec3 p, float q, float q2) {
    p = vec3(p.x*cos(q) - p.y*sin(q), p.x*sin(q) + p.y*cos(q), p.z);
    p = vec3(p.x*cos(q2)+p.z*sin(q2), p.y, -p.x*sin(q2)+p.z*cos(q2));
    return p;
}

float sdSphere(vec3 p, float s, vec3 pos)
{
    p -= pos;
    return length(p)-s;
}

float map(vec3 p) {
    float d = sdSphere(mod(p, 1.), .15, vec3(0.5, 0.5+sin(floor(p.z/1.)+floor(p.x/1.)+time*10.)*.05, 0.5));
    return d;
}

vec3 calcNormal(vec3 p) {
    float eps = 0.01;
    return normalize(vec3(
        map(p + vec3(eps, 0, 0)) - map(p + vec3(-eps, 0, 0)),
        map(p + vec3(0, eps, 0)) - map(p + vec3(0, -eps, 0)),
        map(p + vec3(0, 0, eps)) - map(p + vec3(0, 0, -eps))
        ));
}

void main(void)
{
    
    vec3 point_light_pos = vec3(1., 1., 1.);

    vec3 cam_pos = vec3(time*2., time, time*5.);
    vec3 ray_dir = normalize(vec3(gl_FragCoord.xy.x/resolution.y-resolution.x/resolution.y/2., gl_FragCoord.xy.y/resolution.y-1./2., 1.));
    ray_dir = rotateVector(ray_dir, sin(time)*.5, sin(time*.35)*.5);
    
    float closest_distance = 10000.;
    bool hit = false;
    vec3 hit_pos = cam_pos;
    float t = 0.;
    for (int i = 0; i < 60; i += 1) {
        t = map(hit_pos);
        hit_pos += ray_dir*t;
        if (t < .001) {
            hit = true;
            break;
        }
        closest_distance = min(t, closest_distance);
    }
    
    float light_power = (dot(calcNormal(hit_pos), normalize(point_light_pos-hit_pos))+1.)/2.;
    
    float depth = distance(hit_pos, cam_pos);
    
    float vignette = (1.-abs(gl_FragCoord.xy.x-resolution.x/2.)/resolution.x)*(1.-abs(gl_FragCoord.xy.y-resolution.y/2.)/resolution.y);
    
    if (hit) {
        glFragColor = smoothstep(1., vignette/40., depth/10.)*vignette*vec4(random(floor(hit_pos/1.)), random(floor(hit_pos/1.)+vec3(1., 1., 1.)), random(floor(hit_pos/1.)+vec3(5., 5., 5.)), 1.);
    } else {
        glFragColor = vignette/40.*vec4(1.);
    }
    
}
