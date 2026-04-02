#version 420

// original https://www.shadertoy.com/view/wtcGW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float smin( float a, float b, float k ) {
float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
return mix( b, a, h ) - k*h*(1.0-h);
}

float sdBox(vec3 p, vec3 s) {
p = abs(p)-s;
return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

vec2 path(float z){
float x = sin(z) + 3.0 * cos(z * 0.5) - 1.5 * sin(z * 1.12345);
float y = cos(z) + 1.5 * sin(z * 0.3) + .2 * cos(z * 1.12345);
return vec2(x,y)*0.5 ;
}

vec2 GetDist (vec3 p) 
{
vec2 o = path(p.z) / 5.0;
p = vec3(p.x,p.y,p.z)-vec3(o.x,o.y,0.); 
float r = 3.14159*sin(p.z*0.15)+(time*0.25*1.);
mat2 R = mat2(cos(r), sin(r), -sin(r), cos(r));
p.xy *= R ;    
p = fract(p) * 2. - 1.; 
vec2 box = vec2(sdBox(p-vec3(0,0.0,0), vec3(0.4)),1);
vec2 box2 = vec2(sdBox(p-vec3(0,0.0,0), vec3(0.15,1.1,0.15)),0);
vec2 box3 = vec2(sdBox(p-vec3(0,0.0,0), vec3(1.1, 0.15,0.15)),2);
vec2 box4 = vec2(sdBox(p-vec3(0,0.0,0), vec3(0.15, 0.15,1.1)),3);
vec2 d =(box.x<box2.x)?box:box2;
d=(d.x<box3.x)?d:box3;
d=(d.x<box4.x)?d:box4;
d.x =  smin(d.x,box.x,0.2);
d.x *= 0.4;        
return  d;
}

vec2 RayMarch (vec3 ro, vec3 rd) 
{
vec2 h, t=vec2( 0.);
for (int i=0; i<64; i++) 
{
h = GetDist(ro + t.x * rd);
if(h.x<.001||t.x>100.) break;
t.x+=h.x;t.y=h.y;
}
if(t.x>100.) t.x=0.;
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

float GetLight(vec3 p)
{
vec2 a = path(time * 1.0)*1.0;
vec3 o = vec3(a / 5.0,time-0.5);
vec3 lightPos =  o;
vec3 l = normalize(lightPos-p);
vec3 n = GetNormal(p);
float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
vec2 d = RayMarch(p+n*.001*20., l);
if (d.x<length(lightPos-p)) dif *= 0.5;
return dif;       
}

void main(void)
{
vec2 uv = (gl_FragCoord.xy -.5*resolution.xy) / resolution.y;
vec3 col = vec3(0);
vec2 a = path(time * 1.0)*1.0;
vec3 o = vec3(a / 5.0,time);
vec3 ro = vec3(0,1,time*5.);
vec3 rd = normalize(vec3(uv.x,uv.y-.2,0.6));
float the = time*0.3;
vec2 d = RayMarch (o,rd);
float t =d.x *1.;   
if(t>0.){
vec3 p = o + rd *t;
vec3 baseColor = vec3(0.,0.,0.5);
if(d.y==0.) baseColor=vec3(sin(p.z+time*2.),1.,0);
//if(d.y==0.) baseColor=vec3(sin(p.z+time*1.)-0.4,1.,0.5);
if(d.y==1.) baseColor=vec3(0,cos(p.z+time*4.),1.);
if(d.y==2.) baseColor=vec3(sin(p.z+time*1.)-0.4,1.,0.5);
if(d.y==3.) baseColor=vec3(1,.1,sin(time));
float dif = GetLight (p); 
col = vec3(dif);       
col+=baseColor;
float fog = 1. / (2. + t * t * 0.25);
col *= vec3(fog);   
}
glFragColor = vec4(col,1.0);
}
