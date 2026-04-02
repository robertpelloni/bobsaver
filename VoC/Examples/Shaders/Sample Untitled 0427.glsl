#version 420

// original https://www.shadertoy.com/view/WtfXzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 p){
    vec3 q = fract(p) * 2.0 - 1.0;
    return min(
        min(length(q.xz) - 0.25,length(q.xy) - 0.25)
        ,length(q.yz) - 0.25);
}

float trace (vec3 o, vec3 r){
    float t = 0.0;
    for(int i = 0; i < 32; ++i){
        vec3 p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    return t;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy /resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 r = normalize(vec3(uv,1.0));
    r.xy *= mat2(cos(time),sin(time),-sin(time),cos(time));
    vec3 o = vec3((cos((time) * 1.5* 3.14159265)+1.0) * 0.5
                  ,(sin((time) * 1.5* 3.14159265)+1.0) * 0.5
                  , time * 3.0);
    float t = trace(o,r);
    float fog = 1.0 / (1.0 + t * t * 0.1);
    vec3 fc = vec3(fog);

    // Output to screen
    glFragColor = vec4(fc,1.0);
}
