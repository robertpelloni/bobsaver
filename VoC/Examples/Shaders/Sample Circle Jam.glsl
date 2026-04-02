#version 420

// original https://www.shadertoy.com/view/ttX3zS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float holegrid(vec2 pos, float ang, float zoom, vec2 delta) {
    
    vec2 tr1 = vec2(cos(ang), -sin(ang));
    vec2 tr2 = vec2(sin(ang), cos(ang));
    pos *= zoom;
    pos += delta;
    pos = vec2(
        pos.x * tr1.x + pos.y * tr1.y,
        pos.x * tr2.x + pos.y * tr2.y
    );
    //pos.y *= (1.0 + pos.y * pos.y * 0.03);
    float dt = max(0.0, fract(time) * 2.0 - 1.0);
    int row = int(floor(pos.y + 0.5));
    int isRowZero = 1- min(row*row, 1);
    float dt2 = max(0.0, fract(time + 0.5) * 2.0 - 1.0);
    int col = int(floor(pos.x + 0.5));
    int isColZero = 1- min(col*col, 1);
    pos.x += float(isRowZero) * dt;
    pos.y += float(isColZero) * dt2;
    // Time varying pixel color
    pos = mod(pos + 0.5, 1.0) -0.5;
    float d = length(pos);
    return 1.0-floor(clamp(d* 6.0 - 1.9, 0.0, 1.0));
}
vec3 calc(vec2 pos) {
    float completion = 6.283185307179586 * time / 15.0;
    float ang = completion;
    float zoom = 3.0;
    vec2 delta = vec2(cos(completion), sin(completion));
    float d = holegrid(pos, ang, zoom, delta);
    vec3 col1 = vec3(d, d, d);
    
    float ang2 = completion / 4.0;
    float zoom2 = 12.0 + sin(completion);
    vec2 delta2 = vec2(0.0, 0.0);
    float d2 = holegrid(pos, ang2, zoom2, delta2);
    vec3 col2 = vec3(1.0, d2, d2);
    return min(col1, col2);
}

vec2 pixelToLocal(vec2 pos) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = pos/resolution.xy - 0.5;
    uv.y = uv.y * resolution.y / resolution.x;
    return uv;
}

void main(void)
{
    vec3 col = vec3(0,0,0);
    for (int dy = 0; dy < 4; dy++) {
        
        for (int dx = 0; dx < 4; dx++) {
            vec2 delta = vec2(float(dx)/4.0, float(dy)/4.0);
            vec2 uv = pixelToLocal(gl_FragCoord.xy+delta);
                
            col += calc(uv);
        }
    }
    glFragColor = vec4(col / 16.0, 1.0);
}
