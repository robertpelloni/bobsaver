#version 420

// original https://www.shadertoy.com/view/wd2cWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 cell;
float g;
float pi = 3.14159;
float time2;

float noise(vec3 p) {
    return fract(sin(dot(p, vec3(4.3243241, 34.234, 234.23))) * 342.234);
}

mat2 rotate(float r) { return mat2(cos(r), sin(r), -sin(r), cos(r)); }

float scene(vec3 p) {
    p.x += p.z * p.z * 0.02 * sin(time2 * 2. * pi);

    p.z += time2 * 40. * pi;
    p.xy *= rotate(p.z * 0.10);

    vec3 cellsize = vec3(4, 4, 0);
    cell = floor(p / cellsize);

    p = mod(p, cellsize) - cellsize / 2.;

    return length(p.xy) - 0.5;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    time2 = mod(time / 10., 1.);

    vec3 cam = vec3(0, 0, -5);
    vec3 dir = normalize(vec3(uv, 1));

    float t = 0.;
    for (int i = 0; i < 128; ++i) {
        t += scene(cam + dir * t) * .7;
        if (t < 0.0001 || t > 50.)
            break;
    }

    vec3 h = cam + dir * t;
    vec2 o = vec2(.001, 0);
    vec3 n = normalize(vec3(scene(h + o.xyy) - scene(h - o.xyy),
                            scene(h + o.yxy) - scene(h - o.yxy),
                            scene(h + o.yyx) - scene(h - o.yyx)));

    vec3 light = normalize(vec3(0, 1, 1));
    float diffuse = max(0., dot(n, light));
    vec3 albedo =
        0.05 + 0.95 * vec3(noise(cell.xyy), noise(cell.yxy), noise(cell.yyx));
    float specular = pow(max(dot(normalize(light + -dir), n), 0.), 10000.);
    float ambient = 0.4;
    float fresnel = min(0.5, pow(1. + dot(n, dir), 4.));
    vec3 bg = vec3(0.001);
    vec3 col = mix((ambient + diffuse) * albedo + specular * vec3(1, 0.5, 0.5),
                   bg, fresnel);

    col = mix(col, bg, 1. - exp(-.0001 * t * t * t)); // apply fog

    col = pow(col, vec3(.454)); // gamma correction

    glFragColor = vec4(col, 1.0);
}
