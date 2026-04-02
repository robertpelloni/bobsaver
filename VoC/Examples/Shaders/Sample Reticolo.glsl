#version 420

// original https://www.shadertoy.com/view/Wtt3WM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// restituisce le coordinate di p modulari tra -interval/2 e +interval/2 
vec2 onRep(vec2 p, float interval) {
    return mod(p, interval) - interval * 0.5;
}

float barDist(vec2 p, float interval, float width) {
    return length(max(abs(onRep(p, interval)) - width, 0.0));
}

float cubeDist(vec3 p, float interval, float width) {
    return length(max(abs(mod(p, interval) - interval * 0.5) - width, 0.0));
}

float sphereDist(vec3 p, float interval, float width) {
    return length(0.5 * interval - abs(mod(p + vec3(0, 0, 3.0 * time), interval) - interval * 0.5)) - width;
}

vec3 rotate(vec3 p, float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

// distance estimator
float sceneDist(vec3 p) {
    float bar_x = barDist(p.yz, 0.5, 0.0125);
    float bar_y = barDist(p.xz, 0.5, 0.0125);
    float bar_z = barDist(p.xy, 0.5, 0.0125);
    return min(min(min(bar_x, bar_y), bar_z), min(cubeDist(p, 0.5, 0.0375), sphereDist(p, 1.0, 0.05)));
}

vec3 lerp(vec3 a, vec3 b, float f) {
    return a + f * (b - a);
}

// ----------------------------------------------------------------------------------------------------------------------------

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
//    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p = ( gl_FragCoord.xy * 2. - resolution.xy ) / min(resolution.x, resolution.y);
    vec3 cameraPos = vec3(0.25 * time + 0.5, 0.125 * time, 0.25 * time + 0.125);

    vec2 a = 0.8 * p;
    vec3 rayDirection = normalize(vec3(sin(a.x) * cos(a.y), sin(a.y), cos(a.x) * cos(a.y)));

    rayDirection = rotate(rayDirection, 0.5 * time, vec3(0., 0., 1.));
    rayDirection = rotate(rayDirection, 0.5 * time, vec3(0., 1., 0.));

    float depth = 0.0;
   
    vec3 col = vec3(0.8, 0.9, 1.0);

    // ray marching
    for (int i = 0; i < 99; i++) {
        vec3 rayPos = cameraPos + rayDirection * depth;
        float dist = sceneDist(rayPos);
        if (dist < 0.0001) {
            col = vec3(1.0, 0.9, 0.7) * (0.2 + 0.01 * float(i));
            col = lerp(col, vec3(0.8, 0.9, 1.0), 0.01 * float(i));
            break;
        }
        depth += dist;
    }
    
    // effetto vignette
    vec2 sv = sin(gl_FragCoord.xy / resolution.xy * 3.141592);
    col = col * (0.5 + 0.5 * sv.x * sv.y);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
