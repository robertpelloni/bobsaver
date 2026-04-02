#version 420

// original https://www.shadertoy.com/view/wllBW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rand (vec3 coord) {
    return fract(sin(vec3(
        dot(coord, vec3(127.1, 311.7, 123.456)), 
        dot(coord,vec3(269.5, 183.3, 123.456)), 
        dot(coord, vec3(8.1, 789.7, 31.456)))) * 43758.5453);
}

float minkowskiDistance(vec3 p1, vec3 p2, float power) {
    float d1 = pow(abs(p1.x - p2.x), power);
    float d2 = pow(abs(p1.y - p2.y), power);
    float d3 = pow(abs(p1.z - p2.z), power);
    return pow(d1 + d2 + d3, 1.0 / power);
}

float worley (vec3 coord) {
    
    vec3 i = floor(coord);
    vec3 f = fract(coord);
    
    float min_dist = 999999.0;
    
    for(float x = -1.0; x <= 1.0; x++) {
        for(float y = -1.0; y <= 1.0; y++) {
            for(float z = -1.0; z <= 1.0; z++) {            
                vec3 node = rand(i + vec3(x, y, z)) + vec3(x, y, z);
                float dist = minkowskiDistance(node, f, 0.5);                
                min_dist = min(min_dist, dist);                
            }            
        }
    }
    
    return min_dist;
    
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;    
    uv.x *= resolution.x/resolution.y;
    uv *= 10.0;
    float v = worley(vec3(uv, time));     
    glFragColor = vec4(1.0-vec3(v), 1.0);
}
