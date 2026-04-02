#version 420

// original https://neort.io/art/c1jkhsc3p9f8fetmvhd0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 hsv2rgb(float h, float s, float v){
    vec3 rgb = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return v * mix(vec3(1.0), rgb, s);
}

float random(vec2 v) { 
    return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

float random(float n){
    return fract(sin(n * 222.222) * 2222.55);
}

mat2 rotate(float angle){
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

float sdLine(vec2 p, vec2 a, vec2 b){
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*t);
}

float sdOrb(vec2 uv, vec2 p, float r){
    // return r / length(uv-p);
    vec2 m = (uv-p)*50.0;
    return r / dot(m, m);
}

vec3 dots(vec2 uv){
    vec3 color = vec3(0.0);

    for(float i = 0.0; i <= 20.0; i+=1.0){
        vec2 n1 = vec2(random(vec2(i+100.0)), random(vec2(i*10.0)));
        vec2 p1 = sin(n1*time);
        for(float j = 0.0; j <= 20.0; j+=1.0){
            vec2 n2 = vec2(random(vec2(j+100.0)), random(vec2(j*10.0)));
            vec2 p2 = sin(n2*time);

            color += 0.0003 / sdLine(uv, p1, p2) * hsv2rgb(random(vec2(i+22.0)), 1.0, 1.0);
        }
        float a = random(i+random(i))*200.0*random(i);
        color += sdOrb(uv, p1, 1.522+sin(a*a*a+time*6.0));
    }

    return color;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    color += dots(uv);

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
