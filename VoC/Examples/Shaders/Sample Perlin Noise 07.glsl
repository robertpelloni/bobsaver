#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(float x, float y) {
    return fract(abs(sin(sin(123.321+x) * (y+321.123)) * 456.654));
}

float lerp(float a, float b, float t) {
    return a*(1.0-t) + b*t;
}

float perlin(float x, float y) {
    float col = 0.0;
    for (int i = 0; i < 8; i++) {
        float fx = floor(x);
        float fy = floor(y);
        float cx = ceil(x);
        float cy = ceil(y);
        float a = hash(fx, fy);
        float b = hash(fx, cy);
        float c = hash(cx, fy);
        float d = hash(cx, cy);
        col += lerp(lerp(a, b, fract(y)), lerp(c, d, fract(y)), fract(x));
        col /= 2.0;
        x /= 2.0;
        y /= 2.0;
    }
    return col;
}

float dperlin(float x, float y) {
    float d = perlin(x, y)*800.0;
    return perlin(x + d, y + d);
}

float ddperlin(float x, float y) {
    float d = perlin(x, y)*800.0;
    return dperlin(x + d, y + d);
}

void main( void ) {
    vec2 mouse = vec2(sin(time*0.1247785),cos(time*0.25688))*0.2;
    vec2 p = ( gl_FragCoord.xy / resolution.xy ) - mouse;
    
    p *= 800.0;
    
    float d = perlin(p.x, p.y)*800.0;
    float u = p.x + d;
    float v = p.y + d;
    d = perlin(u, v)*800.0;
    float color = perlin(p.x + d, p.y + d);
        
    glFragColor = vec4( vec3( color*2.0, color*1.5 - sin(u/40.0) * .1, sin(v/40.0)*.5 - .2 ), 1.0 );

}
