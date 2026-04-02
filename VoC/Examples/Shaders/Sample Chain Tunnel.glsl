#version 420

// original https://neort.io/art/bqv7hc43p9f48fkitsb0

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = acos(-1.0);
const float pi2 = pi*2.;
const float angle = 120.0;
const float fov = angle * 0.5 * pi / 180.0;

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

mat2 rot (float a){
  float c = cos(a),s = sin(a);
  return mat2(c,s,-s,c);
}

//https://www.shadertoy.com/view/WlsXWM
float sdLink( in vec3 p, in float le, in float r1, in float r2 ){
    vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
    return length(vec2(length(q.xy)-r1,q.z)) - r2;
  }
float chain(vec3 p ){
  float sc=8.;  p*=sc;
  float le = 0.13, r = 0.2, rr = 0.09;
  vec3 q = p;
  q.y = fract(q.y)-0.5;
  vec3 z = p;
  z.y = fract(z.y+0.5)-0.5;
  float d = min(sdLink(q.xyz,le,r,rr),
             sdLink(z.zyx,le,r,rr))/sc;
             return d;
}

float dist(vec3 p){
  vec3 q = p;
    p.xy *= rot(p.z+0.01);
    p.y =abs(p.y)- 0.5;
    q = mod(q,3.0)-1.5;
    float d = length(q)-0.15;
    for(int i = 0;i<4;i++){
      p.xy = abs(p.xy)-0.3;
        
        
      float d1 = chain(p.xzy);
        d = min(d,d1);
    }
      return d;
}

vec3 getNormal(vec3 p){
    float d = 0.0001;
    return normalize(vec3(
        dist(p + vec3(  d, 0.0, 0.0)) - dist(p + vec3( -d, 0.0, 0.0)),
        dist(p + vec3(0.0,   d, 0.0)) - dist(p + vec3(0.0,  -d, 0.0)),
        dist(p + vec3(0.0, 0.0,   d)) - dist(p + vec3(0.0, 0.0,  -d))
    ));
}

vec3 hsv(vec3 rgb){
  return ((clamp(abs(fract(rgb.x+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*rgb.y+1.)*rgb.z;
}

void main (void){
    vec2 p = (gl_FragCoord.xy * 2. -resolution) /min(resolution.x, resolution.y);
    vec3 ca = vec3(cos(-time)*0.2,  sin(-time)*0.2,  -time);
  vec3 cDir = vec3(0.0,  0.0, -1.0);
  vec3 cUp  = vec3(0.0,  1.0,  0.0);
  vec3 cSide = cross(cDir, cUp);
  float targetDepth = 1.0;
  float al = 1.0;
    vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));
    vec3 ld = vec3(5.0,-5.477,5.0);
    float depth = 0.0;
    vec3 col1 = vec3 (0.0);
    float ac = 0.0;
    vec3 rp = vec3(0.0);
    float aa = 0.0;
    for(int i = 0; i < 50; i++){
      rp = ca+ray*depth;
      float d = dist(rp);
      if(abs(d)<0.001){
        vec3 no = getNormal(rp);
        float diff = clamp(dot(ld, rp),0.1,1.0);
        col1 = (vec3(1.0)*diff)/(aa/50.);
        col1 *= hsv(normalize(col1));
        break;
      }
        ac += pow(exp(-d*5.),15.0);
        aa += 1.;
      depth += d;
  }
    glFragColor = vec4(col1,1.0);

}
