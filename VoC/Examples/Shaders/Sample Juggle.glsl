#version 420

// original https://www.shadertoy.com/view/3lBXRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592
float hash(float x){
    x = fract(sin(x*416.31434));
    x = fract(sin(x*234.41523));
    x = fract(sin(x*235.51424));
    return x;
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}
float smin(float a, float b, float k) {
    float h = clamp( 0.5 + 0.5*(b - a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 uni(vec2 a, vec2 b) {
    if (a.x < b.x) return a;
    return b;
}

vec3 eye() {
    vec3 p = vec3(-.2,.3,2.5);
    p.yz = rot(.05 * cos(time/17.)) * p.yz;
    p.xy = rot(.1 * sin(time/8.)) * p.xy;
    return p;
}

vec3 look() {
    return vec3(.2 * cos(time/3.9)+.5,.2 * sin(time/2.7) -.4,.1 * sin(time/11.2));
}

float sph(vec3 p, vec3 c, float r) {
    return length(p - c) - r;
}

float box(vec3 p, vec3 c, vec3 r) {
    vec3 d = abs(p - c) - r;
    return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float menger(vec3 p) {
   float d = -1000.;

   float s = 1.0;
   for( int m=0; m<3; m++ )
   {
      vec3 a = mod( p*s, 2.0 )-1.0;
      s *= 3.0;
      vec3 r = abs(1.0 - 3.0*abs(a));

      float da = max(r.x,r.y);
      float db = max(r.y,r.z);
      float dc = max(r.z,r.x);
      float c = (min(da,min(db,dc))-1.0)/s;

      d = max(d,c);
   }

   return d;
}
        
float torus(vec3 p, vec3 c, float r1, float r2) {
    vec3 v = p - c;
    return length(vec2(length(v.xy) - r1, v.z)) - r2;
}
vec2 sdf(vec3 p) {
    float ships = 1000.;
    for (int i = 0; i < 3; i++) {
        float angle = 2.*float(i)*PI/3. + time/1.3;
        vec3 q = p - vec3(.2*cos(angle), .2*sin(angle), 1.5);
        q.yz = rot(time + angle) * q.yz;
        q.xy = rot(time/3.2) * q.xy;
        float shipsize = .1;
        float ship = max(box(q, vec3(0., 0., 0.), vec3(shipsize )), menger(q/shipsize)*shipsize);
        ships = min(ships, ship);
    }
    float z = p.z - time;
    p.x += cos(z)* .2;
       float d =  1. - length(p.xy);
    p.xy = rot(z + sin(z) + time/5. + sin(time/4.)/6.) * p.xy;
    float s = 1.;
    z /= 2.;
    for (int i = 0; i < 7; i++) {
        p *= 1.9;
        s *= 1.9;
        z *= 2.57;
        d += (sin(z/4.1) + cos(z/.4)) * sin(p.x+cos(p.y)) * .3/s;
    }
    return uni(vec2(d, 0.), vec2(ships, 1.));
}

vec3 march(vec3 start, vec3 ray) {
    float t = 0.0;
    vec3 c = vec3(1., 0.5, 0.);
    for (int i = 0; i < 99; i++) {
        vec3 p = start + t * ray;
        vec2 d = sdf(p);
        if (d.y == 0.) {
            c += vec3(0.05, d.x/20., d.x*sqrt(sqrt(t))/10.);
        } else {
            c += vec3(.0, .03, 0.05);
        }
        t += d.x * .6;
        if (d.x/t < 0.001) {
            if (d.y == 1.) c -= vec3(1., 0., 0.);
            return c;
        }
    }
    return c;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.)/resolution.y;
    
    vec3 e = eye();
    vec3 l = look();
    vec3 fwd = normalize(l - e);
    vec3 right = normalize(cross(fwd, vec3(0.,1.,0.)));
    vec3 up = cross(right, fwd);
    
    vec3 ray = normalize(uv.x * right + uv.y * up + fwd);
    
    float vignette = 1. - length(uv);
    float noise = hash(uv.x + hash(uv.y + hash(time)));
    vec3 c = vignette * march(e, ray) + noise * .05;
    float w = c.r + c.g + c.b;
    
    // Output to screen
    glFragColor = vec4(c * (w/(5. + w)),1.0);
}
