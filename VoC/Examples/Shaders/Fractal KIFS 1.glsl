#version 420

// by @acaudwell

// based on fractal discovered by knighty:
// http://www.fractalforums.com/3d-fractal-generation/kaleidoscopic-(escape-time-ifs)/

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

#define MAX_RAY_STEPS 22
#define MAX_DE_STEPS  24
#define M mat4(-5.740254e-01, 4.547220e-01, 1.309093e+00, 0.000000e+00, -4.547220e-01, 1.276698e+00, -6.428610e-01, 0.000000e+00, -1.309093e+00, -6.428610e-01, -3.507233e-01, -0.000000e+00, 3.896400e-01, -1.814265e-01, -5.258469e-02-mouse.y*0.3, 1.000000e+00-mouse.x*0.5)

float aspect_ratio;
float ray_scale;
float fov          = tan ( 45.0 * 0.017453292 * 0.5 );

float distance(vec3 p) {

    vec4 q = vec4(p, 1.0);

    for(int i=0;i<MAX_DE_STEPS;i++) {
        q = M * abs(q);
    }

    return length(q) * pow(1.5, float(-MAX_DE_STEPS));
}

void main( void ) {

    aspect_ratio = resolution.y / resolution.x;
    ray_scale    = (1.0 / max(resolution.x, resolution.y)) * 0.67;

    vec2 tx = (gl_FragCoord.xy / resolution)-0.5;

    float a  = time;
    float sa = sin(a);
    float ca = cos(a);

    vec3 dir = vec3( tx.x * fov , tx.y * fov * aspect_ratio, 1.0 );
 
    dir.xy   = vec2( dir.x * ca - dir.y * sa, dir.x * sa + dir.y * ca);
    dir.xz   = vec2( dir.x * ca - dir.z * sa, dir.x * sa + dir.z * ca);

    dir = normalize(dir);

    vec3 cam = vec3(0.0, 0.0, -6.0);
    cam.xz   = vec2( cam.x * ca - cam.z * sa, cam.x * sa + cam.z * ca);

    vec3 ray = cam;

    float l  = 0.0;
    float d  = 0.0;
    float e  = 0.00001;
    float it = 0.0;

    for(int i=0;i<MAX_RAY_STEPS;i++) {
        d = distance(ray);

        ray += d * dir;
        l += d;

        if(d<e) break;

        e  = ray_scale * l;
        it++;
    }

    float f = 1.0-(it/float(MAX_RAY_STEPS));

    float s = max(0.0, pow(1.0-d,50.0));

    vec3 bg = vec3(pow(length(tx),3.5));

    glFragColor = vec4(bg + f*s, 1.0);
}
