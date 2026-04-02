#version 420

// original https://www.shadertoy.com/view/dsfGRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001
#define TAU 6.283185
#define PI 3.141592
#define S smoothstep
#define T time*TAU*0.1

vec4 make_quat(vec3 axis, float angle){
    float theta = angle*0.5;
    return vec4(sin(theta)*normalize(axis), cos(theta));

}

vec3 qtransform( vec4 q, vec3 v ){ 
    return v + 2.0*cross(cross(v, q.xyz ) + q.w*v, q.xyz);
    } 
    
    
vec3 qtransform(vec3 axis, float angle, vec3 v){
    return qtransform(make_quat(axis, angle), v);
}
mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float fractal(vec3 p, float scale, inout vec3 orbit){
   float r=dot(p, p);
   int i;
   float x1, y1, z1;
   float s = scale;
   orbit.b = length(p);
   orbit.g = 0.;
   for(i=0;i<10 && r < MAX_DIST;i++){
      //Folding... These are some of the symmetry planes of the tetrahedron
      //p = qtransform(vec3(2, 0, 1), T*0.5, p);
      p = abs(p);
      s *= scale;
      orbit.b = min(length(p), orbit.b);
      orbit.g = max(length(p)/s, orbit.g);
      if(p.x-p.y<0.){p.xy = p.yx; }
      if(p.x-p.z<0.){p.xz = p.zx; }
      if(p.y-p.z<0.){p.yz = p.zy; }

      
      //Stretche about the point [1,1,1]*(scale-1)/scale; The "(scale-1)/scale" is here in order to keep the size of the fractal constant wrt scale
      //equivalent to: x=scale*(x-cx); where cx=(scale-1)/scale;
      vec3 shift = (vec3(-0.5, 0, -0.5));
      //p = qtransform(vec3(1, 0, 1), T, p);
      vec3 stretch = normalize(vec3(1, 1., 1.))*0.5;
      
      p = scale*p - stretch*(scale-shift);
      //p = qtransform(vec3(3, -1, 2), -0.1*PI, p);
      p = qtransform(vec3(cos(T+0.101), 1, sin(T+0.101)), -T, p);
      orbit.b *= 1.;
      r=dot(p, p);
   }
   return (sqrt(r)-2.)*pow(scale, -float(i));//the estimated distance
}

float GetDist(vec3 p, inout vec3 orbit) {
    
    vec3 v = vec3(1, 1., 1);
    
    
    float scale = 2.;
    
    float d = fractal(p, scale, orbit);
    
    return d;
}

float GetDist(vec3 p){
    vec3 fake;
    return GetDist(p, fake);

}

float RayMarch(vec3 ro, vec3 rd, inout int i, inout float mindist, inout vec3 orbit) {
    float dO=0.;
    mindist = length(ro);
    //orbit += mindist;
    for(i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p, orbit);
        
        if(dS < mindist) mindist = dS;
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    orbit = sin(orbit*TAU+T)*0.5+0.5;
    return dO;
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(.001, 0);
    vec3 n = GetDist(p) - 
        vec3(GetDist(p-e.xyy), GetDist(p-e.yxy),GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 
        f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u;
    return normalize(i);
}

vec3 quad_bezier(vec3 a, vec3 b, vec3 c, vec3 t){
    return mix(mix(a, b, t), mix(a, b, t), t);

}

vec3 BG(vec3 rd){
    vec3 a = vec3(0.1, 0.3, 0.7);
    vec3 b = vec3(0.1, 0.6, 0.3);
    return mix(a, b, dot(rd, vec3(0, cos(T), sin(T))) * 0.5 + 0.5);

}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = (mouse*resolution.xy.xy)/resolution.xy;
    //m *= 0.;

    vec3 ro = vec3(3.*cos(T), 3.*sin(T), 3.*sin(T));
    //ro.yz *= Rot(-m.y*PI);
    //ro.xz *= Rot(-m.x*TAU);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 5.);
    vec3 col = vec3(0);
    int i = 0;
    float mindist;
    vec3 orbit_trap = vec3(0.);;
    float d = RayMarch(ro, rd, i, mindist, orbit_trap);
    float iter = float(i)/float(MAX_STEPS);
    vec3 a = vec3(0.5, 0.1, 0.5);
    vec3 b = vec3(0.1, 0.1, 0.1);
    vec3 c = vec3(0.1, 0.7, 0.1);
    mat3 palette = transpose(mat3(a, b, c));
    col += BG(rd);
    col *= S(SURF_DIST*1., SURF_DIST*15., mindist);
    orbit_trap = smoothstep(0.6, 0.9, orbit_trap);
    orbit_trap.r = 1. - mod(exp((iter)), 1.);
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);

        float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
        col = vec3(1)*pow(1.-iter, 5.)*(palette*orbit_trap);
    }
    col = pow(col, vec3(.4545));    // gamma correction
    
    glFragColor = vec4(col,1.0);
}
