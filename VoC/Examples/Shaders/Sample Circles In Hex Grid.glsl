#version 420

// original https://www.shadertoy.com/view/tsKyRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 colorA = vec3(255., 252., 167.) / 255.;
const vec3 colorB = vec3(117., 252., 167.) / 255.;
const vec3 colorC = vec3(167., 247., 255.) / 255.;

const vec3 cols[3] = vec3[3](colorA, colorB, colorC);

// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    p += vec2(523.124, 244.155);
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float sDistToArc(vec2 uv, vec2 A, vec2 B, float d){
    vec2 v = B - A;
    vec2 n = normalize(vec2(-v.y, v.x));
    vec2 c = A + v / 2.;
    float l = length(v) / 2.;
    if (abs(d) < 0.000001){
        return dot(n, uv - c) + max((abs(dot(normalize(v), uv - c)) - l) * 100., 0.);
    }
    if (d > 0.){
        float h = (l * l) / 2. / d - d / 2.;
        vec2 p = vec2(dot(normalize(v), uv - c), dot(n, uv - c)) - vec2(0., -h);
        if (abs(p.x) > l){
            return 1e9;
        }
        if (p.y < 0.){
            return -1e9;
        }
        return ((length(p) - abs(h + d)));
    } else {
        float h = (l * l) / 2. / d - d / 2.;
        vec2 p = vec2(dot(normalize(v), uv - c), dot(n, uv - c)) - vec2(0., -h);
        if (p.y > 0. || abs(p.x) > l){
            return 1e9;
        }
        return (-(length(p) - abs(h + d)));
    }
}

float getD(vec2 id){
    float h = sqrt(3.) / 6.;
    float d = sqrt(0.25 + h * h) - 0.5;
    float k = 1.2;
    float last = floor(hash12(vec2(hash12(id), floor(time * k)) + 1.) * 2.) * 2. - 1.;
    float new = floor(hash12(vec2(hash12(id), floor(time * k) + 1.) + 1.) * 2.) * 2. - 1.;
    float now = mix(last, new, fract(time * k));                 
    return d * (now);
}

float getDist(vec2 lv, vec2 A, vec2 B, vec2 id){
    float s = ((A - B).x + (A - B).y) / abs((A - B).x + (A - B).y);
    return sDistToArc(lv, A, B, 
                      getD(id + (A + B) / 2.) * s
                     );
}

vec3 TriCoord(vec2 uv){
    vec2 ans;
    const float sqrt3 = sqrt(3.);
    vec2 v = normalize(vec2(3., sqrt3));
    ans.y = floor(uv.y / sqrt3 * 2.) * sqrt3 / 2. + sqrt3 / 4.;
    ans.x = floor(dot(uv, v) / sqrt3 * 2.) - ans.y / sqrt3 + 0.5;
    float h = sqrt3 / 6.;
    vec2 lv = uv - ans;
    float d = sqrt(0.25 + h * h) - 0.5;
    vec2 LC = vec2(-0.25, h / 2.);
    vec2 RC = vec2(0.25, -h / 2.);
    vec2 LLC = vec2(-0.75, -h / 2.);
    vec2 RDC = vec2(0.25, -h / 2. - h * 2.);
    vec2 RRC = vec2(0.75, h / 2.);
    vec2 UC = vec2(-0.25, h / 2. + h * 2.);
    float dd = abs(getDist(lv, RC, LC, ans));
    dd = min(dd, abs(getDist(lv, LC, LLC, ans)));
    dd = min(dd, abs(getDist(lv, RC, RDC, ans)));
    dd = min(dd, abs(getDist(lv, RRC, RC, ans)));
    dd = min(dd, abs(getDist(lv, UC, LC, ans)));
    dd *= 40.;
    dd = min(dd, 1.);
    if (getDist(lv, LC, RC, ans) < 0. || getDist(lv, LLC, LC, ans) < 0. || getDist(lv, RC, RDC, ans) < 0.){
        return cols[int(mod(ans.x + mod(ans.y, 2.), 3.))] * dd;
    }
    if (getDist(lv, RC, LC, ans) < 0. || getDist(lv, RRC, RC, ans) < 0. || getDist(lv, LC, UC, ans) < 0.){
        return cols[int(mod(ans.x + mod(ans.y, 2.) + 2., 3.))] * dd;
    }
    return cols[int(mod(ans.x + mod(ans.y, 2.) + 1., 3.))] * dd;
    return vec3(dd * 20.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    glFragColor.rgb = TriCoord(uv * 5.);
}
