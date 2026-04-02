#version 420

// original https://www.shadertoy.com/view/Ms2BWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float df(vec3 p) {
    p = abs(p);
    p = mod(p, 4.0) - vec3(2.0);
    int n = 0;
    while(n < 10) {
        if(p.x + p.y < 0.0) p.xy = -p.yx;
        if(p.x + p.z < 0.0) p.xz = -p.zx;
        if(p.y + p.z < 0.0) p.yz = -p.yz;
        p = p*2.0 - (2.0 - 1.0)*vec3(1.5);
        p = p*vec3(-0.5, 1, 1);
        n++;
    }
    return length(p)*pow(2.0, -float(n));
}

const int maxStep = 50;
int trace(vec3 from, vec3 rayDir) {
    float t = 0.0;
    for(int i = 0; i < maxStep; i++) {
        vec3 p = from + t*rayDir;
        float d = df(p);
        if(d < 0.003) {
            return i;
        }
        t += d*0.9;
    }
    return maxStep;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy/2.0)/resolution.y;
    
    vec3 camPos = vec3(0, 0, -3.0 + time*0.5);
    vec3 camFront = vec3(0, 0, 1);
    vec3 camRight = vec3(1, 0, 0);
    vec3 camUp = cross(camRight, camFront);
    vec3 rayDir = 0.5*camFront + uv.x*camRight + uv.y*camUp;
    
    int i = trace(camPos, rayDir);
    vec3 color = (1.0 - float(i)/float(maxStep)) * vec3(1);
    
    glFragColor = vec4(color,1.0);
}
