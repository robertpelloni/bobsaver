#version 420

// original https://www.shadertoy.com/view/ldyfzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define KALEIDO 1
#define LIGHTCOUNT 100

#define v2Resolution resolution
#define out_color glFragColor
#define time time

#define pi 3.141592

vec2 r2(vec2 uv) {
  return fract(sin(uv*vec2(1236.512,2975.233)+uv.yx*vec2(4327.135,6439.123)+vec2(1234.93,1347.367))*vec2(4213.523744,974.93242));
}

vec2 r2(int i) {
  return fract(sin(float(i)*vec2(1236.512,2975.233)+vec2(1234.93,1347.367))*vec2(4213.523744,974.93242));
}

mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

vec2 mir(vec2 uv, float a) {

  mat2 ra=rot(a);
  uv *= ra;
  uv.y=abs(uv.y);
  uv *= ra;

  return uv;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float mt=time*0.2;
#if KALEIDO
  uv = mir(uv, mt*0.2);
  uv = mir(uv, -mt*0.4);
  uv = mir(uv, mt*0.6);
  uv = mir(uv, -mt*0.9);
#endif

  float ht=time*0.2;
  uv += abs(vec2(sin(ht),cos(ht)))*(sin(time*0.3)*0.5+0.5)*0.3;

  vec3 tcol=mix(vec3(0.8,0.2,0.2),vec3(0.2,0.8,0.9),sin(1234.12134+time*vec3(0.5,1.3,2.8)));
  float pt=time*0.1;
  float pulse = abs(fract(pt*floor(abs(fract(pt*4.0)*4.0-0.5)*2.0))-0.5)*2.0;

  float st=time*0.2;

  float d=10000.0;
  vec3 col = vec3(0);
  for(int i=0; i<LIGHTCOUNT; ++i) {

    vec2 rr=r2(i*10);
    float a=rr.x*pi*2.0 + st + sin(st*0.6+rr.y)*1.3 + sin(st*0.2+rr.y)*0.6;
    vec2 p = uv+(r2(i)-0.5)*0.5 + vec2(cos(a),sin(a))*0.2;
    float lp=length(p);
    d=min(d,lp-0.01);

    vec3 lcol=mix(vec3(0.8,0.2,0.2),vec3(0.2,0.8,0.9),sin(rr.y*100.0*vec3(0.5,1.3,2.8)));
    lcol = mix(lcol,tcol,pulse);
    float bd = 0.0015/lp;
    col += lcol*bd;

  }

  //col = vec3(0.003)/max(0.001,d);
  float gt=time*0.2;
  vec3 lcol=mix(vec3(0.8,0.2,0.2),vec3(0.2,0.8,0.9),sin(time*vec3(0.5,1.3,2.8)));
  col += abs(fract(gt*floor(abs(fract(gt*4.0)*4.0)-0.5)*2.0)-0.5)*2.0*lcol*pow(abs(fract(d*30.0-time*1.0)-0.5)*2.0,8.0)*max(0.0,0.6 / length(uv)-0.9);

  out_color = vec4(col,0);
}
