#version 420

// original https://www.shadertoy.com/view/sstSW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Disclaimer:
I know nothing about lighting and coloring (I'm colorblind).
I copied the visual effect from Zhao Liang (twitter @neozhaoliang).
And I count on the community to make these things nicer.
*/

#define inf              -1.
#define MAX_ITER         50
#define PI               3.14159265359
#define L2(x)            dot(x, x)
#define L2XY(x, y)       dot(x - y, x - y)
#define ZOOM             5.

// For spheres n is the center, r is the radius
// For planes n is the normal vector, r is the distance between the plane and the origin
// if invert is true then the inside/outside of the sphere is interchanged (not used in this program)
// if hasRealBall is true then this virtual ball has a real ball correspondes to it
struct Ball {
    float[5] n;
    float r;
    bool invert;
};

Ball cocluster;
Ball cluster;

// Distance from a point to a ball
float sdistanceToBall(float[5] p, Ball B) {
    float d2=0.;
    for (int k = 0; k < 5; k++)
        d2 += (p[k]-B.n[k]) * (p[k]-B.n[k]);
    return sqrt(d2) - B.r;
}

void translate(inout float[5] p) {
    for (int k = 0; k < 5; k++) {
        p[k] = 2.*fract(p[k]/2.+0.5) - 1.;
        if (p[k] < 0.)
            p[k] *= -1.;
    }
}

// try to reflect a point p to the positive half space bounded by a ball
// if we are already in the positive half space, do nothing and return true,
// else reflect about the ball and return false
// if B is a sphere we try to reflect p into the interior of B
bool try_reflect(inout float[5] p, Ball B, inout float scale) { 
    float[5] q;
    for (int i = 0; i < 5; i++)
        q[i] = p[i]-B.n[i];
    float d2=0.;
    for (int i = 0; i < 5; i++)
        d2 += q[i] * q[i];
    float k = (B.r * B.r) / d2;
    if ( (k < 1.0 && B.invert) || (k > 1. && !B.invert) )
        return true;
    for (int i = 0; i < 5; i++)
        p[i] = k * q[i] + B.n[i];
    scale *= k;
    return false;
}

 
// return distance to the scene, and get the index of the real ball hitted
float DE(vec3 pp) {
    float[5] p;
    for (int k=0; k<5; k++) 
        p[k] = pp.z + pp.x * cos(float(k)*PI/2.5)/sqrt(2.5) + pp.y * sin(float(k)*PI/2.5)/sqrt(2.5);
    
    float scale = .1;
    for (int i = 0; i < MAX_ITER; i++) {
        bool cond = true;
        translate(p);
        cond = cond && try_reflect(p, cocluster, scale);       
        if (cond)
            break;
    }
    
    translate(p);
    float d = sdistanceToBall(p, cluster);
    d=abs(d);
    return d / scale;
}

void init() {
    cocluster = Ball(float[5](1.,1.,1.,1.,1.), 2., true);
    cluster = Ball(float[5](0.,0.,0.,0.,0.), 1., false);
}

float map(vec2 p) {
    vec2 mouse = (2.0*mouse*resolution.xy.xy-resolution.xy)/resolution.y;
    float k = 1.0;
    //if (mouse*resolution.xy.z > 0.0) {
    //    p -= mouse;
    //    k = dot(p,p);
    //    p /= k;
    //    p += mouse;
    //}
    vec3 q = vec3(p.x, p.y, time*0.2);
    const float strong_factor = .5;
    return DE(q) * strong_factor;
}

vec3 hsv2rgb(vec3 c) {
  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 post_process(vec3 col, vec2 uv) {
  col = pow(clamp(col, 0., 1.), vec3(1.0/2.2)); 
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col *= 0.5 + 0.5*pow(19.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.7);
  return col;
}

void main(void) {

    init();

    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec2 p = 2. * uv - 1.;
    p.x *= resolution.x / resolution.y;
    p *= ZOOM;
    float aa  = 2.0 / resolution.y;
        
    float d = map(p);    
    
    float b = -0.4;
    float t = 10.0;
    const float lh = 2.;
    const vec3 lp = vec3(2.5, 2.5, lh);
    
    vec3 ro = vec3(0, 0, t);
    vec3 pp = vec3(p, 0);
    
    vec3 rd = normalize(pp - ro);

    vec3 ld = normalize(lp - pp);
    
    float bt = -(t-b)/rd.z;
  
    vec3  bp   = ro + bt*rd;
    vec3  srd = normalize(lp - bp);
    float bl = L2(lp - bp);

    float st = (0.0-b)/srd.z;
    vec3  sp = bp + srd*st;

    float bd = map(bp.xy);
    float sd = map(sp.xy);

    vec3 col = vec3(0);
    const float ss = 15.0;
    col       += vec3(1.)  * (1.0 - exp(-ss*(max(sd, 0.0)))) / bl;
    float l   = length(p);
    float hue = fract(0.25*l) + .45;
    float sat = .9*tanh(4.*l);
    vec3 hsv  = vec3(hue, sat, 1.0);
    vec3 bcol = hsv2rgb(hsv);
    
    col       *= (1.0-clamp(tanh(0.75*l), 0., .1)) * 1.3;

    col       = mix(col, vec3(1), smoothstep(-aa, aa, -d));
    col       += 0.5*sqrt(bcol.zxy)*(exp(-(10.0+100.0*tanh(l))*max(d, 0.0)));
    col = post_process(col, uv);
    glFragColor = vec4(col,1.0);
}
