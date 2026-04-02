#version 420

// original https://www.shadertoy.com/view/ts3GRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rep(p,r) (mod(p + r/2.,r) - r/2.)

float sdSphere(vec3 p,float r)
{
  return length(p) -r;
}

mat2 rot(float a)
{
float c  = cos(a); float s = sin(a);
return mat2(c,-s,s,c);
}

float map(vec3 p)
{

  p.xz *= rot(.003);

  //float a = atan(p.z,p.y);

  p.y += 1.5 + sin(time + length(p * 2.31) );

  float plane = p.y + 1.;

  float d = length(p.xy);

  p.xy *= rot(sin(time *.912)+ d * .021);  
  p.y += .5 * sin(d * 5. + time) * .1 +1.15;
  p.xz = rep(p.xz, 4.);

  float sp = sdSphere(p,1.);
  

  return min(plane,sp);
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.1,0.);
  return(normalize(vec3(
    map(p - e.xyy) - map(p + e.xyy),
    map(p - e.yxy) - map(p + e.yxy),
    map(p - e.yyx) - map(p + e.yyx)
)));
}

void main(void)
{
  vec2 uv=vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
  uv-=.5;
  uv/=vec2(resolution.y/resolution.x,1);

  vec3 ro = vec3(0.,0.,-15.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = ro;

  float id = 0.;
  for(float st = 0.; st < 1.; st += 1. / 128.)
  {
    float cd = map(cp);
    if(cd < .01)
    {
      id = 1. - st;
      break;
    }
    cp += rd * cd * .5;
  }

  vec3 norm = normal(cp);
  vec3 ld = normalize(cp - vec3(1. * sin(-time*2.),9.,50.*cos(-time*2.)));
    
  float light = clamp(dot(norm,ld),0.,1.);

  float f = id;
  //vec4 base = vec4(.2,.14,.7,1.);
  vec4 base=vec4(0.0, 0.0, 0.0, 1.0);

  float l = light * id;
  vec4 out_color=vec4(1.);
  //out_color = vec4(mix(vec4(1.),base,1. / l)) ;
  out_color=vec4(mix(vec4(0.2549, 0.8314, 0.2235, 1.0),base,1.-l));
  glFragColor=vec4(out_color);
}
