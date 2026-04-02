#version 420

// original https://www.shadertoy.com/view/ldlBDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPSILON 0.001
#define FAR 32.0
#define MAX_STEPS 64

float prim_box(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float map(vec3 p) {
    float cubesize = 0.5;
    
    p += vec3(cubesize*15.0, 0.0, cubesize*15.0);
    
    float d = FAR;
    for (int y=0; y<15; y++) {
            for (int x=0; x<15; x++) {
                vec2 pos = vec2(float(x) - 7.5, float(y) - 7.5);
                float ho = sin(length(pos * 0.7) - time * 3.0) * 2.0 + 4.0;
                d = min(d, prim_box(p - vec3(float(x) * cubesize * 1.9, 0.0, float(y) * cubesize * 1.9), vec3(cubesize, ho, cubesize)));
               }
    }
    return d;
}

float march_map(vec3 eye, vec3 dir) {
    float depth = 0.0;
    vec3 pos = eye;
    
    for (int i = 0; i < MAX_STEPS; i++) {
        float d = map(pos);
        depth += d;
        pos += dir * d;
        
        if (d < EPSILON) {
            break;
        }
        
        if (d >= FAR) {
            return FAR;
        }
    }
    
    return depth;
}

vec3 map_nrm(vec3 p) {
    vec2 e = vec2(0.005, -0.005); 
    return normalize(e.xyy * map(p + e.xyy) + e.yyx * map(p + e.yyx) + e.yxy * map(p + e.yxy) + e.xxx * map(p + e.xxx));
}

vec3 draw(vec3 eye, vec3 dir) {
    vec3 sky = vec3(249.0/255.0);
    float depth = march_map(eye, dir);
    if (depth >= FAR) {
        return sky;
    } else {
        vec3 hit_pos = eye + dir * depth;
        vec3 nrm = map_nrm(hit_pos);
        
        vec3 color = mix(sky, vec3(230.0/255.0, 228.0/255.0, 176.0/255.0), nrm.x);
        color = mix(color, vec3(130.0/255.0, 186.0/255.0, 180.0/255.0), nrm.y);
        color = mix(color, vec3(83.0/255.0, 84.0/255.0, 132.0/255.0), nrm.z);
        
        return color;
    }
}

void main(void) {
    vec3 eye = vec3(8.0);
    vec3 look = vec3(0.0);
    float scale = 24.0;
    
    vec3 centerdir = normalize(look - eye);
    vec3 right = normalize(cross(centerdir, vec3(0.0, 1.0, 0.0)));
    vec3 up = normalize(cross(right, centerdir));
    
    vec2 FragCoordPolar = gl_FragCoord.xy - resolution.xy * 0.5;
    FragCoordPolar /= resolution.y;
    FragCoordPolar *= scale;
    
    vec3 realeye = eye + right * FragCoordPolar.x + up * FragCoordPolar.y;
    
    glFragColor = vec4(draw(realeye, centerdir), 1.0);
    
    float luma = sqrt(dot(glFragColor.rgb, vec3(0.299, 0.587, 0.114)));
    glFragColor = vec4(glFragColor.rgb, luma);
}
