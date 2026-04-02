#version 420

// original https://www.shadertoy.com/view/ftBSDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define fGlobalTime time
#define timer(a,b,c) (mix(a,b,(asin(sin(c*fGlobalTime))) + 3.1415/2.)/3.1415 )
#define timer1 timer(0.5,1.,.5)
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
// No big diff I guess deep investigation is needed to determine the faster version
float sminEvil(float a,float b,float k){ float h=max(0.,k-abs(a-b));return min(a,b)-0.25*h*h/k;}
float sminMercury(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}
float box(vec3 p, vec3 b){
    vec3 q = abs(p)-b;
    return length(max(vec3(0.),q))+min(0.,max(q.x,max(q.y,q.z)));
}
float diam(vec3 p,float s){
    p = abs(p);
    return (p.x+p.y+p.z-s)*sqrt(1./3.);
  }
float sqq(vec3 p){
  float g = 1.;
  vec4 pp = vec4(p,1.);  
  for(float i=0.;i<=4.;i++){
         pp.xz = abs(pp.xz)-.55;
         pp*=1.2;
         pp.zy *=rot(-.33*i);
         g = min(g,clamp(sin(pp.x*.5)*sin(pp.y*.66)+cos(pp.z*2.),-.5,.5)/pp.a);
        
      }
  return min(length(p.xy)-.5,min(length(p.xz)-.5,length(p.yz)-.5))-g;
  }
vec2 sdf(vec3 p){
  
  p.yz =mix(p.yz,p.yz*rot(atan(inversesqrt(2.))),timer1);
  p.xz =mix(p.xz,p.xz*rot(3.1415/4.),timer1);
  
  vec2 h;
  float q = 1.;
  for(float i=0.;i<=2.;i++){
       p.xz = abs(p.xz)-2.5;
       p.xz*=1.22;
       q*=1.23;
       p.x +=1.;
       p.xy =p.x < p.y ? p.yx:p.xy;
       p.xz*=rot(.785);
    }
  h.x = sqq(p);
  h.x = sminEvil(h.x,diam(p,2.),.5+cos(p.y*10.))/(q*1.5);
  h.y = 1.+cos(p.y*10.);
   return h;
 }
 
#define q(s) s*sdf(p+s).x
 vec2 e= vec2(-.003,.003);
 vec3 norm(vec3 p){return normalize(q(e.xyy)+q(e.yxy)+q(e.yyx)+q(e.xxx));}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

   
    vec3 col =vec3(0.);
  vec3 ro = vec3(0.,0.,-5.+4.*sin(fGlobalTime));
  vec3 rt = vec3(-1.,1.,0.);
  vec3 z = normalize(rt-ro);
  vec3 x = normalize(cross(z,vec3(0,-1.,0.)));
  vec3 y = normalize(cross(z,x));
  
  vec3 rd = mat3(x,y,z)*normalize(vec3(uv,1.));

  ro = mix(ro,vec3(uv*5.,-30.),timer1);

  rd = mix(rd,vec3(0.,0.,1.),timer1);

  vec3 light = vec3(1.,0.,-10.);
  vec3 rp =ro;
  vec3 acc = vec3(0.);
  for(float i=0.;i<=128.;i++){
      vec2 d = sdf(rp);
    if(d.y < 1.){
         acc+=vec3(.1,.7,.4)*max(0.,exp(10.*-abs(d.x)))/(60.+sin(rp.z*10.+fGlobalTime*10.)*30.);
      d.x = max(.002,abs(d.x));
      }    
    rp+=d.x*rd;
    
    if(length(rp)>100.)break;
      if(d.x<=0.001){
          vec3 n = norm(rp);  
          col = vec3(.6,.5,1.5)*sqrt(1.-i/128.)*max(0.,dot(normalize(light-rp),n));
        break;
      }
    
    
  }
  col +=acc;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
