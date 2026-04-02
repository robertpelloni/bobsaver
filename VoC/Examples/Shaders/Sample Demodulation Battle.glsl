#version 420

// original https://www.shadertoy.com/view/dtjcDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define o glFragColor
#define time time

#define F float
#define V vec2
#define W vec3
#define N normalize
#define L length
#define S(x) sin(x + 2.0 * sin(x + 4.0 * sin(x)))
#define sabs(x) sqrt((x) * (x) + 0.1)
#define smax(a, b) ((a + b + sabs(a - (b))) * 0.5)
#define Z(p, s) (asin(sin(p * T / s) * 0.9) / T * s)
#define T 6.283
#define rot(x) mat2(cos(x), -sin(x), sin(x), cos(x))

F gl=0.;
float sdf(vec3 p) {
    vec3 pI = p;
    
    p.x += S(p.z * 0.1 + time) * p.z * 0.05;
    p.y += S(p.z * 0.161 + time) * p.z * 0.05;
    p.xy = vec2(atan(p.y, p.x) / T * 8.0 + S(pI.z * 0.162 + time * 0.2), -length(p.xy) + 1.5 + 0.6 * S(pI.z * 0.2 + time * 0.2));
    
    p.z += time * 4.0;
    
    p.y += 0.5;
    float pl = p.y;
    
    p.xz = vec2(Z(p.xz, 2.0));
    
    p.y += 0.5 * sin(pI.z + time + atan(p.y, p.x));
    float sp = length(p) - 0.3;
    float l = length(p) - 0.02 + 0.02 * sin(pI.z + S(time));
    l *= 0.5;
    
    pl = smax(pl, -sp) + 0.01 * sin(atan(pl, sp) * 40.0);
    
    pl = min(pl, l);
    gl += 0.01 / l * pl;
    if (l < 0.002) gl++;
    
    return pl * 0.5;
}

vec3 norm(vec3 p) {
    float d = sdf(p);
    vec3 e = vec3(0.0, 0.001, 0.0);
    return normalize(vec3(d - sdf(p - e.yxx), d - sdf(p - e.xyx), d - sdf(p - e.xxy)));
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
  o*=0.;

  F i=0.,d=0.,e=1.;
  W p,rd=N(W(uv,1));
  rd.xz*=rot(.2*S(time*.1+uv.y*.2));
  rd.yz*=rot(.1*S(time*.161+uv.x*.23));
  for(;i++<99.&&e>.001;){
    p=rd*d+.00001;
    d+=e=sdf(p);
  }
  W l=W(0,1,0);
  l.xy*=rot(p.z*.4+time*4.);
  W n=norm(p);
  o.r+=dot(n,l)*.5+.5;
  o.g+=dot(n,l.zxy)*.5+.5;
  o.b+=dot(n,l.yzx)*.5+.5;
  o*=(1.-i/99.)*.8+.2;
  //o=pow(max(o,0),vec4(.5));
  o+=gl;
  o*=smoothstep(50.,0.,d);
}
