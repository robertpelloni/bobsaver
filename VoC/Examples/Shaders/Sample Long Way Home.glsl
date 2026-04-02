#version 420

// original https://www.shadertoy.com/view/3sSGDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA (10./resolution.y)
#define MAX_MARCHING_STEPS 255
#define MIN_DIST 0.
#define MAX_DIST 100.0
#define EPSILON 0.0001
#define PI 3.1415
#define TAU (PI * 2.)
#define TORUS vec2(10., 1.)

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

vec2 unionSDF(vec2 a, vec2 b) {
    if(a.x < b.x)
        return a;
    else
        return b;
}

float sdInnerTorus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return t.y - length(q);
}

vec2 sceneSDFwithMat(vec3 samplePoint) {    
    float torus = sdInnerTorus(samplePoint, TORUS);
    return unionSDF(
                    vec2(torus, 1.),
                    vec2(samplePoint.y + .25, 2.)
                    );
}

vec2 shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        vec2 dist = sceneSDFwithMat(eye + depth * marchingDirection);
        if (dist.x < EPSILON) {
            return vec2(depth, dist.y);
        }
        depth += dist.x;
        if (depth >= end) {
            return vec2(end, 0.);
        }
    }
    return vec2(end, 0.);
}

vec2 convertToPolarCoords(in vec3 p){
    float bAng = atan(-p.z, p.x);
    p *= rotateY(-bAng);
    float sAng = atan(p.x - TORUS.x, p.y);
    
    return (vec2(bAng, sAng) + PI)/TAU;
}

vec2 hash( float n ){
    float sn = sin(n);
    return fract(vec2(sn,sn*42125.13));
}

float circleNoise( vec2 uv ){
    float uv_y = floor(uv.y);
    uv.x += uv_y*.31;
    vec2 f = fract(uv);
    vec2 h = hash(floor(uv.x)*uv_y);
    float m = (length(f-.25-(h.x*.5)));
    float r = h.y*.25;
    return smoothstep(r+AA, r, m);
}

const mat2 rot = mat2( 0.4,  0.4, -0.4,  0.4 );
void main(void) {
    vec3 eye = vec3(0., 0., TORUS.x - .125);
    vec3 viewDir = rayDirection(60., resolution.xy);
    vec3 worldDir = viewMatrix(eye, vec3(1., 0., 9.75), vec3(0.0, 1.0, 0.0)) * viewDir;
    
    vec2 dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    if (dist.x < MAX_DIST - EPSILON) {
        vec3 p = (eye + dist.x * worldDir);
        vec2 pc = convertToPolarCoords(p);
        
        if(dist.y == 1.){
            float m = 0.;
            vec2 uv = pc * vec2(64., 16.) + vec2(time * 3., 0.);
            for(float i=1.;i<=3.;i++){
                uv += uv * rot * (1. + .012 * i) + 1121.13;
                m += circleNoise(uv);
            }
            glFragColor = vec4(vec3(m), 1.0);
        }else{
            float clr = smoothstep(.01 + AA, .01, abs(9.1 - length(p.xz)));
            clr = max(smoothstep(.01 + AA, .01, abs(10.9 - length(p.xz))), clr);
            clr = max(smoothstep(.025 + AA, .025, abs(10. - length(p.xz)))
                    * smoothstep(.25 + AA, .25, abs(.5 - fract(p.x + time * 4.))), clr);
            glFragColor = vec4(vec3(clr), 1.0);
        }
    }else{
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
