#version 420

// original https://www.shadertoy.com/view/wtX3z4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898,78.233))) * 43758.5453123);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y; 
    vec2 scaleUv = uv * 25.0;
    
    float s = 2.0 * sin(time * 1.5);   
    float slideX = s * (floor(s * 0.5) + 1.0) * mix(-1.0, 1.0, mod(floor(scaleUv.y), 2.0));
    float slideY = s * -floor(s * 0.5) * mix(-1.0, 1.0, mod(floor(scaleUv.x), 2.0));
    scaleUv += vec2(slideX, slideY);
    
    vec2 flUv = floor(scaleUv);
    vec2 frUv = fract(scaleUv);
        
    float t = 5.0 * time + random(flUv) * 100.0;
    
    float center = 0.55 * length(uv) + 0.45;
    float sizeAnim = (1.0 - (sin(t) * 0.15 + 0.65)) * center;
    float mask = smoothstep(sizeAnim, sizeAnim - 0.05, distance(frUv, vec2(0.5)));
    
    float r = random(flUv);
    float g = random(flUv + 1.0);
    float b = random(flUv - 1.0);
    vec3 col = mask * vec3(r, g, b);
    glFragColor = vec4(col, 1.0);
}
