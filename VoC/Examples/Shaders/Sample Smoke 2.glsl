#version 420

// original https://neort.io/art/bpmh8a43p9fbkbq845p0

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI =  3.141592;

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 6
float fbm (in vec2 st) {
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

vec2 rot(vec2 p,float r){
  mat2 m = mat2(cos(r),sin(r),-sin(r),cos(r));
  return m*p;
}

vec2 pmod(vec2 p,float r){
  float a = atan(p.y,p.x)+PI/r;
  float n = 2.*PI/r;
  a = floor(a/n)*n;

  return rot(p,-a);
}

  float cube (vec3 p,vec3 s){
    vec3 q = abs(p);
    vec3 m = max(s-q,0.);
    return length(max(q-s,0.0))-min(min(m.x,m.y),m.z);
  }

  float dist(vec3 p){
    p.z += 5.6;
    p.xz = rot(p.xz,-time+p.y*0.5+0.1*fbm(p.yy));
    p.y -= time*5.;
    float k = 3.8;
    //p.xz += noise(floor(p.xz*k));
    p.xz = abs(p.xz)-0.9;
    p.y = mod(p.y,k)-0.5*k;
    float d1 = cube(p,vec3(1.9,1.4,0.7));
    return d1- 2.0*fbm(p.xz+p.yy-time-0.1*time);
  }

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
  uv = 2.0*(uv -0.5);
  uv.y = uv.y*resolution.y/resolution.x;

  vec2 p = uv;
float kt =time*2.0;
    float r = 1.1;
    vec3 ro = vec3(sin(kt)*r,cos(kt)*r,5.0);
    vec3 ta =vec3(0.0,-1.,0.);
    
    vec3 cdir = normalize(ta-ro);
    vec3 up = vec3(0.,1.,0.);
    vec3 side  = cross(cdir,up);
    up = cross(side,cdir);
    float fov =1.1;
    vec3 rd = normalize(p.x*side+p.y*up+cdir*fov);
    

  float t = 5.0;
  float d;
  float a = 0.0;
  for(int i =0 ;i<69;i ++){
    d = dist(ro+rd*t);
    d = max(d,0.2);
    a += 0.01*exp(-d)*2.;
   
    t+=d;
  }
  vec3 col = vec3(0.);
  col = vec3(a);
    glFragColor = vec4(col,1.0);
}
