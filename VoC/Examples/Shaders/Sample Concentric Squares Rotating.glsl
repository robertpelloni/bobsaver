#version 420

// original https://www.shadertoy.com/view/Wl2cWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define u_time time
#define u_resolution resolution

#define M_PI 3.1415926535897932384626433832795
#define M_SQRT_2 1.4142135623731

#define mvec2 float[8]

// basis vectors
// "1","e0","e1","e2","e01","e20","e12","e012"

mvec2 conjugate (mvec2 mv) {
    return mvec2 (mv[0], -mv[1], -mv[2], -mv[3], -mv[4], -mv[5], -mv[6], mv[7]);
}

mvec2 reverse (mvec2 mv) {
    return mvec2 (mv[0], mv[1], mv[2], mv[3], -mv[4], -mv[5], -mv[6], -mv[7]);
}

mvec2 dual(mvec2 mv) {
    return mvec2(mv[7], mv[6], mv[5], mv[4], mv[3], mv[2], mv[1], mv[0]);
}

mvec2 Involute (mvec2 mv) {
    return mvec2( mv[0], -mv[1], -mv[2], -mv[3], mv[4], mv[5], mv[6], -mv[7] );
}

// The geometric product.
mvec2 mul (mvec2 a, mvec2 b)
{
    return mvec2 (
        b[0]*a[0]+b[2]*a[2]+b[3]*a[3]-b[6]*a[6],
        b[1]*a[0]+b[0]*a[1]-b[4]*a[2]+b[5]*a[3]+b[2]*a[4]-b[3]*a[5]-b[7]*a[6]-b[6]*a[7],
        b[2]*a[0]+b[0]*a[2]-b[6]*a[3]+b[3]*a[6],
        b[3]*a[0]+b[6]*a[2]+b[0]*a[3]-b[2]*a[6],
        b[4]*a[0]+b[2]*a[1]-b[1]*a[2]+b[7]*a[3]+b[0]*a[4]+b[6]*a[5]-b[5]*a[6]+b[3]*a[7],
        b[5]*a[0]-b[3]*a[1]+b[7]*a[2]+b[1]*a[3]-b[6]*a[4]+b[0]*a[5]+b[4]*a[6]+b[2]*a[7],
        b[6]*a[0]+b[3]*a[2]-b[2]*a[3]+b[0]*a[6],
        b[7]*a[0]+b[6]*a[1]+b[5]*a[2]+b[4]*a[3]+b[3]*a[4]+b[2]*a[5]+b[1]*a[6]+b[0]*a[7]
    );
}

mvec2 mul (mvec2 a, float b) {
    return mvec2(a[0]*b, a[1]*b, a[2]*b, a[3]*b, a[4]*b, a[5]*b, a[6]*b, a[7]*b);
}

mvec2 mul (float a, mvec2 b) {
    return mul(b,a);
}

mvec2 meet(mvec2 a, mvec2 b)
{
    return mvec2(
        b[0]*a[0],
        b[1]*a[0]+b[0]*a[1],
        b[2]*a[0]+b[0]*a[2],
        b[3]*a[0]+b[0]*a[3],
        b[4]*a[0]+b[2]*a[1]-b[1]*a[2]+b[0]*a[4],
        b[5]*a[0]-b[3]*a[1]+b[1]*a[3]+b[0]*a[5],
        b[6]*a[0]+b[3]*a[2]-b[2]*a[3]+b[0]*a[6],
        b[7]*a[0]+b[6]*a[1]+b[5]*a[2]+b[4]*a[3]+b[3]*a[4]+b[2]*a[5]+b[1]*a[6]+b[0]*a[7]
    );
}

mvec2 join(mvec2 a, mvec2 b) {
    return mvec2(
        b[0]*a[7]+b[1]*a[6]+b[2]*a[5]+b[3]*a[4]+b[4]*a[3]+b[5]*a[2]+b[6]*a[1]+b[7]*a[0],
        b[1]*a[7]+b[4]*a[5]-b[5]*a[4]+b[7]*a[1],
        b[2]*a[7]-b[4]*a[6]+b[6]*a[4]+b[7]*a[2],
        b[3]*a[7]+b[5]*a[6]-b[6]*a[5]+b[7]*a[3],
        b[4]*a[7]+b[7]*a[4],
        b[5]*a[7]+b[7]*a[5],
        b[6]*a[7]+b[7]*a[6],
        b[7]*a[7]
    );
}

mvec2 inner(mvec2 a, mvec2 b) {
    return mvec2(
        b[0]*a[0]+b[2]*a[2]+b[3]*a[3]-b[6]*a[6],
        b[1]*a[0]+b[0]*a[1]-b[4]*a[2]+b[5]*a[3]+b[2]*a[4]-b[3]*a[5]-b[7]*a[6]-b[6]*a[7],
        b[2]*a[0]+b[0]*a[2]-b[6]*a[3]+b[3]*a[6],
        b[3]*a[0]+b[6]*a[2]+b[0]*a[3]-b[2]*a[6],
        b[4]*a[0]+b[7]*a[3]+b[0]*a[4]+b[3]*a[7],
        b[5]*a[0]+b[7]*a[2]+b[0]*a[5]+b[2]*a[7],
        b[6]*a[0]+b[0]*a[6],
        b[7]*a[0]+b[0]*a[7]
    );
}

float norm( mvec2 mv) { 
    return sqrt(abs(mul(mv, conjugate(mv))[0]));
}

float inorm(mvec2 mv) { 
    return mv[1] != 0.0 ? mv[1] : mv[7] != 0.0 ? mv[7] : norm(dual(mv));
}

mvec2 normalize2(mvec2 mv) {
    return mul(mv, 1./norm(mv));
}

mvec2 add (mvec2 a, float b) {
    return mvec2(a[0]+b, a[1], a[2], a[3], a[4], a[5], a[6], a[7]);
}

mvec2 add (float a, mvec2 b) {
    return add(b,a);
}

mvec2 apply( mvec2 transformation, mvec2 target) {
    return mul(mul(transformation, target), reverse(transformation));
}

mvec2 point( vec2 p ) {
    return mvec2 (0., 0., 0., 0., p.x, p.y, 1., 0.);
}

vec2 point( mvec2 p ) {
    return vec2( p[4], p[5]);
}

mvec2 line( vec2 p ) {
    return mvec2 (0., 0., p.x, -p.y, 0., 0., 0., 0.);
}

mvec2 line( vec2 p1, vec2 p2 ) {
    return join(point(p1), point(p2));
}

mvec2 dir( vec2 p ) {
    return mvec2 (0., 0., 0., 0., p.x, p.y, 0., 0.);
}

mvec2 rot( float rad, vec2 p) {
    return add(cos(rad*.5), mul(point(p), sin(rad*.5)));
}

mvec2 rot( float rad) {
    return rot(rad, vec2(0.));
}

mvec2 orth_trans( vec2 d) {
    return add(1., dir(d));
}

mvec2 trans(vec2 d) {
    mvec2 r = rot(radians(90.));
    
    return add(1., apply(r, dir(d)));
    
}

float oscilate(float min, float max, float freq) {
    return (sin(u_time)*.5+.5)*(max-min) + min;
}

void main(void) {

    float COUNT = 20.;
    float THICKNESS = oscilate(0.1, 0.9,  0.5) * .5; // oscilate(0.1, 0.9,  0.5);  // .5
    float DRAG = oscilate(0.2, 2.0,  0.05); // oscilate(0.2, 3.0,  0.5); // .5 or 1.2
    float CYCLE_LENGTH = 1.5; // oscilate(1.0, 1.5,  0.2); // oscilate(1.0, 2.0,  0.05); // 1.5
    float SHARPNESS = 100./u_resolution.y; // 10.
    float SPEED = 1.0; // doesn't oscilate nicely

    // Normalized pixel coordinates (from -1 to 1)
    float resScale = 1.0/min(u_resolution.x, u_resolution.y);
    vec2 p = (gl_FragCoord.xy*2.0 - u_resolution.xy)*resScale;
    float dist = abs(length(p)*COUNT);

    float c = 0.;
    for (float i = max(1., trunc(dist/M_SQRT_2)); i < min(dist+1., COUNT); i += 1.) {
        float angleMixFactor = smoothstep(0., 1., 
            mod(u_time*SPEED -i*DRAG/COUNT, CYCLE_LENGTH) );

        float rad = -M_PI * .5 * angleMixFactor; // from 0 to 90 degrees
        mvec2 R = rot(rad);

        vec2 rp = abs(point(apply(R, point(p))));
        float d = max(rp.x,rp.y) * COUNT;
        float e =
            smoothstep(i, i-SHARPNESS, d-THICKNESS) *
            smoothstep(i-SHARPNESS, i, d+THICKNESS)
        ;
        c = max(c, e);
    }
    
    vec3 col = vec3(c);

    glFragColor = vec4(col, 1.0);
    
}
