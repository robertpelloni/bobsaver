#version 420

// original https://www.shadertoy.com/view/Xtj3Dz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14
#define TWO_PI 7.28

const int MAT0 = 0;
const int MAT1 = 1;
const int MAT2 = 2;
const int MAT3 = 3;

float noise(in vec2 uv) {
    return sin(1.5*uv.x)*sin(1.5*uv.y);
}

const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

float fbm(vec2 uv) {
    float f = 0.0;
    f += 0.5000*noise(uv); uv = m*uv*2.02;
    f += 0.2500*noise(uv); uv = m*uv*2.03;
    f += 0.1250*noise(uv); uv = m*uv*2.01;
    f += 0.0625*noise(uv);
    return f/0.9375;
}

float fbm2(in vec2 uv) {
   vec2 p = vec2(fbm(uv + vec2(0.0,0.0)),
                 fbm(uv + vec2(5.2,1.3)));

   return fbm(uv + 4.0*p);
}

float rand(in vec2 uv) {
    return fract(sin(dot(uv.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 add(in vec2 a, in vec2 b) {
 
    int mat = 0;
    if(a.x < b.x) {
      mat = int(a.y);
    } else {
      mat = int(b.y);
    }
    
    return vec2(min(a.x,b.x), mat);
}

vec2 sub(in vec2 a, in vec2 b) {
    
    int mat = 0;
    if(a.x < b.x) {
      mat = int(b.y);
    } else {
      mat = int(a.y);
    }
    
    return vec2(max(a.x, b.x),mat);
}

vec3 rep(in vec3 p, in vec3 c) {
    vec3 q = mod(p,c)-0.5*c;
    return q;
}

vec2 rotate(in vec2 p, in float ang) {
    float c = cos(ang), s = sin(ang);
    return vec2(p.x*c - p.y*s, p.x*s + p.y*c);
}

vec2 torus(in vec3 p, in vec2 t, in int mat) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return vec2(length(q)-t.y, mat);
}

vec2 sphere(in vec3 p, in float r, in int mat) {
    return vec2(length(p) - r, mat);
}

vec2 plane(in vec3 p, in vec4 n, in int mat) {
  return vec2(dot(p,n.xyz) + n.w, mat);
}

vec2 cylinder(in vec3 p, in vec3 c, in int mat) {
  return vec2(length(p.xz-c.xy)-c.z, mat);
}

vec2 box(in vec3 p, in vec3 b, in int mat) {
  return vec2(length(max(abs(p)-b,0.0)), mat);
}

vec2 fractal(in vec3 pos) {
    
    const int iterations = 100;
    const float bailout = 10.0;
          float power = 7.;
    
    vec3 z = pos;
    float dr = 1.5;
    float r = 0.0;
    
    int step = 0;
    
    for (int i = 0; i < iterations ; i++) {
        r = length(z);
           if (r > bailout) break;
        
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        
        dr =  pow( r, power-1.0)*power*dr + 1.0;
        float zr = pow( r,power);
        theta = theta*power;
        phi = phi*power;
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
        step++;
    }
    
    return vec2(0.5*log(r)*r/dr, step);
}

float map(in vec3 p, inout float mat) {
   
   vec2 scene = vec2(999.0, MAT0);

   p *= 1.0 + .25 * cos(time*.25);
    
   vec2 f  = fractal(p);
   
   scene = add(scene, f);
    
   mat = scene.y;
    
   return scene.x;
}

mat3 setLookAt(in vec3 ro, in vec3 ta,in float cr) {
    vec3  cw = normalize(ta-ro);
    vec3  cp = vec3(sin(cr), cos(cr),0.0);
    vec3  cu = normalize( cross(cw,cp) );
    vec3  cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0*uv;
    p.x *= resolution.x / resolution.y;
    
    // camera    
    vec3 ro = vec3(
        -2.5*cos(.25*time),
        cos(.5*time),
        -2.5*sin(.25*time)
       );
    
    vec3 ta = vec3(0.0,0.0,0.0);
    float roll = 0.0;

    // camera tx
    mat3 ca = setLookAt( ro, ta, roll );
    vec3 rd = normalize( ca * vec3(p.xy,1.75) );

    float t = 0.0;      // Near
    float tmax = 120.0; // Far
       
    float h = 0.001;
    float hmax = 0.001;
    
    float mat = 0.0;
    
    vec3 c = vec3(0.0);
    vec3 ao = vec3(0.0);
    
    const int steps = 100;
    for(int i = 0 ; i < steps ; i++) {
        
        if(h < hmax || t > tmax ) {
            ao = vec3(1.0) - float(i)/float(steps);
            break;
        }
        
        h = map(ro + t *rd, mat);
        t += h;
    }
    
    if(t < tmax) {
        vec3 pos = ro+rd*t;
        
        vec2 r = vec2(0.00001,0.0);
        vec3 nor = normalize(vec3(map(pos+r.xyy, mat)-map(pos-r.xyy, mat),
                                  map(pos+r.yxy, mat)-map(pos-r.yxy, mat),
                                  map(pos+r.yyx, mat)-map(pos-r.yyx, mat)));
          
        c = vec3(1.0,0.4,0.1);
        
        c -= ao*.25;
        
        c = c*pow(c.x,2.0);
        
        vec3 lat = vec3(0.5773);
        //c *= 1. - pow(clamp(dot(nor,lat), 0.4, .6),2.0);
        
    } else {
        c = vec3(0.0);
    }
    
    glFragColor = vec4(c,1.0);
}
