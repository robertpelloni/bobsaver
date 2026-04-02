#version 420

// original https://www.shadertoy.com/view/MdVXDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float tmax = 50.0;

float hash(float n) {
    return fract(sin(n)*43758.5453);
}

// old school typical perlin noise.
float noise(vec3 g) {
    vec3 p = floor(g);
    vec3 f = fract(g);

    f = f*f*(3.0 - 2.0*f);
    float n = p.x + p.y*57.0 + p.z*113.0;

    float x = mix(hash(n + 0.0), hash(n + 1.0), f.x);
    float y = mix(hash(n + 57.0), hash(n + 58.0), f.x);
    float z = mix(hash(n + 113.0), hash(n + 114.0), f.x);
    float w = mix(hash(n + 170.0), hash(n + 171.0), f.x);

    return mix(mix(x, y, f.y), mix(z, w, f.y), f.z);
}

float noise(vec2 g) {
    vec2 p = floor(g);
    vec2 f = fract(g);

    f = f*f*(3.0 - 2.0*f);
    float n = p.x + p.y*57.0;

    float x = mix(hash(n + 0.0), hash(n + 1.0), f.x);
    float y = mix(hash(n + 57.0), hash(n + 58.0), f.x);
    return mix(x, y, f.y);
}

const mat2 m2 = mat2(
     0.80, 0.60, -0.60, 0.80
);

float fbm(vec2 p) {
    float f = 0.0;

    f += 0.5000*noise(p); p *= m2*2.01;
    f += 0.2500*noise(p); p *= m2*2.03;
    f += 0.1250*noise(p); p *= m2*2.05;
    f += 0.0625*noise(p);
    f /= 0.9375;

    return f;
}

const mat3 m3 = mat3(
     0.00,  0.80,  0.60,
    -0.80,  0.36, -0.48,
    -0.60, -0.48,  0.64
);

float fbm(vec3 p) {
    float f = 0.0;

    f += 0.5000*noise(p); p *= 2.01;
    f += 0.2500*noise(p); p *= 2.03;
    f += 0.1250*noise(p); p *= 2.05;
    f += 0.0625*noise(p);
    f /= 0.9375;

    return f;
}

void rotate(inout vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);

    p = mat2(c, s, -s, c)*p;
}

float segment(vec3 p, vec3 a, vec3 b) {
    vec3 pa = p - a;
    vec3 ba = b - a;

    float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);

    return length(pa - ba*h);
}

float map(vec3 p) {
    // p = position for trees, q = flat, un-modified space.
    vec3 q = p;
    
    // update the y coord to match the plan.
    p.y -= 2.0*noise(0.15*q);

    // a repetition of trees.
    p.z = mod(p.z + 6.0, 12.0) - 6.0;
    p.x = mod(p.x + 12.0, 24.0) - 12.0;

    // rotate the points in space randomly, relative to the tree origin.
    rotate(p.xy, 0.1*noise(p.xz));
    rotate(p.yz, 0.2*noise(p.xz));

    // some factors for mirroring (only mirror at a certain p.y value)
    float g = smoothstep(1.0, 5.0, p.y);
    float s = smoothstep(-10.0, 0.0, -p.y);
    p.xz = -abs(p.xz) + g*s*0.5*p.y; // mirror.

    // udpate the xz coords based on original displacement.
    p.xz += vec2(g*s*0.5*p.y);
    g = smoothstep(2.0, 7.0, p.y);
    s = smoothstep(-10.0, 2.0, -p.y);
    p.xz = -abs(p.xz) + g*s*0.5*p.y; // rinse and repeat.

    p.xz += vec2(g*s*0.5*p.y); // rinse
    g = smoothstep(3.0, 10.0, p.y);
    s = smoothstep(-30.0, 1.0, -p.y);
    p.xz = -abs(p.xz) + g*s*0.5*p.y; // and repeat.

    return min(
        segment(p, vec3(0, -3, 0), vec3(0, 5.5, 0)) - 0.5 
            + 0.20*smoothstep(1.0, 5.0, p.y) // update the radius of the segment
            + 0.25*smoothstep(2.0, 7.0, p.y) // based on the height of the 
            + 0.35*smoothstep(3.0, 10.0, p.y), // geomertry.
        // just a plane with noise deformations.
        q.y + 1.0 - 2.0*noise(0.15*q));
}

// typical ray marcher.
float march(vec3 ro, vec3 rd) {
    float t = 0.0;

    for(int i = 0; i < 250; i++) {
        float d = map(ro + rd*t);
        if(abs(d) < 0.01 || t >= tmax) break;
        t += d*0.25;
    }

    return t;
}

vec3 normal(vec3 p) {
    vec2 h = vec2(0.001, 0.0);
    vec3 n = vec3(
        map(p + h.xyy) - map(p - h.xyy),
        map(p + h.yxy) - map(p - h.yxy),
        map(p + h.yyx) - map(p - h.yyx)
    );

    // typical fbm-valued bumb maping.
    vec3 b = vec3(0);
    if(p.y + 1.0 - 2.0*noise(0.15*p) > 0.1) {
        // trees, no Y varanice.
        vec3 f = vec3(10.0, 0.1, 10.0);

        b += 0.5*vec3(
            fbm(p*f + h.xyy) - fbm(p*f - h.xyy),
            fbm(p*f + h.yxy) - fbm(p*f - h.yxy),
            fbm(p*f + h.yyx) - fbm(p*f - h.yyx)
        );
    } else {
        float f = 1.0;
        b += 0.1*vec3(
            fbm(f*(p + h.xyy)) - fbm(f*(p - h.xyy)),
            fbm(f*(p + h.yxy)) - fbm(f*(p - h.yxy)),
            fbm(f*(p + h.yyx)) - fbm(f*(p - h.yyx))
        );
    }

    return normalize(n + b);
}

float shadow(vec3 p, vec3 l) {
    float res = 1.0;
    float t = 0.5;

    for(int i = 0; i < 100; i++) {
        float d = map(p + l*t);
        t += d*0.50;
        // iq's soft shadow formul.
        res = min(res, 32.0*d/t);
        if(abs(d) < 0.001 || t >= tmax) break;
    }

    return clamp(res, 0.0, 1.0);
}

mat3 camera(vec3 eye, vec3 lat) {
    vec3 ww = normalize(lat - eye);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));

    return mat3(uu, vv, ww);
}

void main(void) {
    vec2 uv = -1.0 + 2.0*(gl_FragCoord.xy/resolution.xy);
    uv.x *= resolution.x/resolution.y;

    // sky/background color;
    vec3 col = mix(vec3(0.0, 0.6, 1.0), vec3(1), smoothstep(0.2, 1.0, fbm(5.0*uv)));

    // construct primary rays.
    vec3 ro = vec3(10.0, 5.0, time);
    vec3 rd = normalize(camera(ro, ro + vec3(-15.0, -3.0, 3))*vec3(uv, 1.97));

    // march, till intersection or max hit.
    float i = march(ro, rd);
    if(i < tmax) { // if intersection distance is less than max we hit something.

        // geometry. intersection position, surface normal.
        vec3 pos = ro + rd*i; 
        vec3 nor = normal(pos);

        // lighting vars, light direction, shadow, diffuse.
        vec3 lig = normalize(vec3(0.8, 0.5, -0.6));
        float sha = shadow(pos, lig) + 0.5*step(-0.9, pos.y - 2.0*noise(0.15*pos)); // hack to get the internal shadows to be less obtrusive.
        float dif = clamp(dot(lig, nor), 0.0, 1.0)*sha;

        col  = 0.2*vec3(1); // ambient
        col += 0.7*dif; //diffuse

        if(pos.y + 1.0 - 2.0*noise(0.15*pos) > 0.1) {
            col *= vec3(0.6, 0.5, 0.2); // trees are just a brown color.
        } else {
            vec3 mat = vec3(0.1, 0.4, 0.1); // ground is green mixed with white.
            mat = mix(mat, vec3(2.0), smoothstep(0.0, 1.0, 2.0*smoothstep(0.4, 1.0, fbm(1.0*pos))));
            col *= mat;
        }

        // freznel term, cranked up to 11 to get the frozen look.
        col += 2.0*pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 2.0)*sha;
    }

    glFragColor = vec4(col, 1);
}
