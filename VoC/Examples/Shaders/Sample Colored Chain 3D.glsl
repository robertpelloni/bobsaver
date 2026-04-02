#version 420

// original https://neort.io/art/c0eqkfk3p9f30ks5b59g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 hsv2rgb(float h, float s, float v) {
    vec3 res = fract(h+vec3(0,2,1)/3.);
    res = abs(res*6.-3.)-1.;
    res = clamp(res, 0., 1.);
    res = (res-1.)*s+1.;
    res *= v;
    return res;
}

float exp2Fog(float dist, float density) {
    float s = dist * density;
    return exp(-s*s);
}

float sdTorus(vec3 p) {
    return length(vec2(length(p.zx) - 0.3, p.y)) - 0.02;
}

float dist(vec3 p) {
    vec3 q = abs(fract(p) - 0.5);
    q = q.x > q.z ? q.zyx : q;
    float d = sdTorus(q);
    d = min(d, sdTorus(q.yxz + vec3(0, 0, -0.5)));
    d = min(d, sdTorus(q + vec3(-0.5, -0.5, -0.5)));
    d = min(d, sdTorus(q.xzy + vec3(0, -0.5, -0.5)));
    return d;
}

vec3 objColor(vec3 p) {
    vec3 col = vec3(0);
    vec3 q = abs(fract(p) - 0.5);
    float th = 0.01;
    float s = 0.8;
    float v = 1.;
    
    if(sdTorus(q) < th) {
        col = hsv2rgb(1./6., s, v);
    } else if(sdTorus(q + vec3(-0.5, -0.5, -0.5)) < th) {
        col = hsv2rgb(2./6., s, v);
    } else if(sdTorus(q.xzy + vec3(0, -0.5, -0.5)) < th) {
        col = hsv2rgb(3./6., s, v);
    } else if(sdTorus(q.yxz + vec3(0, 0, -0.5)) < th) {
        col = hsv2rgb(4./6., s, v);
    } else if(sdTorus(q.xzy + vec3(-0.5, 0, 0)) < th) {
        col = hsv2rgb(5./6., s, v);
    } else if(sdTorus(q.yxz + vec3(-0.5, -0.5, 0)) < th) {
        col = hsv2rgb(6./6., s, v);
    }
    
    return col;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0);
    
    vec3 cPos = vec3(0, 0.5, 0);
    cPos += vec3(-1, -1, -1)*fract(time*0.3);
    vec3 cDir = normalize(vec3(0.3, 0, -1.));
    vec3 up = vec3(0, 1, 0);
    vec3 cSide = normalize(cross(cDir, up));
    vec3 cUp = normalize(cross(cSide, cDir));
    
    vec3 ray = normalize(p.x*cSide + p.y*cUp + cDir*2.);
    
    vec3 rPos = cPos;
    float d = 0.;
    float count = 0.;
    for(int i=0; i<99; i++){
        d = dist(rPos);
        if(d < 0.0001){
            break;
        }
        rPos += ray * d;
        count++;
    }
    
    if(d < 0.1) {
        vec3 base = objColor(rPos);
        col = base * 20. / count;
    }
    
    float fog = exp2Fog(length(rPos-cPos), 0.1);
    col = mix(vec3(1), col, fog);
    
    glFragColor = vec4(col, 1.);
}
