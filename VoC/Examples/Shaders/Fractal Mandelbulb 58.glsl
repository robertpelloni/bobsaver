#version 420

// original https://www.shadertoy.com/view/ss2SWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision highp float;
#define MAX_STEPS 500
#define MIN_DIST 0.001
#define MAX_DIST 20.0
#define R_MAX 2.0
#define MAX_ITERS 100
#define ZC 2.0
#define PI 3.14159265358979323846264338327950288419716939937510
#define SHADOW 0.9

//stolen from: http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
float mandelbulb(vec3 pos) {
    float power = 1.2 + (time * 0.1);
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < MAX_ITERS ; i++) {
        r = length(z);
        if (r>R_MAX) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, power-1.0)*power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,power);
        theta = theta*power;
        phi = phi*power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return 0.5*log(r)*r/dr;
}

vec3 rotateZ(vec3 pos, float theta) {
    float s = sin(theta);
    float c = cos(theta);

    mat3 rotationMatrix = mat3(
                           vec3(1, 0, 0), 
                           vec3(0, c, -s),
                           vec3(0, s, c)
                           );

    return rotationMatrix * pos;
}

vec3 rotateX(vec3 pos, float theta) {
    float s = sin(theta);
    float c = cos(theta);

    mat3 rotationMatrix = mat3(
                           vec3(c, -s, 0), 
                           vec3(s, c, 0),
                           vec3(0, 0, 1)
                           );

    return rotationMatrix * pos;
}

vec3 rotateY(vec3 pos, float theta) {
    float s = sin(theta);
    float c = cos(theta);

    mat3 rotationMatrix = mat3(
                           vec3(c, 0, s), 
                           vec3(0, 1, 0),
                           vec3(-s, 0, c)
                           );

    return rotationMatrix * pos;
}

float world_map(vec3 pos) {
    return mandelbulb(rotateY(rotateX(pos, time * 0.5), time * 0.5));
}

float ray_march(vec3 origin, vec3 rayDir) {
    float td = MIN_DIST;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 ray = origin + rayDir * td;

        float d = world_map(ray);

        if (d < MIN_DIST) {
            return td;
        }
        
        if (d > MAX_DIST) {
            return -1.0;
        }

        td += d;
    }

    return td;
}

//https://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
float soft_shadow(vec3 origin, vec3 rayDir, float k) {
    float td = MIN_DIST;

    float res = 1.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 ray = origin + rayDir * td;

        float d = world_map(ray);

        if (d < MIN_DIST) {
            return (1.0 - SHADOW);
        }
        
        if (d > MAX_DIST) {
            break;
        }

        res = min(res, k * d / td);
        td += d;
    }

    return res;
}

vec3 calc_normal(in vec3 pos) {
    const float eps = 0.001;

    const vec2 h = vec2(eps, 0);

    return normalize(vec3(world_map(pos + h.xyy) - world_map(pos - h.xyy),
                          world_map(pos + h.yxy) - world_map(pos - h.yxy),
                          world_map(pos + h.yyx) - world_map(pos - h.yyx)
    ));
}

vec3 get_color(in vec3 ro, vec3 dir) {
    float t = ray_march(ro, dir);

    if (t > 0.0) {
        vec3 pos = ro + t * dir;

        vec3 norm = calc_normal(pos);

        vec3 light = vec3(0.8, 0.8, -0.2);

        float k = soft_shadow(pos + norm * 0.001, light, 20.0);
        

        k *= clamp(dot(norm, light), 0.0, 1.0);
        return vec3(1.0 - norm.x, norm.y, norm.x + norm.y) * k * 2.0;
    }

    return vec3(1.0);
}

void main(void)
{
    float ar = resolution.x / resolution.y;

    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y * ar;
    vec3 cam = vec3(0.0, 0, -1.5);
    vec3 rayDir = normalize(vec3(uv, 1.0));
    vec3 color = get_color(cam, rayDir);

    color = pow(color, vec3(0.4545));
    glFragColor = vec4(color, 1.0);
}
