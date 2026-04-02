#version 420

// original https://www.shadertoy.com/view/Xs3cDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14

vec2 hash2(in vec2 uv)
{
  return fract(vec2(sin(uv.x*1834538.331),
               sin(uv.y*617678.44)));
}

float hash(in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

float hash(in vec3 p)
{
  return fract(sin(dot(p,
    vec3(12.6547, 765.3648, 78.653)))*43749.535);
}

float noise3(in vec3 p)
{
  vec3 pi = floor(p);
  vec3 pf = fract(p);

  pf = pf*pf*(3.-2.*pf);

  float a = hash(pi + vec3(0., 0., 0.));
  float b = hash(pi + vec3(1., 0., 0.));
  float c = hash(pi + vec3(0., 1., 0.));
  float d = hash(pi + vec3(1., 1., 0.));

  float e = hash(pi + vec3(0., 0., 1.));
  float f = hash(pi + vec3(1., 0., 1.));
  float g = hash(pi + vec3(0., 1., 1.));
  float h = hash(pi + vec3(1., 1., 1.));

  return mix(mix(mix(a,b,pf.x),mix(c,d,pf.x),pf.y),
  mix(mix(e,f,pf.x),mix(g,h,pf.x),pf.y), pf.z);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners porcentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float fbm(vec2 uv) {
  float f = .5*noise(uv);
  vec2 off = vec2(0.01, 0.01);
  f += .25*noise(uv*2.02 + off);
  f += .125*noise(uv*4.01 + off);
  f += .065*noise(uv*8.03 + off);
  f += .0325*noise(uv*16.012 + off);

  return f;
}

#define red vec3(1.,0.,0.)
#define yellow vec3(1.,1.,0.)
#define blue vec3(0.,0.,1.)
#define white vec3(1.,1.,1.)
#define ocean vec3(0.,0.6,0.93)
  

void main(void)
{
  vec2 uv = gl_FragCoord.xy / resolution.xy;
  vec2 tuv = mouse*resolution.xy.xy/resolution.xy;

  uv.x *= resolution.x/resolution.y;
  vec2 sc = uv-vec2(0.7,0.7);
  float sr = dot(sc,sc);
  float af = atan(sc.y, sc.x);
  
  vec3 sun = vec3(1.,1.,1.)*(1.-smoothstep(sr, 0.00,0.01));
// sun = clamp(sun, 0.,1.);

  vec2 dir = uv;
  dir.x = dir.x*2. - 1.;
  vec3 rd = normalize(vec3(dir, -1.0));
  vec2 duv = uv;
    //if (tuv.x > .5 && mouse*resolution.xy.z > 0.5) {
    //    duv = rd.xz/(rd.y + 0.001);
    //}
  float f = fbm(duv+tuv*4.);
  float tt = 0.1*time;
  float anf = noise(vec2(af*10. + tt*5., tt*4.));
  float f2 = fbm(duv+2.*vec2(cos(f) + cos(tt), sin(f)+sin(tt)) );
  vec3 sky = vec3(0.,0.,max(blue.b*(1.-sr), 0.));
  vec3 col1 = mix(yellow, red, f);
  vec3 col2 = mix(sky, white,
    f2);
  vec3 col = mix(col2, col1, f*f2);

  //col = mix(vec3(0.,0.,0.), col, 2.*(  col.r*col.g));
  col += sun*(4.*(1.-col.g)*exp(-col.g*4.));
  //col = mix(col, sun, clamp(4.*(1.-col.g-col.r)*exp((-col.g-col.r)*4.), 0.,1.));
  glFragColor = vec4(col, 1.);
}
