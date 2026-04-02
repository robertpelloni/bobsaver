#version 420

// original https://www.shadertoy.com/view/Wl2SWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Raymarching animation experiment
// inspired by Inigo Quilez live stream shader deconstruction
// Leon Denise (ponk) 2019.08.28

// Using code from
// Inigo Quilez
// Morgan McGuire

// toolbox
const float PI = 3.1415;
const float TAU = 6.283;
const float distance_max = 10.0;
#define repeat(p,r) (mod(p,r)-r/2.)
float random(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }
mat2 rot(float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
vec3 look (vec3 eye, vec3 target, vec2 anchor, float fov) {
    vec3 forward = normalize(target-eye);
    vec3 right = normalize(cross(forward, vec3(0,1,0)));
    vec3 up = normalize(cross(right, forward));
    return normalize(forward * fov + right * anchor.x + up * anchor.y);
}
float smoothmin (float a, float b, float r) { float h = clamp(.5+.5*(b-a)/r, 0., 1.); return mix(b, a, h)-r*h*(1.-h); }
float sdSphere (vec3 p, float r) { return length(p)-r; }
float sdBox (vec3 p, vec3 b) { vec3 d = abs(p) - b; return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)); }

// geometry
float map (vec3 pos, float time) {
    float scene = 1.;
    const int count = 6;
    float balance = 1.9;
    float t = time + pos.x / 4.;
    t = floor(t)+pow(fract(t),.5);
    float a = 1.0;
    float range = 1.;
    float radius = .4;
    float blend = .7;
    for (int i = count; i > 0; --i) {
        pos.xz = abs(pos.xz)-range*a;
        pos.xy *= rot(cos(t)*balance/a+a*2.);
        pos.zy *= rot(sin(t)*balance/a+a*2.);
        //scene = min(scene, sdBox(pos,vec3(radius*a)));
        scene = smoothmin(scene, sdSphere(pos,(radius*a)), blend*a);
        a /= 1.8;
    }
    
    return scene;
}

vec3 getNormal (vec3 pos, float time) {
     vec2 e = vec2(.001,0);
     return normalize(vec3(map(pos,time)-vec3(map(pos-e.xyy,time),
                                             map(pos-e.yxy,time),
                                             map(pos-e.yyx,time))));
}

vec4 raymarch ( vec3 eye, vec3 ray, float time ) {
    float dither = random(ray.xy+fract(time));
    float total = 0.0;
    float shade = 0.0;
    const int count = 20;
    for (int index = count; index > 0; --index) {
        float dist = map(eye,time);
        dist *= 0.9+0.1*dither;
        total += dist;
        if (total > distance_max) {
            shade = 0.;
            break;
        }
        if (dist < 0.001 * total) {
            shade = float(index)/float(count);
            break;
        }
        eye += ray * dist;
    }
    return vec4(eye, shade);
}

vec3 lighting (vec2 uv, vec3 ray, vec4 result) {
    float shade = result.w;
    return vec3(shade);
    /*
    vec3 normal = getNormal(result.xyz, time);
    vec3 rf = reflect(normal, ray);
    float d = smoothstep(0.0,2.0,length(uv));
    vec3 sky = mix(vec3(0.65,.67,.7), vec3(0.1), d);
    vec3 colorLight = vec3(.91,.88,.87);
    vec3 light = normalize(vec3(-4,8,-4));
    float diffuse = clamp(dot(normal, light),0.,1.);
    float backlight = clamp(dot(rf, normal), 0., 1.);
    float spec = clamp(dot(ray, reflect(light,normal)), 0.,1.);
    vec3 color = mix(sky*.4, vec3(0), shade);
    color += diffuse*colorLight*shade;
    color += pow(clamp(backlight,0.,1.),2.)*colorLight*shade;
    color += .5*pow(clamp(spec,0.,1.), 12.)*shade;
    return color;
    */
}

void main(void)
{
    vec2 uv = 2.*(gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 eye = vec3(0,0,2.5);
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy*2.-1.;
    //if (mouse*resolution.xy.z > 0.5) {
    //    eye.yz *= rot(mouse.y*PI);
    //    eye.xz *= rot(mouse.x*PI);
    //} else {
        eye = vec3(1,2.5,1.);
    //}
    float fov = 1.5;
    vec3 ray = look(eye, vec3(0), uv, fov);
    float dither = random(ray.xy+fract(time));
    vec4 result = raymarch(eye, ray, time+dither/10.);
    vec3 color= lighting(uv, ray, result);
    
    glFragColor = vec4(color,1);
}
