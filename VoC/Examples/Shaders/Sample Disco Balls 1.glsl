#version 420

// original https://neort.io/art/bta9n2c3p9f8mi6u8u50

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = acos(-1.0);

// https://qiita.com/7CIT/items/e48eff9dc755732fe8a0
highp float rand(vec2 co){
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

// https://qiita.com/keim_at_si/items/c2d1afd6443f3040e900
vec3 hsv2rgb(float h, float s, float v) {
    return ((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;
}

// inspired by
// https://qiita.com/edo_m18/items/37d8773a5295bc6aba3d
const vec2 scale = vec2(0.5, 0.8);
vec4 rectCoords(vec2 p) {
    vec2 z = mod(p, scale) - 0.5 * scale;
    vec2 id = p - z;
    
    float x = atan(z.x, z.y);
    z = abs(z);
    float y = min(0.5 * scale.x - z.x, 0.5 * scale.y - z.y);
    
    return vec4(x, y, id);
}

// https://qiita.com/aa_debdeb/items/b78975c5bcb063e28a08
float exp2Fog(float d, float density) {
    float dd = d * density;
    return exp(-dd * dd);
}

const float interval = 3.5;
const float radius = 1.0;
float distFunc(vec3 p) {
    p = mod(p, interval) - interval*0.5;
    return length(p) - radius;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    float t = time * 1.0;
    vec3 color = vec3(1);
    
    vec3 cPos = vec3(0, radius*1.5, -interval/(2.0*pi) * t - interval*0.4);
    cPos.xy *= rotate(t);
    cPos.xy += interval * 0.5;
    
    vec3 cDir = normalize(vec3(0, -0.3, -1));
    cDir.xy *= rotate(t);
    
    vec3 cUp = normalize(vec3(0, 1.0, 0));
    vec3 cSide = normalize(cross(cDir, cUp));
    float targetDepth = 2.0;
    
    vec3 ray = normalize(cSide * p.x + cUp * p.y + cDir * targetDepth);
    const vec3 lightDir = normalize(vec3(-1, 2, 2));

    float distance = 0.0;
    vec3 rPos = cPos;
    for(int i=0; i<100; i++) {
        distance = distFunc(rPos);
        if(abs(distance) < 0.003) {
            vec3 Pos = mod(rPos, interval) - interval*0.5;
            vec3 idPos = rPos - Pos;
            float phi = acos(Pos.z/length(Pos.xz))/pi*scale.x*20.0;
            float theta = clamp(acos(Pos.y/radius), 0.01, pi-0.01);
            if(Pos.x < 0.0) {
                theta = 2.0 * pi - theta;
            }
            theta *= 1.0/(2.0*pi)*scale.y*40.0;
            vec2 st = vec2(phi, theta);
            vec4 rc = rectCoords(st);
            
            Pos = normalize(Pos);
            float spec = pow(clamp(dot(lightDir, Pos), 0.0, 1.0), 30.0);
            float diff = clamp(dot(lightDir, Pos), 0.3, 1.0);
            
            float tc = time * 10.0;
            float r = rand((rc.zw + idPos.xy + idPos.z*0.2343)*0.005 + floor(tc)); // *0.005 to reduce noise on mobile devices
            
            float c = (smoothstep(0.0, 0.2, rc.y));
            color = (vec3(c) + hsv2rgb(r, 1.0, 1.0)) * diff + spec;
            float fog = exp2Fog(length(rPos-cPos), 0.025);
            color = mix(vec3(1), color, fog);
            break;
        }
        rPos += ray * distance;
    }
    
    glFragColor = vec4(color, 1.0);
}
