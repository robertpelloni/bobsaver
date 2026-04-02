#version 420

// original https://www.shadertoy.com/view/ttfSWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdPlane(vec3 p) {
    return p.y;
}

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdEllipsoid( in vec3 p, in vec3 r) {
    return (length(p / r) - 1.0) * min(min(r.x, r.y), r.z);
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float TTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float opIntersection(float d1, float d2) {
    return max(d1, d2);
}
float sdPlane(vec3 p, vec4 n) {
    // n must be normalized
    return dot(p, n.xyz) + n.w;
}
float opSubtraction(float d1, float d2) {
    return max(-d1, d2);
}

float opOnion( in float sdf, in float thickness) {
    return abs(sdf) - thickness;
}

float opSmoothIntersection(float d1, float d2, float k) {
    float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) + k * h * (1.0 - h);
}
//----------------------------------------------------------------------

//----------------------------------------------------------------------

float plant( in vec3 pos, vec4 type) {
    float l = 0.99 / ((type.w) / (length(pos.xz)));
    float d, di, plane, lay;
    d = l;
    if ((l - type.w) < 0.) {

        for (float i = 0.2; i < .85; i += +.101) {

            di = sdTorus(pos + vec3(0, (0.), 0), vec2(0.14 * type.w + i * type.y, i * type.z * type.w));

            di = opOnion(di, type.x * 0.125 * type.w);
            lay = i * (23.416 * 1.7);
            plane = sdPlane(vec3(pos.x, pos.y, pos.z), vec4(sin(lay), 0, cos(lay), 0));
            di = opIntersection(di,

                abs(plane) - (type.x * type.w) + 0.006 + abs(5. * length(pos.xz) - type.w * type.w) * type.x * .3);

            d = min(d, di);

        }
        d = opIntersection(d, sdSphere(pos + vec3(0, -type.w * 0.9, 0), type.w));

    }

    return d;
}
//-------------------------------------------
vec2 map( in vec3 pos) {
    float Strand, Spread, Lift, Size;
    float sqr = 1.;
    float d = length(pos);
    vec3 pfract = fract(pos / sqr) * sqr;
    vec3 pround = round(pos / sqr) * sqr + vec3(sqr * 0.5, 0, sqr * 0.5);
    vec3 mos = vec3(pfract.x, pos.y, pfract.z);

    float i = (pos - pfract).x;
    float j = (pos - pfract).z;

    Strand = 0.01 + fract(sin(34. + fract(cos(15. + j * .51 - i) * 17.) * 6.) * 99.) * 0.125;
    Spread = 0. + fract(sin(24. + fract(sin(j * 14.3455 - i) * 110.) * 3.) * 99.) * .3;
    Lift = .4 + fract(sin(1039. + fract(sin(10. + i * 7. - j) * 9.) * 6.) * 99.) * .15;
    Size = .5 + fract(sin(i * 2. + j) * 99.) * .5;

    d = min(d, plant(mos - vec3(sqr * 0.5, 0, sqr * 0.5), vec4(Strand, Spread * 1.1, Lift, Size)));

    float plane = sdPlane(vec3(pos.x, pos.y, pos.z), vec4(0, 1, 0, 0));
    d = min(d, plane);

    return vec2(d, 3);

}

vec2 castRay( in vec3 ro, in vec3 rd) {
    float tmin = 1.0;
    float tmax = 20.0;

    /*#if 0
    float tp1 = (0.0 - ro.y) / rd.y;
    if (tp1 > 0.0) tmax = min(tmax, tp1);
    float tp2 = (1.6 - ro.y) / rd.y;
    if (tp2 > 0.0) {
        if (ro.y > 1.6) tmin = max(tmin, tp2);
        else tmax = min(tmax, tp2);
    }#endif*/

    float precis = 0.0002;
    float t = tmin;
    float m = -1.0;
    for (int i = -0; i < 250; i++) {
        vec2 res = map(ro + rd * t);
        if (res.x < precis || t > tmax) break;
        t += res.x * 0.2;
        m = res.y;
    }

    if (t > tmax) m = -1.0;
    return vec2(t, m);
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax) {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 16; i++) {
        float h = map(ro + rd * t).x;
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.10);
        if (h < 0.001 || t > tmax) break;
    }
    return clamp(res, 0.0, 1.0);

}

vec3 calcNormal( in vec3 pos) {
    vec3 eps = vec3(0.001, 0.0, 0.0);
    vec3 nor = vec3(
        map(pos + eps.xyy).x - map(pos - eps.xyy).x,
        map(pos + eps.yxy).x - map(pos - eps.yxy).x,
        map(pos + eps.yyx).x - map(pos - eps.yyx).x);
    return normalize(nor);
}

float calcAO( in vec3 pos, in vec3 nor) {
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float hr = 0.01 + 0.12 * float(i) / 4.0;
        vec3 aopos = nor * hr + pos;
        float dd = map(aopos).x;
        occ += -(dd - hr) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

vec3 render( in vec3 ro, in vec3 rd) {
    vec3 col = vec3(0.3, 0.6, 0.0) + rd.y * 0.8;
    vec2 res = castRay(ro, rd);
    float t = res.x;
    float m = res.y;
    if (m > -0.5) {
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormal(pos);
        vec3 ref = reflect(rd, nor);

        // material        
        col = 0.45 + 0.3 * sin(vec3(0.15, 0.8, 0.00) * (m - 1.0));

        if (m < 1.5) {

            float f = mod(floor(5.0 * pos.z) + floor(5.0 * pos.x), 2.0);
            col = 0.4 + 0.1 * f * vec3(0., 1., 0.);
        }

        // lighitng        
        float occ = calcAO(pos, nor);
        vec3 lig = normalize(vec3(-0.6, 0.7, -0.5));
        float amb = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
        float dif = clamp(dot(nor, lig), 0.0, 1.0);
        float bac = clamp(dot(nor, normalize(vec3(-lig.x, 0.0, -lig.z))), 0.0, 1.0) * clamp(1.0 - pos.y, 0.0, 1.0);
        float dom = smoothstep(-0.1, 0.1, ref.y);
        float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);
        float spe = pow(clamp(dot(ref, lig), 0.0, 1.0), 16.0);

        dif *= softshadow(pos, lig, 0.02, 2.5);
      //  dom *= softshadow(pos, ref, 0.02, 2.5);

        vec3 lin = vec3(0.0);
        lin += 1.20 * dif * vec3(1.00, 0.85, 0.55);
        lin += 1.20 * spe * vec3(1.00, 0.85, 0.55) * dif;
        lin += 0.20 * amb * vec3(0.50, 0.70, 0.55) * occ;
        lin += 0.30 * dom * vec3(0.50, 0.70, 0.55) * occ;
        lin += 0.30 * bac * vec3(0.25, 0.5, 0.25) * occ;
        lin += 0.40 * fre * vec3(1.00, 1.00, 0.55) * occ;
        col = col * lin;

        //col = mix( col, vec3(0.8,0.9,0.05), 1.0-exp( -0.002*t*t ) );

    }

    return vec3(clamp(col, 0.0, 1.0));
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

void main(void) {
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x / resolution.y;
    vec2 mo = mouse*resolution.xy.xy / resolution.xy;

    float time = 15.0 + time;
    vec3 fly = vec3(sin(time * 0.0001936), 0, cos(time * 0.0001345)) * 3000.;
    fly += vec3(sin(time * 0.001563), 0, cos(time * 0.001175)) * 300.;
    // camera    
    vec3 ro = fly + 1.2 * vec3(-0.5 + 3.5 * cos(0.16 * time + 6.0 * mo.x), 3.0 + 2.0 * mo.y, 0.5 + 3.5 * sin(0.16 * time + 6.0 * mo.x));
    vec3 ta = fly + vec3(-0.0, -0.0, 0.);

    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 0.0);

    // ray direction
    vec3 rd = ca * normalize(vec3(p.xy, 2.0));

    // render    
    vec3 col = render(ro, rd);

    col = pow(col, vec3(0.4545));

    glFragColor = vec4(col, 1.0);
}
