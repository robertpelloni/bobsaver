#version 420

//Galaxy Collision
//By nikoclass

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int iters = 300;

int fractal(vec2 p) {
  
    vec2 seed = vec2(0.098386255, 0.63876627);    
    
    
    for (int i = 0; i < iters; i++) {
        
        if (length(p) > 2.0) {
            return i;
        }
        p = vec2(p.x * p.x - p.y * p.y + seed.x, 2.0* p.x * p.y + seed.y);
        
    }
    
    return 0;    
}

vec3 color(int i) {
    float f = float(i)/float(iters) * 2.0;
    f=f*f*2.;
    //return vec3(f,f,f);
    vec3 c = vec3((sin(f*2.0)), (sin(f*3.0)), abs(sin(f*7.0)));
    return sqrt(abs(c));
}

float rand(vec2 p) {
    return fract(sin(dot(p ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 stars(vec2 p) {
    float angle = 1.0;
    mat2 m = mat2(cos(angle), -sin(angle),
              sin(angle), cos(angle));
    
    p = m * p;
    
    
    ivec2 cuadrant = ivec2 (p * 500.0);
    vec2 relative = -0.5 + fract(p * 500.0);
    
    float refx = 2.0 * (rand(vec2(cuadrant)));
    float refy = 2.0 * (rand(vec2(cuadrant + 100)));
    vec2 ref = vec2(refx, refy);
    
    float d = 1.0 - clamp(distance(ref, relative), 0.0, 1.);
    
    d = pow(d, 30.0);
    
    return 2.0 *d * (1.0 + color(cuadrant.x + cuadrant.y));
}

vec3 pulsar(vec2 p, vec2 pos, float size, float angle) {
    
    float a = 0.2;
    
    
    mat2 m = mat2(cos(angle), -sin(angle),
              sin(angle), cos(angle));
    
    p = m * p;
    
    pos = m * pos;
    
    float d = pow(p.x - pos.x, a) + pow(p.y - pos.y, a);
    
    if (d < size) {
        return vec3((size - d) * pow(1.0 - distance(p, pos), 10.0));    
    }
    return vec3(0.0);
    
}

vec3 nebulae(vec2 p) {
    
    float a = 10.0;
    float b = 28.0;
    float c = 8.0 / 3.0;
    
    float dt = 0.023;
    
    
    float angle = 2.0;
    mat2 m = mat2(cos(angle), -sin(angle),
              sin(angle), cos(angle));
    p = m*p;

    p += vec2(-0.0, -0.0);
    
    
    const int iters = 1000;
    
    vec2 pr = vec2(0.0);
    
    vec3 point = vec3(10);
    
    vec3 result = vec3(0.0);
    
    for (int i = 0; i < iters; i++) {
        point.x += dt * a * (point.y - point.x);
        point.y += dt * (point.x * (b - point.z) - point.y);
        point.z += dt * (point.x * point.y - c * point.z);
    
        pr.x = 3.0 * point.x / point.z;
        pr.y = 3.0 * point.y / point.z;
        
        float d = distance(pr, p);
        float size = 0.8;
        if (d < size) {
            float intensity = pow(size - d, size * 20.0);
            result += color(i / 10) * intensity;
            //break;
        }
    }
    
    return 2.0 * result;
    //return 5.0 * intensity * vec3(0.6, 0.0, 0.4);
}

vec2 blackHole(vec2 p) {
    
    vec2 position = vec2(0.6, 0.6);
    float size = 0.6;
    
    float d = distance(position, p);
    
    if (d < size) {
        d = size - d ;
        vec2 dir = normalize(p - position);
        p -= dir * pow(d, 1.3);    
    }
    
    return p;
}

void main( void ) {

    vec2 position = 2.5 * (-0.5 + gl_FragCoord.xy / resolution.xy );// + mouse / 1.0;
    position.x *= resolution.x/resolution.y;
    
    position = blackHole(position);
    
    
    vec3 c = vec3(0.0);
    
    
    //c += color(fractal(position));
    
    c += stars(position);    
    
    for (int i = 0; i < 60; i++){
        float r1 = -2.0 + 4.0 * rand(vec2(i, i));
        float r2 = -2.0 + 4.0 * rand(vec2(i+100, i));
        float r3 = 0.6 + 0.3 * rand(vec2(i, i+100));
        float r4 = 3.0 * rand(vec2(i + 100, i+100));
        
        c += pulsar(position, vec2(r1, r2), r3, r4);
        
    }
    
    
    c += nebulae(position);
        
    c += vec3(1.0, 0.0, 1.0)*clamp(pow(dot(position, vec2(1, 1)) * 0.10, 3.0), 0.0, 0.1);
    
    c = c  * 3.;
    
    glFragColor = vec4( c , 1.0 );
}
