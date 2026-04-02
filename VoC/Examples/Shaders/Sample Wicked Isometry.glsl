#version 420

// original https://www.shadertoy.com/view/Wt2fDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define textureCube texture

#define MAX_STEPS 100
#define MAX_DIST 200.
#define EPSILON 0.00001
#define PI 3.14159265
#define IVORY 1.
#define BLUE 2.
#define BLACK 3.
#define RED 4.
#define LIGHT 5.

#define PHI (sqrt(5.)*0.5 + 0.5)
#define time (time / 1.1)

#define N 6

float rnd (float x) {return fract(10000. * sin(10000. * x));}

mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec3 boxTexture(vec3 p, float id) {
    if (p.x + -p.z < 0.) {
        p.xz = p.zx;
        id += 1.;//1000. * rnd(id);
    }
    id = floor(id);
    id = mod(id, 52.);
    float col = mod(id, 10.);
    float row = id - col;
    p.x -= col * 2.;
    p.y -= row * 2.;
    p.xy -= 1.;
    p.xy *= .05;
    return vec3(1);//texture(iChannel0, p.xy).rgb;
}

// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
vec2 getDist(vec3 p) {
    float w = 0.5;
    vec2 step = vec2(2);

    p.xz *= Rot(0.3 * sin(time + length(p.xz))); 

    p.xz = mod(p.xz, step);
    p.xz -= step / 2.;

    p.xz *= Rot(time);
    p.zy *= Rot(PI / 4.);
    p.xz *= Rot(PI / 4.);
    float box1 = sdBox(p, vec3(w));
    float obj = min(box1, box1);
    return vec2(obj * .6, RED);
}
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

vec3 rayMarch(vec3 ro, vec3 rd) {
    float d = 0.;
    float info = 0.;
    //float glow = 0.;
    float step = 0.;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 distToClosest = getDist(ro + rd * d);
        step ++;
        // volumeLight += .01;
        d += abs(distToClosest.x);
        info = distToClosest.y;
        if(abs(distToClosest.x) < EPSILON || d > MAX_DIST) {
            break;
        }
    }
    return vec3(d, info, step);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.);
    vec3 n = getDist(p).x - vec3(getDist(p - e.xyy).x,
                               getDist(p - e.yxy).x,
                               getDist(p - e.yyx).x);
    return normalize(n);
}

vec3 getRayDirection (vec3 ro, vec2 uv, vec3 lookAt) {
    vec3 rd;
    rd = normalize(vec3(uv - vec2(0, 0.), 1.));
    vec3 lookTo = lookAt - ro;
    float horizAngle = acos(dot(lookTo.xz, rd.xz) / length(lookTo.xz) * length(rd.xz));
    rd.xz *= Rot(horizAngle);
    return rd;
}

vec3 getRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    // ray origin
    vec3 ro = vec3(uv.x, 10, uv.y) * 10.;
    // ro.yz *= Rot(PI / 4.);
    // ro.xz *= Rot(-PI / 4.);
    // ro += vec3(-2, 2, -2);
    // ro.xz *= Rot(time);

    // vec2 angle = 2. * 3.14159265 * mouse*resolution.xy.xy / resolution.xy;
    // vec3 lookat = vec3(0, 0, 0);
    // lookat.xz *= Rot(angle.x);
    // lookat.yz *= Rot(angle.y);

    vec3 rd = normalize(vec3(0, -1, 0));
    vec3 rm = rayMarch(ro, rd);
    float d = rm[0];
    float info = rm[1];
    float steps = rm[2];

    vec3 colorBg = vec3(.0);
    vec3 color;
    color = vec3(0);
    vec3 light = vec3(13, 4, 10);
    //light.xz *= Rot(time);
    vec3 p = ro + rd * d;
    if (d < MAX_DIST) {
        vec3 n = getNormal(p);
        //n.zy *= Rot(time);
        // color = vec3( n * 0.5 + 0.5 );

        //color *= info;
        // vec3 tex = boxmap(u_tex_bg, ro + rd * d, n, 32.0 ).xyz;//
        // self shadeing
        // drop shadows
        // trying to raymarch to the light for MAX_DIST
        // and if we hit something, it's shadow
        vec3 dirToLight = normalize(light - p);
        vec3 rayMarchLight = rayMarch(p + dirToLight * .06, dirToLight);
        float distToObstable = rayMarchLight.x;
        float distToLight = length(light - p);
        // if (distToObstable < distToLight) {
        //     color *=  0.;
        // }

        // smooth shadows
        // float shadow = smoothstep(0.0, .15, rayMarchLight.z / PI);
        // color += .1 + .9 * shadow;

        // tex *= color_bw;
        // color = tex;
        // color += 0.6 + vec3( color_bw );
        // coloring 
        if (d < MAX_DIST) {
           if (info == RED) {
                color = boxTexture(p, time) + .1;
                color *= dot(dirToLight, n) * .5 + .5;
            }
        }
    }

    glFragColor = vec4(color, 1);
}
