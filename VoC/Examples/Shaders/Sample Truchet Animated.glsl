#version 420

// original https://www.shadertoy.com/view/tsVXDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float lineFromDistance(float dist, float size) {
    const float thickness = 2.0;
    return clamp((abs(dist - 0.5) * size) - (thickness - 1.0), 0.0, 1.0);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);
}

void main(void)
{
    const float size = 25.0;
    const float period = 2.0;
    
    //vec2 coord = gl_FragCoord.xy + vec2(0.0, time * -10.0);
    vec2 coord = gl_FragCoord.xy;

    vec2 pixCoord = floor(coord / size) * size;
    
    float time = time * rand(pixCoord);
    
    float blend = abs((mod(time, period) / period) - 0.5) * 2.0;
    
    float rand1 = rand(pixCoord + floor(time / period)) > 0.5 ? 1.0 : 0.0;
    float rand2 = rand(pixCoord + floor(((time + 99.9) + period * 0.5) / period)) > 0.5 ? 1.0 : 0.0;
    
    float randVal = mix(rand1, rand2, smoothstep(0.125, 0.875, blend));
    
    vec2 modcoord = mod(coord, size) / size;
    
    if (randVal > 0.5) {
        modcoord.x = 1.0 - modcoord.x;
    }
    
    float boxMix = 1.0 - (abs(randVal - 0.5) * 2.0);
    
    float box1 = lineFromDistance(sdBox(modcoord, vec2(boxMix * 0.5)) + (boxMix * 0.5), size);
    float box2 = lineFromDistance(sdBox(1.0 - modcoord, vec2(boxMix * 0.5)) + (boxMix * 0.5), size);
    
    vec3 outcolor = vec3(box1 * box2);

    // Output to screen
    glFragColor = vec4(outcolor, 1.0);
}
