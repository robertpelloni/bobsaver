#version 420

// original https://www.shadertoy.com/view/wtsBDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define EPSILON 0.0001
#define PI 3.14159265

mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float sdSphere(vec3 p, float radius) { return length(p) - radius; }
float sdBox( vec3 p, vec3 b ) { vec3 q = abs(p) - b; return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0); }

float sdCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

vec2 getDist(vec3 p) {
    
    //p.x += -0.8;
    p.xz *= Rot(time * 2.);
    float scale = 0.4 + 0.1 * sin(time);
    vec2 box = vec2(1e10, 1.);
    
    for (float i = 0.; i < 5.; i++) {
        vec2 box2 = vec2( sdBox(p, vec3(1)) * pow(scale, i), 0.5 + i / 5. );
        box = box.x < box2.x ? box : box2;
        p = abs(p);
        p -= 1.;
        p.xz *= Rot(time);
        p /= scale;
    }
    
    return box;
}

// ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

vec2 rayMarch(vec3 ro, vec3 rd) {
    float d = 0.;
    float info = 0.;
    //float glow = 0.;
    float distToClosestLight = 9999999.;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec2 distToClosest = getDist(ro + rd * d);
        d += distToClosest.x;
        info = distToClosest.y;
        if(abs(distToClosest.x) < EPSILON || d > MAX_DIST) {
            break;
        }
    }
    return vec2(d, info);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.);
    vec3 n = getDist(p).x - vec3(getDist(p - e.xyy).x,
                               getDist(p - e.yxy).x,
                               getDist(p - e.yyx).x);
    return normalize(n);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    
    // ray origin
    vec3 ro = vec3(0, 0., -5.5);
    float zoom = 1.100;
    
    // ray direction
    vec3 rd = normalize(vec3(uv, zoom));
    
    vec2 rm = rayMarch(ro, rd);
    float d = rm[0];
    float info = rm[1];
    
    float color_bw = 0.;
    vec3 color = vec3(0.);
    if (d < MAX_DIST) {
        vec3 n = getNormal(ro + rd * d);
        n.zy *= Rot(time);
        color = vec3( n + 1.0 );
        color *= info;
        //color_bw += 0.5 + dot(n, normalize(vec3(1,1,0))) / 2.;
    }
    //color = vec3( color_bw );
    
    
    
    glFragColor = vec4(color,1.0);
}
