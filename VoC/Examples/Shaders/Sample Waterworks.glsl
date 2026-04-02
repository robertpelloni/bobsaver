#version 420

// original https://www.shadertoy.com/view/MtXyDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float n(vec3 v)
{
float s=.1*dot(v,v),r_,y_;
v/=s;
v.y+=(time/65.)*9.;
vec3 m=fract(v)-.5,l=abs(m);
r_=fract(dot(sin(floor(v)+step(l.yzx,l)*step(l.zxy,l)*sign(m)/2.)*43.5,vec3(.333)));
y_=min(length(m)-.15,abs(length((r_<.333)?m.yz:(r_<.666)?m.zx:m.xy)-.1));
return (((r_>.7)?max(y_,max(l.x,max(l.y,l.z))-.25):y_)-.01)*s/2.;
}

float s(vec3 l)
{
float v=n(l+vec3(0.,-.2,0.));
return min(n(l),(l.y-cos(v*80.-(time/65.)*512.)*(.02-.02*smoothstep(0.,.1,v)))/2.8);
}

void main(void)
{
float v=0.,l;
vec3 m=normalize(vec3(-1.+gl_FragCoord.xy/(resolution.y/2.),-1.)),y;
for(int r=0;r<150;++r)
  {
  v+=l=s(y=vec3(-2.,.5,4.)+m*v);
  if(l<.001) break;
  }
glFragColor=vec4(v<20.?abs(s(y+.02)-l)/vec3(4.,3.,2.)*200.:vec3(0.), 1.);
}
