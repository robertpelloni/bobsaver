#version 420

// original https://www.shadertoy.com/view/wdS3RK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdf(vec3);
vec3 normal(vec3);
float sphere(vec3, float);
float union_smooth(float, float, float);
float sub_smooth(float, float, float);
float ao(vec3, vec3, float);
float ss(vec3, vec3);
float mirrorX(vec3);

mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
  return mat3( cu, cv, cw );
}

mat3 eulerToMat(vec3 e){
  float sx = sin(e.x);
  float sy = sin(e.y);
  float sz = sin(e.z);
  float cx = cos(e.x);
  float cy = cos(e.y);
  float cz = cos(e.z);
  return mat3(
    cy*cz, cz*sx*sy-cx*sz, cx*cz*sy+sx*sz,
    cy*sz, cx*cz+sx*sy*sz, cx*sy*sz-cz*sx,
    -sy, cy*sx, cx*cy);
}

const float EPS = 0.0001;
const float MAX_DIST = 100.0;
const int MAX_STEPS = 128;
const float MIN_STEP_SIZE = 0.005;

const int AO_STEPS = 5;
const float AO_DIST_PER_STEP = 0.5;
const float D2R = 3.141528 / 180.0;
const vec3 bg = vec3(0.7, 0.7, 1.2) * 0.5;

vec3 lightPos = normalize(vec3(1, 1, 1));

struct Shape {
  bool additive;
  float r;
  float blend;
  vec3 pos;
  vec3 scale;
  vec3 rot;
};

Shape shapes[16] = Shape[16](
  Shape(true, 1.0, 1.0, vec3(0.0, 0.5, 0.0), vec3(1,1,1), vec3(0,0,0)*D2R), // head
  Shape(true, 0.4, 0.3, vec3(0, 0.2, 0.6), vec3(1,1,1), vec3(0,0,0)*D2R), // snoot
  Shape(true, 0.4, 0.3, vec3(-0.5, 1.5, -0.5), vec3(1,3,1), vec3(-20,25,0)*D2R), // ear
  Shape(true, 0.4, 0.3, vec3(+0.5, 1.5, -0.5), vec3(1,3,1), vec3(-20,-25,0)*D2R), // ear
  Shape(false, 0.2, 0.2, vec3(-0.7, 2.1, -0.3), vec3(1,3,1), vec3(-20,25,0)*D2R), // ear-cut
  Shape(false, 0.2, 0.2, vec3(+0.7, 2.1, -0.3), vec3(1,3,1), vec3(-20,-25,0)*D2R), // ear-cut
  Shape(false, 0.35, 0.3, vec3(+0.5, 0.7, 0.8), vec3(1,1,1), vec3(0,0,0)*D2R), // eye-socket
  Shape(false, 0.35, 0.3, vec3(-0.5, 0.7, 0.8), vec3(1,1,1), vec3(0,0,0)*D2R), // eye-socket
  Shape(true, 0.5, 0.0, vec3(+0.2, 0.6, 0.35), vec3(1,1,1), vec3(0,0,0)*D2R), // eye
  Shape(true, 0.5, 0.0, vec3(-0.2, 0.6, 0.35), vec3(1,1,1), vec3(0,0,0)*D2R), // eye
  Shape(true, 0.5, 0.1, vec3(0.0, -0.8, 0.0), vec3(1,1,1), vec3(0,0,0)*D2R), // chest
  Shape(true, 0.7, 0.5, vec3(0.0, -1.5, 0.0), vec3(1,1,1), vec3(0,0,0)*D2R), // tummy
  Shape(true, 0.2, 0.1, vec3(-0.7, -0.8, 0), vec3(1,2,1), vec3(0,0,-45)*D2R), // arm
  Shape(true, 0.2, 0.1, vec3(0.7, -0.8, 0), vec3(1,2,1), vec3(0,0,45)*D2R), // arm
  Shape(true, 0.2, 0.1, vec3(-0.3, -2, 0), vec3(1,2,1), vec3(0,0,-15)*D2R), // leg
  Shape(true, 0.2, 0.1, vec3(0.3, -2, 0), vec3(1,2,1), vec3(0,0,15)*D2R) // leg
);

void main(void) {
  vec2 uv = gl_FragCoord.xy/resolution.xy;
  vec2 mouse = mouse*resolution.xy.xy/resolution.xy;

  float camDist = 6.0;
  float spinRate = 0.5;
  vec3 p = vec3(sin(time * spinRate + mouse.x * 6.0) * camDist, (mouse.y - 0.5) * -6.0, cos(time * spinRate + mouse.x * 6.0) * camDist);
  vec3 camDir = normalize(-p);

  mat3 cMatrix = setCamera(p, camDir, 0.0);
  float aspect = resolution.x / resolution.y;
  vec3 dir = cMatrix * normalize(vec3((uv.x - 0.5) * aspect, uv.y - 0.5, 1));

  //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

  bool hit = false;

  for (int i = 0; i < MAX_STEPS; i++) {
    float dist = sdf(p);

    if (dist < EPS) {
      hit = true;
      break;
    }

    if (length(p) > MAX_DIST) {
      break;
    }

    p += dir * max(MIN_STEP_SIZE, dist);
  }

  vec3 outColor = bg.rgb;

  if (hit)  {
    vec3 normal = normal(p);
    float lamp = max(0.0, dot(normal, cMatrix * lightPos)) * 1.0;
    vec3 light = vec3(lamp * 1.5, lamp * 1.3, lamp);
    light += bg.xyz;

    float fBias = 0.0;
    float fScale = 0.5;
    float fPower = 2.0;
    float fresnel = max(0.0, min(1.0, fBias + fScale * pow((1.0 + dot(dir, normal)), fPower)));
    light += fresnel * bg;
    
    float _ao = ao(p, normal, 0.6);
    light *= _ao;

    float _ss = ss(p, -dir);
    light += _ss * vec3(1,0,0.2) * 1.0;

    vec3 baseColor = vec3(0.8,0.8,0.8);

    //float gray = log(1.0 + light);
    outColor = light * baseColor;
    //glFragColor = vec4(ao,ao,ao, 1.0);
  }
  
  glFragColor = vec4(log2(1.0 + outColor.r), log2(1.0 + outColor.g), log2(1.0 + outColor.b), 1.0);

  // for debugging values
  // glFragColor = vec4(dir, 1.0);
}

float sdf(vec3 p) {
  float dist = 1000000.0;
  for(int i = 0; i < shapes.length(); i++) {
    Shape s = shapes[i];
    mat3 mat = eulerToMat(s.rot);
    dist = s.additive
      ? union_smooth(dist, sphere(mat * (p - s.pos) / s.scale, s.r), s.blend)
      : sub_smooth(sphere(mat * (p - s.pos) / s.scale, s.r), dist, s.blend);
  }
  return dist;
}

float sphere(vec3 p, float r) {
  return length(p) - r;
}

vec3 normal(vec3 p) {
  return normalize(vec3(
    sdf(p + vec3(EPS, 0.0, 0.0)) - sdf(p + vec3(-EPS, 0.0, 0.0)),
    sdf(p + vec3(0.0, EPS, 0.0)) - sdf(p + vec3(0.0, -EPS, 0.0)),
    sdf(p + vec3(0.0, 0.0, EPS)) - sdf(p + vec3(0.0, 0.0, -EPS))
  ));
}

float union_smooth(float d1, float d2, float k) {
  float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
  return mix(d2, d1, h) - k * h * (1.0 - h);
}

float sub_smooth(float d1, float d2, float k) {
  float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
  return mix(d2, -d1, h) + k * h * (1.0 - h);
}

float ao(vec3 p, vec3 normal, float k) {
  float actualSum = 0.0;
  for(int i = 1; i <= AO_STEPS; i++) {
    float exp = (1.0 / pow(2.0, float(i)));
    vec3 sampleP = p + normal * float(i) * AO_DIST_PER_STEP;
    actualSum += exp * (float(i) * AO_DIST_PER_STEP - sdf(sampleP));
  }
  return 1.0 - k * actualSum;
}

const int SS_STEPS = 3;
const float SS_DIST_PER_STEP = 0.5;
float ss(vec3 p, vec3 normal) {
  float actualSum = 0.0;
  for(int i = 1; i <= SS_STEPS; i++) {
    float exp = (1.0 / pow(2.0, float(i)));
    vec3 sampleP = p + -normal * float(i) * SS_DIST_PER_STEP;
    actualSum += exp * max(0.0, sdf(sampleP));
    // actualSum += exp * (float(i) * AO_DIST_PER_STEP - sdf(sampleP));
  }
  return actualSum;
}
