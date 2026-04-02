#version 420

// original https://www.shadertoy.com/view/MttcRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 64.
#define EPS 0.0001
#define EPSN 0.001
#define PI 3.14159

mat2 rot(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float distSphere(vec3 p, float r){
    return length(p) - r;
}

vec2 repeat(vec2 p, float t){
    t = 2. * PI / t;
    float angle = mod(atan(p.y, p.x), t) - 0.5 * t;
    return length(p.xy) * vec2(cos(angle), sin(angle));
}

float distScene(vec3 pos){
    
    pos.yz = rot(0.45) * pos.yz;
    pos.y += 0.1;
    
    //floor
    vec3 p = pos - vec3(0., -1.5, 0.);
    float r = length(p.xz);
    float dist = distSphere(p, 1.5) + 0.003 * (sin(150. * r - time));
    
    
    //floating things
    float time = 2. * time;
    float tr = 0.15 * (0.5 + 0.5 * sin(time + 2. * PI / 3.));
    p = pos - vec3(-0.25, tr + 0.1, 0.);
    p.xz = rot(time) * p.xz;
    p.xz = repeat(p.xz, 12.);
    
    float dist1 = p.y - 0.095;
    dist1 = max(dist1, length(p.xy) - 0.1);
    dist = min(dist, dist1);
    
    tr = 0.1 * (0.5 + 0.5 * sin(time));
    p = pos - vec3(0., tr + 0.1, 0.);
    p.xz = rot(time) * p.xz;
    p.xz = repeat(p.xz, 12.);
    p.xy = repeat(p.xy, 14.);
    dist1 = length(p.yz) - 0.01;
    dist1 = max(dist1, distSphere(p, 0.1));
    dist = min(dist, dist1);
    
    tr = 0.1 * (0.5 + 0.5 * sin(time - 2. * PI / 3.));
    p = pos - vec3(0.25, tr + 0.1, 0.);
    p.xz = rot(time) * p.xz;
    p.xy = repeat(p.xy, 12.);
    dist1 = length(p.yz) - 0.02 + 0.05 * abs((fract(8. * p.x) - 0.5));
    dist1 = max(dist1, distSphere(p, 0.1));
    dist = min(dist, dist1);
    
    return dist;
}

vec3 getNormal(vec3 p){
    return(normalize(vec3(distScene(p + vec3(EPSN, 0., 0.)) - distScene(p - vec3(EPSN, 0., 0.)),
                          distScene(p + vec3(0., EPSN, 0.)) - distScene(p - vec3(0., EPSN, 0.)),
                          distScene(p + vec3(0., 0., EPSN)) - distScene(p - vec3(0., 0., EPSN)))));
}

vec3 render(vec2 uv){
    //background
    vec3 col = vec3(0., 0.13, 0.2);
    
    vec3 eye = vec3(0., 0., 5.);
    vec3 ray = normalize(vec3(uv, 1.) - eye);
    
    //raymarch
    float step, dist;
    vec3 pos = eye;
    bool hit = false;
    
    for(step = 0.; step < STEPS; step++){
        dist = distScene(pos);
        if(abs(dist) < EPS){
            hit = true;
            break;
        }
        pos += dist * ray;
    }
    
    vec3 normal = getNormal(pos);
    
    //shade
    vec3 light = vec3(10., 10., 10.);
    vec3 l = normalize(light - pos);
    
    if(hit){
        col = vec3(step / STEPS, 0.3, 0.6) + 0.25 * (0.5 + 0.5 * normal);
        col *= 0.2 + 0.8 * dot(normal, l); //diffuse
        
        //shadow
        vec3 p = pos + 2. * EPS * normal;
        float shadow = 1.;
        float totalDist = length(p - pos);
        for(step = 0.; step < 40.; step++){
            dist = distScene(p);
            totalDist += dist;
            shadow = min(shadow, 10. * dist / totalDist);
            if(abs(dist) < EPS){
                shadow = 0.;
                break;
            }
            p += dist * l;
        }
        col = mix(vec3(0.1, 0.1, 0.2), col, shadow);
    }
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;
    vec3 col = vec3(0);
    
    float aa = 1.;
    for (float i = 0.; i < aa; i++){
        for (float j = 0.; j < aa; j++){
            col += render(uv + vec2(i, j) / (aa * resolution.xy));
        }
    }
    glFragColor = vec4(col / (aa * aa),1.0);
}
