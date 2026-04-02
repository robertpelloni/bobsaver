#version 420

// original https://www.shadertoy.com/view/sssBz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define AA 1

// If you have a strong PC, make it bigger.
#define AA 5

#define hash(x) fract(sin(x) * 43758.5453)
const float PI = acos(-1.);
const float PI2 = acos(-1.)*2.;

const float BPM = 100.;
const float layerInterval = 1.0;
const vec3 lightDir = normalize(vec3(-5, 7, 2));

vec3 background = vec3(0);

mat2 rotate2D(in float angle){
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, s, -s, c);
}

// Get pattern number n1 and n2 from a layer ID.
void getPatternNum(in float ID, out int n1, out int n2){
    // N1 and n2 satisfy the following condition.
    // (n1 - 2) * (n2 - 2) > 4
    n1 = 3 + int(pow(hash(ID), 3.) * 10.); // range [3, 12]
    n2 = int(4. / float(n1 - 2)) + 3 + int(pow(hash(ID * 1.1), 3.) * 10.);
}

// Prepare for Hyperbolic Tessellation.
void prepare(in int n1, in int n2, out float a1, out float a2, out float radius, out vec2 center){
    a1 = PI / float(n1); // Angle between line L1 and L2.
    a2 = PI / float(n2); // Angle of intersection between line L1 and circle C.
    
    float cosa2 = cos(a2);
    float sina1 = sin(a1);
    float coeff = 1. / sqrt(cosa2 * cosa2 - sina1 * sina1);
    radius = sin(a1) * coeff; // Radius of the circle C used for inversion.
    center = vec2(cos(a2) * coeff, 0.); // Center of the circle C used for inversion.
}

// Implement Hyperbolic Tessellation.
// It does roughly the same thing as the shader below, but I've reassembled the formula.
// "Poincare Disk" by soma_arc.
// https://www.shadertoy.com/view/4tdSD4
vec2 tessellate(in vec2 p, in float a1, in float a2, in float radius, in vec2 center){
    float p2 = dot(p,p);
    if(p2 > 1.){
        p /= p2; // Inversion about unit circle.
    }
    
    float da1 = a1 * 2.;
    float cosda1 = cos(da1);
    float sinda1 = sin(da1);
    float tana1 = tan(a1);
    float radius2 = radius * radius;
    
    for(int j=0; j<40; j++){
        vec2 ctop = p - center;
        float ctop2 = dot(ctop, ctop);
        
        if(p.y > tana1 * p.x){
            p *= mat2(cosda1, sinda1, sinda1, -cosda1); // Inversion about line L1.
        } else if(p.y < 0.){
            p.y = -p.y; // Inversion about line L2.
        } else if(ctop2 < radius2){
            p = ctop * radius2 / ctop2 + center; // Inversion about circle C.
        } else {
            break;
        }
    }
    
    return p;
}

// HSV to RGB
vec3 hsv(in float h, in float s, in float v){
    vec3 res = fract(h + vec3(0, 2, 1) / 3.) * 6. - 3.;
    res = abs(res) - 1.;
    res = clamp(res, 0., 1.);
    res = (res - 1.) * s + 1.;
    res *= v;
    
    return res;
}

// Camera path.
vec2 path(in float z){
    z /= layerInterval;
    
    int n1;
    int n2;
    float a1;
    float a2;
    float radius;
    vec2 center;
    
    float dis = 0.1;
    
    float ID = floor(z);
    getPatternNum(ID, n1, n2);
    prepare(n1, n2, a1, a2, radius, center);
    vec2 p0 = vec2(center.x - radius + dis, 0);
    p0 *= rotate2D(PI2 / float(n1) * floor(hash(ID*1.2) * float(n1)));
    
    ID += 1.;
    getPatternNum(ID, n1, n2);
    prepare(n1, n2, a1, a2, radius, center);
    vec2 p1 = vec2(center.x - radius + dis, 0);
    p1 *= rotate2D(PI2 / float(n1) * floor(hash(ID*1.2) * float(n1)));
    
    float f = fract(z);
    return mix(p0, p1, f*f*f*(6.*f*f-15.*f+10.));
}

// Height used for shading.
float getHeight(in vec2 p, in float radius, in vec2 center) {
    float tmp = length(p - center) - radius;
    return exp(-tmp * tmp * 60.);
}

// Raycasting and shading.
vec3 render(in vec3 ro, in vec3 rd){
    vec3 col = vec3(0);
    
    int n1;
    int n2;
    float ID;
    float t;
    float a1;
    float a2;
    float rotA;
    float radius;
    vec2 center;
    vec2 pt;
    vec3 rp;
    
    // Detect collision between ray and a plane cut out by a pattern.
    // Collision detection is performed in order from front to back.
    bool hit = false;
    for(int i=0; i<7; i++){
        float z = ro.z / layerInterval;
        float flz = floor(z);
        ID = flz - float(i);
        t = (ID * layerInterval - ro.z) / rd.z;
        rp = ro + t * rd;
        
        getPatternNum(ID, n1, n2);
        prepare(n1, n2, a1, a2, radius, center);
        
        float rotEase = flz + smoothstep(0.4, 0.6, fract(z));
        
        rotA = 0.;
        if(time > 76.0){
            float h1 = hash(ID*1.4 + flz);
            float h2 = hash(h1*500.);
            rotA += fract(rotEase / float(n1)) * PI2 * sign(h1 - 0.5) * ceil(h2 * float(n1));
        }
        
        pt = tessellate(rp.xy * rotate2D(rotA), a1, a2, radius, center);
        
        if(length(pt - center) < radius + 0.03){
            hit = true;
            break;
        }
    }
    
    // Perform shading.
    if(hit){
        float ho = getHeight(pt, radius, center);
        
        vec2 eps = vec2(0.001, 0);
        pt = tessellate((rp.xy + eps.xy) * rotate2D(rotA), a1, a2, radius, center);
        float hx = getHeight(pt, radius, center);
        pt = tessellate((rp.xy + eps.yx) * rotate2D(rotA), a1, a2, radius, center);
        float hy = getHeight(pt, radius, center);
        
        vec3 normal = normalize(vec3(-(hx - ho)/eps.x, -(hy - ho)/eps.x, 1.));
        
        float diff = max(dot(normal, lightDir), 0.);
        float spec = pow(max(dot(reflect(lightDir, normal), rd), 0.), 20.);
        float metal = 0.6;
        float lightPwr = 8.;
        float amb = 0.5;
        
        col = hsv(ID * PI * 0.5, 0.7, 1.);
        col *= diff * (1. - metal) * lightPwr + spec * metal * lightPwr + amb;
    }
    
    float tmp = t / layerInterval;
    col = mix(background, col, exp(-tmp * tmp * 0.2));
    
    return col;
}

void main(void)
{ 
    vec3 col = vec3(0);
    
    if(time > 57.5){
        background += pow(sin(time * BPM / 60. * PI) * 0.5 + 0.5, 20.);
    }
    
    // Refference: "Hexagonal Grid Traversal - 3D" by iq
    // https://www.shadertoy.com/view/WtSfWK
    for(int m=0; m<AA; m++){
        for(int n=0; n<AA; n++){
            vec2 of = vec2(m, n) / float(AA) - 0.5;
            vec2 uv = ((gl_FragCoord.xy + of) * 2. - resolution.xy) / min(resolution.x, resolution.y);
            
            float time = time;
            float T = smoothstep(0., 10., time);
            float h;
            
            // Motion Blur.
            #if AA > 1
            h = hash(dot(gl_FragCoord.xy, vec2(8.2365 + float(m), 9.2742 + float(n))) * 1.3783 + time);
            time += h * mix(0.5, 0.02, T);
            #endif
            
            vec3 ro = vec3(0, 0, -time * layerInterval * BPM / 60. * 0.5);
            
            float T2 = smoothstep(38., 39.5, time);
            ro.xy = mix(vec2(0), path(ro.z), T2);
            vec3 ta = vec3(path(ro.z - layerInterval * 0.1), ro.z - layerInterval * 0.5);
            vec3 dir = mix(vec3(0, 0, -1), normalize(ta - ro), T2);
            
            vec3 side = normalize(cross(dir, vec3(vec2(0, 1) * rotate2D(ro.y * 2.0 + ro.z * 0.1), 0)));
            vec3 up = normalize(cross(side, dir));
            vec3 rd = normalize(uv.x * side + uv.y * up + dir * (2.125 - length(uv) * 0.25));
            
            // DOF.
            #if AA > 1
            vec3 fp = ro + rd * 1.0;
            h = hash(dot(gl_FragCoord.xy, vec2(3.23481 + float(m), 5.57264 + float(n))) * 1.2253 + time);
            ro.xy += (vec2(h, hash(h*500.)) - 0.5) * mix(0.5, 0.02, T);
            rd = normalize(fp - ro);
            #endif
            
            col += render(ro, rd);
        }
    }
    col /= float(AA*AA);
    
    // Tone mapping.
    //float l=3.;
    //col = col / (1.+col) * (1.+col/l/l);
    
    // Gamma.
    col = pow(col, vec3(1.0 / 2.2));
    
    // Vignetting.
    vec2 p = gl_FragCoord.xy/resolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * p.x * p.y * (1.0 - p.x) * (1.0 - p.y), 0.5);
    
    glFragColor = vec4(col, 1.0);
}
