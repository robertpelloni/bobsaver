#version 420

// original https://www.shadertoy.com/view/MsVczR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'Hypertori Rays'
// Created by hepp maccoy 2018 hepp@audiopixel.com
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Building on techniques by @iq, @alteredq, @mrkishi and others
// Thanks to @cacheflowe & @reinder for advice on ray marching

mat2 r2d(float a) {
    float sa=sin(a);
    float ca=cos(a);
    return mat2(ca,sa,-sa,ca);
}

vec2 amod(vec2 p, float m) {
    float a=mod(atan(p.x,p.y), m)-m*.5;
    return vec2(cos(a), sin(a))*length(p);
}

float soc(vec3 p) {
    vec3 n = normalize(sign(p+1e6));
    return min(min(dot(p.xy, n.xy), dot(p.yz, n.yz)), dot(p.xz, n.xz));
}

float map(vec3 p) {
    float t = (time * 12.) + sin(time * .9) * 20.;
    float a1 = -13. + sin(time * .8) * .3;
    float a2 = -14.5 + sin(time * .9) * .2;
    float d = 1.0; vec3 o = p;
    float a = mod(o.y+5., (20.))-10.; a = abs(o.y);
    p.yz *= r2d(sign(a)* .2);
    p.xz *= r2d(sign(a)*(t * .04));
    p.xz = amod(p.xz, 0.38205625 + sin(time * .7) * .13);
    p.xz = max(abs(p.xz)-14.552, -14.0311);
    p.z = mod(p.z, a1)-(a1 *.5);
    p.x = mod(p.x, a2)-(a2 *.5);
    p.y = mod(p.y+t, 12.)-5.;
    d = min(d, soc(max(abs(p) + 2., -2.)));
    return (length(p*-0.3637)-0.4866)*1.1851 - (d * (1.8873 + sin(time * 5.4) * .03));
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.8;
    return normalize(
        e.xyy * map(p + e.xyy) +
        e.yyx * map(p + e.yyx) +
        e.yxy * map(p + e.yxy) +
        e.xxx * map(p + e.xxx));
}

void main(void) {
    vec2 st = (gl_FragCoord.xy/resolution.xy)*2.5-1.;
    st.x *= 1.7;
    vec3 l = vec3(0, 0, -15);
    vec3 ro = vec3(st, -18. + sin(time * .8) * 1.5);
    vec3 rd = normalize(vec3(st+vec2(0.), 0.4 + sin(time * .6) * .14));
    vec3 mp; mp = ro;
    float md;
    for (int i=0; i<50; i++) {
        md = map(mp); if (md <.001) break; mp += rd*md;
    }
    vec3 p = ro + rd * (mp);
    vec3 normal = calcNormal(p);
    float dif = clamp(dot(normal, normalize(l - p)), 0., 1.);
    dif *= 5. / dot(l - p, l - p);
    vec3 c2 = vec3(pow(dif, .2424));
    c2 += vec3((mp.z * 2.5) * (md * .05), 0, 0 );
    glFragColor = vec4(c2, 1.);
}
