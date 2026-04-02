#version 420

// original https://neort.io/art/bigg4pk3p9f3vpbp9kq0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

  
  const float AA = .02;
  const float blur = .2;
  const float size = .3;
  const float width = .08;
  
  #define PI 3.14159265358979323846

  vec2 diagonalhash2(vec2 p)
  {
    return fract(vec2(sin((p.x + p.y) * 15.543) * 73964.686, sin((p.x + p.y) * 55.8543)*28560.986));
  }
  
  float rand(vec2 c){
      return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
  }

  float noise(vec2 p, float freq ){
    float unit = resolution.x/freq;
    vec2 ij = floor(p/unit);
    vec2 xy = mod(p,unit)/unit;
    //xy = 3.*xy*xy-2.*xy*xy*xy;
    xy = .5*(1.-cos(PI*xy));
    float a = rand((ij+vec2(0.,0.)));
    float b = rand((ij+vec2(1.,0.)));
    float c = rand((ij+vec2(0.,1.)));
    float d = rand((ij+vec2(1.,1.)));
    float x1 = mix(a, b, xy.x);
    float x2 = mix(c, d, xy.x);
    return mix(x1, x2, xy.y);
  }
  
  vec3 pattern(vec2 uv, vec2 m, float z) {
    vec2 grid = floor(uv);
    vec2 subuv = fract(uv);
    
    float seed = noise(grid, 100.);
    
    float phase = sin(time * 1. + seed * 10.);
    // phase = mix(phase, 1., max(1. - length(m*1.5), 0.));
    
    float shape = 0.;
    float df;
    
    vec3 col = vec3(.6, .8, .3);
    
    if(seed < .5) {
      df = length(subuv-.5);
    } else {
      float s = sin(0.785398);
      float c = cos(0.785398);
      subuv = (subuv-.5) * mat2(c, -s, s, c);
      vec2 offsetuv = (abs(subuv) + vec2(.0, .3));
      df = max(offsetuv.x, offsetuv.y);
      offsetuv = (abs(subuv) + vec2(.3, .0));
      df = min(df, max(offsetuv.x, offsetuv.y));
      col = vec3(.9, .3, .2);
    }
    
    float w = width * max(phase, 0.1);
    
    shape = (smoothstep(size + w + AA,size + w, df) - smoothstep(size - w + AA,size - w, df)) * phase;
    shape += (smoothstep(size + w * .1 + blur,size + w * .1, df) - smoothstep(size - w * .1,size - w * .1 - blur, df)) * phase;
    
    vec3 colour = vec3(col * shape * 2.);
    
    return colour;
  }

  void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / min(resolution.y, resolution.x);
    
    float l = length(uv);
    float a = atan(uv.y, uv.x) + l * .2;
    uv = vec2(cos(a) * l, sin(a) * l);
    uv *= 1. + dot(l, l)*.5;
      
    glFragColor = vec4(vec3(noise(uv + diagonalhash2((uv + time) * 20.), 500000.)), 1.) * .2;
    
    vec2 m = (mouse.xy - 0.5 * resolution.xy) / min(resolution.y, resolution.x) - uv;
    
    float z = 40. + sin(time * .2) * 38.;
    uv *= z;
    
    vec2 dir = vec2(time * 1.5, sin(time * .3) * .8);
    a = dir.y * -.2;
    float c = cos(a);
    float s = sin(a);
    
    uv *= mat2(c, -s, s, c);
    
    uv += dir;
    
    
    vec3 colour = pattern(uv, m, z);

    glFragColor += vec4(colour,1.0);
  }
