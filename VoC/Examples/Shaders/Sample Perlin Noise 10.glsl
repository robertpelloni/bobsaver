#version 420

// original https://www.shadertoy.com/view/wlKfDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float prand(vec2 uv) {
    return fract(sin(dot(mod(uv,153.789),vec2(12.9898,78.233)))*43758.5453) - 0.5;
}

float fprand(vec2 uv, float f){
    vec2 sp = uv*f;
    vec2 isp = floor(sp);
    vec2 fsp = fract(sp);
    
    float a = prand(isp+0.5);
    float b = prand(isp+0.5+vec2(1.0,0.0));
    float c = prand(isp+0.5+vec2(0.0,1.0));    
    float d = prand(isp+0.5+vec2(1.0,1.0));
    float wx = smoothstep(0.0, 1.0, fsp.x);
    float wy = smoothstep(0.0, 1.0, fsp.y);
    return mix(mix(a,b,wx), mix(c,d,wx), wy);
    
}

float perlin(vec2 uv, int octaves, float f0, float fmul, float v0, float vmul){
    float val = 0.0;
    float frq = f0;
    float wei = v0;
    float time = mod(time, 1000.0);
    vec2 wind = vec2(0.15, -1.0)*0.005;
    
    for (int i=0; i<octaves; i++) {
        val += wei * fprand(uv+wind*float(i)*time, frq);
        frq *= fmul;
        wei *= vmul;
    }
    
    return val;
}

float pdef(vec2 uv) {
    return perlin(uv, 11, 0.65, 1.6, 1.0, 0.65);
}

float warped(vec2 uv) {
    return pdef(uv+vec2(pdef(uv+pdef(uv)), pdef(uv+pdef(uv+3.145)+1.25)));
}

vec4[3] cols = vec4[3](
        vec4(0.25,0.015,0.01,1.0),
        vec4(0.95,0.75,0.1,1.0),
        vec4(1.0,1.0,1.0,1.0)
    );

vec4 getCol(float col) {
    float lf = float(cols.length()-1);
    float ci = floor(col * lf);
    int cii = int(ci);
    return mix(cols[cii], cols[cii+1], smoothstep(0.0, 1.0, fract(col*lf)));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/max(resolution.x, resolution.y);
    
    float t = mod(time, 1000.0);
    float tm = 10.0;
    float mt = mod(t, tm);
   
    vec4 col1 = getCol(abs(warped(uv+(t-mt))));
    vec4 col2 = getCol(abs(warped(uv+(t+tm-mt))));
    
    glFragColor = mix(col1, col2, smoothstep(0.0,1.0,mt/tm));
    
}
