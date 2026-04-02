#version 420

// original https://neort.io/art/c2u8tvk3p9f8s59bcpng

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float pi = acos(-1.0);
float pi2 = pi * 2.0;

float at = 0.0;

float t = time*4.0;

mat2 rotate(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float sdBox2d(vec2 p, vec2 s){
    p = abs(p) - s;
    return length(max(p, 0.0))+min(max(p.x, p.y), 0.0);
}

float sdBox(vec3 p, vec3 s){
    p = abs(p) - s;
    return length(max(p, 0.0))+min(max(p.x, max(p.y, p.z)), 0.0);
}

float sdTorus(vec3 p, float inRadius, float outRadius){
    vec2 q = vec2(length(p.xz) - outRadius, p.y);
    return length(q) - inRadius;
}

float sdTorusKnots(vec3 p, float inRadius, float outRadius){
    vec2 cp = vec2(length(p.xz) - outRadius, p.y);
    float a = atan(p.x, p.z);
    cp *= rotate(a*8.0);
    cp.y = abs(cp.y)-0.3;

    float d = sdBox2d(cp, vec2(inRadius, inRadius*2.0));
    return d;
}

float sdTriPrism(vec3 p, vec2 h){
  vec3 q = abs(p);
  return max(q.z-h.y,max(q.x*sin(pi/3.0)+p.y*sin(pi/6.0),-p.y)-h.x*sin(pi/6.0));
}

float morphing(vec3 p){
    float t = time * 1.1;
    int index = int(mod(t, 4.0));
    float a = smoothstep(0.2, 0.8, mod(t, 1.0));

    if(index == 0){
        return mix(sdTriPrism(p, vec2(1.0, 1.5)), sdBox(p, vec3(1.0)), a);
    }else if(index == 1){
        return mix(sdBox(p, vec3(1.0)), sdTorus(p, 0.15, 2.0), a);
    }else if(index == 2){
        return mix(sdTorus(p, 0.15, 2.0), sdTorusKnots(p, 0.15, 2.0)*0.4, a);
    }else{
        return mix(sdTorusKnots(p, 0.15, 2.0)*0.4, sdTriPrism(p, vec2(1.0, 1.5)), a);
    }
}

float distanceFunc(vec3 p){
    vec3 p1 = p;
    float dist = 0.0;
    p1.yz *= rotate(pi/2.0);
    p1.xy *= rotate(time*1.5);
    p1.yz *= rotate(time*1.3);
    p1.xz *= rotate(time*1.7);
    float d1 = morphing(p1);
    dist += d1;
    at += 0.002 / (dist + 0.2);

    return dist;
}

vec3 getNormal(vec3 p){
    vec2 err = vec2(0.1, 0.0);
    return normalize(vec3(distanceFunc(p + err.xyy) - distanceFunc(p - err.xyy),
                          distanceFunc(p + err.yxy) - distanceFunc(p - err.yxy),
                          distanceFunc(p + err.yyx) - distanceFunc(p - err.yyx)));
}

// https://www.youtube.com/watch?v=-FvnsYbzpfc
vec3 background(vec3 rayDir){
    vec3 colT = vec3(0.313, 0.816, 0.816);
    vec3 colM = vec3(0.745, 0.118, 0.243);
    vec3 colK = vec3(0.475, 0.404, 0.765);
    vec3 colH = vec3(1.0, 0.776, 0.224);

    vec3 bgColor = vec3(0.0);
    float k = rayDir.y * 0.5 + 0.5;
    bgColor += (1.0-k);

    float a = atan(rayDir.x, rayDir.z);
    float wave1 = sin(a*2.0+time)*sin(a*10.0+time)*sin(a*4.0);
    wave1 *= smoothstep(0.8, 0.5, k);
    bgColor += wave1*colT;

    float wave2 = sin(a*10.0+time+10.0)*sin(a*2.0+time+10.0)*sin(a*6.0+10.0);
    wave1 *= smoothstep(0.8, 0.5, k);
    bgColor += wave2*colM;

    float wave3 = sin(a*5.0+time+20.0)*sin(a*3.0+time+30.0)*sin(a*8.0+20.0);
    wave1 *= smoothstep(0.8, 0.5, k);
    bgColor += wave3*colK;

    float wave4 = sin(a*3.0+time+30.0)*sin(a*5.0+time+20.0)*sin(a*10.0+30.0);
    wave1 *= smoothstep(0.8, 0.5, k);
    bgColor += wave4*colH;

    return bgColor;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    float t = time * 6.0;
    vec3 camPos = vec3(0.0, 0.0, -4.0);
    vec3 lookPos = vec3(0.0, 0.0, 0.0);
    vec3 forward = normalize(lookPos - camPos);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, forward));
    up = normalize(cross(forward, right));
    float fov = 1.0;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward * fov);
    
    vec3 p;
    float df = 0.0;
    float d = 0.0;
    for(int i = 0; i < 64; i++){
        p = camPos + rayDir * d;
        df = distanceFunc(p);
        if(df > 100.0){
            break;
        }
        if(df <= 0.001){
            break;
        }
        d += df;
    }

    if(df <= 0.001){
        vec3 normal = getNormal(p);
        rayDir = refract(rayDir, normal, 0.1);
    }
    color = mix(color, background(rayDir), smoothstep(0.0, 4.0, d));

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
