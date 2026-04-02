#version 420

// original https://www.shadertoy.com/view/wtsyDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;

float remap(float x, float lowIn, float rangeIn, bool invert)
{
    float o = clamp(clamp(x - lowIn, 0., rangeIn) / rangeIn, 0., 1.);
    if (invert) {
        return 1. - o;
    }
    return o;
}

vec3 blend(vec3 x1, vec3 x2, float factor)
{
    return x2 * factor + x1 * (1. - factor);
}

float zigzag(float x)
{
    return abs(1. - mod(x, 2.0));
}

float timeBounce(float x)
{
    return -3. * sin(PI * x) + x;
}

float gear(float x, float y, float rot, float scale, float teethCount, float spokeCount, float center, float inner, float outer)
{
    // constants
    float d = sqrt(x*x+y*y);
    float theta = atan(y, x) + rot;
    // teeth
    const float teethWidth = 0.3; // from 0.0 to 1.0
    const float teethSlant = 0.2; // purely radial sides don't look right
    const float teethSmoothing = 0.06;
    // spokes
    const float spokeWidth = 0.08; // from 0.0 to 1.0
    const float spokeSlant = 0.3; // purely radial sides don't look right
    const float spokeSmoothing = 0.04;
    // radii
    // const float scale = 0.5; // total size of the gear
    const float smoothing = 0.02; // radial; teeth and spoke smoothing are defined separately
    //const float center = 0.2; // spokes start here
    //const float inner = 0.5; // spokes end here
    //const float outer = 0.75; // teeth start here
    
    d /= scale;
    
    if (d < center) {
        return 1.;
    } else if (d < inner) {
        float slant = remap(
                    d, center, inner + smoothing - center, true
                );
        return clamp(
            remap(d, center, 0.25 * smoothing, true) // center smoothing (quarter)
            +
            remap( // spokes
                1. - zigzag(theta / PI * spokeCount) - slant * slant * spokeSlant,
                spokeWidth,
                spokeSmoothing,
                true
            )
            +
            remap(
                d,
                inner - smoothing,
                smoothing,
                false
            )
        , 0., 1.);
    } else if (d < outer) {
        return 1.;
    } else if (d < 1.) {
        return clamp(
            min(
                remap(d, outer, smoothing, true) // ring smoothing
                +
                remap( // teeth
                    1. - zigzag(theta / PI * teethCount) - remap(
                        d, outer, 1. + smoothing - outer, true) * teethSlant,
                    teethWidth,
                    teethSmoothing,
                    true
                )
            ,
                remap( // smooth outer rim of gear
                     d,
                    1. - 2. * smoothing, // smooth double for outside
                    smoothing,
                    true
                )
            )
        , 0., 1.);
    }
    return 0.;
}

float tick(float t){
    const float ticksPerRot = 24.0;
    const float tickLength = 0.125;
    const float tickPeriod = 1.;
    t += 0.5 * tickLength + 0.5 * tickPeriod;
    return (
        floor(t / tickPeriod) + smoothstep(0., 1., (mod(t / tickPeriod, 1.) - 0.5) / tickLength)
         ) / ticksPerRot
    ;
}
  
float spiral(float x) {
  return max(0.0, sin(x) * 0.75 + 0.25);
}

void main(void)
{    
  // colors
  const vec3 colorBase = vec3(0.2, 0.3, 0.5);
  const vec3 colorGear = vec3(0.9, 0.95, 0.95);

  // more params for the ticking inside the tick() function
  float time = tick(time);

  // Normalized pixel coordinates (from 0 to 1)
  float scale = min(resolution.x, resolution.y);
  vec2 uv = (gl_FragCoord.xy - 0.50 * resolution.xy) / scale * 1.41421356;
  
  float angle = atan(uv.y, uv.x);

  // Time varying pixel color
  float cGear = gear(uv.x, uv.y, 2. * PI * time, 0.3, 8., 4., 0.2, 0.5, 0.75);
  // add another gear    rotation speed & offset--v                       v--size
  cGear += gear(uv.x - 0.49, uv.y - 0.19,  0.42 + -2. * PI * time,        0.3, 8., 4., 0.2, 0.5, 0.75);
  cGear += gear(uv.x + 0.19, uv.y - 0.49,  0.42 + -2. * PI * time,        0.3, 8., 4., 0.2, 0.5, 0.75);
  cGear += gear(uv.x - 0.27, uv.y + 0.35, 0.6 + -2. * PI * time * 4./3., 0.2, 6., 4., 0.15, 0.4, 0.7);
  cGear += gear(uv.x + 0.52, uv.y + 0.34,  0.34 + -2. * PI * time * 2./3., 0.4, 12., 6., 0.2, 0.6, 0.8);
  
  vec3 colBase = colorBase;
  vec3 colComp = blend(colBase, colorGear, cGear);

  // Output to screen
  glFragColor =
    vec4(
        colComp
      , 1.
    );
}
