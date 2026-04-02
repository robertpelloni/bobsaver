#version 420

// original https://neort.io/art/brbrl9c3p9f04urh989g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define rep(a,b) mod(a,b) - b * 0.5

float sdCircle(vec2 p, float r){
    return length(p) - r;
}

float sdBox(vec2 p, vec2 s){
    vec2 d = abs(p) - s;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float smoothUnion(float d1, float d2, float k){
    float h = clamp(0.5 + 0.5 * (d2 - d1)/k ,0.0,1.0);
    return mix(d2,d1,h) - k * h * (1.0 - h);
}

float hash(vec2 uv){
    return fract(44363.5316 * sin(dot(uv,vec2(12.8989,72.588))));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    uv *=2.0;
    uv.y -= -0.8;
    // uv *= 0.5;
    vec2 p = uv;
    p.x += 0.5;
    vec2 p1 = uv * 0.5;
    vec2 p2 = uv;
    
    float o = sdBox(uv,vec2(10.0,.4));
    float o1 = sdBox(uv,vec2(10.0,.4));
    float o2 = sdBox(uv,vec2(10.0,.4));
    {
        vec2 i = floor(p);
        float h = hash(vec2(i.x));
        p.y -= time * 0.6 * (0.5 + h * 0.5);
        float hy = hash(vec2(floor(p.y)));
        p = rep(p,1.0);
        p.y += h * 0.25;
        float s = sdCircle(p,0.25);
        s = hy < 0.2 ? s : 1.0;
        o = smoothUnion(o,s,0.25);
    }
    
    {
        vec2 i1 = floor(p1/2.0);
        float h1 = hash(vec2(i1.x));
        p1.y -= time * 0.6 * (0.5 + h1 * 0.5);
        float hy1 = hash(vec2(floor(p1.y)));
        // p1.y += h1;
        p1.y -= 0.5;
        p1 = rep(p1,2.0);
        // p1.y -= -1.0;//h1 * 0.5;
        float s = sdCircle(p1,0.25);
        s = hy1 < 0.5 ? s : 1.0;
        o1 = smoothUnion(o1,s,0.125);
    }
    
    {
        vec2 i2 = floor(p2/8.0);
        float h2 = hash(vec2(i2.x));
        p2.y -= time * 0.6 * (0.5 + h2 * 0.5);
        float hy2 = hash(vec2(floor(p2.y)));
        p2 = rep(p2,8.0);
        p2.y += h2;
        // p2.x -= 1.4;
        float s = sdCircle(p2,1.0);
        // s = hy2 < 0.5 ? s : 1.0;
        o2 = smoothUnion(o1,s,0.125);
    }
    
    o = min(o,o1);
    o = min(o,o2);
    o = smoothstep(0.001,0.0,o);

    glFragColor = vec4(mix(vec3(0.0,0.4,0.9),vec3(1.0),o), 1.0);
}
