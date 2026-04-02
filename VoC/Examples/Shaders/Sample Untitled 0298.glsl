#version 420

// original https://www.shadertoy.com/view/4sKBW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 150.
#define PI 3.14159
#define EPS 0.0001
#define EPSN 0.001

mat2 rot(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float distSphere(vec3 pos, float r){
    return length(pos) - r;
}

float distScene(in vec3 pos, out float colorVariation){
    
    pos.yz = rot(0.6) * pos.yz;
    pos.xz = rot(0.6 + 0.3 * sin(0.5 * time)) * pos.xz;
    pos.y += 0.3;
    
    //repeat
    vec2 q = floor((pos.xz - 0.75) / 1.5);
    pos.xz = mod(pos.xz - 0.75, 1.5) - .75;
    
    float angle = atan(pos.z, pos.x);
    float radius = length(pos.xz);
    
    //repeat petals around y
    float div = 2. * PI / 8.;
    float a = mod(angle, div) - 0.5 * div;
    
    //pointy petal
    float r = radius + 0.25 * abs(a);
    vec3 p = pos;
    p.x = r * cos(a);
    p.z = r * sin(a);
    
    p.z *= 2.;
    p.x *= 0.8;
    p.xy = rot(0.9 - sin(2. * sin(0.75 * time + 1.3 * (q.x + 0.5 * q.y))) * .75 * r) * p.xy;
    p.y *= 10.;
    float r2 = length(p.xz) + 0.25 * abs(a);
    colorVariation = -0.3 * smoothstep(0., 0.2, abs(r2 - sin(4. * abs(2. * r2 - 0.5))));
    float minDist = distSphere(p + vec3(-0.3, 0., 0.), 0.3);
    
    //sphere
    float dist = distSphere(pos - vec3(0., 0.15, 0.), 0.05) + 0.005 * sin(8. * angle);
    if(dist < minDist) colorVariation = .15;
    minDist = min(minDist, dist);
    
    //floor
    p = pos;
    r = abs(smoothstep(0., 1., fract(radius * 3.5)) - 0.5);
    float k = 4.;
    float offset = sin( 0.5 * time);
    float deform = abs( r - cos(k * angle) + offset);
    deform = min(deform, abs( - r - cos(k * (angle + PI)) + offset));
    deform = min(deform, abs( r - cos(k * (angle + PI / 4.)) + offset));
    deform = min(deform, abs( - r - cos(k * (angle + 3. * PI / 4.)) + offset));
    deform = 0.01 * (smoothstep(0., 0.15, deform) - smoothstep(0.15, 0.4, deform));
    dist = 7.5 * (pos.y + deform);
    if(dist < minDist) colorVariation = -.2;
    minDist = min(minDist, dist);
    
    return 0.1 * minDist;
}

vec3 getNormal(vec3 p){
    float c;
    return normalize(vec3(distScene(p + vec3(EPSN, 0., 0.), c) - distScene(p - vec3(EPSN, 0., 0.), c),
                          distScene(p + vec3(0., EPSN, 0.), c) - distScene(p - vec3(0., EPSN, 0.), c),
                          distScene(p + vec3(0., 0., EPSN), c) - distScene(p - vec3(0., 0., EPSN), c)));
}

vec3 render(vec2 uv){
    
    //background
    vec3 col = vec3(0.2, 0.2, 0.2);
    
    vec3 eye = vec3(0., 0., 5.);
    vec3 ray = normalize(vec3(uv, 3.) - eye);
    
    //raymarch
    float step, dist, colorVariation;
    bool hit = false;
    vec3 pos = eye;
    
    for(step = 0.; step < STEPS; step++){
        dist = distScene(pos, colorVariation);
        if(abs(dist) < EPS){
            hit = true;
            break;
        }
        pos += ray * dist;
    }
    
    vec3 normal = getNormal(pos);
    
    //color
    if(hit) col = vec3(step / STEPS, 0.33, 0.66) + 0.25 * normal + colorVariation;
    
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;
    vec3 col = render(uv);
    glFragColor = vec4(col,1.0);
}
