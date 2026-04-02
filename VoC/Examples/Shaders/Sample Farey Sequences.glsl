#version 420

// original https://www.shadertoy.com/view/wd2BWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
// Farey Sequences
// https://en.wikipedia.org/wiki/Farey_sequence
// Each coloured band is a Farey sequence, the black lines form the Stern-
// Brocot tree.
// mla, 2020
////////////////////////////////////////////////////////////////////////////////

vec3 hsv2rgb(in vec3 c) {
  vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
  return c.z * mix( vec3(1.0), rgb, c.y);
}

bool incircle(vec2 z, float x1, float x2) {
  float centre = 0.5*(x1+x2);
  float radius = 0.5*(x1-x2);
  z -= vec2(centre,0);
  return dot(z,z) < radius*radius;
}

// Distance of z from circle with centre on y=0, passing
// through x-x1,x+x2 (or x-x2,x+x1).
float circledist(vec2 z, float x1, float x2) {
  float centre = 0.5*(x1+x2);
  float radius = 0.5*abs(x1-x2);
  z -= vec2(centre,0);
  return length(z)-radius;
}

float check(vec2 z, ivec4 a) {
  int p = a.x, q = a.y, r = a.z, s = a.w;
  // z is in the half disc under [p/q,r/s] (in some order),
  // but not under either of the subsidiary discs
  float x0 = float(p)/float(q);
  float x1 = float(p+r)/float(q+s); // The mediant
  float x2 = float(r)/float(s);
  float d = 1e8;
  d = min(d,abs(z.x-x1));
  d = min(d,abs(circledist(z,x0,x2)));
  d = min(d,abs(circledist(z,x1,x2)));
  d = min(d,abs(circledist(z,x1,x0)));
  float lwidth = 0.03*z.y;
  //return smoothstep(0.5*lwidth,lwidth,d);
  float pwidth = fwidth(z.x);
  //return smoothstep(max(0.0,lwidth-pwidth),max(pwidth,lwidth),d);
  return smoothstep(-pwidth,pwidth,d-lwidth);
}

int farey(vec2 z, out ivec4 a) {
  z = abs(z);
  float x = z.x;
  int p=1,q=0,r=0,s=1;
  int count = 0;
  // The "slow" continued fraction algorithm
  for (int i = 0; i < 20; i++) {
    int p1=r, q1=s;
    for( ; x >= 1.0; x -= 1.0,count++) {
      float x1 = float(p)/float(q);
      float x2 = float(p1+p)/float(q1+q);
      if (!incircle(z,x1,x2)) {
        a = ivec4(p,q,p1,q1);
        return count;
      }
      p1 += p; q1 += q;
    }
    x = 1.0/x;
    r=p; s=q; p=p1; q=q1;
  }
  return -1;
}

void main(void) {
  vec3 aacol = vec3(0);
  int AA = 2;
  float t = 0.5*sqrt(5.0)-0.5;
  //if (mouse*resolution.xy.x > 0.0) t = mouse*resolution.xy.x/resolution.x;
  for (int i = 0; i < AA; i++) {
    for (int j = 0; j < AA; j++) {
      vec2 z = (gl_FragCoord.xy+vec2(i,j)/float(AA))/resolution.x;
      z.x -= t;
      z *= exp(-mod(0.5*time,18.0));
      z.x += t;
      ivec4 a;
      int k = farey(z,a);
      vec3 col = vec3(1);
      if (k >= 0) {
        col = hsv2rgb(vec3(float(k)/6.0,0.8,1));
        col *= check(z,a);
      }
      aacol += col;
    }
  }
  aacol /= float(AA*AA);
  aacol = pow(aacol,vec3(0.4545));
  glFragColor = vec4(aacol,1);
}
