#version 420

// original https://www.shadertoy.com/view/tsj3D3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(uint n){
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    return float( n & uvec3(0x7fffffffU))/float(0x7fffffff);
}

float hash(vec3 p3){
    p3 = fract(p3*.1031);
    p3 += dot(p3,p3.yzx+19.19);
    return fract((p3.x+p3.y)*p3.z);
}

float sphere(vec3 p, float r){
    return length(p)-r;
}

vec3 cellid;
void repeat(inout vec3 p, vec3 dim){
    cellid = floor((p )/(dim));
    p = mod(p, dim)-dim*0.5;
}

const float spacing = 3.0;
vec3 targetpos;
vec3 targetactual;

float target(vec3 p){
    return sphere(p-targetactual, 1.0);
}

float map(vec3 p){
    float t = target(p);
    repeat(p, vec3(spacing));
    return min(t, sphere(p, 0.5));
}

vec3 normal(vec3 p){
    float c = map(p);
    const float e = 0.001;
    return normalize(vec3(c-map(p-vec3(e,0,0)), c-map(p-vec3(0,e,0)), c-map(p-vec3(0,0,e))));
    
}

float intersect(vec3 cam, vec3 ray){
    float d = 0.0;
    const int steps = 80;
    for(int i = 0; i < steps; ++i){
        float t = map(cam+ray*d);
        d += t;
        if(t < 0.001 || d > 50.0)
            break;
    }
    
    return min(d, 50.0);
}

vec3 shade(vec3 cam, vec3 ray, vec3 pos, vec3 n, vec3 rv, float anim){
    const vec3 rc = vec3(0.9,0.1,0.05);
    if(target(pos) < 0.01)
        return rc;
    
    vec3 emit = vec3(0);
    if(hash(cellid + 0.0*floor(time*8.0)/8.0) > 0.75)
        emit = vec3(0.9)*(1.0-smoothstep(6.0, 6.0, distance(targetactual, pos)));
    
    vec3 light = targetactual;
    vec3 lv = normalize(light-pos);
    float lambert = 0.0*max(0.0, dot(n, lv));
    float spec = pow(max(0.0, dot(lv, rv)), 50.0);
    
    float ld = distance(pos, light);
    vec3 surface = 4.0*mix(vec3(1), rc, 0.5)*vec3(lambert+spec)/(1.0+pow(ld, 2.5));
    surface += emit;
    return surface;
}

vec3 getpoint(uint index){
    float a = floor(0.5+4.5*hash(index));
    float b = floor(0.5+4.5*hash(index+1U));
    float c = floor(0.5+4.5*hash(index+2U));
    
    vec3 p = vec3(a,b,c);
    switch( int(mod(float(index), 3.0)) ){
        case 0:
            return p.xyz;
        case 1:
            return p.zxy;
        case 2:
            return p.yzx;
    }
}

vec3 path(float time){
    uint index = uint(time);
    return spacing*mix(getpoint(index), getpoint(index+1U), smoothstep(0.0, 1.0, mod(time, 1.0)));
}

mat3 lookat(vec3 cam, vec3 target){
    vec3 ww = normalize(target - cam);
    vec3 uu = normalize(cross(ww, normalize(vec3(1e-4,1.0-1e-4,1e-4))));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec3 cum = vec3(0);
    const int samples = 3;
    for(int y = 0; y < samples; ++y)
        for(int x = 0; x < samples; ++x){
            vec2 p = -1.0 + 2.0 * (uv + (-1.0+2.0*(vec2(x, y)/float(samples)))/resolution.xy);
            p.y *= resolution.y/resolution.x;
            
            float anim = time;//-texelFetch(iChannel0, ivec2(mod(gl_FragCoord*float(samples)+vec2(x,y),1024.)),0).r/48.0;

            // cam setup
            vec3 cam = vec3(0,0,0) + path(anim);
            targetpos = path(anim+2.25);
            targetactual = path(anim+2.35);
            float fov = mix(0.5, 5.0, smoothstep(5.0, 20.0, distance(cam, targetpos)));
            vec3 ray = normalize(vec3(p, fov));
            ray = lookat(cam, targetpos) * ray;

            // primary ray and shading
            float dist = intersect(cam, ray);
            
            if(dist < 50.0){
                vec3 pos = cam+ray*dist;
                vec3 n = normal(pos);
                vec3 rv = reflect(ray, n);
                vec3 col = shade(cam, ray, pos, n, rv, time);

                // reflection ray
                float rd = intersect(pos+n*0.01, rv);
                vec3 rpos = pos+rv*rd;
                vec3 rn = normal(rpos);
                vec3 rrv = reflect(rv, rn);

                // reflection shading
                vec3 rcol = shade(pos, rv, rpos, rn, rrv, time);
                float fresnel = pow(1.0-max(0.0, dot(n, -ray)), 5.0);
                col = mix(col, rcol, fresnel);
                //col += fresnel/pow(distance(cam, pos), 2.0);

                cum += col;
            }
    }
    
    cum /= float(samples*samples);
    
    cum *= 1.0+0.1*(-1.0+2.0*hash(vec3(gl_FragCoord.xy, time)));
    
    //cum = mix(cum, mix(vec3(0.82,0.99,0.82)*0.02, vec3(0.99,0.92,0.85), cum), 0.25);
    cum = pow(cum, vec3(1.0/2.2));
    cum = smoothstep(-0.2, 1.05, cum);
    glFragColor.rgb = cum;
    
}
