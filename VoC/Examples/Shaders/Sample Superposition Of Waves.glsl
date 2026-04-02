#version 420

// original https://neort.io/art/c39vljk3p9f8s59beql0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI2 = acos(-1.)*2.;

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec2 n = vec2(0);
    
    float N = ceil(mod(time, 10.));
    for(float i = 0.; i < 10.; i++){
        if(i >= N){
            break;
        }
        float a = i / N * PI2;
        vec2 q = (uv - vec2(cos(a), sin(a)) * 0.6) * 50.;
        float R = length(q);
        float T = time * 10.;
        float c = 0.05;
        n += q * (sin(R - T) * c - cos(R - T)) * exp(-R * c) / R;
    }
    
    vec3 lightDir = normalize(vec3(-1, 2, 5));
    vec3 normal = normalize(vec3(n, 1));
    
    float s = max(dot(lightDir, normal), 0.);
    vec3 col = vec3(pow(s, 60.) + s * 0.7);

    glFragColor = vec4(col, 1.0);
}
