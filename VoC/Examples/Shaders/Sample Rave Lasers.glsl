#version 420

// original https://www.shadertoy.com/view/7tBSR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.543,514.123)))*4732.12);
}

float noise(vec2 p) {
    vec2 f = smoothstep(0.0, 1.0, fract(p));
    vec2 i = floor(p);
    float a = rand(i);
    float b = rand(i+vec2(1.0,0.0));
    float c = rand(i+vec2(0.0,1.0));
    float d = rand(i+vec2(1.0,1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    
}

float fbm(vec2 p) {
    float a = 0.5;
    float r = 0.0;
    for (int i = 0; i < 8; i++) {
        r += a*noise(p);
        a *= 0.5;
        p *= 2.0;
    }
    return r;
}

float laser(vec2 p, float s) {
    float r = atan(p.x, p.y);
    float l = length(p);
    float sn = sin(r*s+time);
    return pow(0.5+0.5*sn,5.0)+pow(clamp(sn, 0.0, 1.0),100.0);
}

float clouds(vec2 uv) {
    float c1 = fbm(fbm(uv*3.0)*0.75+uv*3.0+vec2(0.0, + time/3.0));
    float c2 = fbm(fbm(uv*2.0)*0.5+uv*7.0+vec2(0.0, + time/3.0));
    float c3 = pow(fbm(fbm(uv*10.0-vec2(0.0, time))*0.75+uv*5.0+vec2(0.0, + time/6.0)), 2.0);
    return pow(mix(c1, c2, c3),2.0);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 hs = resolution.xy/resolution.y*0.5;
    vec2 uvc = uv-hs;
    float ls = (1.0+3.0*noise(vec2(15.0-time)))*laser(vec2(uv.x+0.5, uv.y*(0.5+10.0*noise(vec2(time/5.0)))+0.1), 15.0);
    ls += fbm(vec2(2.0*time))*laser(vec2(hs.x-uvc.x-0.2, uv.y+0.1), 25.0);
    ls += noise(vec2(time-73.0))*laser(vec2(uvc.x, 1.0-uv.y+0.5), 30.0);
    vec4 col = vec4(0, 1, 0, 1)*((uv.y*ls+pow(uv.y,2.0))*clouds(uv));
    glFragColor = pow(col, vec4(0.75));
}
