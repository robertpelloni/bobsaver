#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

void main() {
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec3 col = vec3(0.);
        
    vec3 ro = vec3(0, 0, -3);
    vec3 rd = vec3(uv, 1);
    vec3 p = vec3(0);
    
    float t = 0.0;
    for (int i = 0; i < 128; i++) {
        p = ro + rd * t;
        

        p.xz *= rotate(time / 2.);    
        p.z = mod(p.z, 2.0) - 1.0;
        
        // hex shaping
        vec2 _p = abs(p.xy);
        float d = dot(_p, vec2(0.5, 0.86));
        d = max(d, _p.x);
        d = abs(d) - 1.;
        d = length(vec2(d, p.z)) - 0.1;
        
        t += 0.5 * d;
        
    }
    
    col += 1.0 / (1.0 + t * t * 0.25);
    
    glFragColor = vec4(col, 1.);
}
