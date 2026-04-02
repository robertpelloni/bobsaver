#version 420

// original https://neort.io/art/bpfodmc3p9f4nmb8c290

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float hash(vec3 uv){
    return fract(43531.7252 * sin(dot(uv,vec3(12.5361,78.3516,127.315))));
}

float noise(vec3 uv){
    uv *= .5;
    uv.x *= 5.0;
    vec3 i = floor(uv);
    vec3 f = fract(uv);
    
    float a0 = hash(i + vec3(0.,0.,0.));
    float a1 = hash(i + vec3(1.,0.,0.));
    float a2 = hash(i + vec3(0.,1.,0.));
    float a3 = hash(i + vec3(1.,1.,0.));
    float a4 = hash(i + vec3(0.,0.,1.));
    float a5 = hash(i + vec3(1.,0.,1.));
    float a6 = hash(i + vec3(0.,1.,1.));
    float a7 = hash(i + vec3(1.,1.,1.));
    
    vec3 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(mix(a0,a1,u.x),mix(a2,a3,u.x),u.y),
           mix(mix(a4,a5,u.x),mix(a6,a7,u.x),u.y),u.z);
}

float fbm(vec3 uv){
    float a = 0.5;
    float f = 2.0;
    float c = 0.0;
    for(int i = 0; i < 3;i++){
        c += noise(uv) * a;
        a *= 0.3;
        uv *= 2.0;
    }
    return c;
}

const float sqrt3 = 1.73205080757;

float tex(vec2 uv){
    // uv *= 4.0;
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float c = step(f.y - f.x,0.0);
    
    float co = noise(vec3(i,c) + time * 0.1);
    
    return co;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    // vec2 p = uv;
    uv += time * 0.1;
    uv.y *= 2.0/sqrt3;
    uv.x += uv.y * 0.5;
    vec2 uv2 = uv;
    uv *= 4.0;
    
    float co = tex(uv);
    float cosh = tex(uv + vec2(0.1,0.1));// - co;
    cosh = clamp(cosh,0.0,1.0);
    
    vec3 color = co > 0.3 ? co > 0.7 ? vec3(.5,0.0,0.0) : vec3(1.0) : vec3(0.0,0.05,0.1);
    cosh = cosh > 0.3 ? cosh > 0.7 ? 1.0 : 0.0 : 1.0;
    color -= co > 0.3 ? co > 0.7 ? 0.0 : cosh * 0.1 : 0.0;
    
    // color *= mix(0.5,1.0,clamp(p.y*4.0 + 2.0,0.0,1.0));
    
    glFragColor = vec4(color,1.0);
}
