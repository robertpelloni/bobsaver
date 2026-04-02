#version 420

// original https://www.shadertoy.com/view/wstSDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// license: CC BY-NC https://creativecommons.org/licenses/by-nc/4.0/

vec2 r(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

vec2 opReflect(vec2 v, vec2 normal) {
    v -= 2. * min(0., dot(v, normal)) * normal;
    return v;
}

const vec2 axisH = vec2(0,1);
const vec2 axisV = normalize(vec2(-sqrt(3.), 1));
const vec2 axisH2 = vec2(-axisV.x, axisV.y);

// this does not work as intended, but the result looks interesting enough and I don’t have time to debug it
float sdHexBox(vec2 position, vec2 halfSize) {
    vec2 absPosition = abs(position);
return max(dot(absPosition, axisH) - halfSize.y, dot(absPosition, axisV) - halfSize.x);
}

void main(void)
{

    float t = time * 2.;

    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.) / resolution.y;
    uv = r(uv, t * 0.05);
    const int segmentCount = 12;
    for (int i = 0; i < segmentCount; i++) {
        float angle = 6.2832 * float(i) / float(segmentCount);
        uv = opReflect(uv, -vec2(cos(angle), sin(angle)));
    }
    
    float dist = dot(uv, axisH) - 0.08; // core
    
    float hexRadius1 = cos(t * 0.13) * 0.06 + 0.25;
    float hexDistance1 = sdHexBox(uv - vec2(sin(t * 0.43) * 0.05 + 0.05,hexRadius1), vec2(0.002,0.03 + cos(t * 0.31) * 0.005));

    float hexRadius2 = cos(t * 0.18 + 0.1) * 0.1 + 0.15;
    float hexDistance2 = sdHexBox(uv - vec2(sin(t * 0.51 + 0.2) * 0.04 + 0.04, hexRadius2), vec2(0.002,0.03 + cos(t * 0.35 + 1.) * 0.01));

    float hexRadius3 = cos(t * 0.21 + 0.2) * 0.05 + 0.2;
    float hexDistance3 = sdHexBox(uv - vec2(sin(t * 0.61 + 0.4) * 0.04 + 0.06, hexRadius3), vec2(0.002,0.03));

    dist = min(dist, min(hexDistance1, min(hexDistance2, hexDistance3)));

    dist = min(dist, max(dot(uv, axisV) - 0.02, dot(uv, axisH) - max(hexRadius1,max(hexRadius2, hexRadius3)))); // arms

    float mask = smoothstep(fwidth(dist), 0., dist);
    float value = mask * pow(min(1.0,abs(dist + 0.2) * 5.), 60.);

    vec3 background = mix(vec3(0.1,0.6,0.7), vec3(0.1,0.2,0.5), length(uv) * 2.);

    vec3 refractedBackground = mix(vec3(0.,0.6,0.7), vec3(0.,0.2,0.5), min(1., length(uv) * 3.));

    glFragColor = vec4(mix(background, value + refractedBackground, mask),1.);
}

