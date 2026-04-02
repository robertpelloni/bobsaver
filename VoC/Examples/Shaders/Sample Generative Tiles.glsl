#version 420

// original https://www.shadertoy.com/view/WtBfzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define EPSILON 0.0001
#define PI 3.14159265
#define IVORY 1.
#define BLUE 2.
#define BLACK 3.

mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sdSphere(vec3 p, float radius) { return length(p) - radius; }
float sdBox( vec3 p, vec3 b ) { vec3 q = abs(p) - b; return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0); }

float sdTorus(vec3 p, float smallRadius, float largeRadius) {
    return length(vec2(length(p.xz) - largeRadius, p.y)) - smallRadius;
}

// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
vec2 getDist(vec3 p) {
    p.y -= 0.5;
    vec2 plane = vec2(p.y+0.5, IVORY);
    float step = 1.5;
    p.x += time;
    p.z -= time;
    
    vec3 pFrame = p;
    pFrame.xz -= step / 2.;
    pFrame.xz = mod(pFrame.xz, step) - step / 2.;
    pFrame.xz *= Rot(PI / 4.);
    pFrame.xz = abs(pFrame.xz);
    pFrame.xz *= Rot(PI / 4.);
    pFrame.xy *= Rot(PI / 4.);
    float frame = sdBox(pFrame, vec2(0.074, step / 2.).xxy);
    
    vec2 id = floor(p.xz / step);
    p.xz = mod(p.xz, step) - step / 2.;
    //p.xz *= Rot(time / 4.);
    vec3 pBox = p;
    // pBox.xz /= 100.;// * (.5 + .5 * sin(time));
    //vec3 pTiles = p;
    float t = time;
    t = floor(t) + smoothstep(0.4, 0.6, fract(t));
    p.y += sin(id.x + id.y * 2. + t / 10.);
    float box = sdBox(pBox, vec2(0.05, step / 2.).yxy);
    //p.yz *= Rot(PI / 2.);
    float scale = 0.7;
    vec2 torus = vec2(sdTorus(p, .4, 1.5), BLUE);
    for (int i = 0; i < 7; i++) {
        p.xz = abs(p.xz);
        p.xz -= 1.;
        p /= scale;
        p.yz *= Rot(PI / 2.);
        p.xy *= Rot(PI / 4.);
        vec2 newTorus = vec2(sdTorus(p, .4, 1.5) * pow(scale, float(i+1)), BLUE);
        torus = torus.x < newTorus.x? torus : newTorus;
    }
    torus = box < torus.x ? torus : vec2(box, 0);
    vec2 fractalAndPlane = torus.x < plane.x? torus : plane;
    //torus.x -=  - 0.03;
    return fractalAndPlane.x < frame ? fractalAndPlane : vec2(frame, BLACK);
}
// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

vec3 rayMarch(vec3 ro, vec3 rd) {
    float d = 0.;
    float info = 0.;
    //float glow = 0.;
    float minAngleToObstacle = 1e10;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 distToClosest = getDist(ro + rd * d);
        minAngleToObstacle = min(minAngleToObstacle, atan(distToClosest.x, d));
        d += distToClosest.x;
        info = distToClosest.y;
        if(abs(distToClosest.x) < EPSILON || d > MAX_DIST) {
            break;
        }
    }
    return vec3(d, info, minAngleToObstacle);
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
    vec3 ro = vec3(-3, 5, 3);
    float zoom = 1.100;
    
    // ray direction
    vec3 rd = getRayDir(uv, ro, vec3(0), 0.75);
    
    vec3 rm = rayMarch(ro, rd);
    float d = rm[0];
    float info = rm[1];
    
    float color_bw = 0.;
    vec3 colorBg = vec3(0.233,0.715,0.920);
    vec3 color = vec3(0);
    vec3 light = vec3(50);
    //light.xz *= Rot(time);
    vec3 p = ro + rd * d;
    if (d < MAX_DIST) {
        vec3 n = getNormal(p);
        //n.zy *= Rot(time);
        //color = vec3( n + 1.0 );
        //color *= info;
        // vec3 tex = boxmap(u_tex_bg, ro + rd * d, n, 32.0 ).xyz;//
        // self shadeing
        color_bw = 0.5 + .5 * dot(n, normalize(light - p));
        // drop shadeos
        // trying to raymarch to the light for MAX_DIST
        // and if we hit something, it's shadow
        vec3 dirToLight = normalize(light - p);
        vec3 rayMarchLight = rayMarch(p + dirToLight * .5, dirToLight);
        float distToObstable = rayMarchLight.x;
        float distToLight = length(light - p);
        // if (distToObstable < distToLight) {
        //     color_bw =  0.;
        // }

        // smooth shadows
        float shadow = smoothstep(0.0, .1, rayMarchLight.z / PI);
        color_bw *= .7 + .3 * shadow;
        

        // tex *= color_bw;
        // color = tex;
    }
    color += 0.6 + vec3( color_bw );
    // coloring
    if (info == IVORY) {
        color *= vec3(0.433,0.457,0.545);
    }
    else if (info == BLUE) {
        color *= vec3(0.655,0.129,0.054);
    }
    else if (info == BLACK) {
        color *= vec3(0.130,0.130,0.130);
    }
    color = mix(color, colorBg, smoothstep(20., 28., d));
    
    
    
    glFragColor = vec4(color,1.0);
}
