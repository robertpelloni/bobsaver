#version 420

// original https://www.shadertoy.com/view/lfsSD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision highp float;
uniform sampler2D backbuffer;

float PI = acos(-1.);

vec3 foldX(vec3 p) {
    p.x = abs(p.x);
    return p;
}

mat2 rotate(float a) {
    float s = sin(a),c = cos(a);
    return mat2(c, s, -s, c);
}

float ball(vec3 p, float r){
  return length(p) - r;
}

float cylinder(vec3 p, float r, float h){
  float d1 = length(p.xy) - r;
  float d2 = abs(p.z) - h;
  
  float d = max(d1, d2);
  
  return d;
}

float cube(vec3 p, vec3 s){
  vec3 q = abs(p);
  vec3 m = max(s-q, 0.0);
  return length(max(q-s, 0.0))-min(min(m.x, m.y), m.z);
}

float dist(vec3 p){
  float scale = 1.6;
  float s = 1.0;
  float d = 999.0;
  
  for(int i=0;i<4;i++){
    float tscale = 0.5;
    p.yz *= rotate(time*tscale);
    p.xy *= rotate(time*tscale/s);
    
    p = abs(p);
    p -= 0.5/s;
    
    p *= scale;
    s *= scale;
    
    float d1 = cylinder(p, 0.03, 1.0);
    float d2 = cube(p, vec3(0.2));
    float d3 = ball(vec3(p.x, p.y, p.z - 1.), 0.15);
    float d5 = min(min(d1, d2), d3)/s;
  
    d = min(d, d5);
 
  }
  
  return d;
}

vec3 calcNormal(vec3 p) // for function f(p)
{
    float eps = 0.0001;
    vec2 h = vec2(eps,0);
    return normalize( vec3(dist(p+h.xyy) - dist(p-h.xyy),
                           dist(p+h.yxy) - dist(p-h.yxy),
                           dist(p+h.yyx) - dist(p-h.yyx) ) );
}

vec3 lighting(vec3 light_color, vec3 lightpos, vec3 pos, vec3 normal, vec3 rd){
  vec3 lightdir = normalize(lightpos - pos);
  float lambrt = max(dot(normal, lightdir), 0.0);
  vec3 half_vector = normalize(lightdir - rd);
  float m = 200.;
  float norm_factor   = ( m + 2. ) / ( 2.* PI );
  vec3 light_specular = light_color * norm_factor * pow( max( 0., dot( normal, half_vector ) ), m );

  return vec3(0.4,0.8,0.9)*lambrt*light_color + light_specular;
}

void main(void) {
  vec2 r=resolution.xy, p=(gl_FragCoord.xy*2.-r)/min(r.x,r.y);
  
  vec3 tar = vec3(0.0, 0.0, 0.0);
  float radius = 2.0;
  float theta = time * 0.5;
  
  vec3 cpos = vec3(radius*cos(theta), 0.5, radius*sin(theta)); //camera pos
  
  vec3 cdir = normalize(tar - cpos); //camera dir
  vec3 side = cross(cdir, vec3(0, 1, 0));
  vec3 up = cross(side, cdir);
  float fov = 1.5; // field of view
  
  vec3 screenpos = vec3(p, 4.0);
  
  vec3 rd = normalize(p.x*side + p.y*up + fov*cdir);
  
  float d = 0.0; //distance
  float t = 0.0; //total distance
  vec3 pos = cpos;
  
  for(int i=0;i<30;i++){
    d = dist(pos);
    t += d;
    pos = cpos + rd*t;
    if(d<0.0001 || t>10.0) break;
  }
  
  vec3 col = vec3(0.0);
  
  vec3 normal = calcNormal(pos);
  
  vec3 light_color = vec3(0.5, 1.0, 0.6);
  vec3 lightpos = vec3(1.0, 2.0, 0.0);
  col = lighting(light_color, lightpos, pos, normal, rd);
  
  light_color = vec3(0.5, 0.5, 1.0);
  lightpos = vec3(2.0, 1.0, 0.0);
  col += lighting(light_color, lightpos, pos, normal, rd);
  col = clamp(col, 0.0, 1.0);
  col = pow(col, vec3(1.4));
  
  if(t>10.0) col = vec3(0.0);

  glFragColor = vec4(col, 1.0);
  
}