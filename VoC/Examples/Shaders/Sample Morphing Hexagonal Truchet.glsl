#version 420

// original https://www.shadertoy.com/view/ssdyRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define AA 1
#define AA 2

#define saturate(x) clamp((x), 0., 1.)
const float PI = acos(-1.);
const float PI2 = acos(-1.) * 2.;

const vec2 vHex = normalize(vec2(1., sqrt(3.)));

//-----------------------------------------------------------
// "Hash without Sine" by Dave_Hoskins.
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
//-----------------------------------------------------------

// Rotation matrix in two dimensions.
mat2 rotate2D(in float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, s, -s, c);
}

// 2D perlin noise.
float perlin2D(in vec2 p) {
    vec2 l = vec2(1, 0);
    vec2 i = floor(p);
    vec2 f = fract(p);
    //vec2 u = f*f*f*(6.*f*f-15.*f+10.);
    vec2 u = f * f * (3. - 2. * f);
    
    return mix(mix(dot(f - l.yy, hash22(i + l.yy) - 0.5), dot(f - l.xy, hash22(i + l.xy) - 0.5), u.x),
               mix(dot(f - l.yx, hash22(i + l.yx) - 0.5), dot(f - l.xx, hash22(i + l.xx) - 0.5), u.x),
               u.y); // range : [-0.5, 0.5]
}

// Trasform HSV color to RGB.
vec3 hsv(in float h, in float s, in float v) {
    vec3 res = fract(h + vec3(0, 2, 1) / 3.) * 6. - 3.;
    res = saturate(abs(res) - 1.);
    res = (res - 1.) * s + 1.;
    res *= v;
    return res;
}

// Hexagonal tiling.
void hexTile(in vec2 p, out vec2 g, out vec2 ID) {
    vec2 h = vHex * 0.5;
    vec2 a = mod(p, vHex) - h;
    vec2 b = mod(p - h, vHex) - h;
    g = dot(a, a) < dot(b, b) ? a : b;
    ID = floor((p - g + 0.01) / h);
}

// Calculate height(z-value) from the floor.
float calcHeight(in vec2 p) {
    float res = 0.;
    
    vec2 g, ID;
    hexTile(p, g, ID);
    
    // Floor.
    vec2 gf = g;
    gf = abs(gf);
    float hh = max(gf.x, dot(gf, vHex)) / (vHex.x * 0.5);
    vec2 noisePos = vec2(p.x, p.y * 5.) * 15.;
    float noiseAmp = 0.003;
    
    // Floor Edge A.
    //res -= smoothstep(0.85, 0.95, hh) * 0.02;
    
    // Floor Edge B.
    /*float Rf = 0.1;
    if(hh > 1. - Rf) {
        float tmp = hh - (1. - Rf);
        float sqh = Rf * Rf - tmp * tmp;
        if(sqh > 0.) {
            res = sqrt(sqh) - Rf;
        }
    }*/
    
    // Floor Edge C.
    float edge0 = 0.8;
    float edge1 = 1.;
    float x = saturate((hh - edge0) / (edge1 - edge0));
    res -= pow(x, 10.) * 0.1;
    
    float T = time + hash12(ID);
    float Ra = vHex.y / 6.;
    
    // State 1.
    vec2 g1 = g;
    if(hash12(ID * 1.1 + floor(T)) < 0.5) {
        g1.y = -g1.y;
    }
    g1.x = abs(g.x);
    float d1 = abs(length(g1 - vec2(0, vHex.y / 3.)) - Ra);
    d1 = min(d1, abs(length(g1 - vec2(vHex.x * 0.5, -Ra)) - Ra));
    
    // State 2.
    vec2 g2 = g;
    g2 = g * rotate2D(floor(hash12(ID * 1.2 + floor(T + 0.5)) * 3.) * PI / 3.);
    g2.y = abs(g2.y);
    float d2 = g2.y;
    d2 = min(d2, abs(length(g2 - vec2(0, vHex.y / 3.)) - Ra));
    
    // Morphing.
    //float morph = smoothstep(-1.0, 1.0, sin((T + 0.25) * PI2));
    float s = 0.4;
    float morph = smoothstep(0.5 - s, 0.5 + s, abs(fract(T) - 0.5) * 2.);
    float d = mix(d1, d2, morph);
    
    // Object.
    float ra = vHex.y / 12.;
    float sqH = ra * ra - d * d;
    if(sqH > 0.) {
        res = sqrt(sqH);
        noisePos = p * 35.;
        noiseAmp = 0.01;
    }
    
    // Add noise.
    res += perlin2D(noisePos) * noiseAmp;
    
    return res;
}

vec3 calcColor(in vec2 p, in float h) {
    vec3 col = vec3(0);
    
    if(h < 0.005) { // Floor.
        vec2 g, ID;
        hexTile(p, g, ID);
        
        col = hsv(hash12(ID), 0.9, 1.);
    } else { // Object.
        col = vec3(1., 1., 1.);
    }
    
    return col;
}

vec3 render(in vec2 p) {
    vec3 col = vec3(0);
    
    vec2 q = p * 1. + time * 0.2;
    
    // Calculate normal using height(z-value) from the floor.
    float h = calcHeight(q);
    vec2 e = vec2(0.001, 0);
    vec3 normal = normalize(vec3(-(calcHeight(q + e.xy) - h) / e.x,
                                 -(calcHeight(q + e.yx) - h) / e.x,
                                 1.));
    
    //vec3 rd = normalize(vec3(p, -2));
    vec3 rd = vec3(0, 0, -1);
    //vec3 lightPos = vec3(vec2(0.5, 0.5) - p, 2);
    vec3 lightPos = vec3(-p, 2);
    lightPos.xy += sin(vec2(7, 9) * time * 0.2);
    vec3 lightDir = normalize(lightPos);
    
    vec3 al = calcColor(q, h);
    float diff = max(dot(normal, lightDir), 0.);
    float spec = pow(max(dot(reflect(lightDir, normal), rd), 0.), 40.);
    float lightPwr = 40. / dot(lightPos, lightPos);
    float amb = 0.;
    
    float metal;
    if(h < 0.005) {
        metal = 0.9;
    } else {
        metal = 0.7;
    }
    
    col += al * (((1. - metal) * diff + metal * spec) * lightPwr + amb);
    
    return col;
}

void main(void)
{
    vec3 col = vec3(0);
    
    for(int m = 0; m < AA; m++) {
        for(int n = 0; n < AA; n++) {
            vec2 of = vec2(m, n) / float(AA) - 0.5;
            vec2 p = ((gl_FragCoord.xy + of) * 2. - resolution.xy) / min(resolution.x, resolution.y);
            
            col += render(p);
        }
    }
    col /= float(AA * AA);
    
    // Tone mapping.
    float l = 3.;
    col = col / (1. + col) * (1. + col / l / l);
    
    // Gamma correction.
    col = pow(col, vec3(1. / 2.2));
    
    // Vignetting.
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.5);
    
    glFragColor = vec4(col, 1.);
}
