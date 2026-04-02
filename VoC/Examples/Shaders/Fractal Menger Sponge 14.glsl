#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tttSzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 dmin(vec4 x, float y, vec3 n) {
    if(x.w < 0.0) return vec4(n,y);
    else if(y < 0.0) return x;
    return x.w < y ? x : vec4(n,y);
}
float square(vec3 p, vec3 v) {
    if(p.z < 0.0 || v.z > 0.0) return -1.0;
    float t = - p.z / v.z;
    vec3 c = p + v * t;
    if(abs(c.x) < 1.0 && abs(c.y) < 1.0) return t;
    else return -1.0;
}
vec4 cube(vec3 p, vec3 v, float flip) {
    vec4 dist = vec4(-1);
    vec3 u = vec3(0,0,1) * flip;
    dist = dmin(dist, square(p.xyz-u,v.xyz), vec3(0,0,1));
    dist = dmin(dist, square(p.zxy-u,v.zxy), vec3(0,1,0));
    dist = dmin(dist, square(p.yzx-u,v.yzx), vec3(1,0,0));
    dist = dmin(dist, square(-p.xyz-u,-v.xyz), vec3(0,0,-1));
    dist = dmin(dist, square(-p.zxy-u,-v.zxy), vec3(0,-1,0));
    dist = dmin(dist, square(-p.yzx-u,-v.yzx), vec3(-1,0,0));
    return dist;
}

vec3 scene(vec3 p, vec3 v) {
    vec3 empty = vec3(0.1);
    vec4 t;
    int count = 0;
    ivec3 l = ivec3(0);
    bool hole = false;
    if(abs(p.x) < 1. && abs(p.y) < 1. && abs(p.z) < 1.) {
        for(int i=0;i<18;i++) {
            vec3 c = p;
            ivec3 e = clamp(ivec3(c * 3. / 2. + 1.5), 0, 2);
            l = l * 3 + e;
            vec3 o = vec3(e - 1) * 2.0 / 3.0;
            p = (p - o) * 3.0;
            count++;
            ivec3 u = e;
            hole = false;
            if(u.x == 1 && u.y == 1) hole = true;
            if(u.y == 1 && u.z == 1) hole = true;
            if(u.z == 1 && u.x == 1) hole = true;
            if(hole) break;
        }
    }
    for(int i=0;i<18;i++) {
        if(!hole) {
            t = cube(p,v,1.);
            if(t.w < 0.) return empty;
            vec3 c = p + v * t.w;
            ivec3 e = clamp(ivec3(c * 3. / 2. + 1.5), ivec3(0), ivec3(2));
            l = l * 3 + e;
            vec3 o = vec3(e - 1) * 2.0 / 3.0;
            p = (p - o) * 3.0;
            count++;
        } else {
            t = cube(p,v,-1.);
            if(t.w < 0.) return empty;
            for(int j=0;j<10;j++) {
                ivec3 e = (l%3+3)%3;
                bool up = false;
                if(t.x < -0.5 && e.x == 2) up = true;
                if(t.y < -0.5 && e.y == 2) up = true;
                if(t.z < -0.5 && e.z == 2) up = true;
                if(t.x > 0.5 && e.x == 0) up = true;
                if(t.y > 0.5 && e.y == 0) up = true;
                if(t.z > 0.5 && e.z == 0) up = true;
                if(up) {
                    vec3 o = vec3(e - 1) * 2.0 / 3.0;
                    p = p / 3.0 + o;
                    l /= 3;
                    count--;
                    if(count == 0) return empty;
                } else break;
            }
            l -= ivec3(t.xyz);
            p += t.xyz * 2.;
        }
        ivec3 u = l%3;
        hole = false;
        if(u.x == 1 && u.y == 1) hole = true;
        if(u.y == 1 && u.z == 1) hole = true;
        if(u.z == 1 && u.x == 1) hole = true;
        if(count >= 7) break;
    }
    vec3 wp = (p+v*t.w) / pow(3.,7.); // what
    vec3 lv = normalize(vec3(-1,2,-0.5));
    return (wp*0.3+0.7) * (normalize(t.xyz)*0.3+0.7) * (dot(t.xyz,lv)*0.5+0.5);
}

vec3 image(vec2 uv) {
    vec3 dir = normalize(vec3(uv*0.7,-1));
    float vignetting = pow(mix(-dir.z,1.,0.5),10.0)*3.0;
    float gt = time/2.;
    
    // Uniform Catmull-Rom spline
    vec3 p0 = vec3(0,5,2);
    vec3 p1 = vec3(0,0,1);
    vec3 p2 = vec3(0,1./3.,-2./3.);
    vec3 p3 = vec3(0,8./9.,-5./9.);
    float t = fract(gt);
    float a = 0.0;
    float t0 = 0.;
    float t1 = pow(distance(p0,p1),a) + t0;
    float t2 = pow(distance(p1,p2),a) + t1;
    float t3 = pow(distance(p2,p3),a) + t2;
    float tt = mix(t1,t2,t);
    vec3 a1 = ((t1-tt)*p0 + (tt-t0)*p1) / (t1-t0);
    vec3 a2 = ((t2-tt)*p1 + (tt-t1)*p2) / (t2-t1);
    vec3 a3 = ((t3-tt)*p2 + (tt-t2)*p3) / (t3-t2);
    vec3 b1 = ((t2-tt)*a1 + (tt-t0)*a2) / (t2-t0);
    vec3 b2 = ((t3-tt)*a2 + (tt-t1)*a3) / (t3-t1);
    vec3 c  = ((t2-tt)*b1 + (tt-t1)*b2) / (t2-t1);
    vec3 eye = c;
    float r = t*3.1415926535/2. - 0.1;
    dir.yz *= mat2(cos(r),-sin(r),sin(r),cos(r));
   
    float m = floor(gt)*3.1415926535/2.;
    eye.yz *= mat2(cos(m),-sin(m),sin(m),cos(m));
    dir.yz *= mat2(cos(m),-sin(m),sin(m),cos(m));
    return scene(eye,dir) * vignetting;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.)/resolution.y*2.;
    vec3 col = vec3(0);
    for(int i=0;i<2;i++) {
        for(int j=0;j<2;j++) {
            col += image(uv + vec2(i,j)/resolution.y/2.) / 4.;
        }
    }
    glFragColor = vec4(col,1.0);
}
