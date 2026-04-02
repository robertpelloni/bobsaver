#version 420

// original https://www.shadertoy.com/view/ssSfDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}

float gyros(vec3 p) {
  
    return (dot(sin(p),cos(p.yxz)));
  }
  float di(vec3 p){
    
      float q=0.;
      vec4 pp = vec4(p,1.);
      for(float i=0.;i<8.;i++){
        q = q+clamp(asin(sin(gyros(pp.xyz)/pp.a)*.9),0.,.5);
         pp*=1.75;
         pp.xyz =abs(pp.xyz)-10.9125;
         pp.xz*=rot(.785);

        }
        return q;
    }
 float diff=0.;
vec2 sdf(vec3 p){
   p.xy*=rot(p.z*.1);
   p.y = -(abs(p.y)-1.);
  vec2 h;

  vec3 op = p;
   p.z +=time;

  h.x = p.y+1.+(diff=(di(p)*.3));
  h.y= 1.;
  h.x *=.7;
  return h;
  } 
  
#define q(s) s*sdf(p+s).x
vec3 norm(vec3 p,float ee){vec2 e=vec2(-ee,ee);return normalize(q(e.xyy)+q(e.yxy)+q(e.yyx)+q(e.xxx));}
vec3 pal(float t){return .5+.5*cos(6.28*(1.*t+vec3(.0,.3,.7)));}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(.1);

  vec3 ro  = vec3(0.,-.9,-5.)+1e-5;
;
  vec3 rt  = vec3(0.,-.950,.0)+1e-5;
  vec3 z   = normalize(rt-ro);
  vec3 x   = normalize(cross(z,vec3(0.,-1.,0.)));
  vec3 y   = normalize(cross(z,x));
  
  vec3 rp = ro;
  vec3 rd = mat3(x,y,z)*normalize(vec3(uv,1.));
  
  vec3 light = vec3(0.,1.,-3.)+1e-4;
  float dd = 0.;
  for(float i=0.;i<128.;i++){
      vec2 d = sdf(rp);
      dd+=d.x;
      rp+=rd*d.x;
    if(dd> 50.) break;
      if(d.x < .0001) {
           vec3 n = norm(rp,.0005);
        vec3 n2 = norm(rp,.002);
           float dif = max(0.,dot(normalize(light-rp),n));
        float spc = pow(max(0.,dot(normalize(ro-rp),reflect(-normalize(light-rp),n))),4.);
           col = dif*vec3(.2)+spc*pal(dot(rp,n)*.1);
            
           break;
      }
   
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
