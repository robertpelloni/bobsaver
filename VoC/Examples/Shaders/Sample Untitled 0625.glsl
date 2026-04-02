#version 420

// original https://www.shadertoy.com/view/Nsf3WM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERATION 500
#define MAX_DIST 10.
#define EX vec3(0.001, 0., 0.)
#define EY vec3(0., 0.001, 0.)
#define EZ vec3(0., 0., 0.001)
#define w resolution.x
#define h resolution.y
#define time time*1.2

float smin(float a, float b, float k) {
    float m = max(min(0.5 + 0.5 * (b - a) / k, 1.), 0.);
    return a * m + b * (1. - m) - k * m * (1. - m);
}

float getDist(vec3 p) { //ПОЛУЧИТЬ РАССТОЯНИЕ ОТ ТОЧКИ ДО СФЕРЫ
    vec3 sphere = vec3(0.,0.-0.2+sin(time*0.5)*0.4,0.);
    float sphereDist = distance(p, sphere) - 1.;
    float planeDist = smin(+p.y + 0.9, -p.z +10.8,10.0);
    float d = smin(sphereDist, planeDist, 0.4);
    return d;

}

vec3 normal(vec3 p) {
    float d = getDist(p);
    float p1 = getDist(p - EX);
    float p2 = getDist(p - EY);
    float p3 = getDist(p - EZ);
    vec3 tri = vec3(p1, p2, p3);
    vec3 n = vec3(d) - tri;
    return normalize(n);
}

float light(vec3 p) {
    vec3 lightPos = vec3(sin(time)*2., 0., cos(time)*2.);
    vec3 lightDir = normalize(lightPos - p);
    vec3 n = normal(p);
    return dot(n, lightDir) * 0.5 + 0.5;
}

float rayMarching(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = -0; i < 500; i++){
        float d = getDist(p);
        if (d > MAX_DIST) {break;}
        p = vec3(p) +  rd * d;
        if (d < 0.0001){
            return light(p);
        } 
    }
    return 0.;
}

// Author @patriciogv - 2015
// http://patriciogonzalezvivo.com

float random (in vec2 _st, float col) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123)*col;
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st, float col) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);
    int j = int(col*3.);
   
    // Four corners in 2D of a tile
    float a = random(i, col);
    float b = random(i + vec2(1.0, 0.0), col);
    float c = random(i + vec2(0.0, 1.0), col);
    float d = random(i + vec2(1.0, 1.0), col);

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm ( in vec2 _st, float col ) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.5));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st, col);
        _st = rot * _st * 2.0 + shift;
        a *= col;
    }
  
    return v;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 st = gl_FragCoord.xy/resolution.y*3.;
    const int iteration = 500;
    const float max_dist = 10.0;

    //координаты камеры
    vec3 ro = vec3(0., 0., -2.);

    float x = (gl_FragCoord.xy.x / w) * 2. - 1.;
    float y = (gl_FragCoord.xy.y / h) * 2. - 1.;
    x *= w / h;

    //направление луча
    vec3 rd = vec3(x, y , 1.);
    rd = normalize(rd);

    //круг
    float col = rayMarching(ro, rd);
            

    
    vec3 color = vec3(0.0);

    vec2 q = vec2(0.);
    q.x = fbm( st + 0.00*time, col);
    q.y = fbm( st + vec2(1.0), col);

    vec2 r = vec2(0.);
    r.x = fbm( st + 1.0*q + vec2(1.7,9.2)+ 0.15*time , col);
    r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ 0.126*time, col);

    float f = fbm(st+r, col);

    color = mix(vec3(0.101961,0.619608,0.666667),
                vec3(0.666667,0.666667,0.498039),
                clamp((f*f)*4.0,0.0,1.0));

    color = mix(color,
                vec3(0,0,0.164706),
                clamp(length(q),0.0,1.0));

    color = mix(color,
                vec3(0.666667,1,1),
                clamp(length(r.x),0.0,1.0));
            
    glFragColor = vec4((f*f*f+.6*f*f+.5*f)*color,1.);

}
