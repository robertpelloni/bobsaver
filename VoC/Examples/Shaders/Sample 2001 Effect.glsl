#version 420

// original https://www.shadertoy.com/view/NdByzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926

float normSin(float x) {
    return sin(x) * 0.5 + 0.5;
}

vec3 toACES(vec3 rgb) {
    mat3 m = mat3(
        0.612494, 0.338737, 0.048856,
        0.070594, 0.917671, 0.011704,
        0.020727, 0.106882, 0.872338
    );
    return rgb * m;
}

vec3 smoothColor(float y, float offset){
    return vec3(
        normSin(time * 5.0) * fract(sin(dot(vec2(y, offset), vec2(12.9898, 78.233))) * 43758.5453),
        normSin(time * 5.0 + 0.67 * PI) * fract(sin(dot(vec2(y + 1.0, offset + 1.0), vec2(12.9898, 78.233))) * 43758.5453),
        normSin(time * 5.0 + 1.33 * PI) * fract(sin(dot(vec2(y + 2.0, offset + 2.0), vec2(12.9898, 78.233))) * 43758.5453)
    );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.x + vec2(0.0, (resolution.x - resolution.y) / (2.0 * resolution.x));

    vec3 dots;
    
    vec2 mLocal = mouse*resolution.xy.xy / resolution.xy;
    if(mLocal.x < 0.01) {
        mLocal.x = 0.5;
    }
    
    for(float i = -0.5; i < 0.5; i+= 0.02) {
        for(float offset = 0.0; offset < 0.99; offset += 0.05) {
            float dt = fract(time * 0.5 + offset);
            vec2 dotPos = vec2(mLocal.x + dt * dt * (1.1 - mLocal.x), 0.5 + i * 0.4 + i * dt * dt * 3.0);
            float brightness = 0.016 * dt;
            float flash = brightness / distance(dotPos, uv);
            dots += min(smoothColor(i, offset) * flash * flash, 3.0);
            
            dotPos = vec2(mLocal.x - dt * dt * (mLocal.x + 0.1), 0.5 + i * 0.4 + i * dt * dt * 3.0);
            brightness = 0.016 * dt;
            flash = brightness / distance(dotPos, uv);
            dots += min(smoothColor(i, offset) * flash * flash, 3.0);
        }
    }
    
    dots *= sqrt(abs(uv.x - mLocal.x));
    dots = toACES(dots);
    // Output to screen
    glFragColor = vec4(dots,1.0);
}
