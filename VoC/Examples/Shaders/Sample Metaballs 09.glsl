#version 420

uniform vec2  resolution;     // resolution (width, height)
uniform vec2  mouse;          // mouse      (0.0 ~ 1.0)
uniform float time;           // time       (1second == 1.0)
uniform sampler2D backbuffer; // previous scene texture

out vec4 glFragColor;

vec2  uv(){return(gl_FragCoord.xy*2.-resolution)/resolution.y;}
vec4  bb(){return texture2D(backbuffer,gl_FragCoord.xy/resolution);}
vec4  gamna(vec3 c){return vec4(pow(c, vec3(1./2.2)), 1);}
vec3  hsv(float h,float s,float v){return((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;}
float rnd(vec2 c){return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453)*2.-1.;}
float smin(float a, float b, float k){return -log(exp(-k*a)+exp(-k*b))/k;}
mat3  camera(vec3 p, vec3 t, float r){vec3 w=normalize(p-t),u=normalize(cross(w,vec3(cos(r),sin(r),0)));return mat3(u,normalize(cross(u,w)),w);}
mat3  euler(float h, float p, float r){float a=sin(h),b=sin(p),c=sin(r),d=cos(h),e=cos(p),f=cos(r);return mat3(f*e,c*e,-b,f*b*a-c*d,f*d+c*b*a,e*a,c*a+f*b*d,c*b*d-f*a,e*d);}

float map(in vec3 p) {
    float d=0.;
    for(int i=0; i<16; i++) {
        float t = time * (rnd(vec2(i,3))+2.);
        d += exp((length(p-vec3(sin(t*rnd(vec2(i,0))),cos(t*rnd(vec2(i,1))),0))-.2)*-4.);  
    }
    return -log(d)/4.;
}

vec3 normal(in vec3 p){
    vec3 v=vec3(.001,0,map(p));
    return normalize(vec3(map(p+v.xyy)-v.z,map(p+v.yxy)-v.z,map(p+v.yyx)-v.z));
}

vec3 trace(inout vec3 pos, inout vec3 dir) {
    float t = 0.;
    for (int i=0; i<60; i++) {
      float d = map(pos + dir * t);
      t += d;
      if (d < 0.001) break;
      if (t > 10.) return vec3(0);
    }
    vec3 n = normal(pos + dir * t);
    pos += dir*t+n*.01;
    dir = reflect(dir, n);
    return (dot(n,vec3(1,1,.5))*.5+.5)*hsv(time/7.,1.,.8);
}

void main(){
    vec3 dir = normalize(vec3(uv(),-1.732));
    vec3 pos = vec3(cos(time)*3.,sin(time)*3.,3);
    dir = camera(pos, vec3(0), 0.) * dir;
    //pos += dir*rnd(floor(uv()*800.))*0.2;
    glFragColor = gamna(trace(pos, dir));
}
