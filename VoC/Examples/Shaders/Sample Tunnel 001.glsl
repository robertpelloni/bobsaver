#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float oa(vec3 q)
{
 return 0.51*acos(-abs(q.x)*0.1)+cos(q.x)+cos(q.y*1.5)+cos(q.z)+cos(q.y*20.)*.05;
}

float ob(vec3 q)
{
 return length(max(abs(q-vec3(cos(q.z*1.5)*.3,-.5+cos(q.z)*.2,.0))-vec3(.125,.02,time+3.),vec3(.0)));
}

float o(vec3 q)
{
 return min(oa(q),ob(q));
}

vec3 gn(vec3 q)
{
 vec3 f=vec3(.01,0,0);
 return normalize(vec3(o(q+f.xyy),o(q+f.yxy),o(q+f.yyx)));
}

void main(void)
{
 vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
 p.x *= resolution.x/resolution.y;
 vec4 c=vec4(1.0);
 vec3 org=vec3(sin(time)*.5,cos(time*.5)*.25+.25,time),dir=normalize(vec3(p.x*1.6,p.y,1.0)),q=org,pp;
 float d=.0;
float beam=0.1;
 for(int i=0;i<32;i++)
 {
  d=o(q);
  q+=d*dir;
  if (d<beam) break;
  beam+=0.1;
 }
 pp=q;
 float f=length(q-org)*0.02;
 dir=reflect(dir,gn(q));
 q+=dir;
 beam=0.1;
 for(int i=0;i<32;i++)
 {
 d=o(q);
 q+=d*dir;
 if (d<beam) break;
 beam+=0.91;
 }
 c=max(dot(gn(q),vec3(.1,.1,.0)),.0)+vec4(.3,cos(time*.5)*.5+.5,sin(time*.5)*.5+.5,1.)*min(length(q-org)*.04,1.);
 if(oa(pp)>ob(pp))c=mix(c,vec4(cos(time*.3)*.5+.5,cos(time*.2)*.5+.5,sin(time*.3)*.5+.5,1.),.3);
 vec4 fcolor = ((c+vec4(f))+(1.-min(pp.y+1.9,1.))*vec4(1.,.8,.7,1.))*min(time*.5,1.);
 fcolor-=0.3*normalize(fcolor);// some simple contrast grading
 glFragColor=vec4(fcolor.xyz,1.0);
}
