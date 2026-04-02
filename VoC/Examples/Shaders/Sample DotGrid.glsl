#version 420

// original https://www.shadertoy.com/view/7lf3Rs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define S smoothstep
#define CAM_DIST 1.
#define SIZE 0.02

// Simplex 2D noise
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

mat4 rotationX( in float angle ) {
    return mat4(    1.0,        0,            0,            0,
                     0,     cos(angle),    -sin(angle),        0,
                    0,     sin(angle),     cos(angle),        0,
                    0,             0,              0,         1);
}

mat4 rotationY( in float angle ) {
    return mat4(    cos(angle),        0,        sin(angle),    0,
                             0,        1.0,             0,    0,
                    -sin(angle),    0,        cos(angle),    0,
                            0,         0,                0,    1);
}

mat4 rotationZ( in float angle ) {
    return mat4(    cos(angle),        -sin(angle),    0,    0,
                     sin(angle),        cos(angle),        0,    0,
                            0,                0,        1,    0,
                            0,                0,        0,    1);
}

void main(void) {
    float ar = resolution.x/resolution.y;

    vec2 myMouse = mouse*resolution.xy.xy / resolution.xy;
    myMouse -= 0.5;
    myMouse.x *= ar;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= ar;
    
    vec2 origUV = uv;
    
    
    vec4 myUV = vec4(uv.x, uv.y + snoise(uv + time * 0.2) * 0.1 + 0.5, 0., 1.);
    
    mat4 rotX = rotationX(PI / 4. + myMouse.y);
    mat4 rotZ = rotationZ(PI / 7. + myMouse.x);
    
    myUV = myUV * rotX;

    myUV = myUV * rotZ;

    mat4 proj = mat4(
        1. / (CAM_DIST - myUV.z), 0, 0, 0,
        0, 1. / (CAM_DIST - myUV.z), 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    );
    
    uv = (myUV * proj).xy;
    
    uv = fract(uv * 20.) - 0.5;
    
    vec3 col = vec3(0.);
    
    col = vec3(0.1) + vec3(S(0.105, 0.1, length(uv)) * map(myUV.z, 0., .7, .3, 0.2));
    //col = vec3(myMouse, 0.);
    
    
    // Output to screen
    glFragColor = vec4(col, 1.0);
}
