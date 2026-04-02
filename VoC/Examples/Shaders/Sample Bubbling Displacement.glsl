#version 420

// original https://www.shadertoy.com/view/4lKfRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float phi = (1.+sqrt(5.))*.5;

float rand(vec2 c){
    return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 eye() {
    return vec3(.2, .5, 2.);
}

vec3 lookAt (vec3 from, vec3 target, vec2 uv) {
    vec3 forward = normalize(target - from);
    vec3 right = normalize(cross(forward, vec3(0,1,0)));
    vec3 up = normalize(cross(forward, right));
    return normalize(forward * .5 + uv.x * right + uv.y * up);
}

mat2 rotation(float angle) {
    float c = cos(angle), s = sin(angle);
    return mat2(c, s, -s, c);
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdDodecahedron(vec3 p, float r)
{
    const vec3 n = normalize(vec3(phi,1,0));

    p = abs(p/r);
    float a = dot(p,n.xyz);
    float b = dot(p,n.zxy);
    float c = dot(p,n.yzx);
    return (max(max(a,b),c)-n.x)*r;
}

float sdIcosahedron(vec3 p, float r)
{
    const float q = (sqrt(5.)+3.)/2.;

    const vec3 n1 = normalize(vec3(q,1,0));
    const vec3 n2 = vec3(sqrt(3.)/3.);

    p = abs(p/r);
    float a = dot(p, n1.xyz);
    float b = dot(p, n1.zxy);
    float c = dot(p, n1.yzx);
    float d = dot(p, n2.xyz)-n1.x;
    return max(max(max(a,b),c)-n1.x,d)*r; // turn into (...)/r  for weird refractive effects when you subtract this shape
}

float displace(float shape, vec3 p, float freq, float scale) {
    float d = sin(freq*p.x)*sin(freq*p.y)*sin(freq*p.z);
    return shape + scale*d;
}

float sdf(vec3 eye) {
    mat2 rot = rotation(time*.1);
    vec3 p = eye;
    p.xy *= rot;
    p.xz *= rot;
    p.yz *= rot;
        
    float shape = min(
            sdDodecahedron(p,.75),
            sdIcosahedron(p.zyx,.75)
        );
    vec3 pos = eye;
    float displacedShape = displace(shape, p, mix(20., 1., (sin(time)*.5 + .5)), .1);
    
    return mix(displacedShape, shape, (sin(time)*.5 + .5));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv = (uv-.5) / 2.;
    uv.x *= resolution.x/resolution.y;

    vec4 color = vec4(0.);

    float shade = 0.;
    float distTotal = 0.;

    vec3 eye = eye();
    vec3 target = vec3(0);
    vec3 ray = lookAt(eye, target, uv);
    const float count = 50.;

    for (float i = count; i > 0.; --i) {

        float dist = sdf(eye);

        if (dist < .0001) {
            shade = i/count;
            break;
        }

        eye += ray * dist;
        distTotal += dist;
    }
    
    vec3 shadeColor = mix(vec3(0., 1., 0.), vec3(0., 0., 1.), (sin(time)*.5 + .5));

    color = vec4(vec3(pow(shade, 2.)) * shadeColor, 1.);
    
    color.rgb += rand(uv+vec2(time*.00001))*.15;
   
    glFragColor = color;
}
