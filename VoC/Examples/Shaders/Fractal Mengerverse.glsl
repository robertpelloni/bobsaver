#version 420

// original https://www.shadertoy.com/view/M3lyRH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265358979323846264;
const int MAX_PRIMARY_RAY_STEPS = 256; //decrease this number if it runs slow on your computer
const float L2 = 0.69314718056;
float iters = 0.0;
float last_distance = 0.0;

// cream and dark red tho

vec2 rot(vec2 X, float a)
{
     float s = sin(a); float c = cos(a);
    return mat2(c, -s, s, c)*X;
}

float hash2D(vec2 uv)
{
     vec2 suv = sin(uv);
    suv = rot(suv, uv.x);
    return fract(mix(suv.x*13.13032942, suv.y*12.01293203924, dot(uv, suv)));
}

float repeat(float x, float t) {
    return mod(x, t) - t/2.; 
}
float repeat_even(float x, float t) {
    return t*(fract(x/2. + 0.5) - 0.5); 
}
vec2 kaleidoscope(vec2 p, float r) {
    // cart2pol
    //repeat x
    // pol2cart
    return vec2(0.0);
}

float maxcomp(vec2 a) {
    return max(a.x, a.y);
}

mat2 rotmat(float angle) {
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);

    return mat2(
        cosAngle, -sinAngle,
        sinAngle,  cosAngle
    );
}

vec3 my_stereo_inv(vec2 p)
{
    float den = dot(p,p)+1.0;
    return vec3(
        2.0*p.x / den,
        2.0*p.y / den,
        (den-2.0)/den
    );
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float sdCross( in vec3 p )
{
  float da = maxcomp(abs(p.xy));
  float db = maxcomp(abs(p.yz));
  float dc = maxcomp(abs(p.zx));
  return min(da,min(db,dc))-1.0;
}

float distanceField(vec3 p) {
    //p = mod(p, 3.0) - 1.5;
    //p.xy *= rotmat(time);
   p.xy = rot(p.xy, p.z);
   p.z = repeat_even(p.z, 1.5);
   p.x = repeat_even(p.x, 1.5);
   p.y = repeat_even(p.y, 1.5);
   
   float d = sdBox(p,vec3(1.0));

   float s = 1.0;
   for( int m=0; m<4; m++ )
   {
      vec3 a = mod( p*s, 2.0 )-1.0;
      s *= 3.0;
      vec3 r = 1.0 - 3.0*abs(a);

      float c = sdCross(r)/s;
      d = max(d,c);
   }

   return d;
}
float dfc(vec3 p) {
    return max(distanceField(p), 0.);
}

float get_ao(vec3 p, vec3 n) {
    float thing = -dfc(p+0.05*n)
        -dfc(p+0.05*n)*3.0 
        -dfc(p+0.1*n)*4.0
        -dfc(p+0.15*n)*3.0
        -dfc(p+0.2*n)*2.0
        -dfc(p+0.25*n)*1.0
        -dfc(p+0.4*n)*1.0
        -dfc(p+0.8*n)*2.0
        ;
    return 1.0 - exp(thing / 2.0);
}
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.00001, 0.0);
    float rd = distanceField(p);
    return normalize(vec3(
        rd - distanceField(p - e.xyy),
        rd - distanceField(p - e.yxy),
        rd - distanceField(p - e.yyx)
    ));
}

vec3 calcNormala(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        distanceField(p + e.xyy) - distanceField(p - e.xyy),
        distanceField(p + e.yxy) - distanceField(p - e.yxy),
        distanceField(p + e.yyx) - distanceField(p - e.yyx)
    ));
}

vec3 castRay(vec3 pos, vec3 dir, float threshold) {
    for (int i = 0; i < MAX_PRIMARY_RAY_STEPS; i++) {
            float dist = distanceField(pos);
            if (abs(dist) < threshold) break;
            last_distance = dist;
            pos += dist * dir * 1.0;
            iters = float(i);
    }
    return pos;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y;
    vec2 wh = vec2(320.0, 180.0)/2.;
    //uv = floor(uv*wh)/wh;
    float angle = time * 0.25;
    float radius = 0.0;
    vec4 v = vec4(cos(time), 0.0, sin(time), 1.0);
    vec3 ro = radius*v.yyy;
    ro -= vec3(0.0, 0.0, 0.25*time);
    uv = uv * rotmat(-time * 0.2);
    vec3 rd = normalize(my_stereo_inv(uv));
    vec3 rayPos = castRay(ro, rd, 0.0001);
    //float ao = 1.0 - (iters / 64.0);
    float itersf = iters; // would love to know how to use last distance to smooth this out
    //exp(-0.02725*(itersf));
    //float ao = 1.0 - (itersf/40.0);
    //ao = 1.0;
    // yea the ao is cooked oh i should dither it
    // should dither iters
    vec3 normal = calcNormal(rayPos);
    float ao = get_ao(rayPos, normal);
    vec3 sun_dir = normalize(vec3(0.1, 0.8, 0.6));
    float d = (max(dot(sun_dir, normal), 0.0)+0.5)/1.5;
    //d *= ao;
    //d = pow(d, 0.99);
    d *= ao;
    vec3 col = mix(vec3(0.3, 0.0, 0.0), vec3(0.7, 0.6, 0.5), d*3.0);
    glFragColor = vec4(col, 1.0);
}
