#version 420

// original https://www.shadertoy.com/view/ldsyzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// afl_ext 2017

/*

VIDEO for people on ShaderToy (no mouse zoom here):
https://youtu.be/tctFlI6bu6Q

*/

#define ZOOM 1.3
 
#define time time
#define resolution resolution
struct Ray { vec3 o; vec3 d; };
struct Sphere { vec3 pos; float rad; };

float planetradius = 371e3;
vec3 sundir = vec3(0.0);
vec2 uv = vec2(0.0);

float minhit = 0.0;
float maxhit = 0.0;
float rsi2(in Ray ray, in Sphere sphere)
{
    vec3 oc = ray.o - sphere.pos;
    float b = 2.0 * dot(ray.d, oc);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float disc = b * b - 4.0 * c;
    if (disc < 0.0) return -1.0;
    float q = b < 0.0 ? ((-b - sqrt(disc))/2.0) : ((-b + sqrt(disc))/2.0);
    float t0 = q;
    float t1 = c / q;
    if (t0 > t1) {
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }
    minhit = min(t0, t1);
    maxhit = max(t0, t1);
    if (t1 < 0.0) return -1.0;
    if (t0 < 0.0) return t1;
    else return t0;
}
mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
}

vec3 getRay(vec2 UV){
    UV = UV * 2.0 - 1.0;
    return normalize(vec3(UV.x, - UV.y, -1.0));
}

float hash( float n ){
    return fract(sin(n)*758.5453);
}

float noise3d( in vec3 x ){
    vec3 p = floor(x);
    vec3 f = fract(x);
    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*157.0 + 113.0*p.z;

    return mix(mix(    mix( hash(n+0.0), hash(n+1.0),f.x),
            mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
           mix(    mix( hash(n+113.0), hash(n+114.0),f.x),
            mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}

float noise2d( in vec2 x ){
    vec2 p = floor(x);
    vec2 f = smoothstep(0.0, 1.0, fract(x));
    float n = p.x + p.y*57.0;
    return mix(mix(hash(n+0.0),hash(n+1.0),f.x),mix(hash(n+57.0),hash(n+58.0),f.x),f.y);
}

 float configurablenoise(vec3 x, float c1, float c2) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f       = f*f*(3.0-2.0*f);

    float h2 = c1;
     float h1 = c2;
    #define h3 (h2 + h1)

     float n = p.x + p.y*h1+ h2*p.z;
    return mix(mix(    mix( hash(n+0.0), hash(n+1.0),f.x),
            mix( hash(n+h1), hash(n+h1+1.0),f.x),f.y),
           mix(    mix( hash(n+h2), hash(n+h2+1.0),f.x),
            mix( hash(n+h3), hash(n+h3+1.0),f.x),f.y),f.z);

}

float supernoise3d(vec3 p){

    float a =  configurablenoise(p, 883.0, 971.0);
    float b =  configurablenoise(p + 0.5, 113.0, 157.0);
    return (a + b) * 0.5;
}
float supernoise3dX(vec3 p){

    float a =  configurablenoise(p, 883.0, 971.0);
    float b =  configurablenoise(p + 0.5, 113.0, 157.0);
    return (a * b);
}

float fbmHI(vec3 p){
   // p *= 0.1;
    p *= 1.2;
    //p += getWind(p * 0.2) * 6.0;
    float a = 0.0;
    float w = 1.0;
    float wc = 0.0;
    for(int i=0;i<5;i++){
        //p += noise(vec3(a));
        a += clamp(2.0 * abs(0.5 - (supernoise3dX(p))) * w, 0.0, 1.0);
        wc += w;
        w *= 0.5;
        p = p * 2.0;
    }
    return a / wc;// + noise(p * 100.0) * 11;
}
float fbmHIx(vec3 p, float dx){
   // p *= 0.1;
    p *= 1.2;
    //p += getWind(p * 0.2) * 6.0;
    float a = 0.0;
    float w = 1.0;
    float wc = 0.0;
    for(int i=0;i<5;i++){
        //p += noise(vec3(a));
        a += clamp(2.0 * abs(0.5 - (supernoise3dX(p))) * w, 0.0, 1.0);
        wc += w;
        w *= 0.5;
        p = p * dx;
    }
    return a / wc;// + noise(p * 100.0) * 11;
}
float rand2s(vec2 co){
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}
mat3 rotmatfortime = mat3(0.0);
float getheight(vec3 a){
    vec3 n = normalize(a);
    return (0.66 +  (-n.y * 0.4 + 0.6) * pow(max(0.0, 0.60 - fbmHIx(rotmatfortime * n * 4.0, 2.0)) * 1.0, 2.0));
}
vec3 planetpos = vec3(0.0);

vec3 intersectterrain2(vec3 start, vec3 end, float planetsize){ // in planetary coords
    const int stepsi = 6;
    float stepsize = 1.0 / 6.0;
    float rd = rand2s(uv) * stepsize;
    float iter = 0.0;
    for(int i=0;i<stepsi;i++){
        vec3 mx = mix(start, end, iter);
        float h = length(mx);
        float h2 = (getheight(mx))*0.3 + planetsize;
        if(h < h2) return mx;
        iter += stepsize;
    }
    return vec3(0.0);
}
vec3 intersectterrain(vec3 start, vec3 end, float planetsize){ // in planetary coords
    const int stepsi = 28;
    float stepsize = 1.0 / 28.0;
    float rd = rand2s(uv) * stepsize;
    float iter = 0.0;
    for(int i=0;i<stepsi;i++){
        vec3 mx = mix(start, end, iter);
        float h = length(mx);
        float h2 = (getheight(mx))*0.3 + planetsize;
        if(h < h2) return intersectterrain2(mix(start, end, iter - stepsize + rd), mix(start, end, iter + stepsize + rd), planetsize);
        iter += stepsize;
    }
    return vec3(0.0);
}

float ccolor = 0.0;
float intersectclouds(vec3 start, vec3 end, float planetsize){ // in planetary coords
    const int stepsi = 7;
    float stepsize = 1.0 / 7.0;
    float rd = rand2s(uv) * stepsize;
    float iter = 0.0;
    float coverage = 0.0;
    float cc = 0.0;
    float cw = 0.01;
    for(int i=0;i<stepsi;i++){
        vec3 mx = rotmatfortime * mix(start, end, iter + rd);
        float h = (length(mx) - planetsize);
        float h2 = smoothstep(0.1, 0.3, h);
        h = smoothstep(0.0, 0.2, h) * (1.0 - smoothstep(0.2, 0.4, h));
        float c = smoothstep(0.56, 0.66, h *  fbmHIx(mx * 1.0 + fbmHIx(mx.yxz * 2.0 + time * 0.001, 3.0) * 0.5 - time * 0.01, 3.0));
        float w = step(0.01, c) * step(0.01, 1.0 - coverage);
        cc += h2 * w;
        cw += w;
        coverage += c;
        iter += stepsize;
    }
    ccolor = pow(1.2*(cc/cw), 4.0);
    return min(coverage, 1.0);
}

vec3 applyatm(vec3 sufracecolor, float dst, vec3 dir, vec3 pos, vec3 n, vec3 startp, vec3 endp){
    vec3 base = vec3(0.0, 0.2, 0.5);
    vec3 ibase = (vec3(1.0) - base) * dst;
    vec3 ibasec = pow(vec3(1.0) - base, vec3(3.0));
    float dt = max(0.0, dot(-sundir, n) * 0.92 + 0.09);
    float mixer = 1.0 / (1.0 + (dt) * 4.0);
    
    float cloudscoverage = intersectclouds(startp, endp, 4.0);
    vec3 sufracecolor2 = mix(sufracecolor, vec3(1.0) * (1.0 - mixer) * ccolor, cloudscoverage);
    vec3 atmsum = vec3(0.0);
    const int stepsi = 8;
    float stepsize = 1.0 / 8.0;
    float rd = rand2s(uv) * stepsize;
    float iter = 0.0;
    Sphere atmosphere = Sphere(planetpos, 4.3);
    Sphere planet = Sphere(planetpos, 4.0);
    for(int i=0;i<stepsi;i++){
        vec3 P = mix(startp, endp, iter + rd);
        float h = length(P) - 4.0;
        h = 1.0 - smoothstep(0.2, 0.3, h);
        Ray r = Ray(P + planetpos, sundir);
        float planethit = rsi2(r, planet);
        float atmhit = rsi2(r, atmosphere);
        float shadow =1.0 - step(0.0001, length(intersectterrain((r.o + r.d * 0.02) - planetpos, (r.o + r.d * atmhit) - planetpos, 4.0)));
        shadow *= 1.0 - intersectclouds((r.o + r.d * 0.03) - planetpos, (r.o + r.d * atmhit) - planetpos, 4.0);
        atmsum += shadow * 23.0 * h * dt * dst * mix(base, ibase, mixer) * stepsize;
        iter += stepsize;
    }
    return (sufracecolor2 * mix(vec3(1.0), ibasec, mixer)) + atmsum;
}

vec3 getplanet(vec3 possurface, vec3 n, vec3 v){
    float height = getheight(possurface - planetpos );
    float height2 = getheight(possurface - planetpos + vec3(0.02, 0.0, 0.0));
    float height3 = getheight(possurface  - planetpos+ vec3(0.0, 0.02, 0.0));
    vec3 p1 = height * n + possurface * 0.5 + vec3(0.0, 0.0, 0.0);
    vec3 p2 = height2 * n + possurface * 0.5 - vec3(0.02, 0.0, 0.0);
    vec3 p3 = height3 * n + possurface * 0.5 - vec3(0.0, 0.02, 0.0);
    vec3 supern = normalize(cross(normalize(p1 - p2), normalize(p1 - p3)));
    //return supern;
    
    float terrainmod = smoothstep(0.33, 0.333, 1.0 - height);
    float mountainmod = smoothstep(0.11, 0.33, 1.0 - height);

    float dt = max(0.0, dot(-sundir, n) * 0.92 + 0.08);
    vec3 gcolor = mix(vec3(0.0, 0.25, 0.1), vec3(0.4), 1.0 - mountainmod);
    gcolor = mix(gcolor, vec3(0.9, 0.9, 0.9) * 3.0, (1.0 - height) * smoothstep(0.56, 0.77, abs(n.y)));
    gcolor = mix(gcolor, vec3(0.3, 0.1, 0.0) * 1.0, (height) * smoothstep(0.66, 0.99, 1.0 - abs(n.y)));;
    float F = pow(1.0 - max(0.0, dot(n, v)), 3.0);
    
    Sphere atmosphere = Sphere(planetpos, 4.3);
    Sphere planet = Sphere(planetpos, 4.0);
    Ray r = Ray(possurface, sundir);
    float planethit = rsi2(r, planet);
    float atmhit = rsi2(r, atmosphere);
    
    float shadow =1.0 - step(0.0001, length(intersectterrain((r.o + r.d * 0.02) - planetpos, (r.o + r.d * atmhit) - planetpos, 4.0)));
    shadow *= 1.0 - intersectclouds((r.o + r.d * 0.03) - planetpos, (r.o + r.d * atmhit) - planetpos, 4.0);
    //shadow *= 1.0 - step(0.0, planethit);
    //return vec3(shadow);
    gcolor *= 0.03 + 0.98 * max(0.0, dot(supern, sundir)) * shadow ;    
    return mix(gcolor*dt,(0.1 + 0.9* shadow) * dt *  (vec3(0.0, 0.1, 0.3)
        + (0.1 + 0.9* shadow) * 3.0 * pow(max(0.0, dot(reflect(v,n), sundir)), 5.0 + 180.0 * fbmHIx(rotmatfortime * (possurface - planetpos) * 4.0 + fbmHIx(rotmatfortime * (possurface - planetpos) * 4.0, 2.0) + time * 0.005, 2.0))) * (0.3 + 0.5 * F) , terrainmod);

}
vec2 minmax = vec2(0.0);
vec2 testIntersectionPlanet(vec2 uv, vec3 pos, float radius, float atmospherethickness, vec2 currentdist){
    Sphere planet = Sphere(pos, radius);
    Sphere atmosphere = Sphere(pos, radius + atmospherethickness);
    Ray r = Ray(vec3(0.0), getRay(uv));
    float planethit = rsi2(r, planet);
    float atmhit = rsi2(r, atmosphere);
    if(planethit < currentdist.x && planethit > 0.0) { currentdist.x = planethit;}
    if(atmhit < currentdist.y && atmhit > 0.0) {minmax = vec2(minhit, maxhit);planetpos = pos; currentdist.y = atmhit;}
    return currentdist;
}
void main(void)
{
    uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.y*=resolution.y / resolution.x;
    rotmatfortime = rotationMatrix(vec3(-0.3, 1.0, 0.0), time * 0.02);
    //position.y = ((position.y * 2.0 - 1.0) * resolution.y/resolution.x) * 0.5 + 0.5;
    vec2 position = uv * 0.5 + 0.5;
    vec2 currentdst = vec2(1001.0);
    currentdst = testIntersectionPlanet(position, vec3(0.0, 0.0, -12.0 * (1.0 / ZOOM)), 4.0, 0.3, currentdst);
    //currentdst = testIntersectionPlanet(position, vec3(7.0, 11.0, -22.0), 4.0, 0.1, currentdst);
    //currentdst = testIntersectionPlanet(position, vec3(-10.0, -5.0, -12.0), 4.0, 0.1, currentdst);
    Ray r = Ray(vec3(0.0), getRay(position));
    vec3 color = vec3(0.0);
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    sundir = normalize(vec3(mouse.x * 2.0 - 1.0, -(mouse.y * 2.0 - 1.0), 0.46 - length(mouse * 2.0 - 1.0)));
    if(currentdst.y < 1000.0){
        if(currentdst.x < 1000.0){
            vec3 plp = intersectterrain((r.o + r.d * minmax.x) - planetpos, (r.o + r.d * currentdst.x) - planetpos, 4.0); 
            vec3 surface = normalize(plp) * length(plp) + planetpos;
            if(length(plp) != 0.0){
                vec3 n = normalize(planetpos - (r.o + r.d * currentdst.y));
                color = getplanet(surface, n, r.d);
                color = applyatm(color, distance((r.o + r.d * minmax.x), surface), r.d, surface, n, 
                           (r.o + r.d * minmax.x) - planetpos, surface - planetpos);
            }
            //color = vec3(smoothstep(0.0, 1.0, length(plp) - 4.0));
            //color =  (position.x < 0.5 ? (r.o + r.d * minmax.x) : surface) * 0.1;
            
        } else {
            vec3 plp = intersectterrain((r.o + r.d * minmax.x) - planetpos, (r.o + r.d * minmax.y) - planetpos, 4.0); 
            vec3 surface = normalize(plp) * length(plp) + planetpos;
            if(length(plp) != 0.0){
                vec3 n = normalize(planetpos - (r.o + r.d * currentdst.y));
                color = getplanet(surface, n, r.d);
                color = applyatm(color, distance((r.o + r.d * minmax.x), surface), r.d, surface, n, 
                           (r.o + r.d * minmax.x) - planetpos, surface - planetpos);
            } else {
                vec3 n = normalize(planetpos - (r.o + r.d * minmax.x));
                color += applyatm(vec3(0.0), minmax.y - minmax.x, r.d, surface, n, 
                           (r.o + r.d * minmax.x) - planetpos, (r.o + r.d * minmax.y) - planetpos);
            }
            //color = vec3(smoothstep(0.0, 1.0, length(plp) - 4.0));
            //color = distance(surface, r.o + r.d * minmax.x) * vec3(1) * 0.1;
        }
    } else {
        color += 2.0 * smoothstep(0.6, 0.7, supernoise3dX(vec3(position * 1000.0, 0.0)) * (0.8 + 0.2 * supernoise3dX(vec3(position * 10.0, 0.0))));   
    }
    color /= (1.0 + length(color) * 0.3);
    //color.r = maxi;
    glFragColor = vec4(pow(color, vec3(1.0 / 2.4)), 1.0 );
}
