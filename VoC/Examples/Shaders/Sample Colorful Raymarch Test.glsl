#version 420

// original https://www.shadertoy.com/view/WlSXzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
mat2 genRot(float val){
    return mat2(cos(val),-sin(val),sin(val),cos(val));
}

float pipeWidth(float t){
    return floor((2. + 0.5 * sin(t * 2. * PI))*2.) / 4.;
}

float mapR(vec3 p){
    p += 1.5;
    p = fract(p / 3.0) * 3.0;
    p -= 1.5;
    float a = length(p.xy) - 0.15 * pipeWidth(p.z);
    float b = length(p.yz) - 0.15 * pipeWidth(p.x);
    float c = length(p.zx) - 0.15 * pipeWidth(p.y);
    return min(a,min(b,c));
}
float mapB(vec3 p){
    p += 1.5;
    p = fract(p / 3.0) * 3.0;
    p -= 1.5;
    float a = length(p.xy - vec2(1.,1.)) - 0.15 * pipeWidth(p.z);
    float b = length(p.yz - vec2(1.,1.)) - 0.15 * pipeWidth(p.x);
    float c = length(p.zx - vec2(1.,1.)) - 0.15 * pipeWidth(p.y);
    return min(a,min(b,c));
}
float mapG(vec3 p){
    p += 1.5;
    p = fract(p / 3.0) * 3.0;
    p -= 1.5;
    float a = length(p.xy - vec2(-1.,-1.)) - 0.15 * pipeWidth(p.z);
    float b = length(p.yz - vec2(-1.,-1.)) - 0.15 * pipeWidth(p.x);
    float c = length(p.zx - vec2(-1.,-1.)) - 0.15 * pipeWidth(p.y);
    return min(a,min(b,c));
}
vec3 trace (vec3 o, vec3 r){
    float tR = 0.0;
    for(int i = 0; i < 256; ++i){
        vec3 pR = o + r * tR;
        float dR = mapR(pR);
        tR += dR * 0.25;
    }
    float tB = 0.0;
    for(int i = 0; i < 256; ++i){
        vec3 pB = o + r * tB;
        float dB = mapB(pB);
        tB += dB * 0.25;
    }
    float tG = 0.0;
    for(int i = 0; i < 256; ++i){
        vec3 pG = o + r * tG;
        float dG = mapG(pG);
        tG += dG * 0.25;
    }
    return vec3(tR,tB,tG);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    float PI = 3.14159265;
    vec2 uv = gl_FragCoord.xy /resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 r = normalize(vec3(uv,1.0)); 
    r.yz *= genRot(- PI / 3.);
    r.xy *= genRot(time * PI / 4.);
    vec3 o = vec3(1.75 * cos((time / 4.) * PI),1.75 * sin((time / 4.) * PI), 0.6 + time * 9. / 8.);
    vec3 t = trace(o,r);
    vec3 colX = vec3(250,209,106) / 255.;
    vec3 colY = vec3(102,197,222) / 255.;
    vec3 colZ = vec3(230,86,141) / 255.;
    vec3 fc = t.x < min(t.y,t.z) ? colX :
                t.y < t.z ? colY : colZ;
    float fogT = min(t.x,min(t.y,t.z));
    float fog = 1.0 / (1.0 + fogT * fogT * 0.05);
    fc = mix(vec3(255,235,238)/255.,fc,fog);

    // Output to screen
    glFragColor = vec4(fc,1.0);
}
