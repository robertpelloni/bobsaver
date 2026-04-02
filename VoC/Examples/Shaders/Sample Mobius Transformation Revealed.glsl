#version 420

// original https://www.shadertoy.com/view/fljfRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
This animation shows Mobius transformations are rigid motions
of "admissible" spheres in the upper half space.

A sphere is called admissible if its highest point lies above
the xy plane.

1. Map the complex plane (xy) to the sphere using inverse
   stereographic projection.
   
2. Translate and rotate the sphere, but make sure the resulting
   sphere is also admissible.

3. Map the sphere back to the complex plane using stereographic
   projection. The north pole is always the highest point on the
   sphere.
   
4. Then you obtain a Mobius transformation of the complex plane.
   All Mobius transformation can be obtained in this way.
   
   Because

   * move the sphere in xy plane is a usual translation of the
     complex plane.
   * move the sphere along the z-direction is a scaling of the
     complex plane.
   * rotate the sphere in xy plane is a usual rotation of the complex
     plane, otherwise it's a circle inversion.
     
For a given Mobius transformation M and a chosen initial position
of the sphere, the rigid motion that gives M is unique.
*/

#define PI            3.141592654
#define TAU           (2.0*PI)
#define ROT(a)        mat2(cos(a), sin(a), -sin(a), cos(a))
#define PCOS(x)       (0.5 + 0.5*cos(x))
#define DOT2(x)       dot(x, x)
#define TIME          time
#define Y             vec3(0, 1, 0)
#define NPOLE(sph)    (sph.xyz + sph.w * Y)
#define PLANE         vec4(0, 1, 0, 1.5)
#define aa            (2.0/resolution.y)

const vec4 hsv2rgb_K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

const float grid_max     = 3.0;
const float grid_size    = 0.5;
const vec3  light_pos    = vec3(3, 4, 3);
const vec3  light_dir    = normalize(light_pos);
const vec3  sky0_color   = HSV2RGB(vec3(0.0, 0.65, 0.95)); 
const vec3  sky1_color   = HSV2RGB(vec3(0.6, 0.5, 0.5));
const vec3  grid_color   = HSV2RGB(vec3(0.6, 0.6, 1.0)); 
const vec3  light_color  = 12.0*HSV2RGB(vec3(0.6, 0.5, 1.0));
const vec3  plane_color  = HSV2RGB(vec3(0.7, 0.125, 1.0/32.0)); 

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

vec2 mod2(inout vec2 p, vec2 size) {
    vec2 id = floor(p / size);
    p = mod(p + size*0.5, size) - size*0.5;
    return id;
}

float rayPlane(vec3 ro, vec3 rd, vec4 p) {
    return -(dot(ro, p.xyz) + p.w) / dot(rd, p.xyz);
}

vec2 raySphere(vec3 ro, vec3 rd, vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if (h < 0.0) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b - h, -b + h);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 58.233))) * 13758.5453);
}

float softShadow(vec3 ro, vec3 rd, vec4 sph, float k) {
    vec3 oc = ro - sph.xyz;
    float r2 = sph.w * sph.w;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - r2;
    float h = b * b - c;
    float d = -sph.w + sqrt(max(0.0, r2 - h));
    float t = -b - sqrt(max(0.0, h));
    return (t < 0.0) ? 1.0 : smoothstep(0.0, 1.0, k * d / t);
}

float bounce() {
    float t = fract(TIME) - 0.5;
    return 0.25 - t*t;
}

vec2 path(float t) {
    const float rad = 0.8;
    return rad * vec2(cos(t), sin(t));
}

void rot(inout vec3 sp) {
    sp.xy    *= ROT(TIME*0.3);
    sp.xz    *= ROT(TIME*0.3);
}

vec3 diffuse(vec3 pos, vec3 nor) {
    float ll = DOT2(light_pos - pos);
    vec3  ld = normalize(light_pos - pos);
    return light_color * max(dot(nor, ld), 0.0) / ll * 20.;
}

vec3 restrictColor(vec2 p, vec3 col) {
    float cond =  step(abs(p.x), grid_max);
          cond *= step(abs(p.y), grid_max);
    return mix(plane_color, col, cond);
}

vec3 planeToSphere(vec3 p, vec4 sph) {
    vec3 N = NPOLE(sph);
    vec3 rd = normalize(N - p);
    float t = raySphere(p, rd, sph).x;
    return p + rd*t;
}

vec3 sphereToPlane(vec3 p, vec4 sph, vec4 plane) {
    vec3 N = NPOLE(sph);
    vec3 rd = normalize(p - N);
    float t = rayPlane(p, rd, plane);
    return p + rd*t - sph.xyz;
}

vec3 computeGridColor(vec3 pos, vec2 pp) {
    vec2 z = pp;
    mod2(z, vec2(grid_size));
    float d1 = smin(abs(z.x), abs(z.y), .05);
    float gm = PCOS(-TAU * TIME + 0.25 * TAU * length(pos.xz));
    
    z = pp;
    vec2 id = mod2(z, vec2(grid_size / 6.));
    float d2 = min(abs(z.x), abs(z.y)) - 0.0125;
    
    float n  = hash21(id);
    float n2 = n * 0.3 + .7;
    if (n < 0.1 * sin(TIME) + 0.1)
        n = 1E6;
    else
        n = 0.0;
  
    vec3 gcol = vec3(0);
    gcol = mix(gcol, HSV2RGB(vec3(hash21(id), 1.0, n2)), vec3(n > 1.0));
    gcol -= 0.2*vec3(2.0, 1.0, 1.0)*exp(-100.0*max(d2+0.01, 0.0));
    gcol = mix(gcol, 6.*vec3(0.1, 0.09, 0.125), smoothstep(-aa, aa, -(d2+0.0075)));
    gcol += 0.5*vec3(2.0, 1.0, 1.0)*exp(-900.0*abs(d2-0.00125));

    vec3 col = clamp(gcol, -1.0, 1.0);

    gcol = mix(vec3(0.75), 2.0*vec3(3.5, 2.0, 1.25), gm);
    gcol *= exp(-mix(400.0, 100.0, gm) * max(d1-0.0125, 0.0));
    gcol *= 0.3;
    col = mix(col, gcol, smoothstep(-aa, aa, -d1 + 0.0125)); 
    return col;
}

vec3 renderBackground(vec3 ro, vec3 rd, vec4 sph, float T) {
    vec3 sky = smoothstep(1.0, 0.0, rd.y) * sky1_color + 
               smoothstep(0.5, 0.0, rd.y) * sky0_color;
               
    sky += pow(max(dot(rd, light_dir), 0.0), 800.0)*light_color;
    if (rd.y >= 0.0)
        return sky;
        
    float ht  = 1.0 + 0.2 * smoothstep(-0.05, 0.1, bounce());
    float t   = rayPlane(ro, rd, vec4(vec3(0.0, ht, 0.0), 0.5));
    vec3 pos  = ro + t*rd;
    vec3 dif  = diffuse(pos, Y);
    float sha = softShadow(pos, normalize(light_pos - pos), sph, 2.0);
    dif *= sha;
    
    vec3 sp = planeToSphere(pos, sph);
    sp -= sph.xyz;
    rot(sp);
    sp += sph.xyz;
    vec3 pp = sphereToPlane(sp, sph, PLANE);

    vec3 col = computeGridColor(pos, pp.xz);
    col = restrictColor(pp.xz, col); 
    col += plane_color * dif;
    col /= (1.0 + 0.25 * DOT2(pos.xz)); 
    col = mix(sky, col, tanh(500.0/(1.0 + DOT2(pos))));
    return col;
}

vec3 renderBall(vec3 ro, vec3 rd, vec4 sph, vec2 st, float T) {
    vec3 pos  = ro + st.x*rd;
    vec3 sp   = pos - sph.xyz;
    vec3 nor  = normalize(sp);
    vec3 ref  = reflect(rd, nor);
    vec3 dif  = diffuse(pos, nor);
    rot(sp);
    pos       = sp + sph.xyz;
    vec3 pp   = sphereToPlane(pos, sph, vec4(0, 1, 0, 0.5));
    vec3 rcol = renderBackground(pos, ref, sph, T);
    
    vec2 z = pp.xz;
    mod2(z, vec2(grid_size));
    float d1 = smin(abs(z.x), abs(z.y), .05);
    float gm = PCOS(-TAU * T + 0.25 * TAU * length(pp));
    
    z = pp.xz;
    vec2 id = mod2(z, vec2(grid_size / 6.));
    float d2 = min(abs(z.x), abs(z.y)) - 0.0125;
    
    float n = hash21(id);
    float n2 = n * 0.3 + .7;
    if (n < 0.1 * sin(T) + 0.1)
        n = 1E6;
    else
        n = 0.0;
  
    vec3 gcol = vec3(0);
    gcol = mix(gcol, HSV2RGB(vec3(hash21(sin(id * TAU)), 1.0, n2)), vec3(n > 1.0));
    gcol -= 0.2*vec3(2.0, 1.0, 1.0)*exp(-100.0*max(d2+0.01, 0.0));
    gcol = mix(gcol, 6.*vec3(0.09, 0.1, 0.125), smoothstep(-aa, aa, -(d2+0.0075)));
    gcol += 1.*vec3(2.0, 1.0, 1.0)*exp(-900.0*abs(d2-0.00125));
    vec3 col = clamp(gcol, -1., 1.);
    gcol = mix(vec3(0.75), 2.0*vec3(3.5, 2.0, 1.25), gm);
    gcol *= exp(-mix(400.0, 100.0, gm) * max(d1-0.0125, 0.0));
    gcol *= 0.3;
    col = mix(col, gcol, smoothstep(-aa, aa, -d1 + 0.0125));
    col = restrictColor(pp.xz, col);
    col += rcol * 0.175;
    return col;
}

vec3 render(vec2 p, vec2 uv) {
    vec2 ph = path(TIME * 0.5);
    vec3 ro = vec3(2.5, 1.0, 0.);
    ro.xz *= ROT(TIME / 3.);
    vec3 lookat = vec3(0., 0., 0.);
    vec3 forward = normalize(lookat - ro);
    vec3 right = normalize(cross(forward, Y));
    vec3 up = normalize(cross(right, forward));
    vec3 rd = normalize(p.x*right + p.y*up + 2.0*forward);
    vec4 sph = vec4(vec3(0., bounce(), 0.), 0.5);
    sph.xz += ph;
    vec2 st = raySphere(ro, rd, sph);
    if (st.x >= 0.0)
        return renderBall(ro, rd, sph, st, TIME);
    else
        return renderBackground(ro, rd, sph, TIME);
}

vec3 postprocess(vec3 col, vec2 q) {
    col = pow(clamp(col, 0.0, 1.0), vec3(1.0/2.2)); 
    col = col*0.6 + 0.4*col*col*(3.0 - 2.0*col);
    col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
    col *= 0.5 + 0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.7);
    return col;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col = render(p, uv);

    //float fi = smoothstep(0.0, 5.0, TIME);
    //col = mix(vec3(0.0), col, fi);

    col = postprocess(col, uv);
    glFragColor = vec4(col, 1.0);
}
