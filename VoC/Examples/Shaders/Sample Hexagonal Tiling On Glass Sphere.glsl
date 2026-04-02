#version 420

// original https://www.shadertoy.com/view/WdyyRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ng 1.5
#define PI 3.141529
struct Ray{
    vec3 o;
    vec3 d;
    float i;
};
    
Ray GetRay(vec2 uv, vec3 camPos, vec3 dir, float zoom){
    Ray r;
    r.o = camPos;
    vec3 f = normalize(dir);
    vec3 right = cross(vec3(.0,1.,.0), f);
    vec3 u = cross(f,right);
    
    vec3 c = r.o + f*zoom;
    vec3 i = c + uv.x *right + uv.y *u;
    r.d = normalize(i -r.o);
    r.i = 1.;
    return r;
}
mat3 Rotate(vec3 u, float t){
    float a = 1.-cos(t);
    return mat3(cos(t) + u.x*u.x*a, u.x*u.y*a - u.z*sin(t), u.x*u.z*a + u.y*sin(t),
                u.y*u.x*a + u.z*sin(t), cos(t)+u.y*u.y*a, u.y*u.z*a - u.x*sin(t),
                u.z*u.x*a - u.y*sin(t), u.z*u.y*a+u.x*sin(t), cos(t) + u.z*u.z*a);
}
vec3 ClosestPoint(Ray r, vec3 p) {
    // returns the closest point on ray r to point p
    return r.o + max(0., dot(p-r.o, r.d))*r.d;
}

float DistRay(Ray r, vec3 p) {
    return length(p-ClosestPoint(r, p));
}
float GetRefractedAngle(float ni, float thetai, float nf){
    return asin(ni/nf*sin(thetai));
}

vec2 Root(float a, float b, float c){
    float x1 = -b;
    float x2 = pow(pow(b,2.)-4.*a*c,.5);
    return vec2((x1+x2)/(2.*a), (x1-x2)/(2.*a));
}

//Random with mouse*resolution.xy.x as parameter
float Random(float s){ //[0,1]
    return fract(cos((mouse.x*resolution.xy.x +.2)*s)*73.17);
}

Ray SphereRefract(Ray ray, vec3 p, float r){
       float d = DistRay(ray, p);
    //return ray;
    if(d < r){
        float ai = asin(d/r);
        float ar = GetRefractedAngle(1., ai, ng);
        float t = Root(pow(length(ray.d),2.), 2.*(dot(ray.o,ray.d) - dot(ray.d, p)), pow(length(ray.o - p),2.) - pow(r,2.)).y;
        vec3 pi = ray.o + t * ray.d;
        vec3 ni = normalize(pi - p);
        vec3 rdir = ray.d*Rotate(normalize(-cross(ray.d,ni)), ai-ar);
        float d2 = 2.*r*cos(ar);
        vec3 pf = rdir * d2 + pi;
        vec3 nf = normalize(pf - p);
        vec3 rdir2 = rdir*Rotate(normalize(-cross(rdir, nf)), ai - ar);
        Ray ray2;
        ray2.d = rdir2;
        ray2.o = pf + rdir2*(t + d2);
        ray2.i = pow((r-d)/r*2.,1.);
        return ray2;
    } else return ray;
}

float S2(float d, float w, float v){
    return smoothstep(d+w/2., d - w/2., v) * smoothstep(d-w/2., d+w/2.,v);
}

vec3 DrawBG(Ray ray, float z, float r){
    float dz = (z - ray.o.z);
    float dx = ray.d.x/ray.d.z*dz;
    float dy = ray.d.y/ray.d.z*dz;
    vec2 uv = vec2(ray.o.x + dx , ray.o.y + dy);
    uv.y+= time;
    
    //tiling 1
    vec2[2] p;
    float d1 = r*(1.+cos(PI/3.));
    float nx = floor((uv.x + d1)/(2.*d1));
    float d2 = r*sin(PI/3.);
    float ny = floor((uv.y + d2)/(2.*d2));
    p[0].x = nx*2.*d1;
    p[0].y = ny*2.*d2;
    
    //tiling 2
    float nx2 = floor(uv.x/(2.*d1));
    float ny2 = floor(uv.y/(2.*d2));
    p[1].x = nx2*2.*d1 + d1;
    p[1].y = ny2*2.*d2 + d2;
    vec3 col = vec3(0.);
    
    for(int i = 0; i < 2; i++){
        vec2 dv = uv-p[i];//delta vector
        float l = length(dv);//delta length
        float a = mod(abs(atan(dv.y/dv.x)),PI/3.);
        float hl = r*sin(PI/3.)/sin(PI*2./3. - a);//hexagonal length
        vec3 color1 = vec3(sin(abs(uv.xy)),cos(uv.y))*2.;
        col += S2(hl, .15,l)*color1;
    }
    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= vec2(.5);
    uv.x *= resolution.x/resolution.y;
    vec3 col = vec3(0.);
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    float d= 10.;
    float r = 1.;
    float dt = 2.*r*sin(PI/3.)/d;
    float dp = PI/3.;
    vec3 o = vec3(0.);

    Ray ray = GetRay(uv, o, vec3(0.,0.,1.), 1.);
    ray = SphereRefract(ray, vec3(0.,.0,1.5), .5);
    col += DrawBG(ray, d, 1.)*ray.i;

    glFragColor = vec4(col,1.0);
}
