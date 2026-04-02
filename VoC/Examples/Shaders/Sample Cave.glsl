#version 420

// original https://neort.io/art/bp7up1s3p9fd1psql0eg

uniform float time;
uniform vec2  resolution;
uniform sampler2D texture;

out vec4 glFragColor;

mat2 rot(float r)
{
  float s = sin(r),c = cos(r);
  return mat2(c,s,-s,c);
}

float rand(vec2 p)
{
  return fract(sin(dot(p,vec2(12.34,56.78)))*12345.678);
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( rand( i + vec2(0.0,0.0) ),
                     rand( i + vec2(1.0,0.0) ), u.x),
                mix( rand( i + vec2(0.0,1.0) ),
                     rand( i + vec2(1.0,1.0) ), u.x), u.y);
}

#define OCTAVES 6
float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

float box(vec3 p,vec3 r)
{
  p = abs(p)-r;
  return (max(p.x,p.y));
}

float map(vec3 p)
{
  float d = 9999.;
  p.z -= time*10.;
  p.x = abs(p.x)-300.;
  float n = pow(fbm(p.yz*vec2(0.008,0.014)),1.8)*50.;
  d = min(d,box(p,vec3(1.+n+pow(length(p.y*0.1),1.4),700.,0.)));
  d = min(d,p.y);
  //d = min(d,box(p,.5));
  return d;
}

vec3 normal(vec3 p)
{
  float e = 0.001;
  vec2 k = vec2(1.,-1.);
  return normalize(
      k.xyy * map(p+k.xyy*e)+
      k.yxy * map(p+k.yxy*e)+
      k.yyx * map(p+k.yyx*e)+
      k.xxx * map(p+k.xxx*e)
    );
}

float ao(vec3 p,vec3 n,float len,float power){
    float oss =0.0;
    for(int i =0;i<3;i++){
        float d = map(p+n*len/3.0*float(i+1));
        oss += (len-d)*power;
        power *=0.5;
    }
    return clamp(1.-oss,0.0,1.0);
}

struct Ray{
  vec3 pos;
  vec3 dir;
};

void main (void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = (gl_FragCoord.xy*2. - resolution.xy) / min(resolution.x,resolution.y);
    vec4 color = texture2D(texture, uv);
    float cc = .5;
    vec3 ro = vec3(.0,13.0,15.);
    //ro.xz *= rot(time);
    vec3 ta = vec3(0.,23.,0.);
    vec3 fo = normalize(ta-ro);
    vec3 le = normalize(cross(vec3(0.,1.,0.),fo));
    vec3 up = cross(fo,le);
    float fov = 1.4;
    Ray ray;
    ray.dir = normalize(vec3(fo*fov+le*p.x+up*p.y));
    ray.pos = ro;
    float t = 0.01,d;
    vec3 col;
    int step = 0;

    for(int i = 0;i<120;i++)
    {
      step = i;
      ray.pos = ro + ray.dir * t;
      d = map(ray.pos);
      if(d<0.01) break;
      t += d;
    }

    if(d<0.01)
    {
      vec3 n = normal(ray.pos);
      vec3 ldir = normalize(vec3(.0,.0,-.5));
      float deff = dot(n,ldir)*0.5+0.5;
      float ao = ao(ray.pos,n,0.25,1.);
      col = vec3(deff) * ao ;

    }
    float a = 1.;
    float fog = min(1.,(1./99.)*float(step));
    vec3 fog2 = 0.002 * vec3(0.15,0.25,.275) * t ;

    glFragColor = vec4(col*fog+fog2*(a*cc+0.01), 1.);
}
