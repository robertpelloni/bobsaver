#version 420

// original https://www.shadertoy.com/view/7l2BDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TURN 6.2831853
#define zigzag(x) abs(1. - 2. * fract(x))
#define angleVec(theta) vec2(cos(theta), sin(theta))

vec3 color(float r) {
    vec3 c = vec3(
        cos( r          * TURN * .5),
        cos((r + 1./3.) * TURN * .5),
        cos((r + 2./3.) * TURN * .5)
    );
    return c*c;
}

float sepMagn(float t) {
    return 0.04 * (1.0 + 0.4 * sin(2. * t * TURN));
}

float dist2(vec2 uv){
    return 1. / (0.02 + length(uv));
}

void main(void)
{
  float time = fract(time / 4.0);
  float t0 =  time       / 3.;
  float t1 = (time + 1.) / 3.;
  float t2 = (time + 2.) / 3.;
  // make the center of the canvas (0.0, 0.0) and
  // make the long edge of the canvas range from -1.0 to +1.0
  float scale = max(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale;
  
  const float zoomSpeed = 6.;
  const float ringSpacing = .1;
  const float ringThickness = 0.1;

  float dist = log(length(uv));
  float distA = dist2(
      uv + sepMagn(t0) * angleVec(TURN * t0)
  ) * ringSpacing + zoomSpeed * time;
  float distB = dist2(
      uv + sepMagn(t1) * angleVec(TURN * t1)
  ) * ringSpacing + zoomSpeed * time;
  float distC = dist2(
      uv + sepMagn(t2) * angleVec(TURN * t2)
  ) * ringSpacing + zoomSpeed * time;
  
  float alphaA = smoothstep(
      -min(0.2, 4. * fwidth(distA)), 0.,
      zigzag(distA + t0) - 1. + ringThickness
  );
  float alphaB = smoothstep(
      -min(0.2, 4. * fwidth(distB)), 0.,
      zigzag(distB + t1) - 1. + ringThickness
  );
  float alphaC = smoothstep(
      -min(0.2, 4. * fwidth(distC)), 0.,
      zigzag(distC + t2) - 1. + ringThickness
  );

  vec3 colA = alphaA * color(t0);
  vec3 colB = alphaB * color(t1);
  vec3 colC = alphaC * color(t2);
  
  vec3 col = colA + colB + colC;
  
  // Output to screen
  glFragColor = vec4(
    col, 1.0
  );
}
