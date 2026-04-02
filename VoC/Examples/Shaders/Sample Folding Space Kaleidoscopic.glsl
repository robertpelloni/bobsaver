#version 420

// original https://www.shadertoy.com/view/mtsGDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926

float uSin(float t) { return 0.5 + 0.5 * sin(t); }

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) { return a + b * cos(6.28318 * (c * t + d)); }

mat3 rot(vec3 ang) {
    mat3 x = mat3(1.0, 0.0, 0.0, 0.0, cos(ang.x), -sin(ang.x), 0.0, sin(ang.x), cos(ang.x));
    mat3 y = mat3(cos(ang.y), 0.0, sin(ang.y), 0.0, 1.0, 0.0, -sin(ang.y), 0.0, cos(ang.y));
    mat3 z = mat3(cos(ang.z), -sin(ang.z), 0.0, sin(ang.z), cos(ang.z), 0.0, 0.0, 0.0, 1.0);
    return x * y * z;
}

mat2 rot(float angle) {
  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

// Fold point p given the fold center and axis normal
vec3 opFold(vec3 p, vec3 c, vec3 n) {
  float dist = max(0.0, dot(p - c, n)); 
  return p - (dist*n*2.0);
}

vec3 opRep(in vec3 p, in vec3 c) {
    vec3 q = mod(p, c) - 0.5 * c;
    return q;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) +
        min(max(d.x, max(d.y, d.z)), 0.0);  // remove this line for an only partially signed sdf
}

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

vec3 map(in vec3 p) {
  //vec3 fold_normal = vec3(1.0, 1.0, 1.0);
  //vec3 fold_normal = vec3(1.0, 0.0, 1.0) * rot(vec3(u_time));
  int num_folds = 6;
  vec3 rep = vec3(28.0,10.0, 28.0);
  float rep_index = (floor((p.y) / rep.y) / (rep.y));
  //rep_index = sin(rep_index*2.0*PI);
  for (int i = 0; i < num_folds; i++) {
    float fi = float(i) / float(num_folds);
    //vec3 fold_normal = vec3(cos(fi*2.0*PI), (cos(fi*6.0*PI) + sin(fi*6.0*PI))*(sin(u_time)), sin(fi*2.0*PI));
    vec3 fold_normal = vec3(cos(fi*2.0*PI), 0.0, sin(fi*2.0*PI));
    fold_normal = normalize(fold_normal);
    p = opFold(p, vec3(0.0), fold_normal);
  }
  p = opRep(p, rep);

    int num_box = 8;
    float d = 10e7;
    float smooth_amt = 0.05;
    float box_size = 1.0 + 0.75*sin(rep_index*2.0*PI + time);
    for (int i = 0; i < num_box; i++) {
      float index = float(i) / float(num_box);
      vec3 polar_p = p;
      polar_p.xz += 7.0*vec2(cos(index*2.0*PI + 2.0*PI*rep_index), sin(index*2.0*PI + 2.0*PI*rep_index))*tan(uSin(time + rep_index*PI*3.0)*PI*0.25 + 0.1*PI);
      
      float curr_d =
          sdBox(rot(vec3(time + index * 2.0 * PI, time + index * 1.0 * PI, time + index * 0.666 * PI)) * polar_p,
                  vec3(box_size));
      //d = curr_d;
      d = opSmoothUnion(d, curr_d, smooth_amt);
      //d = curr_d;

      //p *= 1.15 + 0.25*uSin(u_time*1.13);
      //p.xz *= rot(u_time + index*2.0*PI);
      //box_size *= 0.9;
      //smooth_amt += 0.01*sin(u_time*2.2);
    }

    vec3 result = vec3(abs(d) + 0.005, rep_index, 1.0);

    return result;
}

float pcurve( float x, float a, float b ){
    float k = pow(a+b,a+b) / (pow(a,a)*pow(b,b));
    return k * pow( x, a ) * pow( 1.0-x, b );
}

// https://learnopengl.com/Lighting/Light-casters
float attenuation(float dist, float constant, float linear, float quadratic) {
    return 1.0 / (constant + linear*dist +quadratic*dist*dist);
}

void main(void) {
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= resolution.x / resolution.y;

    // Camera setup.
    vec3 viewDir = vec3(0.0, 1.0, 0.0);
    vec3 cam_up = vec3(0.0, 0.0, 1.0);
    vec3 cam_pos = vec3(0.0, -4.0, 0.0);
    vec3 u = normalize(cross(viewDir, cam_up));
    vec3 v = cross(u, viewDir);
    vec3 vcv = (cam_pos + viewDir);
    vec3 srcCoord = vcv + p.x * u + p.y * v;
    vec3 rayDir = normalize(srcCoord - cam_pos);

    vec3 cA = vec3(0.05, 0.7, 0.97);
    vec3 cB = vec3(0.5, 0.1, 0.5);
    vec3 cC = vec3(1.0, 1.0, 1.0);
    vec3 cD = vec3(0.4, 0.0, 0.7);

    vec4 c = vec4(0.0, 0.0, 0.0, 1.0);
    float depth = 1.0;
    float d = 0.0;
    vec3 pos = vec3(0);
    vec3 colorAcc = vec3(0);
    bool hit = false;
    for (int i = 0; i < 48; i++) {
        //pos = cam_pos + rayDir * depth;
        //pos = cam_pos + rayDir * depth + vec3(0.0, 25.0*u_time*0.159 + 25.0*pcurve(mod(u_time*0.159, 1.0), 3.0, 8.0), 0.0);
        pos = cam_pos + rayDir * depth + vec3(0.0, 35.0*floor(time*1.459) + 35.0*pow(mod(time*1.459, 1.0), 3.0), 0.0);
        pos = pos*rot(vec3(0.0, time, 0.0));
        //pos = cam_pos + rayDir * depth + vec3(0.0, 25.0*floor(u_time*1.159) + 25.0*smoothstep(0.0, 1.0, mod(u_time*1.159, 1.0)), 0.0);
        //pos = cam_pos + rayDir * depth + vec3(0.0, u_time*2.159, 0.0);
        //pos = cam_pos + rayDir * depth + vec3(0.0, u_time, 0.0);
        //pos = cam_pos + rayDir * depth + vec3(0.0, 75.0*u_time*0.459+75.0*smoothstep(0.0, 1.0, mod(u_time*0.459, 1.0)), 0.0);
        vec3 mapRes = map(pos);
        d = mapRes.x;
        if (abs(d) < 0.001) {
          hit = true;
        }
        colorAcc += exp(-abs(d) * (8.0+7.5*sin(time))) * palette(mapRes.y*2.33 + pos.y*0.2, cA, cB, cC, cD);
        colorAcc *= (1.0+attenuation(abs(d), 12.8, 8.0, 20.1) * palette(mapRes.y + pos.y*0.2, cA, cB, cC, cD));
        depth += max(d*0.5, 0.065);
    }
    //if (!hit) {
    colorAcc = colorAcc * 0.02;
      colorAcc *= (1.0+attenuation(depth, 0.5, 0.1, 0.1));
    colorAcc -= vec3(0.05/exp(-depth*0.01));
      //colorAcc -= 0.1/exp(depth*1.00);
    //}
    glFragColor = vec4(colorAcc, 1.0);
}
