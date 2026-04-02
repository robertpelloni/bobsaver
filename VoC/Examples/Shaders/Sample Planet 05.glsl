#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
struct Ray { vec3 o; vec3 d; };
struct Sphere { vec3 pos; float rad; };

float planetradius = 371e3;
Sphere planet = Sphere(vec3(0), planetradius);

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

vec3 getRay(vec2 UV){
    UV = UV * 2.0 - 1.0;
    return normalize(vec3(UV.x, - UV.y, -1.0));
}
vec3 getatm(float dst, vec3 dir){
    return dst * vec3(0.0, 0.3, 0.5);
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
    for(int i=0;i<4;i++){
        //p += noise(vec3(a));
        a += clamp(2.0 * abs(0.5 - (supernoise3dX(p))) * w, 0.0, 1.0);
        wc += w;
        w *= 0.5;
        p = p * 3.0;
    }
    return a / wc;// + noise(p * 100.0) * 11;
}
vec3 getplanet(vec3 possurface, vec3 n, vec3 v,  vec3 sundir){
    float height = fbmHI(possurface);
    float terrainmod = smoothstep(0.37, 0.44, height);
    float mountainmod = smoothstep(0.1, 0.3, height);
    
    vec3 gcolor = mix(vec3(0.3, 0.3, 0.1), vec3(0.1, 0.2, 0.1), mountainmod);
    float F = pow(1.0 - max(0.0, dot(n, v)), 3.0);
    return mix(gcolor,(vec3(0.0, 0.1, 0.3)+ 2.0 * pow(max(0.0, dot(reflect(v,n), sundir)), 25.0 + 40.0 * pow(height * 1.2, 5.0))) * (0.3 + 0.5 * F) , terrainmod);
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy ); 
    position.y = ((position.y * 2.0 - 1.0) * resolution.y/resolution.x) * 0.5 + 0.5;
    Sphere planet = Sphere(vec3(0.0, 0.0, -10.0), 4.0);
    Sphere atmosphere = Sphere(vec3(0.0, 0.0, -10.0), 4.1);
    Ray r = Ray(vec3(0.0), getRay(position));
    float planethit = rsi2(r, planet);
    float atmhit = rsi2(r, atmosphere);
    vec3 color = vec3(0.0);
    if(atmhit > 0.0){
        if(planethit > 0.0){
            color += getatm(abs(atmhit - planethit), r.d);
            vec3 n = normalize(planet.pos - (r.o + r.d * planethit));
            color += getplanet(r.o + r.d * planethit, n, r.d, normalize(vec3(sin(time), -0.6, cos(time))));
        } else {
            vec3 p = normalize(planet.pos - (r.o + r.d * minhit));
            color += getatm(maxhit - minhit, r.d) * (1.0 / 3.0 * (1.0 - p.z));
        }
    }
    
    glFragColor = vec4(color, 1.0 );

}
