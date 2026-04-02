#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fractal_Cube.glsl

void fold(inout vec2 p) {
     p.xy = abs(-p.yx);
     p.yx -= abs(sin(p.y*2.)*.1);
     ///p.xy -= abs(sin(p.x*2.2)*.1);
}

void rotate(inout vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);
    
    p = mat2(c, -s, s, c)*p;
}

float len(vec3 p, float l) {
    p = pow(abs(p), vec3(l));
    return pow(p.x + p.y + abs(p.z), .9992/l);
}

vec4 orb;

float map(vec3 p) {
    float d = 20.0;
    orb = vec4(1000.0);
    for(int i = 0; i < 9; i++) {
        rotate(p.xz, time*0.01);
        rotate(p.xy, time*0.2);
        rotate(p.zy, time*0.1);
        
        fold((p.xy));
        fold((p.xz));
        fold((p.yz));
        fold((p.yx));
        
        p = 2.0*p - 2.0;
        
        d = min(d, (len(p*11.5, 5.1))*pow(2.90, -float(i)));
        orb.x = min(orb.x, length(p.xy));
        orb.y = min(orb.y, length(p.zy));
        orb.z = min(orb.z, length(p.xz));
        orb.w = d;
    }
    
    return d - 0.02;
}

float march(vec3 ro, vec3 rd) 
{
    float t = 0.0;
    for(int i = 0; i < 40; i++) 
    {
        float d = map(ro + rd*t);
        if(d < 0.00001*t || t >= 10.0) break;
        t += d*(0.1 + 0.05*t);
    }
    return t;
}

vec3 normal(vec3 p) 
{
    vec2 h = vec2(0.001, 0.0);
    vec3 n = vec3(
        map(p + h.xyy) - map(p - h.xyy),
        map(p - h.yxy) - map(p + h.yxy),
        map(p + h.yyx) - map(p - h.yyx));
    return normalize(n);
}

void main( void ) 
{
    vec2 uv = (0.3+mouse.y)*(-0.5 + (gl_FragCoord.xy/resolution));
    uv.x *= resolution.x/resolution.y;
    
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 0, -9);
    vec3 rd = normalize(vec3(uv, 1.52));
    
    float i = march(ro, rd);
    if (i < 10.0) 
    {
        vec3 pos = ro + rd*i;
        vec3 nor = normal(pos);
        
        vec3 key = normalize(vec3(0.8, 0.7, -0.6));
        
        col  = 0.52*vec3(1);
        col += 0.7*clamp(dot(key, nor), 0.30, 1.0);
        
        vec3 mat = mix(vec3(1.3), vec3(1, 0.62, 0.02), orb.x);
        mat = mix(mat, vec3(0.2, 1, 0.2), orb.y*0.2);
        mat = mix(mat, vec3(0.2, 0.4, 1), 0.3 - orb.z*0.2);
        
        col *= mat*clamp(0.9 - orb.w, 0.0, 1.0);
        
    }
    
    glFragColor = vec4(col, 1);
}
