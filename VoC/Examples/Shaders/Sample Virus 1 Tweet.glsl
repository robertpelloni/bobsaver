#version 420

// original https://neort.io/art/bqd2jbc3p9fdlitd9i1g

#define t time
#define r resolution
#define R(r)mat2(cos(r),sin(r),-sin(r),cos(r))
uniform vec2 resolution;uniform float time;

out vec4 glFragColor;
void main(){vec3 p,u,e;u=vec3((gl_FragCoord.xy*2.-r)/r.y,.5);u.xy*=R(t*.2);p.xz+=t;for(int i=0;i<20;i++){e.x=length(abs(length(mod(p,.8)-.4))-sin(t*3.+p.y)*.3);e.y+=e.x*.1;p+=u*max(e.x,.01);}glFragColor=vec4(e.yxy,1);}
