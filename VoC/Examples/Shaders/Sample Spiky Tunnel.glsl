#version 420

// original https://www.shadertoy.com/view/4ltGRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.1416
#define time time
float fpos; 

const int iterations = 128;

vec3 mid_light;
 

mat3 rotz(float t){
     return mat3( cos(t),  -sin(t), 0,
                     sin(t),   cos(t), 0,
                    0,        0 ,     1);
}
mat3 roty(float t){
    return  mat3( cos(t),  0,  sin(t),
                   0,       1,  0,
                     -sin(t), 0,  cos(t)); 

}

mat3 rotx(float t){
     return mat3( 1, 0 ,      0,
                  0, cos(t), -sin(t),
                       0, sin(t),  cos(t));
}

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise( in vec2 p ) {
  vec2 i = floor( p );
  vec2 f = fract( p );    
  vec2 u = f*f*(3.0-2.0*f);
  return -1.0+2.0*mix( mix( rand( i + vec2(0.0,0.0) ), 
                rand( i + vec2(1.0,0.0) ), u.x),
               mix( rand( i + vec2(0.0,1.0) ), 
                rand( i + vec2(1.0,1.0) ), u.x), u.y);
}
float trianglewave(float t, float a){
      float q = t / a;
      return 2. * abs( 2.*(q - floor(q + 0.5))) - 1.;
}
float mapFunc(vec3 p){

  p.y +=  0.2 * noise(p.xz + time);
  float amp = 0.2;

  if (time < 20.) {
    amp *= clamp(20. - time, 0., 1.);
    p.y = p.y + trianglewave(p.z, 0.7) * amp + trianglewave(p.x, 0.7) * amp ;
  }

  return 2. + p.y;
}

float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/ k;
}
float mapSphere(vec3 p, float r){
  p.z -= time * 3.;
  p.z = mod(p.z, 20.) - 2.5;
  mid_light = p;
  return length(p)-r;
}
float map(vec3 p){
  p.z += time;
  p.xy += 0.5 * sin(p.z + time);

  float s = mapSphere(p,0.7);
  p.xy = (rotz(p.z * 0.3) * p).xy;
  float third = 2. * pi / 3.;
  float f = mapFunc(p);
  p = rotz(third) * p; 
  float f1 = mapFunc(p);
  p = rotz(third) * p; 
  float f2 = mapFunc(p);

  float k = 2.;
  return min(smin(smin(f, f1, k), f2, k), s);
}

float trace(vec3 origin, vec3 ray, vec3 misc){
    
  float t = 0.0;
  for(int i = 0; i < iterations; i++){
    vec3 point = origin + ray * t;
    float dist = map(point);
    t += dist * 0.5;
  }
  return t;
}

vec3 nor(vec3 p, float prec){
  vec2 e = vec2(prec,0.);

  vec3 n;
  n.x = map(p+e.xyy) - map(p-e.xyy); 
  n.y = map(p+e.yxy) - map(p-e.yxy); 
  n.z = map(p+e.yyx) - map(p-e.yyx);  
  return normalize(n);

}

vec3 Shade(vec3 p, vec3 n,  vec3 o, vec3 color)
{
  vec3 lp = vec3(0,0,1);
  vec3 s = lp - p;
    
  float l = .2;  
  l += .8 * max(dot(n, normalize(s)), 0.);
  l += .85 * pow(max(dot(normalize(o - p), reflect(-normalize(s), n)), 0.), 7.);
  return color * l ;
}

void main(void)
{   
    vec2 res =     resolution.xy / resolution.y;
    vec2 fpos = gl_FragCoord.xy / resolution.xy;
    vec3 pos = vec3(fpos.xy, 1.);
    pos.x *= res.x / res.y;
     mat3 rotmat = rotx(-pi/12.);
    
     pos =  rotmat * pos;
     vec3 ray = normalize(vec3(pos.xy - res / 2.,0.5));
   
     vec3 origin =  vec3(0.0, 0.0, -3.);
     origin =  rotmat * origin;
     float t = trace(origin,ray, vec3(0.5,1.,0.) );

     vec3 p = origin + t * ray;
     float fog = 1.0 / (1.0 + t * t * 0.0025);
    
    vec3 color = vec3(.3,.5,1.);
    float e = 0.01;
    
    vec3 fc = Shade(p,nor(p,e), origin, color);
    
    glFragColor = vec4(fc,1.) * fog;
}
