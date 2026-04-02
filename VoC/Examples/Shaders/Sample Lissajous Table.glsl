#version 420

// original https://www.shadertoy.com/view/4lKcDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159;
const int steps = 200;

// from https://www.shadertoy.com/view/XdSGzh
vec2 lissajous(float t, float a, float b, float d) {
    return vec2(sin(a*t+d), sin(b*t));
}
float lissajous_dist(vec2 uv, float a, float b, float phase) {
    float d = phase;
    
    float m = 1.0;
    float period = 3.141*2.0;
    vec2 lp = lissajous(time, a, b, d)*0.8;
    for(int i = 1; i <= steps; i++) 
    {
        float t = float(i)*period / float(steps);
        t += time;
        vec2 p = lissajous(t, a, b, d)*0.8;
        
        // distance to line
        vec2 pa = uv - p;
        vec2 ba = lp - p;
        float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
        vec2 q = pa - ba*h;
        m = min( m, dot( q, q ) );
        
        lp = p;
    }
    m = sqrt( m );
    m = smoothstep(0.05, 0.0, m);
    
    return m;
}

void main(void) {
    float x_steps = floor(0*resolution.x * 0.02) + 8.0;
    float y_steps = floor(0*resolution.y * 0.02) + 5.0;
    
    vec2 uv = (gl_FragCoord.xy / resolution.xy);
    uv.x *= x_steps;
    uv.y *= y_steps;
    float aorig = floor(uv.x);
    float borig = y_steps - 1.0 - floor(uv.y);
    uv = mod(uv, 1.0);
    uv = (uv - 0.5) * 2.0;
    float m = 0.0;
    float fixphase = time * 0.2;
    float speedmult = 0.0;
    float ljtime = time;
    float a = aorig;
    float b = borig;
    if(a == 0.0 || b == 0.0) {
        ljtime *= max(a, b);
        a = 1.0;
        b = 1.0;
    }
    m = lissajous_dist(uv, a, b, fixphase);
    
    vec2 ljpos = lissajous(ljtime, a, b, fixphase) * 0.8;
    if(length(ljpos - uv) < 0.1) {
        glFragColor.rgb = vec3(1.0);
    }
    
    if(aorig != 0.0 && abs(ljpos.x - uv.x) < 0.03) {
        glFragColor.rgb = vec3(0.4);
    }
    
    if(borig != 0.0 && abs(ljpos.y - uv.y) < 0.03) {
        glFragColor.rgb = vec3(0.4);
    }
    
    vec4 curveColorA = mix(vec4(255.0, 127.0, 39.0, 0.0), vec4(128.0), aorig / (x_steps / 2.0));
    vec4 curveColorB = mix(vec4(128.0, 128.0, 255.0, 0.0), vec4(128.0), borig / (y_steps / 2.0));
    vec4 curveColor = (curveColorA + curveColorB) / (255.0 * 2.0);
    glFragColor = mix(glFragColor, curveColor, m);
    
    if(aorig == 0.0 && borig == 0.0) {
        glFragColor.rgb = vec3(0.0);   
    }    
}
