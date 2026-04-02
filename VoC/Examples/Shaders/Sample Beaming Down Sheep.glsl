#version 420

// original https://www.shadertoy.com/view/7sScRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A convenient anti-aliased step() using auto derivatives
float aastep(float threshold, float value) {
    float afwidth = 0.7 * length(vec2(dFdx(value), dFdy(value)));
    return smoothstep(threshold-afwidth, threshold+afwidth, value);
}

// Anti-aliased implicit line around v == t, in the spirit of
// aastep(), with line width w specified in fragment space (pixels)
float aaline(float t, float v, float w) {
  float fw = 0.7 * length(vec2(dFdx(v), dFdy(v)));
  return smoothstep(t-0.5*w*fw-fw, t-0.5*w*fw+fw, v)
    - smoothstep(t+0.5*w*fw-fw, t+0.5*w*fw+fw, v);
}

// Compute the shortest distance from p to a line segment from p1 to p2.
float lined(vec2 p1, vec2 p2, vec2 p) {
    vec2 p1p2 = p2 - p1;
    vec2 v = normalize(p1p2);
    vec2 s = p - p1;
    float t = dot(v, s);
    if (t<0.0) return length(s);
    if (t>length(p1p2)) return length(p - p2);
    return length(s - t*v);
}

// Compute the shortest distance from p to a circle
// with center at c and radius r.
float circled(vec2 c, float r, vec2 p) {
    return abs(length(p - c) - r);
}

// psrdnoise (c) Stefan Gustavson and Ian McEwan,
// ver. 2021-12-02, published under the MIT license:
// https://github.com/stegu/psrdnoise/
float psrdnoise(vec2 x, vec2 period, float alpha, out vec2 gradient)
{
    vec2 uv = vec2(x.x+x.y*0.5, x.y);
    vec2 i0 = floor(uv), f0 = fract(uv);
    float cmp = step(f0.y, f0.x);
    vec2 o1 = vec2(cmp, 1.0-cmp);
    vec2 i1 = i0 + o1, i2 = i0 + 1.0;
    vec2 v0 = vec2(i0.x - i0.y*0.5, i0.y);
    vec2 v1 = vec2(v0.x + o1.x - o1.y*0.5, v0.y + o1.y);
    vec2 v2 = vec2(v0.x + 0.5, v0.y + 1.0);
    vec2 x0 = x - v0, x1 = x - v1, x2 = x - v2;
    vec3 iu, iv, xw, yw;
    if(any(greaterThan(period, vec2(0.0)))) {
        xw = vec3(v0.x, v1.x, v2.x);
        yw = vec3(v0.y, v1.y, v2.y);
        if(period.x > 0.0)
            xw = mod(vec3(v0.x, v1.x, v2.x), period.x);
        if(period.y > 0.0)
            yw = mod(vec3(v0.y, v1.y, v2.y), period.y);
        iu = floor(xw + 0.5*yw + 0.5); iv = floor(yw + 0.5);
    } else {
        iu = vec3(i0.x, i1.x, i2.x); iv = vec3(i0.y, i1.y, i2.y);
    }
    vec3 hash = mod(iu, 289.0);
    hash = mod((hash*51.0 + 2.0)*hash + iv, 289.0);
    hash = mod((hash*34.0 + 10.0)*hash, 289.0);
    vec3 psi = hash*0.07482 + alpha;
    vec3 gx = cos(psi); vec3 gy = sin(psi);
    vec2 g0 = vec2(gx.x, gy.x);
    vec2 g1 = vec2(gx.y, gy.y);
    vec2 g2 = vec2(gx.z, gy.z);
    vec3 w = 0.8 - vec3(dot(x0, x0), dot(x1, x1), dot(x2, x2));
    w = max(w, 0.0); vec3 w2 = w*w; vec3 w4 = w2*w2;
    vec3 gdotx = vec3(dot(g0, x0), dot(g1, x1), dot(g2, x2));
    float n = dot(w4, gdotx);
    vec3 w3 = w2*w; vec3 dw = -8.0*w3*gdotx;
    vec2 dn0 = w4.x*g0 + dw.x*x0;
    vec2 dn1 = w4.y*g1 + dw.y*x1;
    vec2 dn2 = w4.z*g2 + dw.z*x2;
    gradient = 10.9*(dn0 + dn1 + dn2);
    return 10.9*n;
}

#define PI 3.141592653589793
#define PHI 1.618033988749895
#define Phi 0.618033988749895

float fracmodphi(float k) {
    // (Pray that this maps to an FMA instruction)
    return k * Phi - floor(k * Phi);
}

//
// Find nearest neighbor in an N-point Fibonacci spiral,
// not scaled to fit in the unit circle but growing
// with N to a radius of ~sqrt(N) around the origin.
// Modified version of the algorithm from the article
// "Spherical Fibonacci Mapping" by Keinert et al,
// ACM Trans. on Graphics 34 (2015), 6, 193.
// Ported from HLSL to GLSL by Stefan Gustavson 2021,
// edited for planar mapping and modified for animation
// by Stefan Gustavson 2022.
// This version is Copyright 2022 Stefan Gustavson, released
// under the terms of the MIT license ("use freely with
// credit"): https://opensource.org/licenses/MIT
// 
// The vec3 return value has the position of the nearest
// neighbor in .xy, and its integer index (k) in .z.
// A gradual blend between configurations with N and N+1
// points can be achieved by calling the function with
// intN = floor(t), fracN = fract(t), N <= t < N+1.
// Indices are numbered from 0 up outwards from the origin.
// If you want the index to "follow" a point as it "moves
// outwards" with an animated N, the index needs to be
// recomputed as (intN - k). The point set is not limited
// to N points -- the point returned is the nearest neighbor
// on the infinite plane, with k as large as it takes.
// Mask on k if you want to limit the number of cells.
//
vec3 inversePF(vec2 p, float intN, float fracN) {
    vec3 nn;
    float theta = min(atan(p.y, p.x), PI); // min() to dodge NaN
    float r2 = dot(p,p);
    float i = max(0.0, r2-0.5+fracN);
    float k = max(2.0, 1.0+floor(log(sqrt(5.0)*PI*(i+0.5))/2.0/log(PHI)));
    // F0, F1 are actually faster to compute with pow()
    // than by using an array of precomputed values
    float Fk = pow(PHI, k)/sqrt(5.0);
    float F0 = floor(Fk + 0.5);
    float F1 =  floor(Fk * PHI + 0.5);
    float B0 = fracmodphi(F0);
    B0 = (B0 > 0.62) ? B0-1.0 : B0;
    float B1 = fracmodphi(F1);
    B1 = (B1 > 0.62) ? B1-1.0 : B1;
    mat2 B = mat2(2.0*PI*B0, F0,  // Note how simple this B is, compared to
                  2.0*PI*B1, F1); // the spherical mapping in the reference
    mat2 invB = inverse(B);
    float ctheta = theta + 2.0*PI*fracmodphi(intN);
    float ci = i + 0.5 + fracN;
    vec2 c = floor(invB * vec2(ctheta, ci));
    float dsqmin = 4.0; // Actual min dsq is always less than this
    float r, dsq;
    vec2 q;
    for (float s = 0.0; s < 4.0; s++) { // This loop is a little awkward
        i = dot(vec2(F0, F1),
            vec2(mod(s, 2.0), floor(s*0.5)) + c); // (0,0),(1,0),(0,1),(1,1)
        i = abs(i); // abs() eliminates some misses near the origin
        theta = 2.0*PI*fracmodphi(i-intN); // Set theta=0 at index intN
        r = sqrt(i+0.5+fracN);
        q = vec2(cos(theta)*r, sin(theta)*r);
        dsq = dot(p-q, p-q); // Most numerically sound measure
        if (dsq < dsqmin) {
            dsqmin = dsq;
            nn.xy = q;
            nn.z = i;
        }
    }
    // The algorithm finds the closest point in the set for fracN=0,
    // but it has a few glitches close to some Voronoi boundaries
    // near the origin, where points move around a lot with fracN.
    // The most blatant error is that we sometimes miss cell 0
    // near the origin. Let's fix that, because it encroaches on
    // the useful circular portion of cell 0, but leave the rest.
    // (Straightening out the loop above and just adding this at
    // the end would make it less of a "repeated code" boo-boo,
    // but GLSL compilers inline almost everything anyway.)
    if(r2 < 3.0) {
        theta = 2.0*PI*fracmodphi(0.0-intN);
        r = sqrt(0.0+0.5+fracN);
        q = vec2(cos(theta)*r, sin(theta)*r);
        dsq = dot(p-q, p-q);
        if (dsq < dsqmin) {
            dsqmin = dsq;
            nn.xy = q;
            nn.z = 0.0;
        }
    }
    return nn;
}

vec4 sheep(vec2 uv, vec2 noiseoffset, float time) {
    // A cartoon-style drawing of a sheep (RGB color and alpha mask).
    // Copyright 2022 Stefan Gustavson (stefan.gustavson@gmail.com).
    // This function is released under the MIT license:
    // https://opensource.org/licenses/MIT
    //
    // The sheep is centered at (0.5,0.5), with a body of radius ~ 0.3.
    // It has a bounding box of approximately (0.15, 0.1, 0.85, 0.85),
    // and fits inside a circle af radius 0.4 centered at (0.5, 0.45).
    float r = length(uv-0.5);
    vec2 g;
    float rn = r - 0.025*abs(psrdnoise((uv+noiseoffset)*6.0, vec2(0.0), 0.0, g));
    rn -= 0.012*abs(psrdnoise((uv+noiseoffset)*12.0, vec2(0.0), 0.0, g));

    float sheepbody = 1.0-aastep(0.3, rn);
    float sheepoutline = aaline(0.3, rn, 2.0);
    vec2 headpos = vec2(0.62, 0.55);
    float sheephead = 1.0-aastep(0.1, lined(headpos, headpos+vec2(0.05, -0.08), uv));
    float sheepleftear = 1.0 - aastep(0.03, 
        lined(headpos+vec2(-0.07, 0.01), headpos+vec2(-0.13, -0.07), uv));
    float sheeprightear = 1.0 - aastep(0.03, 
        lined(headpos+vec2(0.05, 0.05), headpos+vec2(0.14, 0.03), uv));
    const vec2 eyepos1 = vec2(-0.01, -0.01);
    const vec2 eyepos2 = vec2(0.06, 0.01);
    float sheepeyes = 1.0-aastep(0.03, min(length(uv-vec2(headpos+eyepos1)),
                                           length(uv-vec2(headpos+eyepos2))));
    psrdnoise(noiseoffset+time*0.1*vec2(sqrt(3.0), sqrt(5.0)), vec2(0.0), 0.0, g);
    vec2 sheeplook = 0.003*g; // gaze direction, keep within radius 0.015
    float sheeppupils = 1.0-aastep(0.015, min(length(uv-vec2(headpos+eyepos1+sheeplook)),
                                              length(uv-vec2(headpos+eyepos2+sheeplook))));
    float sheepleg1 = aastep(0.03,lined(vec2(0.45,0.25), vec2(0.43,0.15), uv));
    float sheepleg2 = aastep(0.03,lined(vec2(0.65,0.25), vec2(0.67,0.15), uv));
    float sheepfrontlegs = 1.0 - min(sheepleg1, sheepleg2);
    float sheepleg3 = aastep(0.03,lined(vec2(0.35,0.28), vec2(0.33,0.18), uv));
    float sheepleg4 = aastep(0.03,lined(vec2(0.55,0.28), vec2(0.57,0.18), uv));
    float sheephindlegs = 1.0 - min(sheepleg3, sheepleg4);
    vec3 bgcolor = vec3(0.0); // "Transparent black" outside alpha-mask
    vec3 woolcolor = vec3(1.0); // Snow white - they had a bath in the spaceship
    vec3 skincolor = vec3(0.0); // Black
    vec3 sheepcolor;
    sheepcolor = mix(bgcolor, vec3(0.0), sheephindlegs);
    sheepcolor = mix(sheepcolor, woolcolor, sheepbody);
    sheepcolor = mix(sheepcolor, skincolor, sheepfrontlegs);
    sheepcolor = mix(sheepcolor, skincolor, sheepoutline);
    sheepcolor = mix(sheepcolor, skincolor, sheepleftear);
    sheepcolor = mix(sheepcolor, skincolor, sheeprightear);
    sheepcolor = mix(sheepcolor, skincolor, sheephead);
    sheepcolor = mix(sheepcolor, vec3(1.0), sheepeyes); // flat white
    sheepcolor = mix(sheepcolor, vec3(0.0), sheeppupils); // flat black
    
    float sheepmask = max(max(sheepbody, sheepoutline), max(sheephindlegs, sheepfrontlegs));
    sheepmask = max(sheepmask, sheeprightear); // Might poke out for some noise offsets
    return vec4(sheepcolor, sheepmask);
}

void main(void)
{
    // Teleport in new sheep for this portion of the time,
    // move flock to make room for more the rest of the time.
    float beamtime = 0.5;
    float SPS = 0.5; // Sheep per second
    
    float starttime = 0.0; // Increase this to start with some sheep already arrived
    float sheeptime = starttime+time*SPS; // Our preferred time unit is "1 sheep"
    
    float intN = floor(sheeptime); // Current number of sheep
    float fracN = (clamp(fract(sheeptime), beamtime, 1.0)-beamtime)/(1.0-beamtime);
    bool scotty = (fract(sheeptime) < beamtime); // Livestock transport beam active,
    float fadein = clamp(fract(sheeptime)/beamtime, 0.0, 1.0); // please stand back
    
    // Zoom out to fit most of the flock in the viewport as it grows
    float scale = 1.5*max(4.0, sqrt(sheeptime));
    float uvscale = 1.0/max(resolution.x, resolution.y);
    vec2 uvcenter = 0.5*resolution.xy;
    // Adjust scale by mouse drags (down-drag zooms out, up-drag zooms in)
    float zoom = 1.5;
    vec2 uv = zoom*scale*(uvscale*(gl_FragCoord.xy-uvcenter));

    // This is for frequency clamping of the noise sum for the grass
    float dP = max(length(dFdx(uv)), length(dFdy(uv)));

    vec2 g, gsum; // To hold gradient from psrdnoise
    float blend1, blend2; // Blend weights for noise clamping
    float grassnoise = 0.0;
    if(dP < 1.0/10.0) {
        blend1 = smoothstep(10.0, 20.0, 1.0/dP);
        grassnoise = blend1*psrdnoise(uv*10.0,vec2(0.0), 0.0, gsum);
        if(dP < 1.0/17.0) {
            blend2 = smoothstep(17.0, 37.0, 1.0/dP);
            grassnoise += 0.5*blend2*psrdnoise(uv*17.0-gsum*0.1, vec2(0.0), 0.0, g);
            if(dP < 1.0/37.0) { // Allow this one to pop in, it's low-contrast
                gsum += g;
                grassnoise += 0.25*psrdnoise(uv*37.0-gsum*0.1, vec2(0.0), 0.0, g);
            }
        }
    }
    vec3 bgcolor = vec3(0.0,0.6+0.1*grassnoise, 0.0);

    // Find the nearest neighbor to uv among the Fibonacci spiral point set
    vec3 nn = inversePF(uv, intN, fracN);

    float beamnoise, beampattern;
    vec3 beamcolor;
    if(nn.z >= intN) {
        glFragColor = vec4(bgcolor, 1.0); // Hide cells with index > intN
    } else {
        float sheepnumber = intN-nn.z; // Count the sheep
        // Mask out discontinuities in local uv (for auto-derivative AA)
        float mask = 1.0-step(0.77, length(uv-nn.xy)); // Sheep is inside this circle
        vec2 localuv = vec2(0.5,0.45)+(uv-nn.xy)*0.5; // Scale 2x and reposition
        localuv.x = (mod(sheepnumber, 2.0) >= 0.5) ? localuv.x : 1.0-localuv.x; // Flip odd sheep
        vec4 sheepRGBA = sheep(localuv, sheepnumber*vec2(sqrt(3.0), sqrt(5.0)), time);
        vec3 mixcolor = mix(bgcolor, sheepRGBA.rgb, sheepRGBA.a*mask);
        if(scotty && (nn.z == 0.0)) { // Beam-in visual effect on sheep #0 ("#N", but really #0)
            beamnoise = psrdnoise(localuv*vec2(10.0, 20.0), vec2(0.0), time*30.0, g);
            beamnoise += 0.6*psrdnoise(localuv*vec2(17.0,33.0)+0.1*g, vec2(0.0), time*15.0, g);
            beampattern = aastep(fadein, 0.5+0.5*beamnoise);
            beamcolor = mix(bgcolor, vec3(1.0,0.0,1.0), beampattern*sheepRGBA.a*mask);
            mixcolor = mix(beamcolor, mixcolor,
                (1.0-beampattern)*sheepRGBA.a*mask*clamp(fadein, 0.3, 1.0)); // Ugh, that blend
        }
        glFragColor = vec4(mixcolor,1.0);
     }
}
