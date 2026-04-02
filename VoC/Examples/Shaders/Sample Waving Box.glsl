#version 420

// original https://neort.io/art/bq18bdk3p9fefb926fog

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define MAX_STEP 100
#define MAX_DIST 100.0
#define SURFACE_DIST 0.01

float smoothMax(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0. , 1.);
  return max(b,a)-k*k*(1.0-h);
}

mat2 Rotate(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

float dBox(vec3 p, vec3 size) {
  float d = length(max(abs(p)-size, 0.0));
  return d;
}

float GetDist(vec3 p) {
  float dP = p.y; // plane distance
  float bd = dBox(p-vec3(0, 1, 0), vec3(1));

  p *= 20. * sin(time * .5);

  float gyroid = dot(sin(p), cos(p.zxy))/10.0;

  // float d = max(bd, gyroid);
  float d = smoothMax(bd, gyroid, 0.5);
  return d;
}

float RayMarch(vec3 ro, vec3 rd) {
  float dO = 0.0; // start origin
  for(int i=0; i<MAX_STEP; i++) {
    vec3 p = ro+dO*rd; // current march position
    float dS = GetDist(p);
    dO += dS;
    if(dS<SURFACE_DIST || dO>MAX_DIST) break;
  }
  return dO;
}

vec3 GetNormal(vec3 p) {
  float d = GetDist(p);
  vec2 e = vec2(0.001, 0);
  vec3 n = d -vec3(
    GetDist(p-e.xyy),
    GetDist(p-e.yxy),
    GetDist(p-e.yyx)
  );
  return normalize(n);
}

float GetLight(vec3 p) {
  vec3 lightPos = vec3(3, 5, 4);
  vec3 l = normalize(lightPos -p);
  vec3 n = GetNormal(p);

  float diff = clamp(dot(n, l)*.5+.5, 0., 1.);
  float d = RayMarch(p+n*SURFACE_DIST*2., l);
  return diff;

}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main() {

    //vec2 uv = (2.0*gl_FragCoord.xy-u_resolution)/min(u_resolution.x, u_resolution.y);
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0.0);

    uv *= .35;

    // camera
    vec3 ro = vec3(0, 4, -5);
    ro.yz *= Rotate(-mouse.y*3.14+1.);
    ro.xz *= Rotate(-mouse.x*6.2831);
    // ray direction
    // vec3 rd = normalize(vec3(uv.x, uv.y-.2, 1));
    vec3 rd = R(uv, ro, vec3(0,1,0), 1.);

    float d = RayMarch(ro, rd);
    vec3 p = ro + rd * d;
    float diff = GetLight(p);

    col = vec3(diff);

    glFragColor = vec4(col, 1.0);
}
