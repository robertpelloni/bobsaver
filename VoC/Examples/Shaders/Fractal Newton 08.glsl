#version 420

// original https://www.shadertoy.com/view/MdsBzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Complex Number math by julesb
// https://github.com/julesb/glsl-util

#define PI 3.14159265

#define cx_mul(a, b) vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x)
#define cx_div(a, b) vec2(((a.x*b.x+a.y*b.y)/(b.x*b.x+b.y*b.y)),((a.y*b.x-a.x*b.y)/(b.x*b.x+b.y*b.y)))
#define cx_modulus(a) length(a)
#define cx_conj(a) vec2(a.x,-a.y)
#define cx_arg(a) atan2(a.y,a.x)
#define cx_sin(a) vec2(sin(a.x) * cosh(a.y), cos(a.x) * sinh(a.y))
#define cx_cos(a) vec2(cos(a.x) * cosh(a.y), -sin(a.x) * sinh(a.y))

vec2 cx_sqrt(vec2 a) {
    float r = length(a);
    float rpart = sqrt(0.5*(r+a.x));
    float ipart = sqrt(0.5*(r-a.x));
    if (a.y < 0.0) ipart = -ipart;
    return vec2(rpart,ipart);
}

vec2 cx_tan(vec2 a) {return cx_div(cx_sin(a), cx_cos(a)); }

vec2 cx_log(vec2 a) {
    float rpart = length(a);
    float ipart = atan(a.y, a.x);
    if (ipart > PI) ipart=ipart-(2.0*PI);
    return vec2(log(rpart),ipart);
}

vec2 cx_mobius(vec2 a) {
    vec2 c1 = a - vec2(1.0,0.0);
    vec2 c2 = a + vec2(1.0,0.0);
    return cx_div(c1, c2);
}

vec2 cx_z_plus_one_over_z(vec2 a) {
    return a + cx_div(vec2(1.0,0.0), a);
}

vec2 cx_z_squared_plus_c(vec2 z, vec2 c) {
    return cx_mul(z, z) + c;
}

vec2 cx_sin_of_one_over_z(vec2 z) {
    return cx_sin(cx_div(vec2(1.0,0.0), z));
}

////////////////////////////////////////////////////////////
// end Complex Number math by julesb
////////////////////////////////////////////////////////////

// From Stackoveflow
// http://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// My own additions to complex number math
#define cx_sub(a, b) vec2(a.x - b.x, a.y - b.y)
#define cx_add(a, b) vec2(a.x + b.x, a.y + b.y)
#define cx_abs(a) length(a)
vec2 cx_to_polar(vec2 a) {
    float phi = atan(a.y / a.x);
    float r = length(a);
    return vec2(r, phi); 
}
    
// Complex power
// Let z = r(cos θ + i sin θ)
// Then z^n = r^n (cos nθ + i sin nθ)
vec2 cx_pow(vec2 a, float n) {
    float angle = atan(a.y, a.x);
    float r = length(a);
    float real = pow(r, n) * cos(n*angle);
    float im = pow(r, n) * sin(n*angle);
    return vec2(real, im);
}
   
mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

// End utils, here comes the actual fractal

// z^6 + z^3 - 1 
vec2 f(vec2 z) {
    return cx_add(cx_add(cx_pow(z, 6.0), cx_pow(z, 3.0)), vec2(-1.0, 0.0));
} 

// f(z) derivated
// 6*z^5 + 3*z^2
vec2 fPrim(vec2 z) {
    vec2 six = vec2(6.0, 0.0);
    vec2 a = cx_mul(six, cx_pow(z, 5.0));
    
    vec2 three = vec2(3.0, 0.0);
    vec2 b = cx_mul(three, cx_pow(z, 2.0));
    return cx_add(a, b);
}

const int maxIterations = 90;
vec2 one = vec2(1, 0);
vec3 newtonRapson(vec2 z) {
  vec2 oldZ = z;
  float s = 0.0;
  for(int i = 0; i < maxIterations; i++){
    z = cx_sub(z, cx_div(f(z), fPrim(z))); 
    if(abs(oldZ.x - z.x) < 0.0001 && abs(oldZ.y - z.y) < 0.0001) {
      break;
    }
    
    vec2 w = cx_div(one, cx_sub(oldZ, z));
    float wAbs = cx_abs(w);
    
    s += exp(-wAbs);
    oldZ = z;
  }
  return vec3(s, cx_to_polar(z));
}

void main(void)
{
    float zoom = (sin(time/3.0)*0.5+0.5)*3.0 + 1.0;
    vec2 centered = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.xy * zoom;
    vec2 rotated = centered * rotate(time/2.0);
    vec3 result = newtonRapson(rotated);
    float c = 1.0-result.x/float(maxIterations)*7.0;    
    vec3 color = hsv2rgb(vec3(result.z*3.0 + time/15.0, 1.0, c));    
    glFragColor = vec4(color, 1.0);
}

