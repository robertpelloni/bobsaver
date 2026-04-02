#version 420

// original https://www.shadertoy.com/view/wsyGzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TRAVERSAL_MAX_IT 256

float n21(vec2 n)
{
    return fract(sin(dot(n, vec2(12.9898,78.233))) * 43758.5453);
}

float n31(vec3 n)
{
    return fract(sin(dot(n, vec3(12.9898,78.233,12.5429))) * 43758.5453);
}

float on21(vec2 uv, float i, float m) {
    m = pow(.5, i - 1. + m);
    float c = 0.;
    for (float j = 0.; j < i; ++j)
        c += n21(floor(uv * m / pow(.5, j))) * pow(.5, j);
    
    return c / 2.;
}

mat3 look_at(vec3 d, vec3 u)
{
    vec3 r = normalize(cross(u, d));
    u = normalize(cross(d, r));
    return mat3(r, u, d);
}

mat3 rotX(float a)
{
    return mat3(
        cos(a), -sin(a), 0,
        sin(a), cos(a), 0,
        0, 0, 1
    );
}

vec3 perspective_ray(vec2 uv, float fov)
{
    return normalize(vec3(uv, fov));
}

float grid(vec3 uv)
{
    /*const float sz = 64.;
    return false 
        || uv.x < 0. || uv.y < 0. || uv.z < 0.
        || uv.x > sz || uv.y > sz || uv.z > sz
        || ((abs(uv.z) == sz / 2. || abs(uv.z) == floor(sz / 1.25) || abs(uv.z) == floor(sz / 1.1)) && n31(uv) < .1)
        || (uv.x < sz / 2. && uv.y < sz / 2. && uv.z > sz / 2.)
        ? 1. : 0.;
    */
    
    return on21(uv.xz, 4., 0.) * 32. > uv.y ? 1. : 0.;
    
    //return n31(uv + 5.) < .001 ? 1. : 0.;
}

bool traverse_voxel(vec3 ro, vec3 rd, out vec3 id, out vec3 n)
{
    // this magic is nesseccary for the algorithm to work. don't ask me why lol
    rd = normalize(1. / rd);
    
    //const int size = 16;
    int x = int(floor(ro.x));
    int y = int(floor(ro.y));
    int z = int(floor(ro.z));
    int stepX = int(sign(rd.x));
    int stepY = int(sign(rd.y));
    int stepZ = int(sign(rd.z));
    //int outX = size * stepX;
    //int outY = size * stepY;
    float tDeltaX = abs(rd.x);
    float tDeltaY = abs(rd.y);
    float tDeltaZ = abs(rd.z);
    float tMaxX = tDeltaX - fract(ro.x * sign(rd.x)) * tDeltaX;
    float tMaxY = tDeltaY - fract(ro.y * sign(rd.y)) * tDeltaY;
    float tMaxZ = tDeltaZ - fract(ro.z * sign(rd.z)) * tDeltaZ;
    int status = -1; // unresolved
    int i = 0;
    
    do {
        if(tMaxX < tMaxY) {
            if (tMaxX < tMaxZ) {
                tMaxX += tDeltaX;
                x += stepX;
                n = vec3(-stepX, 0, 0);
            } else {
                tMaxZ += tDeltaZ;
                z += stepZ;
                n = vec3(0, 0, -stepZ);
            }
        } else {
            if (tMaxY < tMaxZ) {
                tMaxY += tDeltaY;
                y += stepY;
                n = vec3(0, -stepY, 0);
            } else {
                tMaxZ += tDeltaZ;
                z += stepZ;
                n = vec3(0, 0, -stepZ);
            }
        }
        
        if (grid(vec3(x, y, z)) == 1.) {
            status = 0; // hit
            id = vec3(x, y, z);
        }
        
        //if (x == outX || y == outY) status = 1; // outside
    } while(status == -1 && i++ < TRAVERSAL_MAX_IT);
    
    return status == 0;
}

vec3 grass(vec2 uv) {
    float n = on21(uv * resolution.y, 4., 0.);
    uv += n * vec2(9., 17.) / resolution.y;
    float t = time * 10.;
    vec3 c = vec3(0);
    
    c += on21(uv * resolution.y, 4., 0.);
    c *= vec3(.9, 1., .35);
    c *= on21(uv * resolution.y, 3., -3.);
    return c;
}

vec3 dirt(vec2 uv) {
    float n = on21(uv * resolution.y, 4., 0.);
    uv += n * vec2(9., 17.) / resolution.y;
    float t = time * 10.;
    vec3 c = vec3(0);
    
    c += on21(uv * resolution.y, 4., 0.);
    c *= vec3(1., .7, .35);
    c *= on21(uv * resolution.y, 4., 0.);
    return c;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * .5) / resolution.y;
    vec2 m = (mouse*resolution.xy.xy - resolution.xy * .5) / resolution.y;
    vec3 col = vec3(0);
    
    //vec3 ro = vec3(vec2(time * .5), 0);
    vec3 ro = vec3(vec2(0, 32) - m * 64., 0) + .001;
    mat3 l = look_at(normalize(vec3(m * 2., 1)), vec3(0, 1, 0));
    vec3 rd = l * perspective_ray(uv, .5);
    
    {
        vec3 id, n;
        if (traverse_voxel(ro, rd, id, n)) {
            col.b += (smoothstep(float(TRAVERSAL_MAX_IT), 0., length(id - ro))  * .5 + .5) * clamp(dot(rd, -n), 0., 1.);
        }
    }

    glFragColor = vec4(col, 1.);
}
