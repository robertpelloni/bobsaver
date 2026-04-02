#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
// 2013-03-30 by @hintz
#define CGFloat float
#define M_PI 3.14159265359
vec4 hsvtorgb(vec3 col)
{
    float iH = floor(mod(col.x,1.0)*6.0);
    float fH = mod(col.x,1.0)*6.0-iH;
    float p = col.z*(1.0-col.y);
    float q = col.z*(1.0-fH*col.y);
    float t = col.z*(1.0-(1.0-fH)*col.y);
  if (iH==0.0)
  {
    return vec4(col.z, t, p, 1.0);
  }
  if (iH==1.0)
  {
    return vec4(q, col.z, p, 1.0);
  }
  if (iH==2.0)
  {
    return vec4(p, col.z, t, 1.0);
  }
  if (iH==3.0)
  {
    return vec4(p, q, col.z, 1.0);
  }
  if (iH==4.0)
  {
    return vec4(t, p, col.z, 1.0);
  } 
  return vec4(col.z, p, q, 1.0); 
}
void main(void) 
{
    vec2 position = 0.5*(gl_FragCoord.xy - 0.5 * resolution) / resolution.y;
    float x = position.x;
    float y = position.y;
    CGFloat a = atan(x, y);
        CGFloat d = sqrt(x*x+y*y);
        CGFloat d0 = 0.5*(sin(d-time)+1.5)*d+0.02*time;
        CGFloat d1 = 5.0; 
        CGFloat u = mod(a*d1+sin(d*10.0+time), M_PI*2.0)/M_PI*0.5 - 0.5;
        CGFloat v = mod(pow(d0*4.0, 0.75),1.0) - 0.5;
        CGFloat dd = sqrt(u*u+v*v*d1);
        CGFloat aa = atan(u, v);
        CGFloat uu = mod(aa*3.0+3.0*cos(dd*16.0-time), M_PI*2.0)/M_PI*0.5 - 0.5;
        // CGFloat vv = mod(dd*4.0,1.0) - 0.5;
        CGFloat d2 = sqrt(uu*uu+v*v)*1.5;   
    glFragColor = hsvtorgb(vec3(dd+time*0.5/d1, dd, d2));
}
