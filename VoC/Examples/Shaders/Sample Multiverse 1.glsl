#version 420

// original https://www.shadertoy.com/view/XdtyzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// multiverse

#define FOV 40.0

vec3 hash33(vec3 p)
{
    p = fract(p * vec3(443.8975,397.2973, 491.1871));
    p += dot(p.zxy, p.yxz+19.27);
    return fract(vec3(p.x * p.y, p.z*p.x, p.y*p.z));
}

// Modified "stars" function from great shader of user Nimitz.
// https://www.shadertoy.com/view/XsyGWV :

// "Very happy with this star function, cheap and smooth"
vec3 stars(in vec3 p)
{
    vec3 c = vec3(0.);
    float res = 1000.;        
    
    vec3 q = fract(p*(.15*res))-0.5;
    vec3 id = floor(p*(.15*res));
    vec2 rn = hash33(id).xy / 3.;
    float c2 = 1.-smoothstep(0.,.73,length(q * .998));
    c2 *= step(rn.x,.00+0.05);
    c += c2;

    return c*c*.57;
}

vec2 map(vec3 p) {
    return vec2(stars(p * 0.009).r - .14, 0.);
}

vec2 trace(vec3 ro, vec3 rd) {
    vec2 t = vec2(-.2, 0.);
    for (int i = 0; i < 176; i++) {
        vec2 d = map(ro + rd * t.x);
        if (abs(d.x) < 0.005) break;
        t.x += d.x * .7; 
        t.y = d.y;
    }
    return t;
}

float softShadow(vec3 ro, vec3 lp, float k) {
    const int maxIterationsShad = 8;
    vec3 rd = (lp - ro); // Unnormalized direction ray.

    float shade = 1.0;
    float dist = .01;
    float end = max(length(rd), 0.001);
    float stepDist = end / float(maxIterationsShad);

    rd /= end;
    for (int i = 0; i < maxIterationsShad; i++) {
        float h = map(ro + rd * dist).x * 1.;
        shade = min(shade, k*h/dist);
        //shade = min(shade, smoothstep(0.0, 1.0, k * h / dist)); 
        dist += min(h, stepDist * 2.); 
        if (h < 0.001 || dist > end) break;
    }
    return min(max(shade, 0.2), 1.0);
}

// Tetrahedral normal, to save a couple of "map" calls. Courtesy of IQ.
vec3 getNormal( in vec3 p) {
    const vec2 e = vec2(0.001, -0.001);
    return normalize(
        e.xyy * map(p + e.xyy).x +
        e.yyx * map(p + e.yyx).x +
        e.yxy * map(p + e.yxy).x +
        e.xxx * map(p + e.xxx).x);
}

vec3 doColor( in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, float mat) {
    vec3 sceneCol = vec3(0.0);
    
    vec3 ld = lp - sp; 
    float lDist = max(length(ld), 0.001); 
    ld /= lDist; 
    float atten = 1. / (1.0 + lDist * 0.525 + lDist * lDist * 0.05);

    float diff = max(dot(sn, ld), .3);
    float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 14.0);
    vec3 objCol = abs(sin(sp));
    sceneCol += (objCol * (diff + 0.15) + abs(sin(sp)) * spec * 9.) * atten;
    return sceneCol;

}

void main(void) {
    
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / resolution.y;

    uv *= tan(radians (FOV) / 2.0) * .75;
    
    float t = time;
    float 
        sk = sin(t * .2) * 1.0,
        ck = cos(t * .12) * 1.0;
    
    vec3 sceneColor = vec3(0.);
    
    vec3 
        vuv = normalize(vec3(0., 1., 0.)),
        ro = vec3(ck * 3., 99., ck + time * .1) - 10.,
        vrp =  ro - vec3(sk, ck + 10., 10.),
        
        vpn = normalize(vrp - ro),
        u = normalize(cross(vuv, vpn)),
        v = cross(vpn, u),
        vcv = (ro + vpn),
        scrCoord = (vcv + uv.x * u + uv.y * v),
        rd = normalize(scrCoord - ro)
        ;        

    vec3 lp = ro - 1.;
    
    for (int i=1;i<4;i++) {
        vec2 t = trace(ro, rd);

        ro += rd * t.x;

        vec3 sn = getNormal(ro);
        sceneColor += doColor(ro, rd, sn, lp, 0.) * 10. / float(i);
        float sh = softShadow(ro, lp, 0.02);
        sceneColor *= sh;
        rd = mix(rd, reflect(rd, sn), .6);

    }

    glFragColor = vec4(clamp(sceneColor * 3., 0.0, 1.0), 1.0);
}
