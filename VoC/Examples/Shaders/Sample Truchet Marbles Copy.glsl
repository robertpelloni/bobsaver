#version 420

// original https://www.shadertoy.com/view/llSyRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(1031, .1030, .0973, .1099)

//hash function by Dave_Hoskins https://www.shadertoy.com/view/4djSRW
vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

float torus(vec3 p, vec2 r) {
    return length(vec2(abs(abs(length(p.xy)-r.x)-0.1),abs(p.z)-0.1))-r.y;
}

float square(vec3 p, vec2 r) {
    return length(vec2(abs(max(abs(p.x),abs(p.y))-r.x),p.z))-r.y;
}

float map(vec3 p) {
    
    vec3 p2 = mod(p,2.0)-1.0;
    vec3 floorpos = floor(p*0.5);
    float len = 1e10;
    
    vec3 orientation = floor(hash33(floorpos)+0.5)*2.0-1.0;
    
    vec3 p3 = p2*orientation;
    mat3 truchet = mat3(
        vec3(p3.yz*vec2( 1.0, 1.0)+vec2(-1.0,-1.0),p3.x),
        vec3(p3.zx*vec2( 1.0, 1.0)+vec2( 1.0, 1.0),p3.y),
        vec3(p3.yx*vec2( 1.0,-1.0)+vec2( 1.0, 1.0),p3.z)
    );
    
    
    
    vec3 lens = vec3(
        torus(truchet[0],vec2(1.0,0.02)),
        torus(truchet[1],vec2(1.0,0.02)),
        torus(truchet[2],vec2(1.0,0.02))
    );
    vec3 mask = vec3(lessThan(lens,min(lens.yzx,lens.zxy)));
    
    vec3 p4 = truchet[int(dot(mask,vec3(0,1,2)))];
    
    
    
    float dir = (mod(dot(floorpos,vec3(1.0)),2.0)*2.0-1.0);//*dot(mask,vec3(-1.0,1.0,-1.0));
    
    p4 = vec3(fract(dir*(atan(p4.x,p4.y)/6.28*4.0)+time*0.5)-0.5,length(p4.xy)-1.0,p4.z);
    
    return min(dot(lens,mask),length(p4)-0.1);
}

vec3 findnormal(vec3 p, float len) {
    vec2 eps = vec2(0.1,0.0);
    
    return normalize(vec3(
        len-map(p-eps.xyy),
        len-map(p-eps.yxy),
        len-map(p-eps.yyx)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec3 ro = vec3(0.1,0.1,time);
    vec3 rd = normalize(vec3(uv,1.0));
    bool hit = false;
    float dist = 0.0;
    float len;
    for (int i = 0; i < 50; i++) {
        len = map(ro);
        ro += rd*len;
        dist += len;
        if (len < 0.01||dist>10.0) {
            hit = len < 0.01;
            break;
        }
    }
    if (hit) {
        glFragColor = vec4(findnormal(ro,len)*0.5+0.5,1.0);
        glFragColor /= (dist*dist*0.05+1.0);
    }
}
