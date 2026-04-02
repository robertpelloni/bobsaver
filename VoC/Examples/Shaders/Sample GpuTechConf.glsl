#version 420

// original https://www.shadertoy.com/view/lsSSW1

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float map(in vec3 p) {
    
    vec3 q = mod(p+2.0, 4.0)-2.0;
    
     float d1 = length(q) - 1.0;
    
    d1 += 0.1*sin(10.0*p.x)*sin(10.0*p.y + time )*sin(10.0*p.z);
    
     float d2 = p.y + 1.0;
    
    float k = 1.0;
    float h = clamp(0.5 + 0.5 *(d1-d2)/k, 0.0, 1.0);
        
    return mix(d1, d2, h) - k*h*(1.0-h);
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(0.0001, 0.0);
     
    return normalize(vec3( map(p+e.xyy) - map(p-e.xyy),
                           map(p+e.yxy) - map(p-e.yxy),
                           map(p+e.xyx) - map(p-e.xyx)));
    
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * uv;
    
    p.x *= resolution.x / resolution.y;
    
    vec3 ro = vec3(0.0, 0.0, 2.0);
    vec3 rd = normalize(vec3(p, -1.0));
    
    vec3 col = vec3(0.0);
    
    float tmax = 20.0;
    float h = 1.0;
    float t = 0.0;
    for (int i=0; i<100; i++) {
        
        if (h < 0.0001 || t > tmax) break;
        
        h = map(ro + t*rd);   
        t += h;
    }
    
    vec3 lig = vec3(0.5773);
    
    if (t<tmax) {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);
        col = vec3(1.0);
        col = vec3(1.0, 0.8, 0.5)*clamp(dot(nor, lig), 0.0, 1.0);
        col += vec3(0.2, 0.3, 0.4)*clamp(nor.y, 0.0, 1.0);
        col += 0.1;
        col *= exp(-0.1*t);
    }
    
    glFragColor = vec4(col, 1.0);
}
