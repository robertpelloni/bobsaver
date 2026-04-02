#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265

vec3 bary(vec3 a, vec3 b, vec3 c, vec2 p) {
    vec2 v0 = b.xy - a.xy, v1 = c.xy - a.xy, v2 = p - a.xy;
    float inv_denom = 1.0 / (v0.x * v1.y - v1.x * v0.y);
    float v = (v2.x * v1.y - v1.x * v2.y) * inv_denom;
    float w = (v0.x * v2.y - v2.x * v0.y) * inv_denom;
    float u = 1.0 - v - w;
    vec3 bc = abs(vec3(u,v,w));
    if (bc.x + bc.y + bc.z > 1.00009) {
        return vec3(0.0);
    } else {
        return bc;
    }
}

float drawLine (vec3 p1, vec3 p2, vec2 uv, float a) {
    float one_px = 1.0 / resolution.x;
    float d = distance(p1.xy, p2.xy);
    float d_uv = distance(p1.xy, uv);
    float r = 1.0-floor(1.0-(a*one_px)+ distance(mix(p1.xy, p2.xy, clamp(d_uv/d, 0.0, 1.0)), uv));
    return r;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float obj_x = time - resolution.x;
    float str = 1.0;
    
    vec3 p1 = vec3(0.5 + sin(obj_x)       *0.2, 0.25 + cos(obj_x+PI)    *0.1, 0.5 + sin(obj_x));
    vec3 p3 = vec3(0.5 + sin(obj_x+PI)    *0.2, 0.25 + cos(obj_x)       *0.1, 0.5 + sin(obj_x+PI));
    vec3 p2 = vec3(0.5 + sin(obj_x+PI/2.0)*0.2, 0.25 + cos(obj_x-0.5*PI)*0.1, 0.5 + sin(obj_x+PI/2.0)*0.2);
    vec3 p4 = vec3(0.5 + sin(obj_x-PI/2.0)*0.2, 0.25 + cos(obj_x+0.5*PI)*0.1, 0.5 + sin(obj_x-PI/2.0)*0.2);
    vec3 p5 = vec3(0.5 , 0.75, 0.0);

    float lines = drawLine(p1, p2, uv, str)
            + drawLine(p2, p3, uv, str)
            + drawLine(p3, p4, uv, str)
            + drawLine(p4, p1, uv, str)
            + drawLine(p5, p1, uv, str)
            + drawLine(p5, p2, uv, str)
            + drawLine(p5, p3, uv, str)
            + drawLine(p5, p4, uv, str);
    
    vec3 bc1 = bary(p1, p2, p5, uv);
    vec3 bc2 = bary(p2, p3, p5, uv);
    vec3 bc3 = bary(p3, p4, p5, uv);
    vec3 bc4 = bary(p4, p1, p5, uv);
    vec3 bc5 = bary(p1, p2, p3, uv);
    vec3 bc6 = bary(p1, p4, p3, uv);
    
    glFragColor = vec4(bc1 + bc2 + bc3 + bc4 + bc5 + bc6 + lines, 1.0);
}
