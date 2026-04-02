#version 420

// original https://www.shadertoy.com/view/wstGDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Palette cycling (https://www.shadertoy.com/view/ll2GD3) version of 
// 'Triangle ocean' (https://www.shadertoy.com/view/Wst3D8).
#define PI                3.141592653589793
#define TWO_PI            PI * 2.0
#define TIME_SCALE      1.0 / 32.0
#define BRIGHTNESS      0.2
#define TRIPPINESS      8.0
#define ZOOM            12.0

const vec4 color1 = vec4(0, 59, 70, 255) / vec4(255);
const vec4 color2 = vec4(7, 87, 91, 255) / vec4(255);

vec2 coord(in vec2 p) {
  p = p / resolution.xy;
  // correct aspect ratio
  if (resolution.x > resolution.y) {
    p.x *= resolution.x / resolution.y;
    p.x += (resolution.y - resolution.x) / resolution.y / 2.0;
  } else {
    p.y *= resolution.y / resolution.x;
    p.y += (resolution.x - resolution.y) / resolution.x / 2.0;
  }
  // centering
  p -= 0.5;
  p *= vec2(-1.0, 1.0);
  return p;
}

mat2 rotation2d(float angle) {
    return mat2(
        cos(angle), -sin(angle),
        sin(angle), cos(angle)
    );
}

float random (in vec2 st) {
    return fract(
        sin(
            dot(st.xy, vec2(12.9898,78.233))
        ) * 43758.5453123
    );
}

float normalize2(float minV, float maxV, float v) {
    return minV + v * (maxV - minV);
}

// See http://iquilezles.org/www/articles/palettes/palettes.htm
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

void main(void) {
 
    vec2 uv = coord(gl_FragCoord.xy);
    float time = time * TIME_SCALE;

    vec2 wave = uv;
    wave.x += sin(uv.y * TRIPPINESS + time) * 0.1;
    wave.y += cos(uv.x * TRIPPINESS + time) * 0.1;
    uv += wave;

    uv *= rotation2d(PI / 3.2 * time);
    uv *= vec2(normalize2(1., 2., (1. + sin(time)) / 2.));
    uv += vec2(normalize2(5., 10., time));

    vec2 index = floor(ZOOM * uv) / ZOOM;
    float t = floor(random(index) * 4.) / 4.;

    uv = 2.0 * fract(ZOOM * uv) - 1.0;
    uv *= rotation2d(t * TWO_PI);

    float c = step(uv.x, uv.y) * 0.9;
    c = abs(sin(5. + fract((random(index + c) + 0.1))));

    vec3 palColor1 = pal( time*.10, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );   
    vec3 palColor2 = pal( time*.04, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
    vec4 color = random(vec2(c)) > 0.5 ? vec4(palColor1.xyz, 1.0) : vec4(palColor2.xyz, 1.0);

    glFragColor = vec4((c * BRIGHTNESS + 0.5) * color.xyz, 1.0);   
}
