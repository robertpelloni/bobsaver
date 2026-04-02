#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdfczN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 sdf1(vec3 p, float id, float spacing, float side, float offset,
          vec2 xclip,
          vec2 yclip,
          vec2 zclip) {
    float dx = abs((p.x - clamp(floor(p.x/spacing+0.5), xclip.x, xclip.y)*spacing)) - side;
    float dy = abs((p.y - clamp(floor(p.y/spacing+0.5), yclip.x, yclip.y)*spacing)) - side;
    float dz = abs((p.z - clamp(floor(p.z/spacing+0.5), zclip.x, zclip.y)*spacing)) - side;
    if (dx < 0. && dy < 0. && dz < 0.) return vec2(max(dx, max(dy, dz)) - offset, id);
    dx = max(dx, 0.); dy = max(dy, 0.); dz = max(dz, 0.);
    return vec2(sqrt(dx*dx + dy*dy + dz*dz) - offset, id);
}

float pi4 = 3.14159265359*2.;

vec2 sdf(vec3 p) {
    float t = time*0.337;
    if ((int(t) & 1) == 0) {
        if (p.x < -35.) {
            float c = cos(-t*pi4), s = sin(-t*pi4);
            p = vec3(p.x, p.y*c + p.z*s, p.z*c - p.y*s);
        }
    } else {
        if (p.y > 35.) {
            float c = cos(t*pi4), s = sin(t*pi4);
            p = vec3(p.x*c + p.z*s, p.y, p.z*c - p.x*s);
        }
    }
    vec2 full=vec2(-1., 1.);
    vec2 neg=vec2(-1., -1.);
    vec2 pos=vec2(1., 1.);
    vec2 a = sdf1(p, 0., 70., 30., 5., full, full, full);
    vec2 b = sdf1(p + vec3(0., -8., 0.), 1., 70., 25., 5., full, pos, full); if (b.x < a.x) a = b;
    b = sdf1(p + vec3(0., 8., 0.), 6., 70., 25., 5., full, neg, full); if (b.x < a.x) a = b;
    b = sdf1(p + vec3(-8., 0., 0.), 2., 70., 25., 5., pos, full, full);  if (b.x < a.x) a = b;
    b = sdf1(p + vec3(8., 0., 0.), 3., 70., 25., 5., neg, full, full);  if (b.x < a.x) a = b;
    b = sdf1(p + vec3(0., 0., -8.), 4., 70., 25., 5., full, full, pos);  if (b.x < a.x) a = b;
    b = sdf1(p + vec3(0., 0., 8.), 5., 70., 25., 5., full, full, neg);  if (b.x < a.x) a = b;
    return a;
}

void main(void)
{
    float r = 450., h = r*0.6, dist = r*1.5;
    vec3 p = vec3(r*cos(time), h, r*sin(time));
    vec3 w = normalize(-p);
    vec3 u = normalize(cross(w, vec3(0., 1., 0.)));
    vec3 v = cross(u, w);
    vec3 d = normalize(w*dist + (gl_FragCoord.xy.x - resolution.x*0.5)*u + (gl_FragCoord.xy.y - resolution.y*0.5)*v);
    vec4 col = vec4(0., 0., 0., 1.);
    vec3 pp;
    float t = 0.;
    vec2 fv;
    for (int i=0; i<1000; i++) {
        pp = p + t*d;
        fv = sdf(pp);
        if (abs(fv.x) < 0.1 || t > 1000.) break;
        t += fv.x * 0.25;
    }
    if (t > 1000.) {
        col = abs(d.y) * vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        vec3 n = normalize(vec3(sdf(vec3(pp.x+.1, pp.y, pp.z)).x - fv.x,
                                sdf(vec3(pp.x, pp.y+.1, pp.z)).x - fv.x,
                                sdf(vec3(pp.x, pp.y, pp.z+.1)).x - fv.x));
        float L = 0.5 - 0.5*dot(n, d);
        if (fv.y == 0.) {
            col = L * vec4(0.2, 0.2, 0.2, 1.0);
        //*
        } else if (fv.y == 1.) {
            col = L * vec4(1.0, 1.0, 1.0, 1.0);
        } else if (fv.y == 2.) {
            col = L * vec4(1.0, 0.2, 0.2, 1.0);
        } else if (fv.y == 3.) {
            col = L * vec4(1.0, 0.5, 0.2, 1.0);
        } else if (fv.y == 4.) {
            col = L * vec4(0.2, 1.0, 0.2, 1.0);
        } else if (fv.y == 5.) {
            col = L * vec4(0.2, 0.2, 1.0, 1.0);
        //*/
        } else {
            col = L * vec4(1.0, 1.0, 0.2, 1.0);
        }
    }
    glFragColor = col;
}
