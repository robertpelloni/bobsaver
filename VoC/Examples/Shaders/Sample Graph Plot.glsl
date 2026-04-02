#version 420

// original https://www.shadertoy.com/view/slX3W2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float lineWidth = 0.01;
float DELTA = 0.005;

float plot(vec2 uv, vec2 p, vec2 pDelta){
  vec2 delta = pDelta - p;
  float cosPhi = delta.x / length(delta); //cos(atan(delta.y, delta.x));
  float height = lineWidth / 2.0 / cosPhi;
  return abs(uv.y - p.y) - height;
}

float f(float x) {
   float a = sin(x * 20.0 + time) * .5;
   a += sin(x * 24.0 + time * 3.5) * .5;
   a *= .3;
   return a;
}

void main(void)
{
    // Normalized pixel coordinates (from -1.0 to 1.0)
    vec2 uv = (gl_FragCoord.xy/resolution.xy - .5) * 2.0;

    vec2 p = vec2(uv.x, f(uv.x));
    vec2 pDelta = vec2(uv.x + DELTA, f(uv.x + DELTA));

    float d = plot(uv, p, pDelta);
    vec3 col = smoothstep(0.0, 0.01, d) * vec3(1.0, 1.0, 1.0); 

    // Output to screen
    glFragColor = vec4(col,1.0);
}
