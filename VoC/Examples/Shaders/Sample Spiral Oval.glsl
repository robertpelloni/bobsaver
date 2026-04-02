#version 420

// original https://www.shadertoy.com/view/fsdGzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float THRESHOLD_ABERRATION = .044;
const float SMOOTHNESS = .5;
const float LINE_WEIGHT = SMOOTHNESS * .8;
const float DISTANCE = 1.;
const float ROTATION_SPEED = 3.;

mat2 rotate2d(float angle){
    return mat2(cos(angle), -sin(angle),
                sin(angle), cos(angle));
}

float fract2(float x){
  return abs((fract(x) - .5) * 2.);
}

void main(void)
{
    vec2 screen = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    vec3 color = vec3(1.0);
    float time = time * .5;
    
    screen = screen / .5;
    screen = rotate2d(time * ROTATION_SPEED) * screen;
    
    float radius = length(screen) * 4., 
          threshold = atan(screen.y , screen.x);
          

    color *= smoothstep(LINE_WEIGHT, 
    SMOOTHNESS, 
    fract2(radius * (abs(sin(threshold * 1. + .5 * THRESHOLD_ABERRATION)) + 1.) * DISTANCE + time * ROTATION_SPEED));
    
    
    glFragColor = vec4(color, 1.0);
}
