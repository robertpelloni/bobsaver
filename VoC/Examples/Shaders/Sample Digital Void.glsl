#version 420

// original https://www.shadertoy.com/view/wtsSW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (vec2 uv){
    float rand = sin (fract(sin(uv.x * 2.528371
         + sin (uv.y * 7.72962))) * 83.62847) + sin (uv.x + sin (uv.y)) * 22.;
    return rand;
    }

#define PI 3.141592

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 col = vec3 (1., 1., 1.);
    // uv.x += time;
    vec2 outV = uv;
    vec2 newV = (uv - 0.5) * 2.;
    float fade = 1. - abs (uv.x * 2. - 1.);
    outV.x = fade * 2.;
    outV.y += outV.x * newV.y;

    outV.x += time * -0.5;
    outV.x *= 1.5;

    vec2 fpos = fract (outV * 10.);
    //used to add randomness to either side
    outV.x += floor (uv.x * 2. - 1.);
    vec2 ipos = floor (outV * 10.);
    float fval = fpos.x * fpos.y;

    float rand = abs (random (ipos)) * 0.05;
    fval = floor (sin (fpos.x * PI) + rand * 0.8);
    fval *= floor (sin (fpos.y * PI) + 0.3);
    //fval = sin (fpos.y * PI) * rand;

  col = vec3(fval);
  col *= 1. - fade;

  //col = vec3 (rand);

    glFragColor = vec4(col, 1.0);
}
