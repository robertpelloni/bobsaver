#version 420

// original https://www.shadertoy.com/view/Wt2Gzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2xpatterns (mod overlay) - del 20/05/2019 - sin for the win.

vec3 pat1(vec2 pos)
{
    pos*=0.5;
    pos+=vec2(0.5);
    float vv = pos.y*pos.y;
    vv*=sin(pos.x*3.14);
    float v = (sin(sin(pos.x*15.0)*4.0+(vv) *50.0 + time * 2.0))+0.65;
    float stime = 0.5+sin(time*4.0)*0.5;
    vec3 col = vec3( v*0.45, .35*v, 0.25+0.2*v) * (1.5-stime*0.4);
    return col;
}

mat2 rot(float a)
{
  float s = sin(a);
  float c = cos(a);
  return mat2(c, s, -s, c);
}

float pMod1(inout float p, float size)
{
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

void main(void)
{
    vec2 pos = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec3 back = pat1(pos);
    
    float ns = 0.5+sin(time*0.7)*0.5;
    pos*=1.5+(ns*1.1);
    pos.x+=time*0.4;
    float c = pMod1(pos.x,0.58);
    pos.y+= cos(time*0.2+c);
    float c2 = pMod1(pos.y,0.58);
    pos  *= rot(time+c2*3.0);
    float d = 3.0-length(6.0*pos*pos)*7.0;
    
    pos*=rot(pos.x*5.0+time*0.6+log(d));
    pos+=vec2(0.5);
    float vv = (c2+pos.y*pos.y+pos.x*d*d*1.61) + sin(pos.x*12.14);
    vv = sin(sin(pos.x*22.6)*1.0+(vv) * 0.5 + time * 2.0);
    
    float s = sign(vv);
    vv = abs(vv);
    vec3 col1 = s>0.0 ? vec3( vv*.5, .05+0.3*vv, 0.0) : vec3( vv*0.14, 0.2*vv, 0.1*vv);
    col1 = clamp(col1*d,0.0,1.0);
    glFragColor = vec4(mix(back, col1, smoothstep(0.5,1.0,d)),1.0);
}
