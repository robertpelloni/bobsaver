#version 420

// original https://www.shadertoy.com/view/dt23Dd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//@machine_shaman
//precision mediump float;

#define time time
#define mouse mouse*resolution.xy
// define resolution resolution;

float noise(vec2 st){
    return fract(sin(dot(vec2(12.23,74.343),st))*43254.);  
}

#define pi acos(-1.)
float noise2D(vec2 st){
  
  //id,fract
  vec2 id =floor(st);
  vec2 f = fract(st);
  
  //nachbarn
  float a = noise(id);
  float b = noise(id + vec2(1.,0.));
  float c = noise(id + vec2(0.,1.));
  float d = noise(id + vec2(1.));
  
  
  //f
  f = smoothstep(0.,.5,f);
  
  //mix
  float ab = mix(a,b,f.x);
  float cd = mix(c,d,f.x);
  return mix(ab,cd,f.y);
}

mat2 rot45 = mat2(0.707,-0.707,0.707,0.707);

mat2 rot(float a){
  float s = sin(a); float c = cos(a);
  return mat2(c,-s,s,c);
}
float fbm(vec2 st, float N, float rt){
    st*=3.;
 
  float s = .5;
  float ret = 0.;
  for(float i = 0.; i < N; i++){
     
      ret += noise2D(st)*s; st *= 2.9; s/=2.; st *= rot((pi*(i+1.)/N)+rt*8.);
      st.x += time/10.;
  }
  return ret;
  
}

#define FOV 90.
#define imod(n, m) n - (n / m * m)

#define VERTICES 12
#define FACES 20

float iX = .525731112119133606;
float iZ = .850650808352039932;

void icoVertices(out vec3[VERTICES] shape) {
    shape[0] = vec3(-iX,  0.0,    iZ);
    shape[1] = vec3( iX,  0.0,    iZ);
    shape[2] = vec3(-iX,  0.0,   -iZ);
    shape[3] = vec3( iX,  0.0,   -iZ);
    shape[4] = vec3( 0.0,  iZ,    iX);
    shape[5] = vec3( 0.0,  iZ,   -iX);
    shape[6] = vec3( 0.0, -iZ,    iX);
    shape[7] = vec3( 0.0, -iZ,   -iX);
    shape[8] = vec3(  iZ,   iX,  0.0);
    shape[9] = vec3( -iZ,   iX,  0.0);
    shape[10] = vec3(  iZ,  -iX,  0.0);
    shape[11] = vec3( -iZ,  -iX,  0.0);
}

mat2 rotate(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float line(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * t);
}

vec3 v[12];
vec2 p[12];

// using define trick to render different triangles
// not possible in loop on glslsandbox
#define tri(a, b, c) min(min(min(d, line(uv, p[a], p[b])), line(uv, p[b], p[c])), line(uv, p[c], p[a]))
float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}
void main(void)
{
    //vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    //vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv.y += .08 * sin(uv.x + time);

    //uv = floor(uv * 500.) / 500.;
    uv = floor(uv * remap(sin(time),-1.,1.,500.,1000.)) / remap(cos(time),-1.,1.,500.,1000.);
    uv *= 2.9;

    float t = 0.001 + abs(uv.y);
    float scl = 1. / t;
    vec2 st = uv * scl + vec2(0, scl + time);

    // setup vertices
    icoVertices(v);

    // project
    for (int i = 0; i < 12; i++) {
        v[i].xz *= rotate(time * 0.5);
        float scl = 1.0 / (1. + v[i].z * 0.2);
        float dist = distance(v[i].xyz, vec3(0, 0, -3));
        p[i] = v[i].xy * scl;// - vec2(0, 0);
    }

    // ico faces
    float d = 1.0;
    d = min(d, tri(0,  4,  1));
    d = min(d, tri(0,  9,  4));
    d = min(d, tri(9,  5,  4));
    d = min(d, tri(4,  5,  8));
    d = min(d, tri(4,  8,  1));
    d = min(d, tri(8,  10, 1));
    d = min(d, tri(8,  3,  10));
    d = min(d, tri(5,  3,  8));
    d = min(d, tri(5,  2,  3));
    d = min(d, tri(2,  7,  3));
    d = min(d, tri(7,  10, 3));
    d = min(d, tri(7,  6,  10));
    d = min(d, tri(7,  11, 6));
    d = min(d, tri(11, 0,  6));
    d = min(d, tri(0,  1,  6));
    d = min(d, tri(6,  1,  10));
    d = min(d, tri(9,  0,  11));
    d = min(d, tri(9,  11, 2));
    d = min(d, tri(9,  2,  5));
    d = min(d, tri(7,  2,  11));

    // color the scene
    vec3 col = vec3(0);

    col += mix(vec3(0), .5 + .5 * cos(time + st.x + 2. * st.y + vec3(0, 1, 2)), sign(cos(st.x * 10.)) * sign(cos(st.y * 20.))) * t * t;
    //col += smoothstep(0.3, 0., d);
    col *= smoothstep(0.0, 0.1, d);
    col += smoothstep(0.1, 0., d) * (.5 + .5 * cos(time + d * 20. + vec3(33, 66, 99)));
    col += abs(.01 / d);

    // thanks for the dithering effect :)
    col += floor(uv.y - fract(dot(gl_FragCoord.xy, vec2(0.5, 0.75))) * 5.0) * 0.1;
    float fa1 = fbm(uv*rot(sin(uv.x)*0.001) ,5., 3.);
  
  
  
  float fb1 = fbm(st ,5., 5.);
  
  float fa2 = fbm(st+sin(st.x*15.) + fa1*5. ,4., 8.);
  float fb2 = fbm(st + fb1 , 5., 6.);
 
  float fa3 = fbm(st*1.5 + fa2 ,5., 1.);
  float fb3 = fbm(st + fa2, 3., 2.);
  
  vec3 col2 = vec3(0);
  float circle = (fa3);
  
  //salt stained marble thing
  //metal blue
  col2=mix(col2,vec3(0.1,0.3,0.6),pow(fa3*2.4,1.5));
  
  //metal red
  col2=mix(col2,vec3(0.9,0.3,0.3),clamp(pow(fb2*.7,1.9),0.,1.));
  
  //black
  //col2=mix(col2,vec3(0.,0.,0.),clamp(pow(fa2*2.,9.),0.,1.)*0.3);
  
  //gold
  col2=mix(col2,vec3(0.9,0.6,0.3),clamp(pow(fa2*1.5,20.)*0.7,0.,1.));
  
  //black
 col2=mix(col2,vec3(0.),clamp(pow(fb1*1.6,1.)*0.8,0.,1.));
  
  //white
  col2=mix(col2,vec3(0.99),clamp(pow(fb2*1.4-0.05,20.),0.,1.));
 
  col2.yz *= rot(-0.12);

    glFragColor = vec4(col*col2, 1.);
    //glFragColor = vec4(col2, 1.);
}
