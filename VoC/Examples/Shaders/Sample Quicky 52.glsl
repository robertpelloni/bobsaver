#version 420

// original https://www.shadertoy.com/view/7sBSWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define fGlobalTime time
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}
#define flikflok(t) (floor(t)+pow(fract(t),.25))
vec2 sdf(vec3 p) {
  float bt = time*.5;
  float bt3 = time*.33;
   p.z +=floor(bt3*10.);
   p.xy *=rot(p.z*.785*.1);
  vec3 op = p;    
  float tt = 0.0; //texture(iChannel1,p.xz*.1).r*.1;

    vec2 h;
    vec3 pp = p;
    p = abs(p)-1.5;
    h.x = length(p)-1.;
  p.xy = abs(p.x) < abs(p.y)  ?p.yx:p.xy;
  
  
    p.xz/=3.;
    p.xz = asin(sin(p.zx));
    p.xz*=3.;
    h.x = min(h.x,length(p.xz)-.5-clamp(cos(abs(p.y)*4.+fGlobalTime*180./60.*4.),-.25+sin(p.y*10.)*.1,.25)*.4);   
     h.y = 1.;
      h.x*=.7;
   return h;
}
vec2 nv=vec2(-.001,.001);
#define q(s) s*sdf(p+s).x
vec3 norm(vec3 p){return normalize(q(nv.xyy)+q(nv.yxy)+q(nv.yyx)+q(nv.xxx));}
vec3 pal(float t){return .5+.5*cos(6.28*(1.*t+vec3(0.,.3,.7)));}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    float tt = fract(time);
  vec3 bcol = log(1.+tt*100.11)*pal(.5+uv.x);
  
  float ttt = 0.0; //texture(iChannel1,uv*10.).r;
  float pp = fract(time);
    
  
  vec3 ro=vec3(0.,0.,-5.),rd=normalize(vec3(uv,1.-pp*ttt)),rp=ro;
  vec3 light = vec3(1.,2.,-3.);
  vec3 acc = vec3(0.);
  vec3 col =vec3(0.);
  for(float i=0.;i<=69.;i++){
      vec2 d = sdf(rp);
    
        
          acc+=mix(vec3(1.,.7,.2),vec3(.1,.5,.7),step(.5,i/69.))*exp(20.*-abs(d.x))/(10.);
            
       if(d.x<=0.005){
         vec3 n = norm(rp);
        col *= vec3(1.)*max(0.,dot(n,normalize(light-rp)));
      
        break;
        }
        rp+=rd*d.x;
   }
  col +=acc;
 

    // Output to screen
    glFragColor = vec4(col,1.0);
}
