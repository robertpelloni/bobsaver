#version 420

// original https://www.shadertoy.com/view/WdSfDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define inf 1000000.0
#define M_PI 3.1415926

float map(in vec3 p) {
    vec3 z = p;
    float r, theta, phi;
    float dr = 1.0;
    float power = 8.0;

    for(int i = 0; i < 8; ++i)
    {
        r = length(z);

        if(r > 2.0)
            continue;

        theta = power * atan(z.y / z.x);
        phi   = power * (asin(z.z / r) + time * 0.2);

        dr = pow(r, power - 1.0) * dr * power + 1.0;
        r = pow(r, power);

        z = r * vec3(cos(theta) * cos(phi),
                     sin(theta) * cos(phi),
                     sin(phi)) + p;
    }

    return 0.5 * log(r) * r / dr;
}

float cast_ray(in vec3 ro, in vec3 rd) {
    float t = 0.01;
    for (int i = 0; i < 100; ++i) {
        vec3 p = ro + t * rd;

        float h = map(p);
        if (h < 0.001) break;
        if (t > 10.0) break;
        t += h;
    }
    if (t > 10.0) t = inf;
    return t;
}

vec3 calc_normal(in vec3 p) {
    vec2 e = vec2(0.0001, 0.0);
    //return normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //                      map(p + e.yxy) - map(p - e.yxy),
    //                      map(p + e.yyx) - map(p - e.yyx)));
    float d = map(p);
    return normalize(vec3(map(p + e.xyy) - d,
                          map(p + e.yxy) - d,
                          map(p + e.yyx) - d));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.0) / min(resolution.x, resolution.y);

    float r     = 3.0;
    float theta = 2.0*M_PI * (mouse.x / resolution.x - 0.25);
    float phi   = 1.0*M_PI * (mouse.y / resolution.y + 0.000001);

    vec3 ta = vec3(0.0, 0.0, 0.0);
    vec3 ro = ta + r * vec3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta));

    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = normalize(cross(uu, ww));

    vec3 rd = normalize(vec3(uv.x*uu + uv.y*vv + 1.0*ww));

    vec3 col = vec3(0.);

    float t = cast_ray(ro, rd);
    if (t < inf) {
        vec3 p = ro + t*rd;
        vec3 norm = calc_normal(p);

        vec3 c = vec3(1.0);

        vec3  sun1_dir = normalize(vec3(1.0, 2.0, 3.0));
        float sun1_dif = clamp(dot(norm, sun1_dir), 0.0, 1.0);
        float sun1_sha = step(inf - 1.0, cast_ray(p, sun1_dir)) * (1.0 - 0.2) + 0.2;

        vec3  sun2_dir = normalize(vec3(-1.0, -2.0, -3.0));
        float sun2_dif = clamp(dot(norm, sun2_dir), 0.0, 1.0);
        float sun2_sha = step(inf - 1.0, cast_ray(p, sun2_dir)) * (1.0 - 0.2) + 0.2;

        col = c * clamp(0.6 * (sun1_sha * sun1_dif + sun2_sha * sun2_dif), 0.05, 0.90);
    }
    col = pow(col, vec3(0.4545));

    glFragColor = vec4(col, 1.0);
}
