#version 420

// original https://www.shadertoy.com/view/fsjcRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
inspired by https://www.shadertoy.com/view/7lKSWW
*/

#define PATTERN_SCALE 25.0 // (15.0 + mouse*resolution.xy.x*0.1)
#define PATTERN 1
#define SECOND_SCALE fsign*0.95

#define M_PI 3.14159265354

float tent(float f) {
    return 1.0 - abs(fract(f)-0.5)*2.0;
}

vec2 rot2d(vec2 p, float th) {
    return vec2(cos(th)*p.x + sin(th)*p.y,
                cos(th)*p.y - sin(th)*p.x);
}

vec2 symmetry(vec2 uv) {
    uv = abs(uv);
    float fsign = 1.0;
    
    for (int i=0; i<5; i++) {
        uv = rot2d(uv, fsign*M_PI*0.15);
        uv = abs(uv);
        //fsign = -fsign;
    }
    
    return uv;
}

float ctent(float f) {
    f = tent(f);
    
#if PATTERN != 1
    f = f*f*(3.0 - 2.0*f);
#endif
    //f *= f;

    return f;
}

float fpattern(vec2 uv, float seed, float fsign, out float w) {
    vec2 p = uv;
    
    seed += mouse.x*resolution.xy.x/resolution.x*2.0;
    
    seed -= time*0.2*fsign*0.3;
    
    float len = length(uv);
    
    uv = normalize(uv)*pow(len, 0.75);
    
    uv = rot2d(uv, -seed);
    uv = symmetry(uv);
    
    float dx1 = ctent(uv.x);
    float dy1 = ctent(uv.y);
    
    uv = rot2d(uv, seed);
    uv *= SECOND_SCALE;
    
    float dx2 = ctent(uv.x);
    float dy2 = ctent(uv.y);

    float f;

#if PATTERN == 0
    f = (dx1+dy1+dx2+dy2)/4.0;
    f *= f*f*3.0;
    //f += tent(f)*0.5;
#elif PATTERN == 1
    f = (dx1*dx1 + dy1*dy1 + dx2*dx2 + dy2*dy2) / (4.0);
    f *= f*2.0;
#elif PATTERN == 2
    f = sqrt(dx1*dx1 + dy1*dy1 + dx2*dx2 + dy2*dy2) / sqrt(4.0);
    f *= 0.8;
    f *= f;
    //f *= f*f;
#elif PATTERN == 3
    f = min(min(min(dx1, dx2), dx2), dy2);
    //f = sqrt(f)*1.5;
    f = 1.0 - f;
    f *= f*f*0.35;
#elif PATTERN == 4
    f = max(max(max(dx1, dx2), dx2), dy2);
    f = f*0.6;
    f *= f*f*1.8;
    //f /= (length(p)+0.5)*0.5;
#elif PATTERN == 5
    f = sqrt(dy2*dy1);
#endif
    
    //f = (tent(f) + tent(f*1.3))*0.5;
    //f = fract(f);
    //f = tent(f);
    
    if (f < 0.1) {
       w = 0.4;
       f = 0.0;
    } else if (f < 0.2) {
       w = 1.0;
       f = 0.0;
    } else if (f > 0.4) {
       w = 0.7;
       f = 0.7;
    } else {
       w = 1.0;
       f = 1.0;
    }
    
    f /= pow(length(p) + 1.0, 0.1);
        
    return f;
}

vec3 ray_plane_isect(vec3 po, vec3 pn, vec3 ro, vec3 rn, out float t) {
  float div = (pn[1]*rn[1] + pn[2]*rn[2] + pn[0]*rn[0]);

  if (abs(div) < 0.000001) {
      return po;
  }
  
  t = ((po[1] - ro[1])*pn[1] + (po[2] - ro[2])*pn[2] + (po[0] - ro[0])*pn[0])/div;
  return ro + rn*t;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float time = time*0.25;
    
    const int steps = 50;
    
    uv = uv*2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    //uv *= 2.0;
    
    float zrange = 1.0;
    float dz = zrange / float(steps-1);
    float z = zrange;// - fract(time);
    
    float z2 = z;// - time;
    
    float f = 0.2;
    
    float th1 = time*0.2;
    vec3 p = vec3(cos(th1), 0.0, sin(th1));
    
    vec3 zn = vec3(-sin(th1), 0.0, cos(th1));
    vec3 xn = normalize(cross(zn, vec3(0.0, 1.0, 0.0)));
    vec3 yn = normalize(cross(zn, xn));
    
    float scale = 2.5;
    vec3 vn = xn*uv.x*scale + yn*uv.y*scale + zn*3.0;
    vn = normalize(vn);
    float tt = 10000.0;

    float seed = 0.2;
    
    for (int i=0; i<steps; i++) {        
        float fi = float(i);
        
        fi += th1*float(steps-1)/M_PI/2.0;
        fi = floor(fi);
        float th = fi/float(steps-1);
        th *= M_PI*2.0;
        
        //th = floor(th*float(steps)-off)/float(steps);
        //th *= M_PI*2.0;
        //th = th1;
        
        th = -th;
        vec3 p2 = vec3(cos(th), 0.0, sin(th));
        vec3 n = vec3(-sin(th), 0.0, cos(th));
        n.xz = rot2d(n.xz, 0.2);
        
        if (dot(n, vn) < 0.0) {
           //continue;
        }
        
        //p2 *= 1.3;
        
        float t;
        vec3 p3 = ray_plane_isect(p2, n, p, vn, t);
        
        if (t < 0.0 || t > tt) {
            continue;
        }
        
        vec3 tan = -normalize(p2);
        
        p3 -= p2;
        
        float u = dot(p3, tan);
        float v = p3[1];
        float len = length(vec2(u, v));
        
        float lmax = 0.15;
        float lmin = 0.012;
        len *= 0.85;
        
        if (len < lmax && len > lmin) {
          tt = t;
          float fac = max(1.0-tt*1.3, 0.0);
          
          fac = fac*fac*(3.0-2.0*fac)*1.15;
          
          float fsign = mod(fi, 2.0)*2.0 - 1.0;
          float w;
          vec2 vuv = vec2(u, v)*PATTERN_SCALE;
          float f2 = fpattern(vuv, fi*0.2 + 0.2, fsign, w);
          
          if (len < lmin*1.3 || len > lmax*0.95) {
              f2 = float(len > lmin*1.15 && len < lmax*0.95);
              //f2 = float(len < lmin*0.97 || len > lmax*1.01);
              w = 1.0;
          }
          
          if (tt > 1.4) {
              f2 = 0.0;
              w = 0.2;
          }
          
          f2 *= fac;
          f = mix(f, f2, w);
        }
    }
    
    // Time varying pixel color
    

    // Output to screen
    glFragColor = vec4(f,f,f,1.0);
}
