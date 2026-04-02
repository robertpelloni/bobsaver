#version 420

// original https://www.shadertoy.com/view/WtVfDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define corner 6.0
const vec3 diffColor = vec3(0.5, 0.8, 1.0);
const vec3 specColor = vec3(0.7, 0.8, 0.8);
const vec3 baseColor = vec3(0.2,0.5,0.8);

float spire(vec2 p, float num) {
    float a = atan(p.y, p.x);
    float l = log(length(p)) * 16.0 - time * 2.0;

    return sin(cos(a * num) * 0.5 + a + l) * 0.5 + 0.5;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 rd = normalize(vec3(uv, 1.0));
    
    float rotTime = 0.1 * time;
    uv *= mat2(cos(rotTime), sin(rotTime), -sin(rotTime), cos(rotTime));

    float a = atan(uv.y, uv.x) * 4.0 + time;
    vec3 lp = vec3(cos(a), sin(a), -1);
    float e = 1./ resolution.y;
    
    float f = spire(uv, corner);
    float fx = (spire(uv - vec2(e, 0.0), corner) - f);
    float fy = (spire(uv - vec2(0.0, e), corner) - f);
    
    vec3 n = normalize(vec3(fx, fy, -1.));
    vec3 ld = lp - vec3(uv, 0.0);
    
    float len = max(length(ld), 0.01);
    ld /= len;
    float atten = (f * f) / len;

    float diff = max(dot(n, ld), 0.);  
    float spec = pow(max(dot( reflect(-ld, n), -rd), 0.), 2.); 

    vec3 color =  baseColor * vec3(2.0 * f * f- f);
    color = smoothstep(0.05, 0.75, pow(color * color, specColor));
    color = (color * 2.0 + diff * diffColor + spec) * atten;
    
    glFragColor = vec4(sqrt(color), 1.0);
}
