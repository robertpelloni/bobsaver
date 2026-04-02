#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlySzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float r = resolution.y, ksq = 2. / r, sz = r*0.06, sp = sz*(2.6 + 0.5*cos(time*10.));
    float h = r*0.6, dist = r*1.5, n = r*0.025;
    vec3 p = vec3(r*cos(time*0.23), h, r*sin(time*0.2));
    vec3 w = normalize(-p);
    vec3 u = normalize(cross(w, vec3(0., 1., 0.)));
    vec3 v = cross(u, w);
    vec3 d = w*dist + (gl_FragCoord.xy.x - resolution.x*0.5)*u + (gl_FragCoord.xy.y - resolution.y*0.25)*v;
    d.x += cos(2.*gl_FragCoord.xy.x/h+time*2.)*n;
    d.y += cos(3.*gl_FragCoord.xy.y/h+time*2.1)*n;
    d.z += cos(5.*gl_FragCoord.xy.y/h+time*2.7)*n;
    vec4 col = vec4(0., 0., 0., 1.);
    vec3 pp;
    float t = 1000000., tt;
    for (int ix=-1; ix<=1; ix++) {
        float xx = float(ix)*sp;
        for (int iy=-1; iy<=1; iy++) {
            float yy = (1.5 + float(iy))*sp;
            for (int iz=-1; iz<=1; iz++) {
                float zz = float(iz)*sp;
                tt = (xx + sz - p.x) / d.x;
                if (tt > 0. && tt < t) {
                    pp = p + tt*d;
                    if (pp.y >= yy-sz && pp.y <= yy+sz && pp.z >= zz-sz && pp.z <= zz+sz) {
                        t = tt; col = vec4(1., 0., 0., 1.);
                    }
                }

                tt = (xx - sz - p.x) / d.x;
                if (tt > 0. && tt < t) {
                    pp = p + tt*d;
                    if (pp.y >= yy-sz && pp.y <= yy+sz && pp.z >= zz-sz && pp.z <= zz+sz) {
                        t = tt; col = vec4(1., 0.5, 0., 1.);
                    }
                }

                tt = (zz+sz - p.z) / d.z;
                if (tt > 0. && tt < t) {
                    pp = p + tt*d;
                    if (pp.y >= yy-sz && pp.y <= yy+sz && pp.x >= xx-sz && pp.x <= xx+sz) {
                        t = tt; col = vec4(0., 0., 1., 1.);
                    }
                }

                tt = (zz-sz - p.z) / d.z;
                if (tt > 0. && tt < t) {
                    pp = p + tt*d;
                    if (pp.y >= yy-sz && pp.y <= yy+sz && pp.x >= xx-sz && pp.x <= xx+sz) {
                        t = tt; col = vec4(0., 1., 0., 1.);
                    }
                }

                tt = (yy + sz - p.y) / d.y;
                if (tt > 0. && tt < t) {
                    pp = p + tt*d;
                    if (pp.x >= xx-sz && pp.x < xx+sz && pp.z >= zz-sz && pp.z < zz+sz) {
                        t = tt; col = vec4(1., 1., 0., 1.);
                    }
                }
            }
        }
    }

    tt = (p.y / -d.y);
    if (tt > 0. && tt < t) {
        pp = p + tt*d;
        int ix = int(floor(pp.x * ksq));
        int iz = int(floor(pp.z * ksq));
        float L = 0.7 * 900000.0 / (900000.0 + pp.x*pp.x + pp.z*pp.z);
        if (((ix + iz) & 1) == 0) L *= 0.6;
        col = vec4(1., 1., 1., 1.) * L;
    }
    glFragColor = col;
}
