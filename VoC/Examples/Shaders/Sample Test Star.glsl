#version 420

// original https://www.shadertoy.com/view/3tGyWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float createStar(vec2 vUv, float amplitude, float offset) {
    float mipi = 3.14 / 2.;
    float a = mipi - cos(time);
    float time = a * 80.;
    float speed = 0.6;
    float radius = .5;
    float size = 0.0001;
    float angle = atan(vUv.y, vUv.x);
    int count = 5;
    float starAngle = angle + offset;
    float disp = sin(starAngle*float(count)) * amplitude;
    float dist = length(vUv) + disp / time;
    float sigma = abs(dist-radius);
    return smoothstep(size, size+0.01, sigma);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;    
    
    vec3 col1 = vec3(0, 0, 0);
    vec3 col2 = vec3(0.5, 0.5, 0.5);
    vec3 colfinal = vec3(0., 0., 0.);
    float distBetween = 0.07;
    for (int i = 0; i < 9; i++) {
      float offset = float(i) * distBetween;
      colfinal += mix(col2, col1, createStar(uv, 7., offset));
    }
    glFragColor = vec4(colfinal,1.0);
}
