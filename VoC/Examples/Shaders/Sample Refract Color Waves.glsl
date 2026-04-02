#version 420

// original https://neort.io/art/c0eq4uc3p9f30ks5b4vg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// reference by glslfans
vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

mat2 rotate(float angle){
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

float random(float n){
    return fract(sin(n * 22235.3456) * 2134.21);
}

float random3d(vec3 v){
    return fract(sin(dot(v, vec3(22.3456, 12.456, 45.214))) * 2134.21);
}

float valueNoise(vec3 v){
    vec3 i = floor(v);
    vec3 f = smoothstep(0.0, 1.0, fract(v));

    float value1 = mix(random3d(i), random3d(i + vec3(1.0, 0.0, 0.0)), f.x);
    float value2 = mix(random3d(i + vec3(0.0, 1.0, 0.0)), random3d(i + vec3(1.0, 1.0, 0.0)), f.x);
    float value12 = mix(value1, value2, f.y);

    float value3 = mix(random3d(i + vec3(0.0, 0.0, 1.0)), random3d(i + vec3(1.0, 0.0, 1.0)), f.x);
    float value4 = mix(random3d(i + vec3(0.0, 1.0, 1.0)), random3d(i + vec3(1.0, 1.0, 1.0)), f.x);
    float value34 = mix(value3, value4, f.y);

    return mix(value12, value34, f.z);
}

float fbm(vec3 v){
    float n = 0.0;
    float a = 0.5;
    for(int i = 0; i < 5; i++){
        n += a * valueNoise(v);
        v *= 2.0;
        a *= 0.5;
    }
    return n;
}

float smoothMin(float d1, float d2, float k){
    float d = exp(-k * d1) + exp(-k * d2);
    return -log(d) / k;
}

float sdTorus(vec3 p, float inR, float outR){
    vec2 q = vec2(length(p.xz) - outR, p.y);
    return length(q) - inR;
}

float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float sdBox(vec3 p, vec3 s){
    vec3 q = abs(p) - s;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float morphingDF(vec3 p){
    float t = time * 0.8;
    int index = int(mod(t, 3.0));
    float a = smoothstep(0.2, 0.8, mod(t, 1.0));
    if(index == 0){
        return mix(sdBox(p, vec3(0.5)), sdSphere(p, 0.7), a); 
    }else if(index == 1){
        return mix(sdSphere(p, 0.7), sdTorus(p, 0.22, 0.7), a); 
    }else{
        return mix(sdTorus(p, 0.22, 0.7), sdBox(p, vec3(0.5)), a);
    }
}

float distanceFunc(vec3 p){
    vec3 p1 = p;
    // float dist = sdSphere(p1, 1.0);
    p1.xz *= rotate(time * 1.8);
    p1.yz *= rotate(time * 0.8);
    float dist = morphingDF(p1);
    return dist;
}

vec3 getNormal(vec3 p){
    float err = 0.001;
    return normalize(vec3(distanceFunc(p + vec3(err, 0.0, 0.0)) - distanceFunc(p - vec3(err, 0.0, 0.0)),
                          distanceFunc(p + vec3(0.0, err, 0.0)) - distanceFunc(p - vec3(0.0, err, 0.0)),
                          distanceFunc(p + vec3(0.0, 0.0, err)) - distanceFunc(p - vec3(0.0, 0.0, err))));
}

vec3 backgroundTexture(vec2 uv){
    vec3 color = vec3(0.0);
    
    for(float i = 1.0; i <= 10.0; i+=1.0){
        float ampSeed = (i - 6.0) / 8.0 * random(i*10.0) + fbm(vec3(uv * i, time * i / 10.0)) * 0.4;
        float fSeed = i / 10.0 * random(i) * 10.0;

        float wave = uv.y + sin(uv.x * ((10.0 + i) * random(i)) + time * (2.0 + fSeed)) * (0.2 + ampSeed);
        color += (0.012 / abs(0.1 + wave)) * hsv(i/12.0, 1.0, 1.0);
    }

    return color;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);
    vec3 camPos = vec3(0.0, 0.0, -2.0);
    vec3 lookPos = vec3(0.0, 0.0, 0.0);
    vec3 forward = normalize(lookPos - camPos);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, forward));
    up = normalize(cross(forward, right));
    float fov = 1.0;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + fov * forward);

    vec3 p;
    float d = 0.0;
    float df = 0.0;
    for(int i = 0; i < 64; i++){
        p = camPos + rayDir * d;
        df = distanceFunc(p);
        if(df <= 0.001){
            break;
        }
        if(df > 100.0){
            break;
        }
        d += df;
    }

    vec3 lightPos = vec3(10.0, 10.0, -10.0);
    if(df <= 0.001){
        vec3 normal = getNormal(p);
        rayDir = refract(rayDir, normal, 0.2);
    }

    float depth = length(p - camPos);
    vec2 uv2 = p.xy / (depth * rayDir.z);
    color += backgroundTexture(uv2);

    return color;
}

void main(void){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy)/min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
