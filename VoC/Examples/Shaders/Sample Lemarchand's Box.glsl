#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wddBzS

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Lemarchand's Box
//
// ...from the Hellraiser series.
// A few firsts for me - Bump mapping, blood(!), and a different camera system.
// Quite happy, but would like to have added electricity arcs. Alas I'm hitting
// Shadertoy's 'Max 5 second' compile time rule...
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane
// and a bunch of others for sharing their knowledge!

#define MIN_DIST         0.0015
#define MAX_DIST         50.0
#define MAX_STEPS        72.0
#define SHADOW_STEPS     30.0
#define MAX_SHADOW_DIST  18.0

float lift, hatch, circRot, chain;

// #define AA  // Enable this line if your GPU can take it!

struct Hit {
    float d;
    vec4 po;
    float spe; // 0: None, 30.0: Shiny
};

// Thanks Shane - https://www.shadertoy.com/view/lstGRB
float n31(vec3 p) {
    const vec3 s = vec3(7.0, 157.0, 113.0);
    vec3 ip = floor(p);
    vec4 h = vec4(0.0, s.yz, s.y + s.z) + dot(ip, s);
    p -= ip;
    
    h = mix(fract(sin(h) * 43758.5453), fract(sin(h + s.x) * 43758.5453), p.x);
    
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float n11(float n) {
    float flr = floor(n);
    n = fract(n);
    vec2 rndRange = fract(sin(vec2(flr, flr + 1.0) * 12.3456) * 43758.5453);
    return mix(rndRange.x, rndRange.y, n * n * (3.0 - 2.0 * n));
}

float istep(float a, float b) { return 1.0 - step(a, b); }

float max2(vec2 v) { return max(v.x, v.y); }

Hit minH(Hit a, Hit b) {
    if (a.d < b.d) return a;
    return b;
}

float remap(float f, float in1, float in2, float out1, float out2) {
    return mix(out1, out2, clamp((f - in1) / (in2 - in1), 0.0, 1.0));
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

vec3 rot(vec3 p, vec3 ax, float a) {
    // Thanks Blackle.
    return mix(dot(ax, p) * ax, p, cos(a)) + cross(ax, p) * sin(a);
}

float opRep(float p, float c) {
    float c2 = c * 0.5;
    return mod(p + c2, c) - c2;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max2(q.yz)), 0.0);
}

float sdUBox(vec3 p) { return sdBox(p, vec3(1.0)); }

float sdCylinder(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
    return min(max2(d), 0.0) + length(max(d, 0.0));
}

vec3 getRayDir(vec3 ro, vec2 uv) {
    const vec3 r = vec3(0.0, 1.0, 0.0);
    vec3 forward = normalize(r - ro),
         right = normalize(cross(r, forward)),
         up = cross(forward, right);
    return normalize(forward + right * uv.x + up * uv.y);
}

float sdFan(vec3 p) {
    float d = 1e7;
    mat2 m = rot(0.785);
    for (int i = 0; i < 4; i++)
        d = min(d, sdBox(p, vec3(0.2 * length(p.xz), 2.0, 2.0))), p.xz *= m;

    return d;
}

float hole(vec3 p) {
    return sdBox(rot(p, vec3(0.0, 1.0, 0.0), 0.78), vec3(0.35, 10.0, 0.35));
}

// Outline square.
float sq(vec2 p, float r1, float r2) {
    float mp = max2(p);
    return step(r1, mp) - step(r2, mp);
}

// Outline circle.
float circ(vec2 p, float r1, float r2) {
    float d = length(p);
    return istep(r1, d) * step(r2, d);
}

vec3 tex(vec4 po) {
    if (po.w == 0.0) // Ground.
        return po.rgb;
    
    if (sdUBox(po.xyz) < 0.0) // Inside cube (Wood)
        return mix(vec3(0.035, 0.02, 0.01), vec3(0.025, 0.015, 0.01), n11(n31(po.xyz * vec3(3.0, 1.0, 3.0)) * 30.0));
    
    // On cube surface.
    const vec2 e = vec2(1.0, -1.0) * 0.00001;
    vec3 n = normalize(e.xyy * sdUBox(po.xyz + e.xyy) + 
                        e.yyx * sdUBox(po.xyz + e.yyx) + 
                       e.yxy * sdUBox(po.xyz + e.yxy) + 
                       e.xxx * sdUBox(po.xyz + e.xxx));
    
    float c = 0.0, patt = step(0.25, n31(po.xyz * 42.5) * 2.2 * n31(po.xyz * 10.6));
    vec2 p;
    if (abs(n.x) > 0.001) {
        p = abs(po.zy);
        
        // Decoration lines.
        c = istep(0.015, abs(abs(po.z + 0.05 * sign(po.y)) - 0.04)) +
            istep(0.015, abs(p.y - 0.04));

        p = abs(po.zy * rot(0.785));
        c += istep(0.015, abs(p.x - 0.04)) + istep(0.015, abs(p.y - 0.04));
        float d = step(0.0, p.x - 0.02) * step(0.0, p.y - 0.02);

        // Decoration squares.
        p = abs(abs(po.zy) - 1.0);
        c += sq(p, 0.5, 0.53) + sq(p, 0.56, 0.59);
        c *= d;
        
        // Circle outlines.
        p = abs(po.zy);
        float cc = length(abs(p - 0.45) - 0.45);
        c += istep(0.3, cc) * step(0.27, cc);

        // Inner outline.
        c *= istep(0.8, max2(p));
        c += sq(p, 0.8, 0.83);
        
        c *= step(0.27, cc); // Cut-outs.
        
        c += istep(0.22, cc) + // Circles.
             step(0.88, max2(p)); // Outer square.
    } else if (abs(n.z) > 0.001) {
        // Inner square.
        p = abs(po.xy * rot(0.785));
        c = istep(0.63, max2(p));
        
        // Corner circle segments.
        c += circ(abs(abs(po.xy) - 0.83), 0.55, 0.4);

        // Spiky circle.
        p = abs(po.xy);
        c *= step(0.24, length(p)) *
             step(0.42 * pow(abs(sin(1.57 + atan(po.y, po.x) * 4.0)), 10.0), length(p));

        // Outer square.
        c += step(0.88, max2(p));
    } else {
        // Surface pattern.
        c += step(0.3, ((n31(po.xyz * 47.5) + n31(po.xyz * 30.0)) * n31(po.xyz * 7.5)) / 2.0);
        
        // Outer square.
        c += step(0.92, max2(abs(po.xz)));

        // Radial lines.
        c += circ(abs(po.xz), 0.62, 0.56);
        p = vec2(1.0) * rot(sin(atan(po.z, po.x) * 16.0 + 4.5));
        c *= step(0.3, p.x - 0.1);
        c += istep(0.3, abs(p.x - 0.1));

        // Cut-out circle.
        c *= step(0.56, length(po.xz));
        
        // Circle (and pattern).
        p = po.xz * rot(circRot * 1.57);
        c += istep(0.5, length(po.xz)) *
             1.0 - (istep(0.12 - hatch, mod(atan(p.x, p.y) + 1.57, 1.57)) * step(0.01, mod(clamp(length(p) + 0.12, 0.32, 0.6), 0.04)));
        
        p = abs(po.xz);
        patt = 1.0;
    }

    // Outer square.
    c *= istep(0.98, max2(p));
    
    return mix(
        vec3(0.018, 0.011, 0.005),
        mix(mix(vec3(0.13, 0.09, 0.002), vec3(0.3, 0.23, 0.006), n31(po.xyz * 58.6)), vec3(0.95, 0.8, 0.4) * 0.2, n31(po.xyz * 50.0)),
        min(c, patt));
}

Hit topBox(vec3 p) {
    p.y -= min(sin(lift * 3.141) * 6.0, 2.0);
    p.xz *= rot(max(0.0, smoothstep(0.0, 3.0, ((lift - 0.1) * 6.0)) * 3.141 / 4.0));

    float b = sdUBox(p), // Whole box.
          c = sdCylinder(p, 0.5, 1.0); // Central circle.

    vec3 pp = p;
    pp.y -= 0.99;
    pp.xz = abs(pp.xz);
    pp -= vec3(0.25, 0.0, 0.25);
    pp = rot(pp, normalize(vec3(-1.0, 0.0, 1.0)), hatch * 2.0);
    float l = max(sdBox(pp, vec3(0.26, 0.01, 0.26)), length(p.xz) - 0.5), // Lid.
          ho = hole(p);
    
    Hit h = Hit(0.0, vec4(p, 1.0), step(0.0, b) * 50.0);
    p.xz *= rot(0.2);
    h.d = max(min(max(b, sdFan(p)), c), -ho);
    h.d = min(h.d, l);
    
    return h;
}

Hit botBox(vec3 p) {
    float b = sdUBox(p), // Whole box.
          c = sdCylinder(p, 0.45, 0.95), // Central circle.
          ho = hole(p);      
    
    Hit h = Hit(0.0, vec4(p, 2.0), step(0.0, b) * 50.0);
    p.xz *= rot(0.2);
    h.d = min(c, max(max(b, -sdFan(p)), 0.5 - length(p.xz)));

    return h;
}

float flrPat(vec3 p) {
    p.x = mod(p.x, 1.0) - 0.5;
    p.y += 0.06;
    return length(p.xy) - 0.1 * abs(sin(p.z * 3.141));
}

Hit flr(vec3 p) {
    p.y += 1.04;

    float splat = n31(p * 30.12);
    vec3 rgb = mix(mix(vec3(mix(0.13, 0.17, n31(p * 8.28))), vec3(0.11, 0.12, 0.13), splat), vec3(0.125, 0.002, 0.002) * splat, splat * 0.3 + smoothstep(0.6, 0.8, n31(p * 0.46)));
    
    p.xz *= rot(0.3);
    return Hit(min(p.y, min(flrPat(p), flrPat(p.zyx + vec3(0.0, 0.0, 0.5)))), vec4(rgb, 0.0), 10.0);
}

float chn(vec3 p, float i) {
    p.xy *= rot(0.3);
    p.y += i * 2.0 - chain;
    float oy = p.y;
    const vec3 s = vec3(0.075, 0.15, 0.015);
    vec3 s2 = vec3(s.xy, 1.015),
        p2 = p.zyx;
    
    p.y = mod(oy, 0.45) - 0.225;
    p2.y = mod(oy - 0.225, 0.45) - 0.225;
    
    return max(min(max(sdBox(p, s), -sdBox(p, s2)), max(sdBox(p2, s), -sdBox(p2, s2))) - 0.02, oy);
}

Hit chains(vec3 p) {
    const vec2 u = vec2(1.0, -1.0);
    return Hit(min(min(min(chn(p, 0.0), chn(p * u.yxx, 1.0)), chn(p.zyx, 2.0)), chn(p.zyx * u.yxx, 3.0)),
               vec4(0.04, 0.03, 0.03, 0.0),
               50.0);
}

// Map the scene using SDF functions.
Hit map(vec3 p) {
    return minH(minH(minH(topBox(p), botBox(p)), flr(p)), chains(p));
}

vec3 calcNormal(vec3 p) {
    const float sceneAdjust = 0.25;
    const float h = 0.0001 * sceneAdjust;      
    vec3 n = vec3(0.0);
    for (int i = min(frames, 0); i < 4; i++) {
        vec3 e = 0.5773 * (2.0 * vec3((((i + 3) >> 1) & 1), (i >> 1) & 1, i & 1) - 1.0);
        n += e*map(p+e*h).d;
    }
    
    return normalize(n);
}

const vec3 sunPos = vec3(8.0, 3.0, -8.0);

float calcShadow(vec3 p, vec3 lightPos) {
    // Thanks iq.
    vec3 rd = normalize(lightPos - p);
    
    float sha = 1.0, t = 0.1;
    for (float i = 0.0; i < SHADOW_STEPS; i++)
    {
        float h = map(p + rd * t).d;
        sha = min(sha, 15.0 * h / t);
        t += h;
        if (sha < 0.001 || t > MAX_SHADOW_DIST) break;
    }
    
    return clamp(sha, 0.0, 1.0);
}

// Quick ambient occlusion.
float ao(vec3 p, vec3 n, float h) {
    return map(p + h * n).d / h;
}

/**********************************************************************************/

vec3 vignette(vec3 col) {
    vec2 q = gl_FragCoord.xy / resolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.4);
    return col;
}

vec3 applyLighting(vec3 p, vec3 rd, Hit h) {
    const vec3 sunCol = vec3(2.0, 1.6, 1.4);
    vec3 sunDir = normalize(sunPos - p),
         n = calcNormal(p);
    
    float u = tex(h.po + vec2(0.02, 0.0).xyyy).r;
    float r = tex(h.po + vec2(0.02, 0.0).yxyy).r;
    vec3 c = tex(h.po);
    n = normalize(vec3(c.r - r, c.r - u, 0.0) * 0.2 + n);
    float ao = dot(vec2(ao(p, n, 0.5), ao(p, n, 2.0)), vec2(0.3, 0.5)),
        
    // Primary light.
    pri = max(0.0, dot(sunDir, n)),
    
    // Secondary(/bounce) light.
    bounce = max(0.0, dot(sunDir * vec2(-1.0, 0.0).xyx, n)) * 0.3,

    // Specular.
    spe = smoothstep(0.0, 1.0, pow(max(0.0, dot(rd, reflect(sunDir, n))), h.spe)) * h.spe / 10.0,
    
    // Fresnel
    fre = smoothstep(0.7, 1.0, 1.0 + dot(rd, n)),
    
    // Fog
    fog = exp(-length(p) * 0.14);
    
    // Combine.
    return mix(((pri * mix(0.4, 1.0, calcShadow(p, sunPos)) + bounce) * ao + spe) * sunCol * c, vec3(0.01), fre) * fog;
}

vec3 march(vec3 ro, vec3 rd) {
    // Raymarch.
    vec3 p;
    
    float d = 0.01;
    Hit h;
    for (float i = 0.0; i < MAX_STEPS; i++) {
        p = ro + rd * d;
        h = map(p);
        
        if (abs(h.d) < MIN_DIST * d || d > MAX_DIST)
            break;
        
        d += h.d; // No hit, so keep marching.
    }
    
    if (d > MAX_DIST)
        return vec3(0.0); // Distance limit reached - Stop.
    
    // Lighting.
    return applyLighting(p, rd, h);
}

void main(void)
{
    lift = hatch = circRot = chain = 0.0;

    // Camera.
    float time = mod(time, 45.0);
    float t = min(min(min(time, abs(time - 8.0)), abs(time - 12.0)), abs(time - 36.0));
    float dim = 1.0 - pow(abs(cos(clamp(t, -1.0, 1.0) * 1.57)), 10.0);
    
    vec3 cam;
    
    if (time < 8.0) {
        cam = mix(vec3(0.5, 0.5, 18.75), vec3(-0.5, 0.0, 3.75), remap(time, 0.0, 8.0, 0.0, 1.0));
    }
    else if (time < 12.0) {
        cam = mix(vec3(0.0, 0.0, 5.6), vec3(-0.5, 0.05, 5.6), remap(time, 8.0, 12.0, 0.0, 1.0));
    }
    else if (time < 36.0) {
        cam = mix(vec3(0.12, 0.7, 3.67), vec3(0.12, 0.7, 5.0), remap(time, 15.0, 30.0, 0.0, 1.0));
        circRot = smoothstep(0.0, 1.0, remap(time, 22.0, 24.0, 0.0, 1.0)) - smoothstep(0.0, 1.0, remap(time, 13.0, 15.0, 0.0, 1.0));
        lift = remap(time, 16.0, 21.0, 0.0, 1.0) - remap(time, 25.0, 30.0, 0.0, 1.0);
        hatch = remap(time, 31.0, 34.0, 0.0, 0.98);
    } else {
        hatch = 1.0;
        chain = (time - 36.0) * 4.0;
        cam = mix(vec3(0.02, 0.98, 5.78), vec3(0.02, 1.0, 2.56), smoothstep(0.0, 1.0, remap(time, 36.0, 37.0, 0.0, 1.0)));
        cam.z -= remap(time, 40.0, 41.0, 0.0, 1.2);
        dim = remap(time, 40.5, 41.0, 1.0, 0.0); 
    }

    vec3 ro = vec3(0.0, 0.0, -cam.z);
    ro.yz *= rot(cam.y * -1.4);
    ro.xz *= rot(cam.x * -3.141);
    
    vec3 col = vec3(0.0);
#ifdef AA
    for (float dx = 0.0; dx <= 1.0; dx++) {
        for (float dy = 0.0; dy <= 1.0; dy++) {
            vec2 uv = (gl_FragCoord.xy + vec2(dx, dy) * 0.5 - 0.5 * resolution.xy) / resolution.y;
#else
            vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
#endif

            col += march(ro, getRayDir(ro, uv));
#ifdef AA
        }
    }
    col /= 4.0;
#endif
    
    // Output to screen.
    glFragColor = vec4(vignette(pow(col * dim, vec3(0.4545))), 1.0);
}
