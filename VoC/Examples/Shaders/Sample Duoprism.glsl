#version 420

// original https://www.shadertoy.com/view/DdtXzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float xmin = -1.9;
const float xmax = 1.9;
const float ymin = -2.0;
const float ymax = 2.0;
const float CRADIUS = 0.15;  // edges radius
const float SRADIUS = 0.25;  // spheres radius
const int RTYPE = 1; // type of the 4D rotation
const int A = 4;
const int B = 4;
const float PI = 3.14159265358979324;

// duoprism vertices ----------------------------------------------------------
vec4[A*B] Vertices() {
  vec4[A*B] vertices;
  float a; float b; vec2 v1; vec2 v2;
  int i;
  for(i = 0; i < A; i++) {
    a = 2.0 * PI * float(i) / float(A); 
    v1 = vec2(cos(a), sin(a));
    for(int j = 0; j < B; j++) {
      b = 2.0 * PI * float(j) / float(B); 
      v2 = vec2(cos(b), sin(b));
      vertices[i+j*A] = vec4(v1, v2);
    }
  }
  return vertices;
}

// duoprism edges -------------------------------------------------------------
bool dominates(ivec2 c1, ivec2 c2) {
  return c2[0]>c1[0] || (c2[0]==c1[0] && c2[1]>c1[1]);
}
int modulo(int a, int b) {
  float af = float(a);
  float bf = float(b);
  return int(mod(mod(af, bf) + bf, bf));
}
bool Edges(out ivec2 edges_source[2*A*B], out ivec2 edges_target[2*A*B]) {
  int counter = 0;
  ivec2 candidate;
  for(int i = 0; i < A; i++) {
    for(int j = 0; j < B; j++) {
      ivec2 c1 = ivec2(i, j);
      candidate = ivec2(i, modulo(j-1, B));
      if(dominates(c1, candidate)) {
        edges_source[counter] = c1;
        edges_target[counter] = candidate;
        counter++;
      }
      candidate = ivec2(i, modulo(j+1, B));
      if(dominates(c1, candidate)) {
        edges_source[counter] = c1;
        edges_target[counter] = candidate;
        counter++;
      }
      candidate = ivec2(modulo(i-1, A), j);
      if(dominates(c1, candidate)) {
        edges_source[counter] = c1;
        edges_target[counter] = candidate;
        counter++;
      }
      candidate = ivec2(modulo(i+1, A), j);
      if(dominates(c1, candidate)) {
        edges_source[counter] = c1;
        edges_target[counter] = candidate;
        counter++;
      }
    }
  }
  return 0==0;
}

// ROTATIONS 4D ---------------------------------------------------------------
//// rotation around the plane spanned by 'axis1' and 'axis2'
vec4 rotation4D(vec4 axis1, vec4 axis2, float theta, vec4 v) {
  axis1 = normalize(axis1);
  axis2 = normalize(axis2);
  float vx = dot(v, axis1);
  float vy = dot(v, axis2);
  float coef1 = vx * cos(theta) - vy * sin(theta);
  float coef2 = vy * cos(theta) + vx * sin(theta);
  vec4 pvector = vx*axis1 + vy*axis2; 
  return coef1*axis1 + coef2*axis2 + (v-pvector);
}
const vec4 AX1 = vec4(0, 0, 1, 1);
const vec4 AX2 = vec4(1, 1, 0, 0);
//// right-isoclinic rotation
vec4 rotation4DR(vec4 v, float theta, float phi, float xi) {
  float a = cos(xi);
  float b = sin(theta)*cos(phi)*sin(xi);
  float c = sin(theta)*sin(phi)*sin(xi);
  float d = cos(theta)*sin(xi);
  float p = v.x, q = v.y, r = v.z, s = v.w;
  return vec4(
    a*p - b*q - c*r - d*s,
    a*q + b*p + c*s - d*r,
    a*r - b*s + c*p + d*q,
    a*s + b*r - c*q + d*p
  );
}
const float THETA = PI/4.0;
const float PHI = PI/4.0;

// SPHERE STUFF ---------------------------------------------------------------
// ro is the ray origin, rd is the (normalized) ray direction, R is the radius
vec4 iSphere(vec3 ro, vec3 rd, float R) {
  float b = 2.0 * dot(ro, rd);
  float c = dot(ro, ro) - R * R; 
  float delta = b * b - 4.0 * c;
  if(delta < 0.0) { return vec4(-1.0); } // No intersection
  float t = (-b - sqrt(delta)) / 2.0;    // Intersection occurred
  vec3 nrml = (ro + t*rd) / R;
  return vec4(t, nrml);
}

// CONE STUFF -----------------------------------------------------------------
// ro is the ray origin, rd is the ray direction, 
// pa and pb are the centers of the caps, ra and rb are the radii
float dot2(vec3 v) { return dot(v,v); }
vec4 iCappedCone(
  vec3 ro, vec3 rd, vec3 pa, vec3 pb, float ra, float rb, bool caps
) {
  vec3 ba = pb - pa;
  vec3 oa = ro - pa;
  vec3 ob = ro - pb;
  float m0 = dot(ba,ba);
  float m1 = dot(oa,ba);
  float m2 = dot(ob,ba); 
  float m3 = dot(rd,ba);

  if(caps) {
    if(m1 < 0.0) {
      if(dot2(oa*m3-rd*m1) < (ra*ra*m3*m3)) {
        return vec4(-m1/m3, -ba*inversesqrt(m0));
      }
    } else if(m2 > 0.0) {
      if(dot2(ob*m3-rd*m2) < (rb*rb*m3*m3)) {
        return vec4(-m2/m3, ba*inversesqrt(m0));
      }
    }
  }
  
  float rr = ra - rb;
  float hy = m0 + rr*rr;
  float m4 = dot(rd,oa);
  float m5 = dot(oa,oa);
  
  float k2 = m0*m0 - m3*m3*hy;
  float k1 = m0*m0*m4 - m1*m3*hy + m0*ra*rr*m3;
  float k0 = m0*m0*m5 - m1*m1*hy + m0*ra*(rr*m1*2.0 - m0*ra);
  
  float h = k1*k1 - k2*k0;
  if(h < 0.0) return vec4(-1.0);

  float t = (-k1-sqrt(h))/k2;
  float y = m1 + t*m3;
  if(y > 0.0 && y < m0) {
    return vec4(t, normalize(m0*(m0*(oa+t*rd)+rr*ba*ra)-ba*hy*y));
  }
  
  return vec4(-1.0);
}

// ----------------------------------------------------------------------------

// Modified stereographic projection
//  https://laustep.github.io/stlahblog/posts/ModifiedStereographicProjection.html
vec3 stereog(vec4 q) {
  return acos(q.w/sqrt(2.0)) * q.xyz/sqrt(2.0-q.w*q.w);
}

// get the intersection value of t and the normal -----------------------------
// ro is the ray origin, rd is the ray direction 
vec4 getTnorm(vec3 ro, vec3 rd) {
  vec4[A*B] vertices = Vertices();
  ivec2 edges_source[2*A*B]; ivec2 edges_target[2*A*B];
  bool nothing = Edges(edges_source, edges_target);

  float t = 1.0e20; 
  vec4 OUTPUT = vec4(t);
  vec4 tnorm;
  float xi = time;
  for(int k = 0; k < 2*A*B; k++) {
    ivec2 ei = edges_source[k];
    ivec2 ej = edges_target[k];
    vec4 vi4 = vertices[ei[0] + ei[1]*A]; 
    vec4 vj4 = vertices[ej[0] + ej[1]*A]; 
    vec3 vi = RTYPE == 0 ? 
      stereog(rotation4D(AX1, AX2, xi, vi4)) : 
      stereog(rotation4DR(vi4, THETA, PHI, xi)); 
    vec3 vj = RTYPE == 0 ? 
      stereog(rotation4D(AX1, AX2, xi, vj4)) :
      stereog(rotation4DR(vj4, THETA, PHI, xi)); 
    tnorm = iCappedCone(ro, rd, vi, vj, CRADIUS, CRADIUS, false);
    if(tnorm.x > 0.0){
      OUTPUT = tnorm.x < t ? tnorm : OUTPUT;
      t = min(t, tnorm.x);
    }
  }
  float t_cylinder = t;
  for(int k = 0; k < A*B; k++){
    vec3 vk = RTYPE == 0 ? 
      stereog(rotation4D(AX1, AX2, xi, vertices[k])) : 
      stereog(rotation4DR(vertices[k], THETA, PHI, xi)); 
    tnorm = iSphere(ro - vk, rd, SRADIUS);
    if(tnorm.x > 0.0) {
      OUTPUT = tnorm.x < t ? tnorm : OUTPUT;
      t = min(t, tnorm.x);
    }
  }
  return OUTPUT;
}

// ----------------------------------------------------------------------------
void main(void) {
  float aspectRatio = resolution.x/resolution.y;
  vec2 uv = vec2(
    ((xmax - xmin) * gl_FragCoord.xy.x/resolution.x + xmin) * aspectRatio, 
    (ymax - ymin) * gl_FragCoord.xy.y/resolution.y + ymin
  );

  // Cast a ray out from the eye position into the scene
  vec3 ro = vec3(uv, 5); 
  vec3 rd = normalize(vec3(uv, -4));

  // Default color if we don't intersect with anything
  vec3 rayColor = vec3(54.0, 57.0, 64.0) / 255.0;
  // Direction the lighting is coming from
  vec3 lightDir = normalize(vec3(0.0, 0.0, 1.0));
  // Ambient light color
  vec3 ambient = vec3(0.05, 0.1, 0.1);
  // See if the ray intersects with any objects.
  vec3 objColor = vec3(0.0, 1.0, 0.0);
  vec4 tnorm = getTnorm(ro, rd);
  if(!(tnorm.x == 1.0e20)) {
    vec3 nrml = tnorm.yzw;
    vec3 toEye = -rd;
    vec3 r_m = normalize(-reflect(lightDir, nrml));
    float specular = 0.72 * pow(max(dot(r_m, toEye), 0.0), 8.0);
    float diffuse = max(dot(nrml, lightDir), 0.0); // diffuse factor
    rayColor = objColor * (diffuse + ambient) + specular;
  }
  glFragColor.rgb = rayColor;
}
