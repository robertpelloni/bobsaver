#version 420

// original https://www.shadertoy.com/view/flfGW8

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

void main(void) {
    float n = 2.0;
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 uvp = gl_FragCoord.xy/resolution.xy;
    uv += 0.75*noise(uv*3.0+time/2.0+noise(uv*7.0-time/3.0)/2.0)/2.0;
    float grid = (mod(floor((uvp.x)*resolution.x/n),2.0)==0.0?1.0:0.0)*(mod(floor((uvp.y)*resolution.y/n),2.0)==0.0?1.0:0.0);
    //float grid = (mod(mod(floor((uvp.y)*resolution.y/n),2.0)+floor((uvp.x)*resolution.x/n),2.0)==0.0?1.0:0.0);
    vec3 col = mix(vec3(0), vec3(0.2, 0.4, 1), 5.0*vec3(pow(1.0-noise(uv*4.0-vec2(0.0, time/2.0)),5.0)));
    col *= grid;
    col = pow(col, vec3(1.0/2.2));
    glFragColor = vec4(col,1.0);
}
