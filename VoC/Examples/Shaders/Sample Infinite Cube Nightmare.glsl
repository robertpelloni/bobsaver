#version 420

// original https://www.shadertoy.com/view/WdtcRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float EPS = 0.01;
const float PI = 3.1415;
vec3 color = vec3(0.3, 0.4, 0.5);
vec3 glow;

void rotate(inout vec2 s,float v) {
    s=s*cos(v)+sin(v)*vec2(s.y,-s.x);
}

vec3 rep(vec3 p, float m) {
    vec3 c = floor(p/m + 0.5)*m;
    return p - c;
}

float extrude(float d1, float d2, float m) {
    return min(d1, max(d2, d1-m));
}

float smin( float a, float b, float k )
{
    float blend0=clamp(.5+.5*(b-a)/k,0.,1.);
    return mix( b, a, blend0 )-k*blend0*(1.-blend0);
}

float cube(vec3 p, float b) {
    vec3 q = abs(p) - b;
      return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float dist(vec3 p) {
    float r = 0.04*length(p);
    
    rotate(p.xz, time + 0.5*sin(time) - r);
    rotate(p.xy, 1.2*time -r);
    p = abs(p) - 5.;
    float factor = 0.5*sin(10.*r) + 0.4*r;
    float d = cube(p.xxy, 1.0) +factor;
    d = min(d, cube(p.xxz, 1.0)+factor);
    d = min(d, cube(p.zzy, 1.0)+factor);
    glow = vec3(0.4) + 0.1*sin(3.*p + 4.*time);
    glow *= 1. + 0.4*sin(10.*r - 6.*(floor(time) + smoothstep(0., 0.5, fract(time))));
    return min(d, cube(p, 3.0)) + 0.05*sin(dot(p, vec3(10.)));
}

vec3 getNormal(vec3 p) {
    vec2 e = 0.5 * vec2(EPS, 0.);
    return normalize(vec3(dist(p + e.xyy) - dist(p - e.xyy),
                          dist(p + e.yxy) - dist(p - e.yxy),
                          dist(p + e.yyx) - dist(p - e.yyx)));
}

vec3 glowacc;

float raymarch(vec3 p, vec3 dir) {
    glowacc = vec3(0.0);
    float d = 0.0, t, old_d = 0.0, old_t = 0.0;
    for (int niters=0; niters<100; niters++) {
        d = dist(p + dir*t);
        if (d < EPS) break;
        old_d = d;
        old_t = t;
        t += 0.5*d;
        glowacc += 0.05*glow/pow(d, 0.2);
    }
    return old_t + (t - old_t)*(old_d - EPS)/(old_d - d);
}

float shade(vec3 p, vec3 ray_dir, vec3 light_pos) {
    vec3 normal = getNormal(p);
    vec3 lightdir = normalize(p - light_pos);
    float ambient=0.25, diffuse=0.5, mat_specular=0.3, mat_hardness=0.0;
    return ambient
           + diffuse * max(dot(lightdir, normal), 0.0)
           + mat_specular * pow(max(dot(lightdir, reflect(ray_dir, normal)), 0.0), mat_hardness);
}

void main(void) {
    vec2 pos = (gl_FragCoord.xy * 2. / resolution.xy -1.)*vec2(16./9., 1.);
   
    vec3 p = vec3(3.0, -9.0, 15.0);
    vec3 camera_target = vec3(0.0);
    float camera_AoV = 60.0 * 2.*PI/360.0;
    
    vec3 fog_color = vec3(0.0);
    vec3 light_pos = vec3(-10.0, -10.0, -10.0);
    
    // get ray direction
    vec3 forward = normalize(camera_target - p);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(forward, up));
    up = normalize(cross(forward, right));
    float ratio = 2.*tan(camera_AoV/2.0);
    vec2 q = pos * ratio;
    vec3 ray_dir = normalize(q.x * right + q.y * up + forward);
    
    // raymarch and light the scene
    float t = raymarch(p, ray_dir);
    vec3 ray_end = p + t*ray_dir;

    float fogfactor = clamp(t*t/5000., 0.0, 1.0);

    glFragColor.rgb = mix(color * shade(ray_end, ray_dir, light_pos), fog_color, fogfactor);

    if (dist(ray_end) > 2.0*EPS) {
        glFragColor.rgb = fog_color;
    }
    
    glFragColor.rgb += glowacc;
       
}
