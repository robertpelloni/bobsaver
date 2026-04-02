// original 1https://neort.io/art/c275s243p9f8s59b8mdg

#version 420

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float pi = acos(-1.0);
float pi2 = pi * 2.0;

mat2 rotate(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float sdBox2d(vec2 p, vec2 s){
    p = abs(p) - s;
    return length(max(p, 0.0))+min(max(p.x, p.y), 0.0);
}

float sdTorus(vec3 p, float inRadius, float outRadius){
    vec2 q = vec2(length(p.xz) - outRadius, p.y);
    return length(q) - inRadius;
}

float sdTorusKnots(vec3 p, float inRadius, float outRadius, float divide){
    vec2 cp = vec2(length(p.xz) - outRadius, p.y);
    float a = atan(p.x, p.z);
    cp *= rotate(a*8.0);
    cp.y = abs(cp.y)-0.3;

    // float d = length(cp) - inRadius*sin(divide*a+time*divide);
    float d = sdBox2d(cp, vec2(inRadius, inRadius*2.0)*sin(divide*a+time*divide));
    return d;
}

float distanceFunc(vec3 p){
    vec3 p1 = p;
    vec3 p2 = p;
    vec3 p3 = p;
    vec3 p4 = p;
    float d = 0.0;

    p1.yz *= rotate(pi/2.0);
    float torusKnot1 = sdTorusKnots(p1, 0.12, 1.3, 1.0);
    d += torusKnot1;

    p2.yz *= rotate(-pi/2.0);
    float torusKnot2 = sdTorusKnots(p2, 0.12, 2.6, 2.0);
    d = min(d, torusKnot2);

    p3.yz *= rotate(pi/2.0);
    float torusKnot3 = sdTorusKnots(p3, 0.12, 3.9, 4.0);
    d = min(d, torusKnot3);

    p4.yz *= rotate(-pi/2.0);
    float torusKnot4 = sdTorusKnots(p4, 0.12, 5.2, 16.0);
    d = min(d, torusKnot4);

    return d*0.4;
}

vec3 getColorFromDistanceFunc(vec3 p){
    vec3 p1 = p;
    vec3 p2 = p;
    vec3 p3 = p;
    vec3 p4 = p;
    float d = 0.0;

    p1.yz *= rotate(pi/2.0);
    float torusKnot1 = sdTorusKnots(p1, 0.12, 1.3, 1.0);
    d += torusKnot1;

    p2.yz *= rotate(-pi/2.0);
    float torusKnot2 = sdTorusKnots(p2, 0.12, 2.6, 2.0);
    d = min(d, torusKnot2);

    p3.yz *= rotate(pi/2.0);
    float torusKnot3 = sdTorusKnots(p3, 0.12, 3.9, 4.0);
    d = min(d, torusKnot3);

    p4.yz *= rotate(-pi/2.0);
    float torusKnot4 = sdTorusKnots(p4, 0.12, 5.2, 16.0);
    d = min(d, torusKnot4);

    if(d == torusKnot1){
        return vec3(0.313, 0.816, 0.816);
    }
    else if(d == torusKnot2){
        return vec3(0.745, 0.118, 0.243);
    }
    else if(d == torusKnot3){
        return vec3(0.475, 0.404, 0.765);
    }
    else if(d == torusKnot4){
        return vec3(1.0, 0.776, 0.224);
    }else{
        return vec3(1.0);
    }
}

vec3 getNormal(vec3 p){
    vec2 err = vec2(0.001, 0.0);
    return normalize(vec3(distanceFunc(p + err.xyy) - distanceFunc(p - err.xyy),
                          distanceFunc(p + err.yxy) - distanceFunc(p - err.yxy),
                          distanceFunc(p + err.yyx) - distanceFunc(p - err.yyx)));
}

vec3 background(vec3 rayDir){
    float k = rayDir.y * 0.5 + 0.5;
    return mix(vec3(0.0863, 0.1569, 0.1922), vec3(0.7725, 0.1451, 0.1451), k);
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    vec3 camPos = vec3(0.0, 0.0001, -6.0);
    vec3 lookPos = vec3(0.0, 0.0, 0.0);
    vec3 forward = normalize(lookPos - camPos);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, forward));
    up = normalize(cross(forward, right));
    float fov = 1.0;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward * fov);
    vec3 lightPos = vec3(20.0, 10.0, -20.0);

    color += background(rayDir);
    
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
        vec3 lv = lightPos - p;
        vec3 normal = getNormal(p);
        vec3 r = reflect(rayDir, normal);
        float spec = pow(max(0.0, r.y), 22.0);
        float l = clamp(dot(normal, normalize(lv)), 0.1, 1.0);
        color = mix(background(rayDir), vec3(l), 0.6)+spec;
        color *= getColorFromDistanceFunc(p);
    }
    
    color = pow(color, vec3(0.4545));

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
