#version 420

// original https://www.shadertoy.com/view/DlsGWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float tau = 2. * acos(-1.);

const vec3 forward = vec3(0., 0., 1.);
const vec3 up = vec3(0., 1., 0.);
const vec3 right = vec3(-1., 0., 0.);
const vec3 cam = vec3(0., 0., -2.0);
const vec3 sph = vec3(0., 0., 0.);

const float ptCt = 200.;
const float speed = 1.;

float t;

float dist(vec3 rayDir) {
    float minDist = 99999.;
    for (float i = 0.; i < ptCt; i++) {
        float iNorm = i / ptCt;
        
        vec4 denoms = vec4(0.243453, 0.4234345, 0.2357797, 0.165777341);
        vec2 rand = mod(iNorm * vec2(1.3236574234, 0.934556756345), denoms.xy) / denoms.xy;
        rand = mod(rand.yx, denoms.zw)/denoms.zw;
        rand = mod(rand, denoms.xz)/denoms.xz;
        rand = mod(rand.yx, denoms.yw)/denoms.yw;
        
        float phi = acos(1. - fract(rand.x + t/4.) * 2.);
        float theta = rand.y * tau + t * (rand.x + iNorm + 2.)/4.;
        
        float horz = sin(phi);
        vec3 iPos = vec3(horz * cos(theta), cos(phi), horz * sin(theta)) + sph;
        
        float iDist = length(rayDir * dot(rayDir, iPos - cam) + cam - iPos);
        minDist = min(iDist, minDist);
    }
    
    return minDist;
}

void main(void)
{
    t = time * speed;
    vec2 uv = (gl_FragCoord.xy/resolution.xy * 2. - 1.);
    uv.x*= resolution.x / resolution.y;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward);
    
    float d = dist(rayDir);
    if (d < 0.02) {
        glFragColor = vec4(1., 1., 1., 1.);
    } else {
        glFragColor = vec4(0., 0., 0., 1.);
    }
}
