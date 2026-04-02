#version 420

// original https://neort.io/art/c54lcqs3p9fe3sqpjtb0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define MAX_STEP 100
#define MAX_DIST 100.0
#define SURFACE_DIST 0.01

#define S(a, b, t) smoothstep(a, b, t)

#define PI 3.14159265359
#define HALF_PI 1.57079632675
#define TWO_PI 6.283185307

vec3 palette(float t,vec3 a,vec3 b,vec3 c,vec3 d )
{
    return a + b * cos( TWO_PI * (c*t+d));
}

vec3 colorize(float d, float t)
{
    return palette(d+t,vec3(0.5),
        vec3(0.5,0.5,0.5),
        vec3(0.5,0.5,0.5),
        vec3(0.0,.1,0.2));
}

float smoothMin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0. , 1.);
  return mix(b,a,h)-k*k*(1.0-h);
}

float smoothMax(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0. , 1.);
  return max(b,a)-k*k*(1.0-h);
}

mat2 Rotate(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

float sdCapsuel(vec3 p, vec3 a, vec3 b, float r) {
  vec3 ab = b-a;
  vec3 ap = p-a;

  float t = dot(ap, ab)/dot(ab, ab);
  t = clamp(t, 0.0, 1.0);

  vec3 c = a + t*ab;
  float d = length(p-c)-r;

  return d;
}

float sdTorus(vec3 p, vec2 r) {
  float x = length(p.xz)-r.x;
  float y = p.y;
  return length(vec2(x,y))-r.y;
}

float dBox(vec3 p, vec3 size) {
  float d = length(max(abs(p)-size, 0.0));
  return d;
}

float sdGyroid(vec3 p, float scale, float thickness, float bias) {
  p *= scale;
  float gyroid = abs(dot(sin(p), cos(p.zxy))-bias)/scale-thickness;
  return gyroid;
}
vec3 Transform(vec3 p) {
  p.xy *= Rotate(p.z*.1);
  p.z -= time * .1;
  p.y -= .3;
  return p;
}

float GetDist(vec3 p) {
  p = Transform(p);
  float dP = p.y; // plane distance
  // float dP = dot(p, normalize(vec3(1,1,1)));

  p *= .675;

  float bd = dBox(p, vec3(1));

  float gyroid = sdGyroid(p, 5.23, 0.03, 1.4);
  float gyroid2 = sdGyroid(p, 10.76, 0.03, .3);
  float torus = sdTorus(p, vec2(p.x, p.z));
  // float gyroid3 = sdGyroid(p, 20.76, 0.03, .3);
  // float gyroid4 = sdGyroid(p, 35.76, 0.03, .3);
  // float gyroid5 = sdGyroid(p, 60.76, 0.03, .3);
  // float gyroid6 = sdGyroid(p, 110.76, 0.03, .3);

  gyroid = min(gyroid, torus);
  // float g = min(gyroid, gyroid2); // union
  // float g = max(gyroid, -gyroid2); // sub
  // gyroid -= gyroid2 * 1.5;
  // gyroid -= gyroid3 * .3;
  // gyroid += gyroid4 * .2;
  // gyroid += gyroid5 * .2;
  // gyroid += gyroid6 * .3;
  // float d = max(bd, gyroid * .8);
  float d = gyroid * .95;
  // float d = smoothMax(bd, gyroid, 0.4);
  return abs(d);

  // float d = min(dP, bd);
  // return d;
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
  vec2 e = vec2(0.02, 0);
  vec3 n = d -vec3(
    GetDist(p-e.xyy),
    GetDist(p-e.yxy),
    GetDist(p-e.yyx)
  );
  return normalize(n);
}

float GetLight(vec3 p) {
  vec3 lightPos = vec3(3, 5, 4);
  // lightPos.xz += vec2(sin(u_time), cos(u_time));
  vec3 l = normalize(lightPos -p);
  vec3 n = GetNormal(p);

  float diff = clamp(dot(n, l)*.5+.5, 0., 1.);
  float d = RayMarch(p+n*SURFACE_DIST*2., l);

  // float diff = clamp(dot(n, l), 0., 1.); // -1 to 1 --> 0 to 1

  // shadow
  // float d = RayMarch(p+n*SURFACE_DIST*2.0, l);
  // if(d<length(lightPos-p)) diff *= .1;

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

vec3 Background(vec3 rd) {
  vec3 col = vec3(0.);
  float y = rd.y*.5+.5;
  float t  = time;
  col += (1.-y) * vec3(1., 1., 1.)*2.;
  float a = atan(rd.x, rd.z);
  float flames = sin(a*10.+t)*sin(a*7.-t)*sin(a*6.-t);
  flames *= S(.8, .5, y);
  col += flames;
  col = max(col, 0.);
  col += S(.5, .0, y);
  return col;
}

void main(void) {
    // normalize
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0.0);
    float t  = time;
    // uv *= .35;

    // uv *=cos(uv*0.0012+sin(t));

    // camera
    vec3 ro = vec3(0, 0, -.03);
    // ro.yz *= Rotate(-mouse.y*3.14+1.);
    // ro.xz *= Rotate(-mouse.x*6.2831);
    
    
    ro.yz *= Rotate((-time*0.1)*3.14+1.);
    ro.xz *= Rotate((time*0.1)*6.2831);
    
    // ray direction
    vec3 rd = normalize(vec3(uv.x, uv.y-.2, 1));

    vec3 lookat = vec3(0,0,0);

    // vec3 rd = R(uv, ro, lookat, .8); // last zoomjavascript:void(0)

    float d = RayMarch(ro, rd);

    if(d<MAX_DIST) {
      vec3 p = ro + rd * d;
      vec3 n = GetNormal(p);

      float height = p.y;

      p = Transform(p);

      float diff = n.y*.5+.5;
      col += diff * diff;

      float g2 = sdGyroid(p, 10.76, 0.03, .3);
      col *=S(-0.1, .1, g2); // blackening

      float crackWidth = -0.02+S(0., -.5, n.y) * 0.04;
      float cracks = S(crackWidth, -.03, g2); // first crack's width

      float g3 = sdGyroid(p+t * .1, 5.76, 0.03, .0);
      float g4 = sdGyroid(p-t * .05, 4.76, 0.03, .0);
      cracks *= g3 * g4 *20.+.2 * S(.2, .0, n.y);

      col += cracks * vec3(.62, .4, .85) * 3. * sin(time);

      float g5 = sdGyroid(p-vec3(0., t, 0.), 3.76, 0.03, .0);

      col += g5*vec3(.62, .4, .85);

      col += S(0., -2., height)*vec3(.62, .4*sin(time), .85*cos(time));
        
      col = colorize(col.r+col.b, col.g);

    }

    col = mix(col, Background(rd), S(0., 7. , d));
    glFragColor = vec4(col, 1.0);
}
