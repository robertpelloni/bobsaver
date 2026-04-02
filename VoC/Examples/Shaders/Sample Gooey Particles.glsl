#version 420

// original https://www.shadertoy.com/view/MtjyWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float radius = .05;
const float edgeWidth = .01;
const int numTrailParticles = 100;
const float trailLength = .3;
const float metaballThreshold = .9;
const float metaballRadius = .00027;
const float speedMultiplier = 1.1;

vec2 getPos(float t, float aspect) {
    float tx = t / aspect;
    vec2 p = vec2(sin(2.2 * tx) + cos(1.4 * tx), cos(.3 * t) + sin(-1.9 * t));
    p.y *= 0.2;
    p.x *= 0.4;
     return p;
}

float metaballFunc(vec2 pos, vec2 uv, float radius) 
{
    return radius / length(uv - pos);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - vec2(.5);
    uv.x *= resolution.x / resolution.y;
    vec3 color = vec3(.2, 1.2, .2);
    vec3 colorFinal = vec3(0.);
    float finalFactor = 0.;
    float aspect = resolution.x / resolution.y;
    float mb = 0.;
    
    for (int i = 0; i < 17; i++) 
    {
        float minDistance = 1.0;
        for (int j = 0; j < numTrailParticles; j++) {
            float pct = float(j) / float(numTrailParticles);
            vec2 pos = getPos(time * speedMultiplier + float(i) * 1.5 - pct * trailLength, aspect);
            float segmentLength = length(pos - uv);
            minDistance = min(minDistance, segmentLength + pct * (radius + edgeWidth));
            mb += metaballFunc(pos, uv, metaballRadius * pct);
        }
        finalFactor += smoothstep(radius + edgeWidth, radius, minDistance);
    }
    finalFactor += smoothstep(mb + .04, mb, metaballThreshold);
    
    glFragColor = vec4(min(finalFactor, 1.) * color,1.0);
}
