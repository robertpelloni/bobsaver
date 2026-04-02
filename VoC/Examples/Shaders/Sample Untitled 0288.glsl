#version 420

// original https://www.shadertoy.com/view/XdVfDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 150.
#define EPS 0.001
#define EPSN 0.01

mat2 rot(float angle){
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float distSphere(vec3 pos, float radius){
    return length(pos) - radius;
}

float distScene(vec3 pos){
    vec3 twistedPos = vec3(rot(1.5 * sin(0.1 * pos.z + time)) * pos.xy, pos.z);
    vec3 repeatPos = mod(twistedPos, 1.) - 0.5;
    float dist = distSphere(repeatPos, 0.1 + 0.1 * sin(pos.z + 2. * time));    
    return dist;
}

vec3 getNormal(vec3 pos){
    return normalize(vec3(distScene(pos + vec3(EPSN, 0., 0.)) - distScene(pos - vec3(EPSN, 0., 0.)),
               distScene(pos + vec3(0., EPSN, 0.)) - distScene(pos - vec3(0., EPSN, 0.)),
               distScene(pos + vec3(0., 0., EPSN)) - distScene(pos - vec3(0., 0., EPSN))));
}

vec3 render(vec2 uv){
    vec3 bgcol = vec3(1. - length(uv)) + length(uv) * vec3(0., 0., 0.3);
    vec3 eye = vec3(0., 0., 3.);
    vec3 ray = normalize(vec3(uv, 0.) - eye);
    vec3 pos = eye;
    float dist, step;
    bool hit = false;
    
    for(step = 0.; step < STEPS; step++){
        dist = distScene(pos);
        if(dist < EPS){
            hit = true;
            break;
        }
        pos += ray * dist;
    }
    float totalDist = length(pos - eye);
    vec3 col = vec3(step / STEPS, 0.33, 0.66);
    if(hit && totalDist < 30.)col = mix(col, getNormal(pos) * 0.5 + 0.5, 0.7);
    col = mix(bgcol, col, 1./exp(totalDist * totalDist * 0.0006)); //fog
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;    
    vec3 col = render(uv);
    glFragColor = vec4(col,1.0);
}
