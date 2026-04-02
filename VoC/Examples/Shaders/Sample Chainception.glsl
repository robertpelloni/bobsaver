#version 420

// original https://www.shadertoy.com/view/MlBcD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rotnor(norm) mat2(norm.xy, vec2(-norm.y,norm.x))
#define rotang(spin) mat2(cos(spin),sin(spin),-sin(spin),cos(spin))
#define pi acos(-1.0)
#define chains 6.0
float torus(vec3 p, float r, float l) {
    
    return length(vec2(length(max(abs(p.xy)-vec2(0,l),vec2(0)))-r,p.z));
}

float torusring(vec3 p) {
    float len = 1e10;
    for (float i = 0.0; i < chains; i++) {
        float i2 = i+time;
        vec2 rot = vec2(cos(i2*pi*2.0/chains),sin(i2*pi*2.0/chains));
        
        vec3 p2 = p;
        p2 = p2 - vec3(rot,0)*3.0;
        p2.xy*=rotnor(rot);
        p2.xz*=rotang(i2*pi*0.5);
        len = min(len,torus(p2,0.5,1.5)-0.1);
    }
    return len;
}

float torusringintorusrings(vec3 p) {
    float len = 1e10;
    for (float i = 0.0; i < chains; i++) {
        float i2 = i+time;
        vec2 rot = vec2(cos(i2*pi*2.0/chains),sin(i2*pi*2.0/chains));
        
        vec3 p2 = p;
        p2 = p2 - vec3(rot,0)*4.0;
        p2.xy*=rotnor(rot);
        p2.xz*=rotang(i2*2.0);
        len = min(len,torusring(p2));
    }
    return len;
}

float map(vec3 p) {
    float len = torusringintorusrings(p);
    
    return len;
}

vec3 normal(vec3 p) {
    vec2 eps = vec2(0.01,0.0);
    
    return normalize(vec3(
        map(p+eps.xyy)-map(p-eps.xyy),
        map(p+eps.yxy)-map(p-eps.yxy),
        map(p+eps.yyx)-map(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec3 ro = vec3(1,0,-8);
    vec3 rd = normalize(vec3(uv,1));
    float dist = 0.0;
    
    bool hit = false;
    for (int i = 0; i < 100; i++) {
        float len = map(ro);
        
        if (len < 0.01 || dist > 20.0) {
            hit = len < 0.01;
            break;
        }
        
        dist += len;
        ro += rd*len;
    }
    if (hit)
    glFragColor = vec4(normal(ro)*0.5+0.5,1.0);
    else
    glFragColor = vec4(uv,sin(time)*0.5+0.5,1.0);
}
