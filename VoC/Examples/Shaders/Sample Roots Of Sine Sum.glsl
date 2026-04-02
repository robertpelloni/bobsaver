#version 420

// original https://www.shadertoy.com/view/fdSSDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define draw(d, c) color = mix(color, c, smoothstep(unit, 0.0, d))

float evalSineSum(in float x, in float a, in float b, in float c, in float d, in float e) {
    return a * sin(2.0 * x + b) + c * sin(x + d) + e;
}

float evalSineSumPrime(in float x, in float a, in float b, in float c, in float d, in float e) {
    return 2.0 * a * cos(2.0 * x + b) + c * cos(x + d);
}

// Roots repeat at intervals of 2π
int solveSineSum(in float a, in float b, in float c, in float d, in float e, inout vec4 roots) {
    float shift = 0.5 * b, s = d - shift, ea = e / a;
    vec2 sc = vec2(sin(s), 2.0 * cos(s)) * c / a;

    // Solve a quartic in tan((x+b/2)/2)
    float qa = ea - sc.x;
    float qb = sc.y - 4.0;
    float qc = 2.0 * ea;
    float qd = sc.y + 4.0;
    float qe = ea + sc.x;

    qb /= qa; qc /= qa; qd /= qa; qe /= qa; // Divide by leading coefficient to make it 1

    float bb = qb * qb;
    float p = qc - 0.375 * bb;
    float q = qd - 0.5 * qb * qc + 0.125 * bb * qb;
    float r = qe - 0.25 * qb * qd + 0.0625 * bb * qc - 0.01171875 * bb * bb;
    int nroots = 0;

    // Solve for an arbitary root to x^3 + 2px^2 + (p^2 - 4r)x - q^2
    float ra = 2.0 * p;
    float rb = p * p - 4.0 * r;
    float rc = -q * q;

    float raa = ra * ra;
    float inflect = ra / 3.0;

    float rp = rb - raa / 3.0;
    float rq = raa * ra / 13.5 - ra * rb / 3.0 + rc;
    float rppp = rp * rp * rp, rqq = rq * rq;

    float p2 = abs(rp);
    float v1 = 1.5 / rp * rq;

    float lambda;
    if (rqq * 0.25 + rppp / 27.0 > 0.0) {
        float v2 = v1 * sqrt(3.0 / p2);
        if (rp < 0.0) lambda = sign(rq) * cosh(acosh(v2 * -sign(rq)) / 3.0);
        else lambda = sinh(asinh(v2) / 3.0);
        lambda = -sqrt(p2 / 3.0) * lambda;
    }

    else lambda = sqrt(-rp / 3.0) * cos(acos(v1 * sqrt(-3.0 / rp)) / 3.0);
    lambda = 2.0 * lambda - inflect;

    // Solve two quadratic equations (checking for negative sqrts which should be complex)
    if (lambda < 0.0) return nroots;
    float sqrtLambda = sqrt(lambda);

    float pLambda = p + lambda, qLambda = q / sqrtLambda;
    float offs = 0.25 * qb;

    float foo = lambda - 2.0 * (pLambda + qLambda);
    float bar = lambda - 2.0 * (pLambda - qLambda);

    if (foo >= 0.0) {
        roots.xy = atan((vec2(1.0, -1.0) * sqrt(foo) + sqrtLambda) * 0.5 - offs) * 2.0 - shift;
        nroots += 2;
    }

    if (bar >= 0.0) {
        vec2 others = atan((vec2(1.0, -1.0) * sqrt(bar) - sqrtLambda) * 0.5 - offs) * 2.0 - shift;
        if (nroots > 0) roots.zw = others;
        else roots.xy = others;
        nroots += 2;
    }

    return nroots;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y * 8.0;
    float unit = 16.0 / resolution.y;
    float t = 0.25 * unit;
    vec3 color = vec3(1.0);

    // Grid
    draw(abs(mod(uv.x + 0.25, 0.5) - 0.25) + t, vec3(0.0, 0.0, 1.0));
    draw(abs(mod(uv.y + 0.25, 0.5) - 0.25) + t, vec3(0.0, 0.0, 1.0));
    draw(abs(uv.x), vec3(1.0, 0.0, 0.0));
    draw(abs(uv.y), vec3(1.0, 0.0, 0.0));

    // Parameters
    float a = sin(time * 0.25) * 1.25;
    float b = sin(time) * 2.0;
    float c = sin(time) * 2.0;
    float d = cos(time * 0.75);
    float e = sin(time * 0.5);

    // Draw the function and its roots
    float fx = evalSineSum(uv.x, a, b, c, d, e);
    float dx = evalSineSumPrime(uv.x, a, b, c, d, e);
    draw(abs(uv.y - fx) / sqrt(1.0 + dx * dx) - t, vec3(0.5, 0.0, 0.5));

    vec4 roots;
    int nroots = solveSineSum(a, b, c, d, e, roots);
    for (int n=0; n < nroots; n++) {
        draw(length(vec2(mod(uv.x - roots[n] + 3.14, 6.28) - 3.14, uv.y)) - 0.1, vec3(0.0));
    }

    glFragColor = vec4(color, 1.0);
}
