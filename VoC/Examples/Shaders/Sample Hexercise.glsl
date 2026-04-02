#version 420

// original https://www.shadertoy.com/view/WsSXRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot and Alkama for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// This shader was inspired by the AWESOME tutorial from BigWings : 
// https://www.youtube.com/watch?v=VmrIDyYiJBA&t=1s

// Music by Alkama <3 thank you

// Cookie Collective rulz

#define hr vec2(1., sqrt(3.))
#define detail 15.
#define time time
#define PI 3.141592
#define BPM 126./60.
#define coloured_grid(_id) vec3(1., rand(_id.x), rand(_id.y))
#define anim(t) (PI/3.*(floor(t*BPM)+pow(fract(t*BPM),3.)))

float rand (float x)
{return fract(sin(x)*25.55);}

mat2 rot(float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

vec2 moda(inout vec2 uv, float rep)
{
    float per = 2.*PI/rep;
    float a = atan(uv.y,uv.x);
    float l = length(uv);
    a = mod(a, per)-per*0.5;
    return vec2(cos(a),sin(a))*l;
}

float HexDist (vec2 uv)
{
    uv = abs(uv);
    return max(dot(uv, normalize(hr)), uv.x);
}

vec4 HexGrid (vec2 uv)
{
    uv *= detail;
    vec2 ga = mod(uv, hr)-hr*0.5;
    vec2 gb = mod(uv-hr*0.5, hr) - hr*0.5;

    vec2 guv = dot(ga,ga) < dot(gb,gb) ? ga : gb;

    vec2 id = uv-guv;
    guv.y = .5-HexDist(guv);
    return vec4(guv.x, guv.y, id.x,id.y);
}

float sphere_mask(vec2 id)
{
    float s1 = step(length(id),2.5);
    id *= rot(-anim(time));
    id = moda(id,7.);
    id.x -= 5.5;
    return smoothstep(2.5,2.,length(id)) + s1;
}

float line_mask(vec2 id)
{
    id *= rot(anim(time));
    id.yx = moda(id.yx, 3.);
    id.x -= 1.;
    id.x += sin(id.y+time);
    return step(abs(id.x),2.);
}

float wave1 (vec2 id)
{
    id.y += 2.5;
    id.y += sin(id.x+time*2.);
    return step(id.y,0.5);
}

float wave2 (vec2 id)
{
    id.y -= 2.5;
    id.y += sin(id.x-time*4.);
    return step(0.5, id.y);
}

vec3 lines_hexa (vec2 id)
{
    float m = clamp(line_mask(id) - sphere_mask(id),0.,1.);
    return coloured_grid(id).xxy*0.9*m;
}

vec3 spheres_hexa(vec2 id)
{return coloured_grid(id).yxz*0.6 * sphere_mask(id);}

vec3 background(vec2 id)
{ 
    float foreground_masks = sphere_mask(id)+ line_mask(id);
    float m1 = clamp(wave1(id)-foreground_masks,0.,1.);
    float m2 = clamp(wave2(id)-foreground_masks,0.,1.);
    return (coloured_grid(id).zyx *0.8 * m1 + coloured_grid(id).xyz*0.8*m2)*0.5;
}

vec3 frame(vec2 uv)
{
    vec4 hc = HexGrid(uv);
    vec3 col = lines_hexa(hc.zw) + spheres_hexa(hc.zw) + background(hc.zw);
    col += step(1.-(hc.y*abs(sin(length(hc.zw*(PI/3.)*0.08)-anim(time)))), 0.89)*0.4;
    return col;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  
  vec3 col = frame(uv);
  glFragColor = vec4(pow(col,vec3(1.5)),1.);
}
