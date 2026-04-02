#version 420

// original https://www.shadertoy.com/view/MltSWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 point)
{
    vec3 q = fract(point) * 2.0 - 1.0;
    return length(q) - .25;
}

float trace(vec3 orgn, vec3 ray)
{
    float t = 0.0;
    for (int ndx = 0; ndx < 32; ndx++) {
        vec3 point = orgn + ray * t;
        float d = map(point);
        t += d * .5;
    }
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    float theta = time * .25;
    
    
    vec3 ray = normalize(vec3(uv, 1.0));
    ray.xz *= mat2(cos(theta), -sin(theta), sin(theta), cos(theta));
    ray *= mat3(.5 + abs(sin(theta)), 0.0, 0.0, 0.0, .5 + abs(cos(theta)), 0.0, 0.0, 0.0, abs(sin(theta)));
    
    
    vec3 orgn = vec3(0.0, 0.0, time);
    float trc = trace(orgn, ray);
    
    float fog = 1.0 / (1.0 + trc * trc * .1);
    
    vec3 fg = vec3(fog, fog, fog * 2.5);
    glFragColor = vec4(fg,1.0);
}
