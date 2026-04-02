#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tttXRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI    radians(180.)
#define TAU radians(360.)

vec2 rotate(float angle, float radius)
{
    return vec2(cos(angle),-sin(angle)) * radius;
}

vec2 perp(vec2 v)
{
    return vec2(-v.y, v.x);
}

float udTriangle( vec2 p, vec2 a, vec2 b, vec2 c )
{
  vec2 ab = b - a; vec2 pa = a - p;
  vec2 bc = c - b; vec2 pb = b - p;
  vec2 ca = a - c; vec2 pc = c - p;
    
  float d0 = dot(perp(ab), pa);
  float d1 = dot(perp(bc), pb);
  float d2 = dot(perp(ca), pc);
    
  return min(min(d0, d1), d2);

}

float sdfTriangle(vec2 p)
{
    float radius = 1.2;
    float angle = time * 0.8;
    vec2 a = rotate( angle, radius);
    vec2 b = rotate( TAU / 3. + angle, radius);
    vec2 c = rotate( 2. * TAU / 3. + angle, radius);
    
    return udTriangle(p, a, b, c);
}

float radFilter(float v)
{
    float thickness = 0.2;
    return smoothstep(1. - thickness, 1., v) * smoothstep(1. + thickness, 1., v);
}

float distFilter(float v)
{
    return smoothstep(0., 0.5, v);
}

void main(void)
{
    vec2    p = (gl_FragCoord.xy - resolution.xy * .5) / (resolution.y * .5);
    float    angle = atan(p.y, p.x);
    float     l = length(p) * 13.;
    int        circleId = int(floor(l));
    int        modCircleId = circleId % 2;
    float d = sdfTriangle(p);
    d = distFilter(d);
    float speed = mix(0.1, -0.1, float(modCircleId));
    l+= sin((angle - time * speed) * float(circleId) * 5.) * 0.3 * d;
    l = fract(l) * 2.;
    float    t = min(l, 2. - l);
    t = radFilter(t); 
    glFragColor = vec4(vec3(t),1.);
}
