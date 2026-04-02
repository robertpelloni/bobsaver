#version 420

// original https://www.shadertoy.com/view/ls2BzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STAR_SIZE 0.06
#define VIEW_DIST 20.
// horizontal
#define FOV 95.
#define Z_OFFSET 10.

// from https://www.shadertoy.com/view/4djSRW
///  3 out, 3 in...
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

float distToStar(vec3 rd, vec3 ro, vec3 cell) {
    vec3 hash = (hash33(cell) * (1. - STAR_SIZE * 2.)) + STAR_SIZE;
    return length(cross(rd, cell - 0.5 + hash - ro));
}

float lenSq(vec3 v) {
    return dot(v, v);
}

void main(void) {
    vec2 wc = gl_FragCoord.xy - resolution.xy * .5;
    
    vec3 ro = vec3(wc / 10000., -Z_OFFSET);
    vec3 dir = vec3(wc * sin(radians(FOV / 2.)), resolution.x * .5 * cos(radians(FOV / 2.)));
    dir = normalize(dir);
    
    vec2 m = (mouse*resolution.xy.xy - resolution.xy * .5) / 80.;
    m.y = -m.y;
    m.y = clamp(3.14 / 2., -3.14 / 2., m.y);
    
    vec2 msin = sin(m);
    vec2 mcos = cos(m);
    
    mat3 mat = mat3(1, 0, 0,
                   0, mcos.y, -msin.y,
                   0, msin.y, mcos.y);
    mat *= mat3(mcos.x, 0, msin.x,
                  0,        1, 0, 
                  -msin.x, 0, mcos.x);
    
    dir *= mat;
    ro *= mat;
    
    ro.z += time;
    
    float br = 0.;
    
    vec3 stp = sign(dir);
    vec3 cell = floor(ro) + 0.5;
    
    while(lenSq(cell - ro) < VIEW_DIST * VIEW_DIST) {
        int closestDim = -1;
        float minDistSq = 9000.;
        
        for(int d = 0; d < 3; d++) {
            vec3 offset = vec3(0);
            offset[d] = stp[d];
            
            float distSq = lenSq(cross((cell + offset) - ro, dir));
            
            if(distSq < minDistSq) {
                minDistSq = distSq;
                closestDim = d;
            }
        }
        
        cell[closestDim] += stp[closestDim];
        
        float dist = distToStar(dir, ro, cell);
        
        br += max(0., (STAR_SIZE - dist)) * (1. / STAR_SIZE);
        
        if(br >= 1.)
            break;
    }
    
    glFragColor = vec4(br);
}
