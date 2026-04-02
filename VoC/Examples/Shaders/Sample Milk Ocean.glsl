#version 420

// original https://www.shadertoy.com/view/fll3RN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Lots of stuff from IQ's blog, nothing special. Mostly trying to get something 
that feels semi-translucent. Mouse drag for camera
*/

float farClip = 30.0;
float pi = 3.14159;

float rand(vec2 co){
  return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float sphere(vec3 p, vec3 c, float r) {
  return length(p - c) - r;
}

float plane( vec3 p, vec3 n, float h )
{
  return dot(p,n) + h;
}

float smin(float a, float b, float k)
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

float map(vec3 p) {
  float d1 = sphere(p, vec3(.1, sin(time*.9)*.2, 0.), .13);
  float d2 = sphere(p, vec3(-.1, cos(time)*.15, 0.), .1);
  float d3 = sphere(p, vec3(0., sin(time*.7)*.12, .1), .08);
  float d4 = plane(p, vec3(0., 1., 0.), .2);
  float r = length(p.xz);
  float c = exp(-1.5 * r * r);
  d4 += .03 * cos((r - time * .35) * 20.) * c * (1. - c*c*c*c*c);
  float s1 = smin(smin(d1, d2, .07), d3, .07);
  return smin(s1, d4, .2);
}

vec3 calcNormal(vec3 p) {
  vec2 e = vec2(0.0001, 0.0);
  return normalize(vec3(
    map(p + e.xyy) - map(p - e.xyy),
    map(p + e.yxy) - map(p - e.yxy),
    map(p + e.yyx) - map(p - e.yyx)));
}

float marchRay(vec3 ro, vec3 rd) {
  float t = 0.0;
  for(int i = 0; i < 300; i++) {
    vec3 p = ro + t * rd;
    float h = map(p);
    if (h < 0.0001) return t;
    t += h;
    if (t > farClip) return 0.0;
  }
  return t;
}

float softShadow(vec3 ro, vec3 rd, float k) {
  float res = 1.0;
    float ph = 1e20;
    for( float t = 0.; t<100.;)
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;

  float tx = time / 2.0;
  float ty = 0.3;
  //if (mouse*resolution.xy.z > 0.0) {
  //  tx = mouse*resolution.xy.x / resolution.x * 3.1416 * 3.0 + 3.14;
  //  ty = mouse*resolution.xy.y / resolution.y - 0.1;
  //}

  vec3 ro = vec3(cos(tx), ty, sin(tx));
  vec3 ta = vec3(0.0, 0.0, 0.0);

  // camera axes
  vec3 ww = normalize(ta - ro);
  vec3 uu = normalize(cross(ww, vec3(0,1,0)));
  vec3 vv = normalize(cross(uu, ww));

  vec3 rd = normalize(uv.x*uu + uv.y*vv + .6*ww);

  float t = marchRay(ro, rd);

  vec3 l = normalize(vec3(cos(time) * 0. + 1., 0.5, 0. * sin(time)));
  float vdotl = max(dot(rd, l), 0.0);

  vec3 fog = vec3(.55, .7, .9);
  vec3 sun = vec3(1.6, 1.2, 1.);
  float sunAmount = pow(vdotl, 16.);
  fog = mix(fog, sun, sunAmount);
  vec3 col = fog;

  if (t > 0.0) {
    col = vec3(0.0);
    vec3 p = ro + t * rd;

    vec3 n = calcNormal(p);
    vec3 r = reflect(-l, n);

    float ndotl = clamp(dot(n, l), 0., 1.);
    float rdotv = clamp(dot(-rd, r), 0., 1.);

    vec3 albedo = vec3(0., .2, .5);
    albedo = vec3(.75);
    //albedo = n * .5 + .5;
    //albedo = vec3(.2, .9, .2);

    float fr = pow(1. + dot(n, rd), 4.) * .7;
    float ao = clamp(map(p + n * .01) / .01, 0., 1.);
    float sss = smoothstep(0., 1., map(p + l * .5) / .5);
    float sha = softShadow(p + .01 * n, l, 6.);

    float diff = ndotl;
    float sp = pow(rdotv, 100.);
    float sky = clamp(.5 + .5 * n.y, 0., 1.);
    float ind = clamp(dot(n, normalize(l * vec3(-1., 0., -1.))), 0., 1.);

    vec3 lin = (sss + diff * sha) * .5 * sun;
    lin += sky * vec3(.15, .2, .3) * ao;
    lin += ind * vec3(.4, .3, .2) * ao;

    col = albedo * lin + sp * sha;

    col = mix(col, fog, fr + sunAmount);
    col = mix(fog, col, exp(-.001*t*t*t));
  }

  //col = col / (col + vec3(1.0));
  col = pow(col, vec3(1.0 / 2.2));

  glFragColor = vec4(col, 1.0);

}
