#version 420

// original https://www.shadertoy.com/view/Xl3XWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 mouse2 = vec2(cos(time*0.1), sin(time*0.1)) + (-resolution.xy + 2.0*mouse*resolution.xy.xy)/resolution.y; 

vec3 formula(vec2 p) {
    p*= 0.3;
    p += mouse2;
    vec3 col = vec3(100.0);
    for(int i = 0; i< 4; i++) {
        p = 2.0*clamp(p, -0.5, 0.5) - p;
        p *= clamp(1.0/dot(p, p), 1.0, 1.0/0.02);
        float a = 0.0;
        p *= mat2(cos(a), sin(a), -sin(a),cos(a));
        col = min(col, vec3(length(sin(p)), abs(p)));
    }

    return col;
}

vec3 gs = vec3(0.21, 0.72, 0.07);

vec3 bump(vec2 p, float e) {
    vec2 h = vec2(e, 0.0);
    mat3 m = mat3(
        formula(p + h) - formula(p - h),
        formula(p + h.yx) - formula(p - h.yx),
        -0.3*gs);
    
    vec3 g = (gs*m)/e;
    
    return normalize(g);
}

float edge(vec2 p, float e) {
    vec2 h = vec2(e, 0.0);
    float d = dot(gs, formula(p));
    vec3 n1 = gs*mat3(formula(p + h.xy), formula(p + h.yx), vec3(0));
    vec3 n2 = gs*mat3(formula(p - h.xy), formula(p - h.yx), vec3(0));
    
    vec3 vv = abs(d - 0.5*(n1 + n2));
    float v = min(1.0, pow(vv.x+vv.y+vv.z, 0.55)*1.0);
    
    return v;
}

void main(void) {
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    
    vec3 rd = normalize(vec3(p, 1.0));
    //rd = normalize(rd - vec3(mouse, 0.0));
    
    vec3 sn = bump(p, 0.02);
    vec3 re = reflect(rd, sn);
    vec3 col = vec3(0);
    
    col += 0.5*clamp(dot(-rd,sn), 0.0, 1.0);
    col += 0.3*pow(clamp(1.0 + dot(rd, sn), 0.0, 1.0), 8.0);
    col *= formula(p);
    col += pow(clamp(dot(-rd, re), 0.0, 1.0), 8.0)*(8.0*formula(p));
    
    col *= edge(p, 0.01);
    
    col = 
    col = pow(col, vec3(1.0/2.2));
    glFragColor = vec4(col, 1);
}
