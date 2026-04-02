#version 420

// original https://www.shadertoy.com/view/ssXSD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 solveCubic(in float a, in float b, in float c, in float d) {
    float aa = a * a, bb = b * b;

    float denom = 3.0 * aa;
    float inflect = b / (3.0 * a);

    float p = c / a - bb / denom;
    float q = bb * b / (13.5 * aa * a) - b * c / denom + d / a;
    float ppp = p * p * p, qq = q * q;

    float p2 = abs(p);
    float v1 = 1.5 / p * q;

    vec4 roots = vec4(0.0, 0.0, 0.0, 1.0);
    if (qq * 0.25 + ppp / 27.0 > 0.0) {
        float v2 = v1 * sqrt(3.0 / p2);
        if (p < 0.0) roots[0] = sign(q) * cosh(acosh(v2 * -sign(q)) / 3.0);
        else roots[0] = sinh(asinh(v2) / 3.0);
        roots[0] = -2.0 * sqrt(p2 / 3.0) * roots[0] - inflect;
    }

    else {
        float ac = acos(v1 * sqrt(-3.0 / p)) / 3.0; // 0π/3,       2π/3,               4π/3
        roots = vec4(2.0 * sqrt(-p / 3.0) * cos(vec3(ac, ac - 2.09439510239, ac - 4.18879020479)) - inflect, 3.0);
    }

    return roots;
}

// Implicit equation: y = 1 / (1 + sqrt(x^2 + y^2)^2)
// ---> y = 1 / (1 + x^2 + y^2)
// ---> x^2y + yz^2 + y - 1 = 0
vec4 iBump(in vec3 ro, in vec3 rd, in float h) {
    float xxzz = dot(ro.xz, ro.xz) + 1.0;
    float xzuw = dot(ro.xz, rd.xz) * 2.0;
    float uuww = dot(rd.xz, rd.xz);

    float coeff1 = uuww * rd.y;
    float coeff2 = rd.y * xzuw + uuww * ro.y;
    float coeff3 = ro.y * xzuw + xxzz * rd.y;
    float coeff4 = xxzz * ro.y - h;

    return solveCubic(coeff1, coeff2, coeff3, coeff4);
}

vec3 nBump(in vec3 p, in float h) {
    return normalize(vec3(p.x * p.y, 0.5 * dot(p.xz, p.xz) + 0.5, p.y * p.z));
}

void main(void) {
    vec2 center = 0.5 * resolution.xy;
    float time = time;

    vec2 mouse = vec2(-0.85, -0.5);
    vec2 uv = (gl_FragCoord.xy - center) / resolution.y;
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 ro = vec3(0.0, 0.0, 8.0);
    vec3 rd = normalize(vec3(uv, -1.0));

    // Rotate with mouse
    float cy = cos(mouse.x), sy = sin(mouse.x);
    float cp = cos(mouse.y), sp = sin(mouse.y);

    ro.yz *= mat2(cp, -sp, sp, cp);
    ro.xz *= mat2(cy, -sy, sy, cy);
    rd.yz *= mat2(cp, -sp, sp, cp);
    rd.xz *= mat2(cy, -sy, sy, cy);

    // Height
    float h = 1.251 + 1.25 * sin(time);
    vec2 offs = 2.0 * sin(2.0 * time + vec2(1.57, 0.0));
    ro.xz -= offs;

    vec4 hits = iBump(ro, rd, h);
    int nHits = int(hits[3]);

    // Find closest valid intersection
    vec3 hitPos;
    float tMin = 1000000.0;
    bool flagHit = false;
    for (int n=0; n < nHits; n++) {
        vec3 hitCandid = ro + rd * hits[n];
        if (hits[n] > 0.0 && hits[n] < tMin) {
            hitPos = hitCandid;
            tMin = hits[n];
            flagHit = true;
        }
    }

    if (flagHit) {
        vec3 n = nBump(hitPos, h);

        hitPos.xz += offs;
        float diff = abs(dot(n, -rd));
        float checkers = mod(dot(floor(hitPos.xz), vec2(1.0)), 2.0);

        //glFragColor = mix(vec4(0.5 + 0.5 * checkers, 0.0, 0.0, 1.0), texture(iChannel0, reflect(-rd, n)), 0.25) * diff;
        //glFragColor = vec4(0.5 + 0.5 * checkers, 0.0, 0.0, 1.0);
        glFragColor = mix(vec4(0.5 + 0.5 * checkers, 0.0, 0.0, 1.0), vec4(0.0), 0.25) * diff;
    }

    else {
        //glFragColor = texture(iChannel0, rd);
    }

    glFragColor.rgb = pow(glFragColor.rgb, vec3(0.75));
}
