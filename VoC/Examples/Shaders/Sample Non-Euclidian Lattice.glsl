#version 420

// original https://www.shadertoy.com/view/7dlyW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FDIST 0.5
#define PI 3.1415926
#define cameradist 2.5
#define TIME_T 5.
#define TIME_H 1.
#define TIME_L 10.

// raytrace a 2D box with outgoing normal
vec2 box2d(in vec2 ro, in vec2 rd, in vec2 r, out vec2 no) {
    vec2 dr = 1.0/rd;
    vec2 n = ro * dr;
    vec2 k = r * abs(dr);
    
    vec2 pout =  k - n;
    vec2 pin =  - k - n;
    float tout = min(pout.x, pout.y);
    float tin = max(pin.x, pin.y);
    no = -sign(rd) * step(pout.xy, pout.yx);
    return vec2(tin, tout);
}

// Raytrace box, returns (t_in, t_out) and incident normal
vec2 box(in vec3 ro, in vec3 rd, in vec3 r, out vec3 no) {
    vec3 dr = 1.0/rd;
    vec3 n = ro * dr;
    vec3 k = r * abs(dr);
    
    vec3 pout =  k - n;
    vec3 pin =  - k - n;
    float tout = min(pout.x, min(pout.y, pout.z));
    float tin = max(pin.x, max(pin.y, pin.z));
    no = -sign(rd) * step(pin.zxy, pin.xyz) * step(pin.yzx, pin.xyz);
    return vec2(tin, tout);
}

//raytrace a wirebox
vec2 wirebox(in vec3 eye, in vec3 rd, in float r, in float thickness, out vec3 no, out mat3 rot) {
    float rad = r;
    rot = mat3(1.0);
    vec2 t = box(eye, rd, vec3(r), no);
    //float lastT = t.x;
    if (t.y > t.x) {
        //trace the inner walls by tracing infinite rectangular shafts in each face, then repeating once for the inner walls
        vec3 ro = eye + t.x * rd;
        for (int i=0; i<16; ++i) {
            rad -= thickness;
            float offset = rad + thickness;
            //transform the ray into tangent space to intersect it with a shaft perpendicular to the normal
            mat2x3 invproj = mat2x3(no.zxy, no.yzx);
            mat3x2 proj = transpose(invproj);
            rot = rot * mat3(no.zxy, no.yzx, no.xyz);
            vec2 n2;
            vec2 ro2d = proj * ro;
            ro2d = mod(ro2d+offset, offset*2.)-offset;
            vec2 t2 = box2d(ro2d, proj * rd, vec2(rad), n2);
            if (t2.x > 0. || t2.y < 0.) {
                break;
            }
            t.x += t2.y;
            ro = eye + t.x * rd - no * (dot(no, ro) - offset);
            no = invproj * n2;
            //lastT = t2.y;
        }
        
        t.y += 1000.;
    }
    return t;
}

float oscillate(float t)
{
    float t_osc = 0.5*(TIME_H+TIME_L)+TIME_T;
    float h_l = 0.5*TIME_L/t_osc;
    float h_h = (0.5*TIME_L+TIME_T)/t_osc;
    return smoothstep(0., 1., (clamp(abs(mod(time, t_osc*2.)/t_osc-1.), h_l, h_h) - h_l) / (h_h - h_l));
}

void main(void)
{

    //define thickness
    float THICKNESS = 0.03 + 0.4 * oscillate(time);
    
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.x;
    float ang = time * 0.5;
    
    vec3 eye;
    //if (mouse*resolution.xy.z > 0.) {
    //    float mouseY = (1.0-1.15*mouse*resolution.xy.y/resolution.y) * 0.5 * PI;
    //    float mouseX =  -(mouse*resolution.xy.x/resolution.x) * 2. * PI;
    //    eye = cameradist*vec3(cos(mouseX) * cos(mouseY), sin(mouseX) * cos(mouseY), sin(mouseY));
    //} else {
        eye = cameradist*vec3(cos(ang), sin(ang), 0.3 * sin(ang/0.70752)+.3);
    //}
    vec3 w = -normalize(eye);
    vec3 u = normalize(cross(w, vec3(0., 0., 1.)));
    vec3 v = cross(u, w);
    vec3 rd = normalize(u*uv.x + v*uv.y + FDIST * w);
    
    //trace the outer box
    vec3 n;
    
    mat3 rot;
    vec2 t = wirebox(eye, rd, 1., THICKNESS, n, rot);
    float objmask = step(0., t.y-t.x);
    
    //trace the floor
    float tfloor = -(eye.z + 2.)/rd.z;
    float floormask = step(0., tfloor);
    vec3 bgcol = floormask * vec3(.5, .7, .8);
    if (floormask > 0.5) {
        //floor shadow
        vec3 lightdir = normalize(vec3(-.3, -.5, -1.));
        vec3 floorpt = eye + tfloor * rd;
        vec3 ns;
        vec2 ts = box(floorpt, lightdir, vec3(1.), ns);
        bgcol *= step(ts.y, ts.x);
    }
    mat3 traf = mat3(-.5, .3, 0, 0, .5, 0.5, -0.3, 0.8, -0.4);
    vec3 col = mix(bgcol, (rot*traf*n)*.5 + .5, objmask);
    glFragColor = vec4(mix(col, vec3(0.5, 0.1, 0.), objmask * min(1., (t.x/50.))), 1.);
}
