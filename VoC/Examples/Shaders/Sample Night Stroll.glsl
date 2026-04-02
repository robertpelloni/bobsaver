#version 420

// original https://www.shadertoy.com/view/3tXGDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define HEIGHT 0.8
#define SCALE 0.25
#define FDIST 0.5
#define GRADIENT_EPS 0.01
#define ITERS 30
#define TOL 0.01
#define LEVELS 4
#define CRATER_RADIUS 0.15
#define CRATER_HEIGHT 35.
#define CRATER_SCALE 0.05
#define CRATER_LEVELS 2
#define SPEED 2.

vec2 noise2D(vec2 uv) {
    vec2 k = vec2(2234.4, 18100.1);
    return fract(k*sin(dot(k, uv)));
}

float noise1D(float t) {
    return fract(14950.5*sin(1905.1*t));
}

float cubemix(float a, float b, float t) {
    float c = t*t*(3.-2.*t);
    return mix(a, b, c);
}

float voronoi(vec2 uv) {
    vec2 iuv = floor(uv);
    vec2 fuv = fract(uv);
    int i;
    int j;
    float d = 2.;
    for (i=-1;i<=1;i++) {
        for (j=-1;j<=1;j++) {
            d = min(d, length(fuv-vec2(i,j)-noise2D(iuv+vec2(i,j))));
        }
    }
    
    return d*d;
}

float voronoifract(vec2 uv) {
    float d = 0.;
    int i;
    float fac = 1.;
    for (i=0; i<LEVELS; i++) {
        d += fac*voronoi(uv);
        uv *= 4.;
        fac *= 0.25;
    }
    return d;
}

float craters(vec2 uv) {
    vec2 iuv = floor(uv);
    vec2 fuv = fract(uv);
    vec2 pos = noise2D(iuv)*(1.-2.*CRATER_RADIUS)+CRATER_RADIUS;
    float d = length(pos-fuv);
    d*=d;
    return min(d, CRATER_RADIUS*CRATER_RADIUS)-CRATER_RADIUS*CRATER_RADIUS;
}

float cratersfract(vec2 uv) {
    float d = 0.;
    int i;
    float fac = 1.;
    for (i=0; i<CRATER_LEVELS; i++) {
        d += fac*craters(uv);
        uv *= 8.;
        fac *= 0.125;
    }
    return d;
}

float map(vec3 pos) {
    float h = pos.y;
    h -= HEIGHT*voronoifract(pos.zx*SCALE);
    h -= CRATER_HEIGHT*cratersfract(pos.zx*CRATER_SCALE);
    return h;
}

vec2 raymarch(vec3 ro, vec3 rd) {
    float d=0.;
    int i;
    for (i=0; i<ITERS; i++) {
        float dist = map(ro+d*rd);
        d += dist;
        if (dist < TOL) {
            return vec2(d, 1.);
        }
    }
    return vec2(d, 0.);
}

vec3 gradient(in vec3 pos) {
    vec3 offset = vec3(-GRADIENT_EPS, 0.0, GRADIENT_EPS);
    float dx0 = map(pos+offset.xyy);
    float dxf = map(pos+offset.zyy);
    float dy0 = map(pos+offset.yxy);
    float dyf = map(pos+offset.yzy);
    float dz0 = map(pos+offset.yyx);
    float dzf = map(pos+offset.yyz);
    return normalize(vec3(dxf - dx0, dyf - dy0, dzf - dz0));
}

void main(void)
{
    float t = SPEED*time;
    float height1 = -map(vec3(0.,0.,t));
    float height2 = -map(vec3(0.,0.,t-0.2));
    vec3 ro = vec3(0., 3.+0.11*(height1+height2), t);
    vec3 up = vec3(0., 1., 0.);
    vec3 w = normalize(vec3(0., -0.7+0.11*(height1-height2), 1.));
    vec3 u = cross(w, up);
    vec3 v = cross(u, w);
    vec2 coord = gl_FragCoord.xy/resolution.xy-0.5;
    vec3 rd = normalize(w*FDIST+u*coord.x+v*coord.y);
    
    vec2 d = raymarch(ro, rd);
    vec3 n = gradient(ro+d.x*rd);
    vec3 col = vec3(pow(dot(rd, w), 10.)*dot(n, -rd));
    glFragColor = vec4(col,1.);
    
}
