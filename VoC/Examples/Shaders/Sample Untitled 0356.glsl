#version 420

// original https://www.shadertoy.com/view/tss3Rl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float map(vec3 p)
{
  vec3 cp = p;
  float dist = 1000.;

  float time = time * .5;

  p.zx *= rot(-time * .25);

  for(float it = 0.; it < 4.; it += 1.)
{
  p.xz *= rot(sin(p.y + time + (fract(sin(it * 2369.)))) * PI / (it + 1.) * 1.5);

  p.y += p.x * .125;
  p.zy *= rot(time);

  dist  =smin(dist, length(p) - 1., .25);
}

  return dist;
}

float ray(inout vec3 cp, vec3 rd, out float cd)
{
  float st = 0.;
  for(;st < 1.; st += 1. /32.)
  {
    cd = map(cp);
    if(cd < .01)
    {
      break;
    }
    cp += rd * cd * .75;
  }

  return st;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,.0);

  return normalize(vec3(
  map(p - e.xyy) - map(p + e.xyy),
  map(p - e.yxy) - map(p + e.yxy),
  map(p - e.yyx) - map(p + e.yyx)
));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
  uv *= .35;

  vec3 eye = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = eye;

  float cd;
  float st = ray(cp, rd, cd);

  glFragColor = vec4(0.);
  if(cd < .01)
  {
    vec3 ld = normalize(vec3(0.,-1.,1.));
    ld.xz *= rot(time * .1);

    vec3 norm = normal(cp);
    float li = dot(ld, norm);

    ld.zy *= rot(time * .25);
    float li2 = dot(normalize(vec3(1.,0.,1.)), norm);
    

    float f = pow(max(li,li2), 2.);
    f = sqrt(f);
    vec4 col = vec4(norm, 0.);

    col.xy *= rot(time * .5);
    col.yz *= rot(time * .75);
    col.xz *= rot(time * .125);
    col = abs(col);
    glFragColor = mix(vec4(0.), col * 1.5, f);
  }

}
