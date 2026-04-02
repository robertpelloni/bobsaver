#version 420

// original https://www.shadertoy.com/view/ltdcWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAXITERS 1000
#define LENFACTOR 0.9
#define NDELTA 0.001
#define MAXSTEP 0.05
#define NDELTAX vec3(NDELTA, 0., 0.)
#define NDELTAY vec3(0., NDELTA, 0.)
#define NDELTAZ vec3(0., 0., NDELTA)

vec4 plasma(vec3 uv)
{
    float d = 0.0;
    for (float i = 0.0; i < 25.0; ++i)
        d += cos( max(0.0, 3.14 - distance(uv, vec3(
            sin(i + time * mod(i * 2633.2363, 0.42623)) * 3.0,
            cos(i * 0.617 + time * mod(i * 36344.2363, 0.52623)) * 3.0,
            cos(i * 1.617 + time * 3. * mod(i * 45634.53453, 0.34544)) * 8.0 - 12.0
        ))));
    float r = cos(d * 6.0), g = cos(d * 3.0), b = cos(d * 1.5);
    return vec4((r+g*0.8+b*0.4) + 1.5,
                r*0.8+g*0.6+b*0.2 + 0.2,
                r*0.4+g*0.3+b*0.1, 1.0);
}

float addCuboid(float d, vec3 p, vec3 c, vec3 r) {
    vec3 cd = r - abs(p - c);
     return max(d, min(cd.x, min(cd.y, cd.z)));
}

float scene(vec3 p, vec3 tardisPos, mat3 tardisRot) {
    // tube
    float d = length(p.xy) - 2.;
    if (p.z < -4.) return d;
    // tardis
    p = (p - tardisPos) * tardisRot;
    // body
    d = addCuboid(d,p, vec3(0., .0, 0.), vec3(.18, .38, .18));
    // top/bottom
    d = addCuboid(d,p, vec3(0., 0.4, 0.), vec3(.22, .02, .22));
    d = addCuboid(d,p, vec3(0., 0.46, 0.), vec3(.03, .07, .03));
    d = addCuboid(d,p, vec3(0., -.4, 0.), vec3(.22, .02, .22));
    d = addCuboid(d,p, vec3(0., .44, 0.), vec3(.18, .02, .18));
    // corner struts
    d = addCuboid(d,p, vec3(-.18, 0., 0.18), vec3(.02, .4, .02));
    d = addCuboid(d,p, vec3(.18, 0., 0.18), vec3(.02, .4, .02));
    d = addCuboid(d,p, vec3(-.18, 0., -0.18), vec3(.02, .4, .02));
    d = addCuboid(d,p, vec3(.18, 0., -0.18), vec3(.02, .4, .02));
    // centre struts
    d = addCuboid(d,p, vec3(0., 0., 0.), vec3(.19, .4, .02));
    d = addCuboid(d,p, vec3(0., 0., 0.), vec3(.02, .4, .19));
    // horizontal struts
    d = addCuboid(d,p, vec3(0., -0.2, 0.), vec3(.19, .02, .19));
    d = addCuboid(d,p, vec3(0., 0., 0.), vec3(.19, .02, .19));
    d = addCuboid(d,p, vec3(0., 0.2, 0.), vec3(.19, .02, .19));
    return d;
}
    
vec3 sceneNormal(vec3 p, vec3 tardisPos, mat3 tardisRot) {
    return normalize(vec3(
        scene(p + NDELTAX, tardisPos, tardisRot) - scene(p - NDELTAX, tardisPos, tardisRot),
        scene(p + NDELTAY, tardisPos, tardisRot) - scene(p - NDELTAY, tardisPos, tardisRot),
        scene(p + NDELTAZ, tardisPos, tardisRot) - scene(p - NDELTAZ, tardisPos, tardisRot)
    ));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.yy;
    vec3 ray = normalize(vec3(uv, 1.));
    vec3 cam = vec3(0., 1., -1.);
    
    vec3 tardisPos = vec3(sin(time) * 0.25, cos(time) * 0.25 + 1., -3.);
    float sx = sin(time), sy = sin(time * 0.83), sz = sin(time * 0.51),
              cx = cos(time), cy = cos(time * 0.83), cz = cos(time * 0.51);
    mat3 tardisRot = mat3(cx, -sx, 0, sx, cx, 0, 0, 0, 1)
        * mat3(1, 0, 0, 0, cy, -sy, 0, sy, cy)
        * mat3(cz, 0, sz, 0, 1, 0, -sz, 0, cz);
    
    vec3 pos = cam;
    for (int i = 0; i < MAXITERS; ++i) {
        float dist = scene(pos, tardisPos, tardisRot);
        dist = min(dist, MAXSTEP);
        ray.x += (sin(time * 0.6 + pos.z * 0.4) * 0.02
            + sin(time * 0.83 + pos.z * 0.37) * 0.0312) * dist;
        ray.y += (cos(time * 1.12 + pos.z * 0.2) * 0.035
            + cos(time * 1.42 + pos.z * 0.51) * 0.024) * dist;
        ray = normalize(ray);
        pos += ray * dist * LENFACTOR;
        if (dist > -0.0001) break;
    }
    
    // tube
    if (dot(pos.xy, pos.xy) > 3.9 || pos.z < -20.) {
        vec3 light = vec3(cos(time * 0.72) * 1.8,
                          cos(time * 0.34) * 1.8,
                          sin(time * 0.72) * 5. - 10.);
        vec3 toLight = light - pos;
        float brightness = 1.5;
        // I've not checked but I'm guessing inverse-square-law here:
        brightness /= pow(length(toLight), 0.5);
        brightness += 0.3;
        glFragColor =  max(vec4(0.), plasma(pos)) * brightness
            * vec4(vec3(-dot(sceneNormal(pos, tardisPos, tardisRot),
                             normalize(toLight) )) * brightness, 1.);
            //+ texture(iChannel0, uv)*pow(length(pos),2.)*0.003;
    } else {
        // box
        vec3 p = (pos - tardisPos) * tardisRot;
        float l = -sceneNormal(pos, tardisPos, tardisRot).z;
        if (p.y < 0.2 || p.y > 0.4 || p.x > .19 || p.z > .19 || p.x < -.19 || p.z < -.19
                 || fract((p.x)*18.) > 0.96
                    || fract((p.z)*18.) > 0.96
                 || ( p.y > 0.298 && p.y < 0.302 ))
            glFragColor = vec4(0.,0.,l,1.);
        else
            glFragColor = vec4(l,l,l,1.);
    }
    //glFragColor = vec4(fract(pos), 1.);
    //glFragColor = vec4(sceneNormal(pos, tardisPos, tardisRot) * 0.5 + 0.5, 1.);
}
