#version 420

// original https://www.shadertoy.com/view/XsKczR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Nelumbo Rays
// Original shader by AudioPixel
// March 2018 - hepp@audiopixel.com

// Building on techniques by @iq, @alteredq, @mrkishi and others
// Thanks to @cacheflowe & @reinder for advice on ray marching

float soc(vec3 p) {
    vec3 n = normalize(sign(p+1e6));
    return min(min(dot(p.xy, n.xy), dot(p.yz, n.yz)), dot(p.xz, n.xz));
}

mat2 r2d(float a) {
    float sa=sin(a);
    float ca=cos(a);
    return mat2(ca,sa,-sa,ca);
}

vec2 amod(vec2 p, float m) {
    float a=mod(atan(p.x,p.y), m)-m*.5;
    return vec2(cos(a), sin(a))*length(p);
}

float map(vec3 p) {
    float d = 1.0; vec3 o = p;
    float a = mod(o.y+5.0+time, (20.))-10.; a = abs(o.y);
    float ss = time * .4 + sin(time) * .6 ; 
    p.yz *= r2d(sign(a)* (2.*.011 + (ss*.02)) - .2 + (-.1821 - sin(time * .09) * .315 + sin(time * .3) * .6));
    p.xz *= r2d(sign(a)*ss);
    p.xz = amod(p.xz, 0.7853975);
    p.xz = max(abs(p.xz)-(-0.1527 + sin(time) * 2.7), -0.7384 - sin(time * .3) * 1.2);
    p.z = mod(p.z, -1.4761)-(-0.73805);
    float s1 = 8.7073 + sin(time * .4) * 6.;
    p.x = mod(p.x, s1)-(s1 *.5);
    p.y = mod(p.y+2., 22. + sin(time) * .014)-5.;
    d = min(d, soc(max(abs(p)-0.1831, 0.1593)));
    return (length(p*-0.1409)-1.3971)*.2746 - (d * -2.);
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005;
    return normalize(
        e.xyy * map(p + e.xyy) +
        e.yyx * map(p + e.yyx) +
        e.yxy * map(p + e.yxy) +
        e.xxx * map(p + e.xxx));
}

void main(void) {
    vec2 st = (gl_FragCoord.xy/resolution.xy)*2.5-1.;
    st.x *= 1.7;

    vec3 ro = vec3(st, 10.5022);
    vec3 rd = normalize(vec3(st+vec2(0.), -0.4142));
    vec3 mp; mp = ro; float md;

    for (int i=0; i<50; i++) {
        md = map(mp);
        if (md <.001) break;
        mp += (rd * 0.4807)*md*0.8384;
    }

    vec3 c1 = vec3(-0.2386 - (length(ro-mp) * .025) * -1.291), c2, c3;
    vec3 p = ro + rd * (mp);

    if (md > 0.0964) {
        vec3 l = vec3(0);
        vec3 normal = calcNormal(p);
        float dif = clamp(dot(normal, normalize(l - p)), 0., 1.);
        dif *= 5. / dot(l - p, l - p);
        c2 = vec3(pow(dif, .4545)); 
    } else {
        c3 = vec3(p.x * .15);
    }

    vec3 c4 = vec3((mp.z * 2.5) * (md * .05), 0, 0); c2 = vec3((c2.r > 0.5) ? max(c4.r, 2.0 * (c2.r - 0.5)) : min(c4.r, 2.0 * c2.r), (c2.r > 0.5) ? max(c4.g, 2.0 * (c2.g - 0.5)) : min(c4.g, 2.0 * c2.g),(c2.b > 0.5) ? max(c4.b, 2.0 * (c2.b - 0.5)) : min(c4.b, 2.0 * c2.b));
    glFragColor = vec4(abs(c1 - (c2 - c3)), 1.);
}
