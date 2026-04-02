#version 420

// original https://www.shadertoy.com/view/wlG3zV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001

const float PI = 3.14159265;

mat3 rotate( in vec3 v, in float angle)
{
 float c = cos(radians(angle));
 float s = sin(radians(angle));    
 return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
 (1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
 (1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
 );
}

float box( in vec3 p, in vec3 data )
{
 return max(max(abs(p.x)-data.x,abs(p.y)-data.y),abs(p.z)-data.z);
}

float sdOctahedron( vec3 p, float s)
{
  return (p.y+p.z)*0.735027;
}

mat2 Rot(float a) {
 float s = sin(a);
 float c = cos(a);
 return mat2(c, -s, s, c);
}

float smin( float a, float b, float k ) {
 float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
 return mix( b, a, h ) - k*h*(1.0-h);
}

float sdBox(vec3 p, vec3 s) {
 p = abs(p)-s;
 return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}
vec2 condmin(in vec2 d1, in vec2 d2) {
 return vec2(min(d1.x, d2.x), mix(d1.y, d2.y, step(d2.x, d1.x)));
}

float g1;

vec2 GetDist(vec3 p) {
 vec2 d;
 d.x =p.y +10.;
 for(int i=0; i<5; i++)
 {
  p = abs(p);
 // p = rotate( normalize( vec3(2. ,0.,2. ) ), sin(59.*0.2)*100.)*p;
   p = rotate( normalize( vec3(1.3 ,-.1,2. ) ), sin(59.*0.2)*80.)*p;
  vec2 dbox = vec2(sdOctahedron( p- vec3(-0.,0,abs(sin(p.z-time)*2.)),1.),1.);
  if( dbox.x < d.x)
  {
   g1 +=3./(0.6+pow(abs(dbox.x),10.));
   d = condmin( d,dbox);
  }    
 }
 return d ;
}

vec2 RayMarch(vec3 ro, vec3 rd) {
vec2 h, t=vec2( 0.);  
for (int i=0; i<64; i++) 
 {   
  h = GetDist(ro + t.x * rd);   
  if(h.x<0.001||abs(t.x)>70.) break;
  t.x+=h.x *.6;
  t.y=h.y;
 }
 if(t.x>70.) 
 t.x=.0;
return t;
}

vec3 GetNormal(vec3 p){
 vec2 d = GetDist(p);
 vec2 e = vec2(0.001,0);
 vec3 n = d.x - vec3(
 GetDist(p-e.xyy).x,
 GetDist(p-e.yxy).x,
 GetDist(p-e.yyx).x);
 return normalize(n);
}

float GetLight(vec3 p) {
 vec3 lightPos = vec3(sin(time),cos(time),0.);
 vec3 l = normalize(lightPos-p);
 vec3 n = GetNormal(p);
 float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
 vec2 d = RayMarch(p+n*.001*1., l);
 if (d.x<length(lightPos-p)) dif *= .01;
 return dif;       
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
 vec3 f = normalize(l-p),
 r = normalize(cross(vec3(0,1,0), f)),
 u = cross(f,r),
 c = p+f*z,
 i = c + uv.x*r + uv.y*u,
 d = normalize(i-p);
 return d;
}

void main(void)
{
 vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
 vec2 m = mouse*resolution.xy.xy/resolution.xy;
 vec3 col = vec3(0);  
 vec3 ro = vec3(-3, -10., 1.);
 ro.yz *= Rot(-m.y*3.14+1.);
 ro.xz *= Rot(-m.x*6.2831);
 ro.xy *= Rot(cos(time*0.1)*3.14+2.);
 //ro.xz *= Rot((cos(time*0.1))*3.2831-0.1);   
 vec3 rd = R(uv, ro, vec3(0,0,0), .7);
 vec2 d = RayMarch(ro, rd);   
 float t =d.x *1.;   
 if(t>0.){
 vec3 p = ro + rd *t;
 vec3 baseColor = vec3(1.,1.,0.);
 if(d.y==1.) baseColor=vec3(sin(p.z+time)+1.,1.,1.);
 float dif = GetLight (p); 
 col = vec3(dif);  
 col+=baseColor; 
 float fog = 1. / (1. + t * t * .004);
 col *= vec3(fog);   
 }
 vec3 sky = vec3(1., 1., 1.);
 col = mix(sky, col, 0.84/(d.x/100.*.9+1.)); 
 col *=g1*vec3(.001);
 glFragColor = vec4(col,1.0);
}
