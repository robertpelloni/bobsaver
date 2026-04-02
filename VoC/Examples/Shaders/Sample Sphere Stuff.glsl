#version 420

// original https://www.shadertoy.com/view/MlBXzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Ray{
    vec3 p,v;
};
    
struct Sphere{
    vec3 o;
    float r;
};
    
struct Hit{
    vec3 p;
    vec3 n;
    float l;
};

vec3 color(int index){
    if(index == 0) return vec3(0,0,1);
    if(index == 1) return vec3(0,1,1);
    if(index == 2) return vec3(1,0,0);
    if(index == 3) return vec3(1,1,0);
    if(index == 4) return vec3(0,1,0);
    if(index == 5) return vec3(1,0,1);
    else return vec3(0);
}
const float infinity = 100000000000.0;
    
Hit hit(Ray ray,Sphere sphere){
    vec3 o = sphere.o - ray.p;
    
    float p = dot(ray.v,o);
    float q = dot(o,o) - sphere.r * sphere.r;
    
    vec2 d = p + vec2(1,-1) * sqrt(p*p - q);
    vec3 p0 = ray.p + ray.v * min(d.x,d.y);
    return Hit(
        p0, //hitpoint
        (p0 - sphere.o)/sphere.r, //avoiding "normalize"
        (d.x > 0.0 && d.y > 0.0) ? min(d.x,d.y) : infinity //throw away if hitpoints are behind the rayposition
    );    
}

vec3 rotateY(in vec3 v, in float a) {
    return vec3(cos(a)*v.x + sin(a)*v.z, v.y,-sin(a)*v.x + cos(a)*v.z);
}

vec3 rotateX(in vec3 v, in float a) {
    return vec3(v.x,cos(a)*v.y + sin(a)*v.z,-sin(a)*v.y + cos(a)*v.z);
}

void main(void) {
    vec2 uv = ( gl_FragCoord.xy / resolution.xy ) - 0.5;
    uv.x *= resolution.x/resolution.y;
    
    Ray ray = Ray(vec3(0),normalize(vec3(uv.x,uv.y,0.75)));
    ray.v = rotateY(ray.v,-0.1 * time);
    ray.v = rotateX(ray.v,-0.13 * time);
    
    float r = mix(0.6,sqrt(3.0) * 0.5,min(1.0,1.5 * pow(sin(time) * 0.5 + 0.5,0.3)));
    Sphere spheres[6];
    spheres[0] = Sphere(vec3(0,0,+1),r);
    spheres[1] = Sphere(vec3(0,0,-1),r);
    spheres[2] = Sphere(vec3(0,+1,0),r);
    spheres[3] = Sphere(vec3(0,-1,0),r);
    spheres[4] = Sphere(vec3(+1,0,0),r);
    spheres[5] = Sphere(vec3(-1,0,0),r);
    
    float factor = 0.7;
    float lightStrength = 1.0;
    glFragColor = vec4(0,0,0,1);
    
    const int REFLECTIONS = 9;
    for(int i = 0; i < REFLECTIONS; i++){
        Hit h = Hit(vec3(0),vec3(0),infinity);
        int found = -1;
        for(int j = 0; j < 6; j++){
            Hit x = hit(ray,spheres[j]);
            if(x.l < h.l){
                h = x;
                found = j;
               }
        }
        if(found != -1){
            ray.p = h.p;
            ray.v = reflect(ray.v,h.n);
            
            vec3 lightVec = -normalize(h.p);
            float diffuse = dot(h.n,lightVec);
            float specular = pow(abs(dot(reflect(-lightVec,h.n),lightVec)),20.0);
            glFragColor.xyz += lightStrength * (diffuse * color(found) + specular);
        }
        lightStrength *= factor;
    }
    glFragColor.xyz *= 1.3 * (1.0 - factor);
}
