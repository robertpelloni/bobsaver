#version 420

// orignal https://neort.io/art/bpak2443p9f4nmb8apbg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;
const float pi = acos(-1.);
const float pi2 = pi*2.;

mat2 rot(float r)
{
  float s = sin(r),c = cos(r);
  return mat2(c,s,-s,c);
}

vec2 pmod(vec2 p,float r)
{
  float a = atan(p.x,p.y) + pi/r;
  float n = pi2/r;
  a = floor(a/n)*n;
  return p.xy * rot(-a);
}

float rand(vec2 p)
{
  return fract(sin(dot(p,vec2(12.456,67.567)))*12456.2456);
}

float noise(vec2 p)
{
  vec2 i = floor(p);
  vec2 f = fract(p);

  vec2 offset = vec2(0.,1.);
  float a = rand(i);
  float b = rand(i+offset.yx);
  float c = rand(i+offset.xy);
  float d = rand(i+offset.yy);

  vec2 u = smoothstep(0.,1.,f);

  return mix(mix(a,b,u.x),mix(c,d,u.x),u.y);
}

float box(vec3 p,float r)
{
  p = abs(p)-r;
  return max(p.x,p.z);
}

float dist(vec3 p)
{
  float d = 9999.;
  float t = time;
  float r = 8.;
  p.xy = pmod(p.xy,r);
  
  for(int i = 0;i<5;i++)
  {
    p = abs(p)-0.75;
    p.xz *= rot(noise(p.yy*0.5-time*float(i+1)*0.125));
  }
  
  
  d = min(d,box(p,.25));
  return d;
}

vec3 normal(vec3 p)
{
  float e = 0.001;
  vec2 k = vec2(1.,-1.);
  return normalize(k.xyy * dist(p+k.xyy*e) + k.yxy * dist(p+k.yxy*e) + k.yyx * dist(p+k.yyx*e) + k.xxx * dist(p+k.xxx*e));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec2 uv2 = (gl_FragCoord.xy) / resolution.xy;
    float cc = noise(vec2(noise(vec2(time))))*0.8+0.2;
    float cc2 = 0.25;
    vec3 ro = vec3(0.,0.,-12.);
    vec3 ta = vec3(0.,0.,0.);
    vec3 fo = normalize(ta-ro);
    vec3 le = normalize(cross(vec3(0.,1.,0.),fo));
    vec3 up = normalize(cross(fo,le));
    float fov = 1.2;
    vec3 ray = normalize(vec3(fo*fov+up*uv.y+le*uv.x));
    vec3 pos,col;
    float d,t =0.01;

    int step = 0;
    for(int i = 0;i<80;i++)
    {
      step = i;
      pos = ro + ray*t;
      d = dist(pos);
      if(d<0.01)
      {
        vec3 n = normal(pos);
        vec3 ld = normalize(vec3(0.,0.,1.));
        
        float NdotL = dot(n,ld)*0.5+0.5;
        float spec = pow(clamp(dot(reflect(ld, n), ray), 0.0, 1.0), 10.0);
        col = vec3(NdotL)+spec*vec3(3.,0.1,0.1);
        
        break;
      }
      t += d;
    }

    float fog = max(0.,(1./60.)*float(step))*(cc*cc2);
    vec3 fog2 = 0.001 * vec3(1.5,0.1,0.1) * t;
    col = col*fog ;
    if(d<0.01) col += fog2;
    vec3 backbuffer = texture2D(backbuffer, uv2).rgb;
    col += mix(col,backbuffer,0.7);

    glFragColor = vec4(vec3(col), 1.0);
}
