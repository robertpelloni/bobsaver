#version 420

// original https://www.shadertoy.com/view/dsd3zf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Collecting some github stars" by mrange. https://shadertoy.com/view/cst3zX
// 2023-03-01 06:38:51

// CC0: Collecting some github stars
// Do I get the senior dev job now?

// Another meme shader

#define TIME        time
#define RESOLUTION  resolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

const float cw = 0.05;
const float bw = 0.5*cw*23.0/32.0;
const float br = cw*3.0/32.0;

vec3 hsb2rgb( in vec3 c )
{
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return (c.z * mix( vec3(1.0), rgb, c.y));
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b) {
  vec2 d = abs(p)-b;
  return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float hexagram(vec2 p, float r) {
  const vec4 k = vec4(-0.5,0.8660254038,0.5773502692,1.7320508076);
  p = abs(p);
  p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
  p -= 2.0*min(dot(k.yx,p),0.0)*k.yx;
  p -= vec2(clamp(p.x,r*k.z,r*k.w),r);
  return length(p)*sign(p.y);
}

vec3 effect(vec2 p, vec2 pp) {
  const vec3 rgbb  = 1.0/vec3(255.0);
  const vec3 bgcol = pow(rgbb*vec3(14.0, 17.0, 23.0), vec3(2.0));
  const vec3 fgcol = pow(rgbb*vec3(24.0, 27.0, 34.0), vec3(2.0));
  vec3 hicol = hsb2rgb( vec3(p.x,0.7,1.0) );//(rgbb*vec3(24.0, 27.0, 34.0), vec3(2.0));
  
  
  
  const vec3 locol = pow(rgbb*vec3(40.0, 68.0, 42.0), vec3(2.0));
  //const vec3 hicol = pow(rgbb*vec3(132.0, 210.0, 91.0), vec3(2.0));
  float aa = 2.0/RESOLUTION.y;
  float aaa = cw;
  vec2 cp = p;
  vec2 np = mod2(cp, vec2(cw));
  
  vec3 col = bgcol;
  
    //if (abs(np.y) < 13.0) {
    
    np.x += TIME*10.0;
    float nep = mod1(np.x, 24.0);
    float nh0 = hash(nep+123.4);
    float nh1 = fract(8667.0*nh0);
  
    vec2 ep = np*cw;
    float r = mix(0.25, 0.5, nh0)*1.0; 
    float pt = mix(0.5, 1.0, nh1);
  
    float ft = mod(TIME+pt*nh1, pt);
    ep.y -= -mix(2.0, 1.0, nh1)*(ft-pt*0.5)*(ft-pt*0.5)+r-0.5+0.125;
    ep *= ROT(2.0*mix(0.5, 0.25, nh0)*TIME+TAU*nh0);

    float ed = hexagram(ep, 0.5*r);
    ed = abs(ed)-0.05;
    
     hicol = hsb2rgb( vec3(ep.x,0.9,0.9) );
    
    float cd = box(cp, vec2(bw-br))-br;
  
    vec3 ecol = mix(fgcol, hicol, smoothstep(aaa, -aaa, ed));
    
    col = mix(col, ecol, smoothstep(aa, -aa, cd)); 
  //}
  
  col = sqrt(col);
  return col;
}

void main(void) {

  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p, pp);
  
  glFragColor = vec4(col, 1.0);
}
