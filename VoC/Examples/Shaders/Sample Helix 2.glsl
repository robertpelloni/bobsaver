#version 420

// original https://www.shadertoy.com/view/3d3XWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI (acos(-1.))

struct mapdata {
    int id;
    float dist;
};

struct hitpoint {
    bool hit;
    mapdata data;
    vec3 pos;
    vec3 normal;
};

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

mapdata mapMin(mapdata d1, mapdata d2) {
    mapdata result = d1;
    if (d2.dist < d1.dist) {
        result.id = d2.id;
        result.dist = d2.dist;
    }
    return result;
}

mapdata map(vec3 p) {
    mapdata result;
    
    vec3 pp1 = p;
    vec3 pp2 = p;
    
    float r = 0.2;
    float t = PI + 0.5 * time;
    float twist = -0.67 * p.y;
    pp1.x += r * cos(t + twist);
    pp1.z += r * sin(t + twist);
    pp2.x += r * cos(t + PI + twist);
    pp2.z += r * sin(t + PI + twist);
    
    float rep = 0.33;
    pp1.y = mod(p.y, rep)-0.5*rep;
    pp2.y = pp1.y;
    
    // Spheres
    float spr = 0.09;
    float spd1 = sdSphere(pp1, spr);
    float spd2 = sdSphere(pp2, spr);
    result = mapMin(mapdata(1, spd1), mapdata(2, spd2));
    
    // Connecting line
       float cad = sdCapsule(pp1, vec3(0, 0, 0), pp1 - pp2, 0.02);
    result = mapMin(result, mapdata(3, cad));
    
    return result;
}

vec3 lookAt(vec2 uv, vec3 origin, vec3 target, float fov) {
    vec3 zz = normalize(target - origin);
    vec3 xx = normalize(cross(zz, vec3(0,1,0)));
    vec3 yy = normalize(cross(xx, zz));
    return normalize(uv.x * xx + uv.y * yy + fov * zz); 
}

vec3 normal(vec3 pos) {
    vec2 e = vec2(0.0005, 0.);
    return normalize(
        vec3(
            map(pos + e.xyy).dist - map(pos - e.xyy).dist,
            map(pos + e.yxy).dist - map(pos - e.yxy).dist,
            map(pos + e.yyx).dist - map(pos - e.yyx).dist
        )
    );
}

float diffuse(vec3 nor, vec3 lightDir) {
    return clamp( dot(nor, lightDir), 0.0, 1.0);
}

hitpoint raycast(vec3 ro, vec3 rd) {
    hitpoint h;
    
    // Raymarching
    float t = 0.0;
    mapdata m;
    for(int i=0; i<100; i++) {
        mapdata m = map(ro + t * rd);
        float d = m.dist; 
        if (abs(d) < 0.001) {
            h.hit = true;
            h.data = m;
            h.pos = ro + t * rd;
            h.normal = normal(h.pos);
            break;
        }
        t += d;
        if (t > 20.) {
            break;
        }
    }
    return h; 
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    vec3 col = vec3(0.1, 0.1, .6 * (uv.y + 0.5));
    
    // Camera
    float ct = -0.5 * time;
    vec3 ro = vec3(0, ct, 1.);
    vec3 rd = lookAt(uv, ro, vec3(0, -2. + ct, 0), 1.);
    
    // Render
    hitpoint h = raycast(ro, rd);
    if (h.hit) {
        float c = 0.0;
        c += (2. * uv.y + 0.8) * diffuse(h.normal, vec3(1, 1, 2));
        float shadow = 0.8 * diffuse(h.normal, vec3(-1, 0, 0));
        c += pow(shadow, 3.);
        
        vec3 mat = vec3(0);
        if (h.data.id == 1) {
            mat = vec3(0.9, 0.1, 0.1);
        } else if (h.data.id == 2) {
            mat = vec3(0.1, 0.1, 0.9);
        } else if (h.data.id == 3) {
            mat = vec3(0.3, 0.6, 0.3);
        }
        
        col = mat * c;
    }
    
    
    glFragColor = vec4(col,1.0);
}
