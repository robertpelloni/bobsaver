#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.141592653589793;

float smin(float a, float b, float k) {
  float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float hash(vec2 p) {
  return fract(sin(p.x*15.73 + p.y*35.28) * 43758.23);
}

vec2 hash2(vec2 p) {
  mat2 m = mat2(15.73, 35.28, 75.43, 153.26);
  return fract(sin(m * p) * 43758.23);
}

float shash(vec2 p) {
  return hash(p) * 2.0 - 1.0;
}

vec2 shash2(vec2 p) {
  return hash2(p) * 2.0 - 1.0;
}

float noise(vec2 p) {
  vec2 g = floor(p);
  vec2 f = fract(p);
  vec2 k = f*f*f*(6.0*f*f - 15.0*f + 10.0);

  float lb = dot(shash2(g + vec2(0.0, 0.0)), vec2(0.0, 0.0) - f);
  float rb = dot(shash2(g + vec2(1.0, 0.0)), vec2(1.0, 0.0) - f);
  float lt = dot(shash2(g + vec2(0.0, 1.0)), vec2(0.0, 1.0) - f);
  float rt = dot(shash2(g + vec2(1.0, 1.0)), vec2(1.0, 1.0) - f);

  float b = mix(lb, rb, k.x);
  float t = mix(lt, rt, k.x);
  return 0.5 + 0.5 * mix(b, t, k.y);
}

vec4 monster(vec2 p) {
    float d = length(p) - 0.95 + noise(p) * 0.1;
    d = smoothstep(0.01, 0.0, d);
    vec2 q = p;
    vec4 col = vec4(0.0);
    col = mix(col, vec4(253.0 / 255.0, 234.0 / 255.0, 191.0 / 255.0, 1.0), d);
    
    q.y = p.y * 1.1;
    float a = 0.5 + 0.5 * (atan(q.y, q.x) / pi);
    float r = 0.5 + 0.5 * sin(a * pi * 50.0);
    r = exp(-10.0 * r * r);
    float dr = noise(vec2(floor(a * 50.0), 0.5) + time);
    dr = clamp(dr, 0.5, 1.0);
    float pins = length(q) - 0.45 - r * 0.5 + dr * 0.5;

    q.y = p.y *(1.1 + 0.1 * sin(time));
    float di = length(q) - 0.45 + noise(q * 1.2) * 0.2;
    
    float body = smin(pins, di, 0.1);
    body = smoothstep(0.01, 0.0, body);
    col = mix(col, vec4(0.0, 0.0, 0.0, 1.0), body);
    
    float ew_l = length(p - vec2(-0.16, 0.0)) - 0.13 + noise(p * 6.0 + time) * 0.05;
    ew_l = smoothstep(0.01, 0.0, ew_l);
    col = mix(col, vec4(1.0, 1.0, 1.0, 1.0), ew_l);
    
    float eb_l = length(p - vec2(-0.12, 0.0)) - 0.025 + noise(p * 12.0 + time) * 0.025;
    eb_l = smoothstep(0.01, 0.0, eb_l);
    col = mix(col, vec4(0.0, 0.0, 0.0, 1.0), eb_l);
    
    float ew_r = length(p - vec2(0.1, 0.02)) - 0.14 + noise(p * 5.0 + time) * 0.05;
    ew_r = smoothstep(0.01, 0.0, ew_r);
    col = mix(col, vec4(1.0, 1.0, 1.0, 1.0), ew_r);
    
    float eb_r = length(p - vec2(0.05, 0.0)) - 0.025 + noise(p * 12.0 + time) * 0.025;
    eb_r = smoothstep(0.01, 0.0, eb_r);
    col = mix(col, vec4(0.0, 0.0, 0.0, 1.0), eb_r);
    
    return col;
}

void main( void ) {

    vec2 p = ( gl_FragCoord.xy / resolution.xy );
    p = 2.0 * p - 1.0;
    p.x *= resolution.x / resolution.y;
    vec4 col = monster(p);
    
    glFragColor = vec4( col.rgb, 1.0 );
}
