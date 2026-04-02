#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3slyz7

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 256;
const float MIN_DIST = 0.0;
const float MAX_DIST = 500.0;
const float EPSILON = 0.00001;

float random(vec2 st) {
    //p  = 50.0*fract( p*0.3183099 );
    //return fract( p.x*p.y*(p.x+p.y) );
    
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    float a = random(i + vec2(0,0));
    float b = random(i + vec2(1,0));
    float c = random(i + vec2(0,1));
    float d = random(i + vec2(1,1));

    return a + (b-a)*u.x + (c-a)*u.y + (a - b - c + d)*u.x*u.y;
}

float fbm(vec2 st, int octaves) {
    float f = 2.0;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for (int i=0; i<octaves; i++) {
        float n = noise(st);
        a += b*n;
        b *= s;
        st *= f;
    }
    return a;
}

float sceneSDF(vec3 samplePoint) {
    return samplePoint.y + fbm(samplePoint.xz, 9);
}

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection) {
    float dist = 0.001;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        vec3 pos = eye + dist * marchingDirection;
        float d = sceneSDF(pos);
        if (d < EPSILON) {
            break;
        }
        
        dist += d*0.4;
        
        if (dist >= MAX_DIST) {
            dist = MAX_DIST;
            break;
        }
    }
    
    return dist;
}
   

vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

vec3 estimateNormal(vec3 p) {
    const float h = 0.0001;
    #define ZERO (min(frames,0)) // non-constant zero
    vec3 n = vec3(0.0);
    for(int i = ZERO; i < 4; i++) {
        vec3 e = 0.5773 * (2.0 * vec3((((i+3)>>1)&1), ((i>>1)&1), (i&1)) - 1.0);
        n += e * sceneSDF(p + e * h);
    }
    return normalize(n);
}

float sigmoid(float x) {
    return 1.0 / (1.0 + exp(-x));
}

vec3 phongIllumination(vec3 eye, vec3 worldDir, float dist) {
    const vec3 ambientLight = vec3(0.5);
    vec3 color = ambientLight * 0.2;
    
    vec3 diffuseColor = vec3(41., 31., 2.) / 255.;
    
    const vec3 lightPos = vec3(-10000.0, 10000.0, 0.0);
    const float lightIntensity = 0.6;
    
    vec3 p = eye + worldDir * dist;
    
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    
    float dotLN = dot(L, N);
    
    if (dotLN < 0.0) {
        return color;
    }
    
    diffuseColor = mix(vec3(0.8), diffuseColor, max(N.y, 0.0));
    
    float top = sigmoid((p.y + 0.4) * 20.);
    diffuseColor = mix(diffuseColor, vec3(1.5), top);
    
    float shadow = shortestDistanceToSurface(lightPos, normalize(p - lightPos));
    
    float shadowMul = 1.0;
    if (length(lightPos - p) - length(lightPos - (lightPos + shadow * normalize(p - lightPos))) > 0.001) {
        shadowMul = 0.3;
    }

    color = mix(lightIntensity * (diffuseColor * dotLN), color, shadowMul);
    return color;
}

vec3 applyFog(vec3 rgb, vec3 rayOri, vec3 rayDir, float dist) {
    float fogAmount = 1.0-exp(-dist * .03);
    vec3  fogColor  = vec3(0.7,0.7,0.65);
    vec3 foggedColor = mix(rgb, fogColor, fogAmount);
    
    float y_dist = max((rayOri + rayDir * dist).y + 1.0, 0.);
    fogAmount = exp(-y_dist * 5. );
    foggedColor = mix(foggedColor, vec3(0.7,0.7,0.7), fogAmount);
    
    return foggedColor;
}

mat3 viewMatrix(vec3 eye, vec3 lookAt, vec3 up) {
    vec3 f = normalize(lookAt);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

void main(void)
{
    vec2 mouse;
    mouse = vec2(0.0,-0.037);
    
    vec3 viewDir = rayDirection(90.0, resolution.xy);
    vec3 eye = vec3(0.0, .1, time * 0.5);
    
    mat3 viewToWorld = viewMatrix(eye, vec3(mouse.x * 3.14 * 4., mouse.y * 3.14 * 4., -1.0), vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = normalize(viewToWorld * viewDir);
    
    float dist = shortestDistanceToSurface(eye, worldDir);
    
    if (dist >= MAX_DIST - EPSILON) {
        glFragColor = vec4(.7, .7, .65, 1.);
        return;
    }
    
    vec3 p = eye + dist * worldDir;
    
    vec3 color = phongIllumination(eye, worldDir, dist);
    
    color = applyFog(color, eye, worldDir, dist);
    
    glFragColor = vec4(color, 1.0);
}
