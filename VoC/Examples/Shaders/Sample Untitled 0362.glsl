#version 420

uniform float time;
uniform vec2  mouse;
uniform vec2  resolution;

out vec4 glFragColor;

const float PI = 3.1415926535897932384626433832795;
const float PI_2 = 1.57079632679489661923;
const float PI_4 = 0.785398163397448309616;

vec4  b  = vec4(0.0, 0.0, 0.0, 1.0);
vec4  c1 = vec4(1.0,1.0,1.0,1.0);
vec4  c2 = vec4(1.0,0.0,1.0,1.0);
vec4  c3 = vec4(0.0,1.0,1.0,1.0);
vec4  c4 = vec4(1.0,0.0,0.0,1.0);
vec4  bx = vec4(-0.5, -0.5, 0.7, 0.7);
vec2  ps = vec2(0.);

const int n = 4;

vec4  ac[n];
vec4  ab[n];
vec2  ap[n];
float pp[n];
float at[n];

vec4   c;

float box(vec2 p, vec4 rc){
 vec2  hv = step(rc.xy, p) * step(p, rc.xy + rc.zw);
 float t  = 1. - hv.x * hv.y;
 return t;
}

vec2 rot(vec2 v, float p){
 return 0.5 * vec2(cos(time + p), sin(time + p));
}

void main( void ) {
 vec2      p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x,resolution.y);
 ac[0] = c1;   ac[1] = c2;    ac[2] = c3;        ac[3] = c4;
 ab[0] = bx;   ab[1] = bx;    ab[2] = bx;        ab[3] = bx;
 ap[0] = ps;   ap[1] = ps;    ap[2] = ps;        ap[3] = ps;
 pp[0] = PI_2; pp[1] = PI;    pp[2] = PI + PI_2; pp[3] = PI + PI;
 at[0] = 0.;   at[1] = 0.;    at[2] = 0.;        at[3] = 0.;
    
 c = b;
     
 for(int i = 0; i < n; ++i){
  ap[i] = rot(ap[i], pp[i]);
 }
 for(int i = 0; i < n; ++i){
  ab[i].xy += ap[i];
 }
 for(int i = 0; i < n; ++i){
  at[i] = box(p, ab[i]);
 }

 float yy = ab[0].y;
 float yt = at[0];
 vec4  yc = ac[0];
 for(int i = 1; i < n; ++i){
  if(yy < ab[i].y){
   yy = ab[i].y;
   yt = at[i];
   yc = ac[i];
  }
 }

 for(int i = 0; i < n; ++i)
  c = mix(ac[i], c, at[i]);
 c = mix(yc, c , yt);        
 glFragColor = c;
}
