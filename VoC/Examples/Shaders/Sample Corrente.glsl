#version 420

// original https://www.shadertoy.com/view/ctSfRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define rot(a) mat2 (cos(a), sin(a), -sin(a), cos(a))
#define PI 3.1415
#define T  time * 2.
#define torus(p) length(vec2(length(p.xz) - .28, p.y)) - .07

/*    relateds
        https://www.shadertoy.com/view/ctSfRV *
        https://www.shadertoy.com/view/ml2fRV 
        https://www.shadertoy.com/view/mlBBzK
        https://www.shadertoy.com/view/dtSfRc
        https://www.shadertoy.com/view/DlffD4
        https://www.shadertoy.com/view/DlXfzj
    
*/ 

vec2 path(float z) {
    return 1.3 * vec2(
        sin(z * .3), 
        cos(z * .5) 
    );
}

vec3 cor; 

float chain(vec3 p){
    p.z = 1.5 * p.z - 2.2 * T;

    vec3 q = p;
    q.xy *= rot(PI/2.);
    q.z = fract(p.z + .5) - .5;
    p.z = fract(p.z) - .5;
    
    return min(torus(p), torus(q));
}

float map(vec3 p){
    p.z += T;
    p.xy -= path(p.z) - path(T);
 
    // 
        float ss = 1.5;
        float s = 1.;

        mat2 rotate = ss * rot(.5 * p.z);

        float i = 0., d = 100.;
        while(i++ < 2.){
            p.xy = abs(p.xy * rotate) - s;
            s /= ss;
            
            float c = chain(p) * s;
            if (c < d){
                d = c;
                cor = vec3(1,.75,0) * (.125 * i + .2);
            }
        }
        
        return d;
}

void main(void) {
    vec2 u = gl_FragCoord.xy;

    // resolution
    vec2 uv = (u - .5 * R)/R.y;

    // camera
    vec3 ro = vec3(0, 0, -1),
         rd = normalize(vec3(uv, 1));
         
    //if (length(mouse*resolution.xy.xy) > 40.) {
    //    rd.yz *= rot(-PI * .5 + mouse*resolution.xy.y/R.y * PI);
    //    rd.zx *= rot(PI - mouse*resolution.xy.x/R.x * PI * 2.);
    //}
    
    // raymarch
    float s, i, d, far = 60.;
    while(i++ < 200.) {
        s = map(ro + d * rd);
        d += s * .5;
        if(d > far || s < .001) break;
    }

    vec3 col;
    if(d < far){
        // normal
        vec2 e = vec2(.01, 0);
        vec3 p = ro + rd * d,
             n = normalize(
                 map(p) - vec3(
                     map(p-e.xyy), 
                     map(p-e.yxy),
                     map(p-e.yyx)));

        // colors
        col = cor;
        col *= -dot(reflect(n, rd), n) *.1 + .45;
        col = pow(col * 1.6, vec3(.7)) * 3.5 - .6;
    } 
    
    else{
        col = vec3(.5);
    }

    glFragColor = vec4(col, 1);
}