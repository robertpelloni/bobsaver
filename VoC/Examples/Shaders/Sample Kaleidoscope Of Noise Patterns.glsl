#version 420

// original https://www.shadertoy.com/view/wtdyW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592658;
const float TWOPI = 2.0 * PI;

// pseudo-random function, returns value between [0.,1.]
float rand (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(31.7667,14.9876)))
                 * 833443.123456);
}

//bilinear value noise function
float bilinearNoise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners of a 2D square
    float f00 = rand(i);
    float f10 = rand(i + vec2(1.0, 0.0));
    float f01 = rand(i + vec2(0.0, 1.0));
    float f11 = rand(i + vec2(1.0, 1.0));

    vec2 u = smoothstep(0.,1.,(1.-f));
    return u.x*u.y*f00+(1.-u.x)*u.y*f10+
    u.x*(1.-u.y)*f01+(1.-u.x)*(1.-u.y)*f11;
    
}

void main(void) {
  vec2 uv =gl_FragCoord.xy/ resolution.xy;
  //from Cartesian to polar coordinates
  float scale=3.;
  uv=fract(scale*uv)-.5;
  float radius = length(uv);
  float angle = atan(uv.y, uv.x);
  //change Nsections using horizontal movement of mouse
    float Nsections=20.;//-15.*mouse*resolution.xy.x/resolution.x;
  //create Nsections which are identical
  float angleM = mod(angle, TWOPI/Nsections);
  //make each section symmetric along its bisector
  angleM = abs(angleM -PI/Nsections);
  //back to Cartesian coordinates
  uv = radius*vec2(cos(angleM),sin(angleM));
  uv=sin(uv+.04*time);
  vec3 color=vec3(bilinearNoise(100.*uv),bilinearNoise(75.*uv),bilinearNoise(50.*uv));
  glFragColor = vec4(color,1.);
}
