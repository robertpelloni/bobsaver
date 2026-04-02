#version 420

// original https://www.shadertoy.com/view/wsXSRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time 
#define rez resolution.xy
vec2 tile(vec2 p, float a){return mod(p,vec2(a))-vec2(a/2.0);} 
vec3 mcol;
float irx=1.0; 
float DE(vec3 z0){ 
  z0.yz=tile(z0.yz,1.74); 
  vec4 c = vec4(-0.1,0.01,-0.92,0.0),z = vec4(z0,1.0); 
  for(int n=0;n<5;n++){ 
    z.zyx=abs(z.xyz)-0.31; 
    z*=1.68/clamp(dot(z.xyz,z.xyz),0.14,1.08); 
    z+=c; 
  } 
  mcol=vec3(0.45,0.13,0.15)+20.0*abs(sin(z.yxz))/z.w; 
  z=abs(z); 
  return min((z0.x+0.6)*irx,(max(z.x,z.y)-1.1)/z.w); 
} 
vec3 background(vec3 rd){ 
  rd=abs(rd); 
  return vec3(1.0,0.9,0.0)*pow(1.0-min(rd.z,rd.y),6.0); 
} 
float rnd; 
void randomize(in vec2 p){rnd=fract(time+sin(dot(p,vec2(13.3145,117.7391)))*42317.7654321);} 
vec3 scene(vec3 ro, vec3 rd){
  vec3 bcol=background(rd); 
  vec4 col=vec4(0.0);//color accumulator 
  irx=1.0/(1.0-abs(rd.x));//to speed up floor in DE 
  float t=DE(ro)*rnd,d,od=1.0,px=1.0/rez.x; 
  for(int i=0;i<199;i++){ 
    d=DE(ro+rd*t); 
    if(d<px*t){ 
      float dif=clamp(1.0-d/od,0.0,1.0)/(t*t);//cam light 
      float alpha=(1.0-col.w)*clamp(1.0-d/(px*t),0.0,1.0); 
      col+=vec4(clamp(mcol*dif+bcol*exp(-1.0+t*0.05),0.0,1.0),1.0)*alpha; 
      if(col.w>0.99)break; 
    } 
    t+=d;od=d; 
    if(t>20.0)break; 
    mcol=vec3(0.0); 
  } 
  col.rgb+=bcol*(1.0-clamp(col.w,0.0,1.0));
  return col.rgb;
}
mat3 lookat(vec3 fw){
  fw=normalize(fw);vec3 rt=normalize(cross(fw,vec3(1.0,0.0,0.0)));return mat3(rt,cross(rt,fw),fw);
}
vec2 bx_cos(vec2 a){return clamp(abs(mod(a,8.0)-4.0)-2.0,-1.0,1.0);} 
vec2 bx_cossin(float a){return bx_cos(vec2(a,a-2.0));}
vec3 path(float t){
  return vec3(min(-0.2+t*0.03,1.4),bx_cossin(t*0.1)*8.7)+vec3(0.3/(1.0+t*0.1))*sin(sin(vec3(1.0,0.9,0.7)*t));
}
void main(void) {
  vec2 uv=vec2(gl_FragCoord.xy-0.5*rez)/rez.x; 
  randomize(uv);
  float tim=time*0.5+time*time*0.03;
  vec3 ro=path(tim),rd=normalize(vec3(uv.xy,1.0));ro.x-=0.2;
  rd=lookat(path(tim+1.0)-ro)*rd;
  glFragColor=vec4(scene(ro,rd),1.0);
}
