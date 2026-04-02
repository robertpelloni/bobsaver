#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void rot(inout vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);
    
    p = mat2(c, s, -s, c)*p;
}

float form(vec2 p) {
    p *= 0.7;

    for(int i = 0; i < 6; i++) {
        p = abs(p)/clamp(dot(p*0.5, p), 0.4 , 1.0) - vec2(0.4);
        rot(p, 3.141*cos(0.3*time));
        p *= 0.8 + 0.1*sin(time);
    }
    
    return length(p);
}

vec3 bump(vec2 p) {
    vec2 h = vec2(0.003, 0.0);
    
    return normalize(vec3(
        form(p + h.xy) - form(p - h.xy),
        form(p + h.yx) - form(p - h.yx),
        -1.0));
}

vec3 render(vec2 p) {
    vec3 rd = normalize(vec3(p, 2.2));
    vec3 nor = bump(p);
    
    vec3 ref = reflect(rd, nor);
    vec3 col = vec3(pow(clamp(dot(ref, nor), 0.0, 1.0), 25.0));
    
    return col;
}

void main( void ) {
    vec2 p = (-resolution + 2.0*gl_FragCoord.xy)/resolution.y;
    
    vec3 col = vec3(1);
    float d = form(p);
    
    col = mix(vec3(0.2, 0.4, 2.2), vec3(0.4, 0.7, 0.2), smoothstep(0.39, 0.4, d));
    col = mix(col, vec3(0.24, 0.0, 0.4), smoothstep(0.3, 1.0, d*d));
    col *= render(p);
    
    col = pow(abs(col), vec3(1.0/2.2));
    glFragColor = vec4(col, 1);
}
