#version 420

// original https://www.shadertoy.com/view/wlKSDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 * 01 Mar 2020
 * Just want to make something from scratch again. I think building on the things
 * that I have built before may not be the best approach for every single model,
 * because it doesn't always allow me to get the practice in, and I stick to doing
 * things the same way every time, and don't have an oppurtunity to improve the base
 * framework... ‾\_(ツ)_/‾
 * As far as possible, apart from the sdf functions, I want to rewrit the whole thing
 * from scratch, just to see where the whole thing can be simpler.
*/

#define RAYMARCH_STEPS 100
#define MAX_RAYMARCH_DISTANCE 15.0
#define RAYMARCH_SURFACE_DISTANCE 0.01
#define PI 3.14159
vec3 rotate3D(vec3 point, vec3 rotation) {
    vec3 r = rotation;
    mat3 rz = mat3(cos(r.z), -sin(r.z), 0,
                   sin(r.z),  cos(r.z), 0,
                   0,         0,        1);
    mat3 ry = mat3( cos(r.y), 0, sin(r.y),
                    0       , 1, 0       ,
                   -sin(r.y), 0, cos(r.y));
    mat3 rx = mat3(1, 0       , 0        ,
                   0, cos(r.x), -sin(r.x),
                   0, sin(r.x),  cos(r.x));
    return rx * ry * rz * point;
}
float sdfSphere(vec3 position, vec3 center, float radius) {
    return distance(position, center) - radius;
}
float sdfEllipsoid(vec3 position, vec3 center, vec3 radii) {
    position -= center;
    float k0 = length(position/radii);
    float k1 = length(position/(radii*radii));
    return k0*(k0-1.0)/k1;
}
float sdfEllipsoidRotated(vec3 position, vec3 center, vec3 radii, vec3 rotation) {
    position -= center;
    position = rotate3D(position, rotation);
    float k0 = length(position/radii);
    float k1 = length(position/(radii*radii));
    return k0*(k0-1.0)/k1;
}
float sdfPlane( vec3 position, vec4 n ) {
    return dot(position, normalize(n.xyz)) + n.w;
}
float sdfRoundBoxRotated(vec3 position, vec3 center, vec3 box, vec3 rotation, float radius) {
    position -= center;
    position = rotate3D(position, rotation);
    vec3 q = abs(position) - box;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - radius;
}
float dot2(vec2 v) {
    return dot(v, v);
}
vec4 sdfJoint3DSphere(vec3 position, vec3 start, vec3 rotation, float len, float angle, float thickness) {
    vec3 p = position;
    float l = len;
    float a = angle;
    float w = thickness;
    p -= start;
    p = rotate3D(p, rotation);

    if( abs(a)<0.001 ) {
        return vec4( length(p-vec3(0,clamp(p.y,0.0,l),0))-w, p );
    }

    vec2  sc = vec2(sin(a),cos(a));
    float ra = 0.5*l/a;
    p.x -= ra;
    vec2 q = p.xy - 2.0*sc*max(0.0,dot(sc,p.xy));
    float u = abs(ra)-length(q);
    float d2 = (q.y<0.0) ? dot2( q+vec2(ra,0.0) ) : u*u;
    float s = sign(a);
    return vec4( sqrt(d2+p.z*p.z)-w,
               (p.y>0.0) ? s*u : s*sign(-p.x)*(q.x+ra),
               (p.y>0.0) ? atan(s*p.y,-s*p.x)*ra : (s*p.x<0.0)?p.y:l-p.y,
               p.z );
}
float sdfCappedCone( vec3 p, vec3 origin, vec3 scale, float h, float r1, float r2, float radius )
{
    p*=scale;
    p -= origin;
    vec2 q = vec2( length(p.xz), p.y );
    vec2 k1 = vec2(r2,h);
    vec2 k2 = vec2(r2-r1,2.0*h);
    vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
    vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
    float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
    return s*sqrt( min(dot2(ca),dot2(cb)) ) - radius;
}
float smin(float d1, float d2, float k) {
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}
float smax(float d1, float d2, float k) {
    float h = max(k-abs(d1-d2),0.0);
    return max(d1, d2) + h*h*0.25/k;
}
vec2 distanceField(vec3 pos) {
    //pos = rotate3D(pos, vec3(0.0, 0.0, -0.2));
    float material = 1.0;
    float d, d1, d2;
    vec3 t1, symx;
    d = MAX_RAYMARCH_DISTANCE;
    // base head
    d1 = sdfCappedCone(pos, vec3(0.0, -0.0, 0.0), vec3(1.0, 1.0, 1.0), 1.0, 0.5, 0.3, 0.9);
    d = smin(d, d1, 0.001);
    d1 = sdfSphere(pos, vec3(0.0, 0.5, 0.4), 1.6);
    d = smin(d, d1, 0.4);

    // eyesockets
    d1 = sdfRoundBoxRotated(pos, vec3(0.0, 0.6, -1.2), vec3(2.0, 0.0, 0.0), vec3(0.0, 0.0, 0.12), 0.4);
    d2 = sdfRoundBoxRotated(pos, vec3(0.0, 1.2, -1.2), vec3(2.5, 0.4, 0.4), vec3(-0.4, 0.0, 0.18), 0.1);
    d1 = smax(d1, -d2, 0.1);
    d = smax(d, -d1, 0.2);

    // cheekbones
    symx = vec3(abs(pos.x), pos.yz);
    d1 = sdfSphere(symx, vec3(0.8, -0.25, -0.8), 0.3);
    d = smin(d, d1, 0.4);

    // chin
    d1 = sdfRoundBoxRotated(pos, vec3(0.0, -1.4, -1.05), vec3(0.4, 0.2, 0.2), vec3(0.3, 0.0, 0.0), 0.04);
    d = smin(d, d1, 0.5);

    // jaw
    symx = vec3(abs(pos.x), pos.yz);
    d1 = sdfRoundBoxRotated(symx, vec3(0.8, -1.0, -0.4), vec3(0.3, 0.2, 0.6), vec3(-0.3, 0.8, 0.3), 0.01);
    d = smin(d, d1, 0.5);

    // nose
    t1 = pos-vec3(0.0, 0.4, -1.0);
    t1 = rotate3D(t1, vec3(0.4, 0.0, 0.0));
    symx = vec3(abs(t1.x), t1.yz);
    d1 = sdfRoundBoxRotated(t1, vec3(0.0), vec3(0.1, 0.4, 0.2), vec3(-0.2, 0.0, 0.0), 0.05);
    d2 = sdfRoundBoxRotated(t1, vec3(0.0, -0.4, 0.0), vec3(0.06, 0.4, 0.2), vec3(0.2, 0.0, 0.0), 0.05);
    d1 = smin(d1, d2, 0.1);
    d2 = sdfSphere(t1, vec3(0.0, -0.72, -0.23), 0.1);
    d1 = smin(d1, d2, 0.2);
    d2 = sdfSphere(t1, vec3(0.22, -0.64, -0.2), 0.12);
    d1 = smin(d1, d2, 0.2);
    d2 = sdfSphere(t1, vec3(-0.23, -0.66, -0.2), 0.13);
    d1 = smin(d1, d2, 0.2);
    d = smin(d, d1, 0.2);

    //eyes
    d1 = sdfSphere(pos, vec3(0.44, 0.5, -0.8), 0.35);
    if (d1<d)
        material = 2.0;
    d = smin(d, d1, 0.02);
    d1 = sdfSphere(pos, vec3(-0.44, 0.5, -0.8), 0.35);
    if (d1<d)
        material = 2.0;
    d = smin(d, d1, 0.02);
    d1 = sdfSphere(pos, vec3(0.48, 0.49, -1.0), 0.20);
    if (d1<d)
        material = 3.0;
    d = smin(d, d1, 0.02);
    d1 = sdfSphere(pos, vec3(-0.42, 0.46, -1.0), 0.19);
    if (d1<d)
        material = 3.0;
    d = smin(d, d1, 0.02);

    // mouth
    d1 = sdfSphere(pos, vec3(-0.48, -0.82, -1.4), 0.12);
    d = smax(d, -d1, 0.23);
    d1 = sdfSphere(pos, vec3(0.48, -0.82, -1.4), 0.12);
    d = smax(d, -d1, 0.23);
    t1 = rotate3D(pos, vec3(0.3, 0.0, -0.1));
    d1 = sdfCappedCone(t1, vec3(0.1, -0.95, -0.84), vec3(1.0, 1.0, 1.0), 0.2, 0.5, 0.3, 0.0);
    d = smin(d, d1, 0.12);
    t1 = rotate3D(pos, vec3(0.27, 0.0, -0.14));
    d1 = sdfCappedCone(t1, vec3(0.1, -1.35, -0.84), vec3(1.0, 1.0, 1.0), 0.1, 0.3, 0.5, 0.0);
    d = smin(d, d1, 0.23);

    // neck
    d1 = sdfCappedCone(pos, vec3(0.0, -1.5, 0.4), vec3(1.0, 1.0, 1.0), 0.9, 1.3, 1.1, 0.1);
    d = smin(d, d1, 0.05);

    // ears
    symx = vec3(abs(pos.x), pos.yz);
    symx = rotate3D(symx, vec3(0.0, 0.0, -0.1));
    symx.y /= 1.2;
    t1 = symx - vec3(1.5, 0.13, 0.0);
    d1 = sdfSphere(t1, vec3(0.0), 0.5);
    d2 = sdfRoundBoxRotated(t1, vec3(0.0), vec3(0.1, 2.0, 2.0), vec3(0.0, 0.9, 0.0), 0.0);
    d1 = smax(d2, d1, 0.05);
    d2 = sdfSphere(t1, vec3(0.25, 0.1, 0.0), 0.1);
    d1 = smax(-d2, d1, 0.3);
    d2 = sdfSphere(t1, vec3(0.21, -0.1, -0.01), 0.1);
    d1 = smax(-d2, d1, 0.1);
    d = smin(d, d1, 0.05);

    // warpaint
    symx = vec3(abs(pos.x), pos.yz);
    d1 = sdfRoundBoxRotated(symx, vec3(0.74, 0.1, -1.0), vec3(0.25, 0.04, 1.0), vec3(0.0, 0.0, 0.2), 0.1);
    if (d1<d)
        material = 4.0;

    return vec2(d, material);
}

vec2 raymarch(vec3 point, vec3 direction) {
    // return type: vec2(distance, material);
    float dist = 0.0;
    vec2 d;
    for (int i=0; i<RAYMARCH_STEPS; i++) {
        d = distanceField(point);
        dist += d.x;
        point += d.x * direction;
        if (d.x < RAYMARCH_SURFACE_DISTANCE)
            return vec2(dist, d.y);
        if (dist > MAX_RAYMARCH_DISTANCE)
            return vec2(dist, 0.0);
    }
    return vec2(dist, 0.0);
}

vec3 calculate_normal(vec3 pos) {
    vec3 h = vec3(0.001, 0.0, 0.0);
    float d = distanceField(pos).x;
    return normalize(vec3(
                d-distanceField(pos+h.xyy).x,
                d-distanceField(pos+h.yxy).x,
                d-distanceField(pos+h.yyx).x
    ));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.xy)*2.0 - vec2(1.0);
    uv.y *= resolution.y / resolution.x;
    vec3 point = vec3(uv, -5.0);
    vec3 camera = vec3(0.0, 0.0, -6.0);
    float mouseX = ((-mouse.x*resolution.xy.x/resolution.x)+0.5)*PI/1.5;
    mouseX = 0.3 + 0.3*sin(time/2.0);

    point = rotate3D(point, vec3(0.0, mouseX, 0.0));
    camera = rotate3D(camera, vec3(0.0, mouseX, 0.0));
    vec3 light_position = vec3(1.0, 1.0, -3.0);
    vec3 ray_direction = normalize(point-camera);
    vec2 obj = raymarch(point, ray_direction);
    float dist = obj.x;
    float material = obj.y;
    vec3 color = vec3(0.01);
    if (dist < MAX_RAYMARCH_DISTANCE) {
        vec3 surface_point = point + ray_direction*dist;
        vec3 normal = calculate_normal(surface_point);
        float light = dot(normal, normalize(surface_point-light_position));
        light = max(0.0, light);
        if (material < 1.5) {
            color = vec3(0.38, 0.22, 0.15);
            color += vec3(0.18) * smoothstep(0.1, 1.0, light);
            color += vec3(0.05) * smoothstep(0.3, 1.0, light);
        } else if (material < 2.5) {
            color = vec3(0.25, 0.28, 0.34);
            color += vec3(0.33) * smoothstep(0.1, 1.0, light);
        } else if (material < 3.5) {
            color = vec3(0.03, 0.025, 0.02);
            color += vec3(0.2) * smoothstep(0.9, 1.0, light);
        } else if (material < 4.5) {
            color = vec3(0.002, 0.002, 0.002);
            color += vec3(0.1) * smoothstep(0.1, 1.0, light);
        }
    }
    color = pow( color, vec3(1.0/2.2) );
    glFragColor = vec4(color, 1.0);
}
