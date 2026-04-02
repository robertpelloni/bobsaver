#version 420

// original https://www.shadertoy.com/view/3ljcWy

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

float ropeSDF(float coiledness, uint n, vec3 point) {
    for (uint i = 0u; i < n; ++i) {
        float r = length(point.xz);
        float t = atan(-point.x, -point.z) + PI;
        
        t -= 2.0*PI*coiledness;
        t = mod(t, 2.0*PI/3.0) + 2.0*PI/3.0;
        
        point.x = r*sin(t);
        point.z = r*cos(t);
        
        point.z += 1.0;
        point.xz *= 1.0 + 1.0/sin(PI/3.0);
        //point.z *= -1.0;
    }
    
    point.xz /= 1.0 + sin(PI/3.0);
    
    float lpxz = length(point.xz);
    
    vec2 d = vec2(lpxz, abs(point.y + 0.5)) - vec2(1.0,0.5);
    
    for (uint i = 0u; i < n; ++i) d.x /= 1.0 + 1.0/sin(PI/3.0);
    
    d.x *= 1.0 + sin(PI/3.0);
    
    return min(max(d.x,d.y), 0.0) + length(max(d, 0.0));
}

float sceneSDF(vec3 point) {
    point.y /= 20.0;
    return ropeSDF(1.0-(0.5*sin(time*0.2)+0.5)*(point.y+1.0), 6u, point);
   /*return min(
       min(
           min(
               sphereSDF(vec3(-0.7, 0.7, 0.0), 0.5, point),
               sphereSDF(vec3(0.7, 0.7, 0.0), 0.5, point)
           ),
           sphereSDF(vec3(0.0), 1.0, point)
       ),
       planeSDF(vec3(0.0), vec3(0.0, 1.0, 0.0), point)
     );
   */
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
    
    vec3 lightcolor = light.color * 1.0 / pow(length(lightchord/3.0)/light.strongth+1.0, 2.0);
    
    vec3 colour = diffuse * lightcolor * max(dot(normal, normalize(lightchord)), 0.0);
    colour = screen(colour, bounce * lightcolor * max(vec3(1.0) - 5.0*(vec3(1.0) - dot(normalize(lightchord), reflect(normalize(point - camera), normal))), 0.0));
    
    return screen(current, colour);
}

void main(void)
{
    float lightangle = time;
    
    Light light1 = Light(vec3(2.0*cos(lightangle), 2.0, 2.0*sin(lightangle)), 10.0, vec3(1.0, 0.0, 0.0));
    
    lightangle += PI*2./3.;
    
    Light light2 = Light(vec3(2.0*cos(lightangle), 2.0, 2.0*sin(lightangle)), 10.0, vec3(0.0, 1.0, 0.0));
    
    lightangle += PI*2./3.;
    
    Light light3 = Light(vec3(2.0*cos(lightangle), 2.0, 2.0*sin(lightangle)), 10.0, vec3(0.0, 0.0, 1.0));
    
    float disttoscreen = 1.0;
    
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(0.5);
    uv.y *= resolution.y/resolution.x;
    
    vec3 camorigin = vec3(-6.0, 6.0, 0.0);
    
    mat4 camtoscene = transform(camorigin.x, camorigin.y, camorigin.z)*euler(PI*0.5, -PI*0.18, 0.0);
    
    Ray ray = Ray((camtoscene*vec4(vec3(0.0),1.0)).xyz,
                  normalize(camtoscene*vec4(uv.x, uv.y, disttoscreen, 0.0)).xyz);
    
    vec3 point = camorigin;
    
    float scenedist = sceneSDF(point);
    float raydist = 0.0;
    
    float epsilon = 0.001;
    float end = 100.0;
    
    while (scenedist > epsilon) {
        if (raydist > end) {
            glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }
        
        point = rayPoint(ray, raydist);
        
        scenedist = sceneSDF(point);
        
        raydist += scenedist;
    }
    
    vec3 normal = sceneSDFNormal(point);
    vec3 diffuse = vec3(1.0);
    vec3 bounce = vec3(1.0);
        
    vec3 colour = lightPoint(light1, point, normal, camorigin, diffuse, bounce, vec3(0.0));
    colour = lightPoint(light2, point, normal, camorigin, diffuse, bounce, colour);
    colour = lightPoint(light3, point, normal, camorigin, diffuse, bounce, colour);

    // Output to screen
    glFragColor = vec4(colour,1.0);
}
