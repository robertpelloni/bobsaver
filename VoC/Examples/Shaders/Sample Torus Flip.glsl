#version 420

// original https://www.shadertoy.com/view/sscXWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Light {
    vec3 position;
    float strongth;
    vec3 color;
};

#define PI 3.1415926
    
mat4 euler(float x, float y, float z) {
    mat4 xmat = mat4(vec4(1.0,  0.0,    0.0,    0.0),
                     vec4(0.0,  cos(x), sin(x), 0.0),
                     vec4(0.0, -sin(x), cos(x), 0.0),
                     vec4(0.0,  0.0,    0.0,    1.0));
    mat4 ymat = mat4(vec4( cos(y), 0.0, sin(y), 0.0),
                     vec4( 0.0,    1.0, 0.0,    0.0),
                     vec4(-sin(y), 0.0, cos(y), 0.0),
                     vec4( 0.0,    0.0, 0.0,    1.0));
    mat4 zmat = mat4(vec4( cos(z),  sin(z), 0.0, 0.0),
                     vec4(-sin(z),  cos(z), 0.0, 0.0),
                     vec4( 0.0,     0.0,    1.0, 0.0),
                     vec4( 0.0,     0.0,    0.0, 1.0));
    
    return xmat*ymat*zmat;
}

mat4 transform(float x, float y, float z) {
    return mat4(vec4(1.0, 0.0, 0.0, 0.0),
                vec4(0.0, 1.0, 0.0, 0.0),
                vec4(0.0, 0.0, 1.0, 0.0),
                vec4(x,   y,   z,   1.0));
}

float sphereSDF(vec3 center, float radius, vec3 point) {
    return length(point - center) - radius;
}

float planeSDF(vec3 origin, vec3 normal, vec3 point) {
    return dot(point - origin, normal);
}

vec4 stereographicProj(vec3 point) {
    vec4 p4 = vec4(point, 2.0);
    float norm = length(p4);
    return 4.0*p4/(norm*norm) - vec4(vec3(0.0),1.0);
}

float torus4SDF(vec4 point, vec4 pl1, vec4 pl2, float radius) {
    float dp1 = dot(point,pl1);
    float dp2 = dot(point,pl2);
    vec4 pp = pl1*dp1 + pl2*dp2;
    vec4 ppp = point - pp;
    vec4 cp = pp/length(pp);
    vec4 ppmcp = pp-cp;
    return sqrt(dot(ppmcp,ppmcp) + dot(ppp,ppp)) - radius;
}

float sceneSDF(vec3 point) {
    float theta = time;//PI/2.0*sin(time)*sin(time);
    return torus4SDF(stereographicProj(point), 
                    vec4(0.0,1.0,0.0,0.0),
                    vec4(cos(theta),0.0,0.0,sin(theta)),
                    0.8);
    /*return min(
        min(
            min(
                sphereSDF(vec3(-0.7, 0.7, 0.0), 0.5, point),
                sphereSDF(vec3(0.7, 0.7, 0.0), 0.5, point)
            ),
            sphereSDF(vec3(0.0), 1.0, point)
        ),
        planeSDF(vec3(0.0), vec3(0.0, 1.0, 0.0), point)
      );*/
}

vec3 sceneSDFGradient(vec3 point, float epsilon) {
    vec3 xe = vec3(epsilon, 0.0, 0.0)/2.0;
    vec3 ye = vec3(0.0, epsilon, 0.0)/2.0;
    vec3 ze = vec3(0.0, 0.0, epsilon)/2.0;
    
    return vec3(
        (sceneSDF(point + xe) - sceneSDF(point - xe)) / epsilon,
        (sceneSDF(point + ye) - sceneSDF(point - ye)) / epsilon,
        (sceneSDF(point + ze) - sceneSDF(point - ze)) / epsilon
      );
}

vec3 sceneSDFNormal(vec3 point) {
    return normalize(sceneSDFGradient(point, 0.01));
}

vec3 rayPoint(Ray ray, float dist) {
    return ray.origin + dist * ray.direction;
}

vec3 screen(vec3 a, vec3 b) {
    return vec3(1.0) - (vec3(1.0) - a)*(vec3(1.0) - b);
}

vec3 lightPoint(Light light, vec3 point, vec3 normal, vec3 camera, vec3 diffuse, vec3 bounce, vec3 current) {
    vec3 lightchord = light.position - point;
    
    vec3 lightcolor = light.color * 1.0 / pow(length(lightchord)/light.strongth+1.0, 2.0);
    
    vec3 colour = diffuse * lightcolor * max(dot(normal, normalize(lightchord)), 0.0);
    colour = screen(colour, bounce * lightcolor * max(vec3(1.0) - 5.0*(vec3(1.0) - dot(normalize(lightchord), reflect(normalize(point - camera), normal))), 0.0));
    
    return screen(current, colour);
}

void main(void)
{
    float lightangle = time;
    
    Light light1 = Light(vec3(20.0*cos(lightangle), 5.0, 20.0*sin(lightangle)), 1000.0, vec3(1.0, 0.0, 0.0));
    
    lightangle += PI*2./3.;
    
    Light light2 = Light(vec3(20.0*cos(lightangle), 5.0, 20.0*sin(lightangle)), 1000.0, vec3(0.0, 1.0, 0.0));
    
    lightangle += PI*2./3.;
    
    Light light3 = Light(vec3(20.0*cos(lightangle), 5.0, 20.0*sin(lightangle)), 1000.0, vec3(0.0, 0.0, 1.0));
    
    float disttoscreen = 0.5;
    
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(0.5);
    uv.y *= resolution.y/resolution.x;
    
    vec3 camorigin = vec3(5.0, 2.0*cos(time*2.0+PI) + 6.0, -7.0 + 3.0*cos(time*2.0+PI));
    
    mat4 camtoscene = transform(camorigin.x, camorigin.y, camorigin.z)*euler(0.7 + 0.4*cos(time*2.0+PI), 0.5, 0.0);
    
    Ray ray = Ray((camtoscene*vec4(vec3(0.0),1.0)).xyz,
                  normalize(camtoscene*vec4(uv.x, uv.y, disttoscreen, 0.0)).xyz);
    
    vec3 point = camorigin;
    
    float scenedist = sceneSDF(point);
    bool invert = scenedist < 0.0;
    if (invert) scenedist = -scenedist;
    float raydist = 0.0;
    
    float epsilon = 0.01;
    float end = 100.0;
    
    while (scenedist > epsilon) {
        if (raydist > end) {
            glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }
        
        point = rayPoint(ray, raydist);
        
        scenedist = invert ? -sceneSDF(point) : sceneSDF(point);
        
        raydist += scenedist;
    }
    
    vec3 normal = sceneSDFNormal(point);
    vec3 diffuse = vec3(1.0);
    vec3 bounce = vec3(1.0);
        
    vec3 colour = lightPoint(light1, point, normal, camorigin, diffuse, bounce, vec3(0.3));
    colour = lightPoint(light2, point, normal, camorigin, diffuse, bounce, colour);
    colour = lightPoint(light3, point, normal, camorigin, diffuse, bounce, colour);

    // Output to screen
    glFragColor = vec4(colour,1.0);
}
