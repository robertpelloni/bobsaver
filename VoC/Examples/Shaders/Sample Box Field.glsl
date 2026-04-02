#version 420

// original https://www.shadertoy.com/view/3tSBzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 empty() { return vec4(0.,0.,0.,1e20); }
vec4 inv(vec4 a) { return vec4(a.xyz, -a.w); }
vec4 un(vec4 a, vec4 b) { return a.w < b.w ? a : b; }
vec4 isect(vec4 a, vec4 b) { return a.w > b.w ? a : b; }
vec4 diff(vec4 a, vec4 b) { return isect(a, inv(b)); }

vec4 sphere(vec3 matl, vec3 p, float r) { return vec4(matl, length(p) - r); }
vec4 box(vec3 matl, vec3 p, vec3 r, float o) { return vec4(matl, length(max(vec3(0.), abs(p)-r+o))-o); }

mat3 rotX(float a) { float s = sin(a), c = cos(a); return mat3(1.,0.,0.,0.,c,-s,0.,s,c); }
mat3 rotY(float a) { float s = sin(a), c = cos(a); return mat3(c,0.,s,0.,1.,0.,-s,0.,c); }
mat3 rotZ(float a) { float s = sin(a), c = cos(a); return mat3(c,-s,0.,s,c,0.,0.,0.,1.); }

vec4 repeating(vec3 p, vec2 grid)
{
    vec3 color = vec3(.2) + vec3(
        fract(1e3*sin(dot(grid, vec2(1e2, 1e1)))),
        fract(1e3*sin(dot(grid, vec2(2e2, 6e1)))),
        fract(1e3*sin(dot(grid, vec2(3e2, 2e1)))));

    float h = 1.*fract(1e3*sin(dot(grid, vec2(6e2, 3e1))));

    p *= rotY(time*8.*pow(fract(sin(dot(grid, vec2(2e2, 8e2)))),1.5));
    
    return box(color, p, vec3(1.2, h, 1.2), .1);
}

vec4 scene(vec3 p)
{
    p -= vec3(0., -10., 3.);
      p *= rotX(.4);
    p *= rotY(time * 0.04);

    vec3 sky = vec3(.9, .9, 1.2);
    vec4 r = inv(sphere(sky, p, 800.));

    vec2 grid = floor(p.xz / 4.);
    p.xz = mod(p.xz, 4.)-2.;

    r = un(r, repeating(p, grid));
   
    return r;
}

vec3 shade(vec3 p, vec4 r)
{
    const vec2 e = vec2(0.01, 0.);
    const vec3 light = normalize(vec3(1.,1.,-2.));
                    
    vec3 grad = (vec3(scene(p+e.xyy).w, scene(p+e.yxy).w, scene(p+e.yyx).w) - vec3(r.w)) / e.x;
    float diff = .8 * dot(grad, light);
    float spec = 2. * pow(dot(grad, light), 20.);
    
    return r.xyz * diff + r.xyz * spec;
}

void main(void)
{
    vec2 coord = gl_FragCoord.xy;
    vec2 uv = (coord/resolution.xy - vec2(.5)) * vec2(resolution.x / resolution.y, 1.);
    float fov = 1.1 + 0.9 * sin(time*.4);
    vec3 view = normalize(vec3(uv.xy, 1./fov));
    vec4 color = vec4(0.,0.,0.,1.);

    int iter = 0;
    vec3 p = vec3(0.);
    while (++iter < 300) {
             vec4 r = scene(p);
        if (abs(r.w) < .001) {
               color.xyz = shade(p, r);
               break;
        }
        p += view * r.w;
    }
    
    color.rgb *= sqrt(1.0 - dot(uv,uv));
    color.rgb = pow(color.rgb, vec3(.8));

    glFragColor = color;
}
