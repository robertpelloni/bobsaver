#version 420

// original https://www.shadertoy.com/view/tdySzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_MARCHING_STEPS 64
#define EPSILON .0001

#define MIN_FLOAT 1e-6
#define MAX_FLOAT 1e6

float time2=time;

struct Ray{vec3 origin, direction;};
struct Light{vec3 normal; vec3 attenuation; float radius;};
    
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

vec3 hsv2rgb(vec3 c) {
    // Íñigo Quílez
    // https://www.shadertoy.com/view/MsS3Wc
    vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);
    rgb = rgb * rgb * (3. - 2. * rgb);
    return c.z * mix(vec3(1.), rgb, c.y);
}

vec3 Rotate(in vec3 norm, in float yaw, in float pitch){
    float cosp = cos(pitch);
    float sinp = sin(pitch);
    
    mat3 rotp;
    rotp[0][0] = 1.0;
    rotp[0][1] = 0.0;
    rotp[0][2] = 0.0;
    rotp[1][0] = 0.0;
    rotp[1][1] = cosp;
    rotp[1][2] = -sinp;
    rotp[2][0] = 0.0;
    rotp[2][1] = sinp;
    rotp[2][2] = cosp;
    
    float cosy = cos(yaw);
    float siny = sin(yaw);
    
    mat3 roty;
    roty[0][0] = cosy;
    roty[0][1] = 0.0;
    roty[0][2] = siny;
    roty[1][0] = 0.0;
    roty[1][1] = 1.0;
    roty[1][2] = 0.0;
    roty[2][0] = -siny;
    roty[2][1] = 0.0;
    roty[2][2] = cosy;
    
    norm = (rotp * norm);
    norm = (roty * norm);
    
    return norm;
}

mat3 rotX(float a){
    return mat3(1., 0., 0., 0., cos(a), -sin(a), -sin(a), 0., cos(a)); 
}

const float PI = acos(-1.);
float opSubtraction(float d1, float d2){return max(-d1,d2);}
const float RINGS_COUNT = 5.;
const float RINGS_WIDTH = .5;
const float RINGS_THICKNESS = .1;
const float OUTER_RINGS_D = RINGS_COUNT * RINGS_WIDTH;
float world(vec3 p){
      float outer = opSubtraction(length(p) - OUTER_RINGS_D, opSubtraction(p.y + RINGS_THICKNESS, p.y - RINGS_THICKNESS));
    float inner = MAX_FLOAT;
    for(float i=0.; i<RINGS_COUNT; i++){
        float animationPhase = smoothstep(1. - i * .25, 2. - i * .25, time2);;
        vec3 rp = p * rotX(animationPhase * PI);
        inner = min(inner, max(opSubtraction(length(p) - i * RINGS_WIDTH,
                                             length(p) - i * RINGS_WIDTH - RINGS_WIDTH),
                               opSubtraction(rp.y + RINGS_THICKNESS,
                                             rp.y - RINGS_THICKNESS)));
    }
    return min(outer, inner);
}

//Loopless version - need much more iterations. Less eficient in this case
/*
float world(vec3 p){
      float l = length(p);
    float ringID = min(floor(l/.5), 4.);
    
    float time2 = fract(time2 * .5) * 4.;
    float outer = opSubtraction(length(p) - 2.5, opSubtraction(p.y + .1, p.y - .1));
    float animationPhase = ringID * .1;
    vec3 rp = p * rotX(animationPhase * PI);
    float inner = opSubtraction(length(p) - ringID * .5, max(length(p) - ringID * .5 - .5, opSubtraction(rp.y + .1, rp.y - .1)));
    return min(outer, inner);
}
*/

float march(vec3 eye, vec3 marchingDirection){
    const float precis = 0.001;
    float t = 0.0;
    float l = 0.0;
    for(int i=0; i<MAX_MARCHING_STEPS; i++){
        float h = world( eye + marchingDirection * t );
        if( h < precis ) return t;
        t += h;
    }
    return -1.;
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        world(vec3(p.x + EPSILON, p.y, p.z)) - world(vec3(p.x - EPSILON, p.y, p.z)),
        world(vec3(p.x, p.y + EPSILON, p.z)) - world(vec3(p.x, p.y - EPSILON, p.z)),
        world(vec3(p.x, p.y, p.z  + EPSILON)) - world(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

vec3 PointOnCircle(in vec3 pos, in vec3 circlePos, in vec3 circleNorm, in float circleRadius){
     vec3 d = pos - circlePos;
    vec3 qc = d - dot(circleNorm, d) * circleNorm;
    
    return (circlePos + circleRadius * normalize(qc));
}

float Attenuation(float d, float c, float l, float q){
    return (1.0 / (c + (l * d) + (q * d * d)));
}

float Lighting_Ring(in vec3  toView, in vec3  pos, in vec3  norm, in Light light){
    // Get the closest point on the circle circumference on the plane 
    // defined bythe light's position and normal. This point is then used
    // for the standard lighting calculations.
    
    vec3 pointOnLight = PointOnCircle(pos, vec3(0.), light.normal, light.radius);
    vec3 toLight      = pointOnLight - pos;
    vec3 toLightN     = normalize(toLight);
    
    float lightCos    = dot(-toLightN, estimateNormal(pointOnLight));
          lightCos    = max(0., lightCos);
    
    float lightDist   = length(toLight);
    float attenuation = Attenuation(lightDist, light.attenuation.x, light.attenuation.y, light.attenuation.z);
    
    vec3 reflVector = reflect(-toView, norm);
    
    if(lightDist < .025)
        return 1.;
    return lightCos * attenuation * max(dot(toLight, norm), 0.);
}

vec3 render(){
    vec3 color = vec3(0.);
    float a = 0.0; //(mouse.x*resolution.xy.x/resolution.x) * PI;
    vec3 eye = vec3(4. * sin(a), 4.5, 4. * cos(a)) * 1.3;
    vec3 viewDir = rayDirection(60., resolution.xy);
    vec3 worldDir = viewMatrix(eye, vec3(0., -.5, 0.), vec3(0., 1., 0.)) * viewDir;
    
    float dist = march(eye, worldDir);
    if (dist >= 0.) {
        vec3 p = (eye + dist * worldDir);
        vec3 norm = estimateNormal(p);
        color = vec3(0.);
        for(float i=0.; i<RINGS_COUNT; i++){
            float animationPhase = smoothstep(1. - i * .25, 2. - i * .25, time2);;
            Light light = Light(Rotate(vec3(0., 1., 0.), 0., animationPhase * PI), vec3(.1, 1., 2.), i * RINGS_WIDTH + RINGS_WIDTH - .0001);
            vec3 ligthColor = hsv2rgb(vec3((i/(RINGS_COUNT - 1.) * PI * 2.), 1., 1.));
            color += ligthColor * 16. * Lighting_Ring(worldDir, p, norm, light);
        }
        color /= 5.;
    }
    return color;
}

#define AA 2
void main(void) {
    time2 = fract(time2 * .33 + .8) * 3.;
    glFragColor -= glFragColor;
    for(int y = 0; y < AA; ++y)
        for(int x = 0; x < AA; ++x)
            glFragColor.rgb += clamp(render(), 0., 1.);
    glFragColor.rgb /= float(AA * AA);
}
