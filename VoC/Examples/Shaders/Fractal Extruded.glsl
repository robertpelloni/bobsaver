#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MARCHING_STEPS 256
#define NEAR 0.0
#define FAR 150.0
#define EPSILON 0.005

float sphereSDF(vec3 p, float radius)
{
    return length(p) - radius;
}

float juliaSDF(vec4 p)
{
    float steps=30.0;
    vec2 c=vec2(p.x,p.y);
    vec2 z=vec2(p.z,p.w);
    for(int i=0;i<30;i++){
        if(length(z)>2.0){
        steps=(min(float(steps),float(i)+2.0/(length(z))));
            break;
        }
        z=vec2(z.x*z.x-z.y*z.y+c.x,2.0*z.x*z.y+c.y);
    }
    return 0.1/float(steps+1.0);
}

float sceneSDF(vec3 p)
{
    return juliaSDF(vec4(p.x+2.0*mouse.x-1.0,p.z+2.0*mouse.y-1.0,p.x,p.z))-(-p.y/10.0);//sphereSDF(p, 1.0);
}

vec3 getNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

float getDistance(vec3 eye, vec3 ray) {
    float depth = NEAR;

    for(int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * ray);
        if(dist < EPSILON) {
            return depth;
        }

        depth += dist;

        if(depth >= FAR) {
            return FAR;
        }
    }

    return FAR;
}

vec3 getRay(vec2 p, float fov, vec3 eye, vec3 target, vec3 up)
{
    vec3 dir = normalize(eye - target);
    vec3 side = normalize(cross(up, dir));
    float z = - up.y / tan(radians(fov) * 0.5);
    return normalize(side * p.x + up * p.y + dir * z);
}

vec4 render(float t, vec2 p)
{
    float fov = 30.0;
    vec3 eye = 6.0*vec3(sin(time/100.0), 1.0, cos(time/100.0));
    vec3 target = vec3(0.0, 0.0, 0.0);
    vec3 up = vec3(0.0, 1.0, 0.0);

    vec3 ray = getRay(p, fov, eye, target, up);

    float dist = getDistance(eye, ray);

    if(dist == FAR) {
        return vec4(0.5, 0.1, 0.5, 1.0);
    }

    vec3 normal = getNormal(eye + dist * ray);

    float diff = dot(normal, normalize(vec3(1.0, 1.0, 1.0)));

    return vec4(vec3(diff), 1.0);
}

void main( void ) {
    vec2 p = 2.0 * (gl_FragCoord.xy / resolution.xy - 0.5) * resolution.x / resolution.y;
    glFragColor = render(time, p);
}
