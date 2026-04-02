#version 420

// original https://www.shadertoy.com/view/tljGzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A Shadertoy version of a Munker illusion, as investigated by Prof David Novick:
// http://www.cs.utep.edu/novick/colors/explanation/

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// cosine palette from: iq, https://www.shadertoy.com/view/ll2GD3
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}
vec3 pal_1(in float t)
{
  return pal( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
}
    
struct Ray {
    vec3 r0;
    vec3 rd;
};    
struct Material {
    vec3 c;
};
struct Hit {
    float dist;
    vec3 normal;
    Material material;
    int id;
};    
struct Sphere {
    int id;
    vec3 s0;
    float sr;
    Material material;
};
float raySphereIntersect(vec3 r0, vec3 rd, vec3 s0, float sr) {
    // - r0: ray origin
    // - rd: normalized ray direction
    // - s0: sphere center
    // - sr: sphere radius
    // - Returns distance from r0 to first intersecion with sphere,
    //   or -1.0 if no intersection.
    float a = dot(rd, rd);
    vec3 s0_r0 = r0 - s0;
    float b = 2.0 * dot(rd, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    if (b*b - 4.0*a*c < 0.0) {
        return -1.0;
    }
    return (-b - sqrt((b*b) - 4.0*a*c))/(2.0*a);
}
Hit traceSphere(Ray r, Sphere s)
{
    float dist = raySphereIntersect(r.r0, r.rd, s.s0, s.sr);    
    if (dist > 0.0) {
        vec3 p = r.r0 + r.rd * dist;
        vec3 n = normalize(p-s.s0);
        return Hit(dist, n, s.material, s.id);
    }
    return Hit(-1.0, vec3(0.0), s.material, -1);
}

vec3
pos(int id)
{
    // TODO return a whole sphere not just center
    float fx = 2.0;
    float fy = 2.0;
    float fz = 2.0;
    float num = 3.0;
    float t = (time*0.05+float(id)/num) * 3.14159 * 2.0;
    return vec3(
        sin(fx*t) * 2.5,
        cos(fy*t) * 1.5,
        sin(fz*t) * 1.5 + 9.0);
}

Hit trace(Ray r)
{
    // TODO should be a loop
    Sphere s1 = Sphere(0, pos(0), 0.7, Material(vec3(0.8, 0.7, 0.6)) );
    Sphere s2 = Sphere(1, pos(1), 0.7, Material(vec3(0.8, 0.7, 0.6)) );
    Sphere s3 = Sphere(2, pos(2), 0.7, Material(vec3(0.8, 0.7, 0.6)) );
    Hit h1 = traceSphere(r,s1);
    Hit h2 = traceSphere(r,s2);
    Hit h3 = traceSphere(r,s3);
    
    // Find closest ray hit
    Hit h;
    h.dist = -1.0;
    h = h1;
    if ((h2.dist > 0.0 && h2.dist < h.dist) || (h.dist < 0.0)) h = h2;
    if ((h3.dist > 0.0 && h3.dist < h.dist) || (h.dist < 0.0)) h = h3;
    
    // Shade hit
    if (h.dist > 0.0) {
        h.material.c = vec3(0.0);
        float direct = dot(h.normal, normalize(vec3(0.5, 0.5, -1)));
        vec3 albedo = pal_1(0.9);
        h.material.c += albedo * direct;
    }
    
    return h;
}

void main(void)
{
    // Normalized device coordinates (0..1)
    vec2 ndc = gl_FragCoord.xy/resolution.xy;
    
    const float fov_x_deg = 60.0;
    const float screen_distance = 1.0/tan(radians(fov_x_deg/2.0));
    
    // "Screen" space coordinates (-1..+1 in max dimension)
    vec2 sp = 2.0*(gl_FragCoord.xy-resolution.xy/2.0)/max(resolution.x, resolution.y);
    
    // Left-handed camera ray: +X right, +Y up, +Z into scene
    Ray cr;
    cr.r0 = vec3(0.0);
    cr.rd = vec3(sp.x, sp.y, screen_distance);

    // Sample radiance
    vec3 c = vec3(0.0);
    Hit h = trace(cr);
    if (h.dist >= 0.0) {
        c += h.material.c;
    } else {
        //c += vec3(abs(sp.x), abs(sp.y), 0.0);
    }
    
    // Comp stripes
    if (true) {
        float x = ( sp.y) * 70.0;
        int n = int(mod(x, 4.0));
        vec3 c2 = c;
        if (h.id == -1 || (h.id == n || h.id == n+1)) {
          c2 = pal_1(float(n)*0.25 + time*0.2);
        }
        float on = 5.0;
        float off = 3.0;
        float cycle_time = mod(time, on+off);
        if (cycle_time < on) {
            c = c2;
        } else {
          c = mix(c, c2, cos((cycle_time-on)/off*3.14159*2.0)*0.5+0.5);
        }
    }
    
    // Output to screen
    glFragColor = vec4(c.x, c.y, c.z, 1.0);
}
