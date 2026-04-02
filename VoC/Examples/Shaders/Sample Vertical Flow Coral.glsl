#version 420

// original https://www.shadertoy.com/view/Wdf3zn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2D Random
float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation
    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

vec2 vectorField(vec2 uv){
  vec2 res = uv;
  float n = noise(res*vec2(3.0));
  res.y -= time*0.05;
  res += sin(res.yx*40.) * 0.02;
  res += vec2(n);
  return res;
}

float plot(float val, float c, float t){
  float l = smoothstep(c,c-t,val);
  float r = smoothstep(c,c-t/5.,val);
  return r-l;
}

void main(void) {
  float t = 0.2; // try 0.2 or 0.3
  vec4 m = vec4(0.0);//mouse*resolution.xy / resolution.xxxx;
  vec2 st = gl_FragCoord.xy/resolution.xy;
  st.y *= resolution.y / resolution.x;
  st = vec2(st.y, st.y * (st.x * 0.4));
  st = vectorField(st);

  float cell = 0.2 + m.y*0.3;
  vec2 modSt = mod(st, vec2(cell));

  float x = plot(modSt.x, cell, t);
  float y = plot(modSt.y, cell, t);
    
  vec3 green = vec3(0.733,1.,0.309 );
  vec3 red = vec3(1.,0.352,0.207);
  vec3 blue = vec3(0.086,0.290, 0.8 );

    
  vec3 col = blue * x;
  col     += green * y;
  col     += red*vec3(smoothstep(1.3, .01,x+y));

  glFragColor = vec4(col,1.0);
}
