#version 420

// original https://www.shadertoy.com/view/WlBBzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'Squishy donut cat'
//
// My daughter made a sketch of a 'squishy' in a donut.
// A few hours later, a new shader is born.
// 
// Based on my 'Blender donut'
// https://www.shadertoy.com/view/ttfyWB
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane
// and a bunch of others for sharing their knowledge!

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(123.45, 875.43))) * 5432.3);
}

// Thanks Shane - https://www.shadertoy.com/view/lstGRB
float noise(vec3 p) {
    const vec3 s = vec3(7.0, 157.0, 113.0);
    vec3 ip = floor(p);
    vec4 h = vec4(0.0, s.yz, s.y + s.z) + dot(ip, s);
    p -= ip;
    
    h = mix(fract(sin(h) * 43758.5453), fract(sin(h + s.x) * 43758.5453), p.x);
    
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float fbm(vec3 p) {
    return (noise(p) + noise((p + 0.2) * 1.98) * 0.5 + noise((p + 0.66) * 4.12) * 0.25) / 1.75;
}

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float sdTorus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q) - t.y;
}

float sdCapsule(vec3 p, float h, float r) {
  p.z -= clamp(p.z, 0.0, h);
  return length(p) - r;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
  vec3 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h) - r;
}

float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb) {
  p.x = abs(p.x);
  float k = (sc.y * p.x > sc.x * p.y) ? dot(p.xy, sc) : length(p.xy);
  return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}

vec3 getRayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);
    return normalize(forward + right * uv.x + up * uv.y);
}

vec2 min2(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 sdDonut(vec3 p) {
    return vec2(sdTorus(p, vec2(4.0, 1.4)), 1.5);
}

float fbmc;
vec2 sdCream(vec3 p) {
    float d = abs(p.y + fbmc + 0.7) - 2.3;
    return vec2(max(sdDonut(p).x, -d) - 0.13, 2.5);
}

vec2 sdSprinkles(vec3 p) {
    float dd = sdCream(p - vec3(0.0, 0.05, 0.0)).x;
    
    vec3 id = floor(p / 0.3);
    
    mat2 r = rot(noise(id) * 3.141);
    p.xz *= r;
    p.xy *= r;
    p.xz *= r;
    
    p = mod(p, 0.3) - 0.15;
    
    p.xz *= r;
    p.xy *= r;
    p.xz *= r;
    float d = max(sdCapsule(p, 0.3, 0.02), dd);
    
    return vec2(d, mod(id.x, 6.0) + mod(id.y, 6.0) + mod(id.z, 6.0) + 10.5);
}

vec2 map(vec3 p) {
    fbmc = fbm(p * 0.6) * 2.0;
    vec2 d = sdDonut(p) - fbm(p * 8.0) * 0.02;
    d = min2(d, sdCream(p));
    d = min2(d, sdSprinkles(p));
    d = min2(d, vec2(p.y + 1.7, 3.5));
    
    vec3 mp = p;
    mp.x = abs(mp.x);
    
    // Paws.
    vec2 cat = vec2(length(mp - vec3(1.3, 1.4, -3.96)) - 0.2, 7.5);
    cat = min2(cat, vec2(length(mp - vec3(1.5, 1.4, -4.00)) - 0.2, 7.5));
    cat = min2(cat, vec2(length(mp - vec3(1.7, 1.45, -3.86)) - 0.2, 7.5));
    cat = min2(cat, vec2(length(mp - vec3(1.5, 1.3, -3.5)) - 0.6, 6.5));

    // Body
    mp.y += (sin(time)+0.33*sin(time * 3.0)) * 0.5;
    cat = min2(cat, vec2(sdCapsule(mp.xzy, 1.6, 3.0), 6.5));
    
    // Eyes.
    cat = min2(cat, vec2(length(mp - vec3(0.8, 2.4, -2.3)) - 0.7, 5.5));
    
    // Ears.
    vec3 ep = mp;
    ep.xz *= rot(-0.5 + sin(time * 2.0) * 0.1);
    float ear = length(ep - vec3(2.0, 4.0, 0.0)) - 0.8;
    ear = max(ear, -ep.z);
    cat.x = smin(cat.x, ear, 0.3);
    
    // Nose.
    vec3 np = mp - vec3(0.0, 1.9, -2.9);
    float nose = sdCapsule(np, vec3(0.0), vec3(0.16, 0.16, 0.0), 0.15);
    nose = smin(nose, sdCapsule(np * vec3(-1.0, 1.0, 1.0), vec3(0.0), vec3(0.16, 0.16, 0.0), 0.15), 0.05);
    cat = min2(cat, vec2(nose, 2.5));
    
    // Mouth.
    np.x = abs(np.x);
    np -= vec3(0.2, -0.1, -0.1);
    float mouth = sdCappedTorus(np, vec2(-1.0, 0.0), 0.2, 0.05);
    cat = min2(cat, vec2(mouth, 8.5));
    
    return min2(d, cat);
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(0.00005, -0.00005);
    return normalize(e.xyy * map(p + e.xyy).x + 
                     e.yyx * map(p + e.yyx).x + 
                     e.yxy * map(p + e.yxy).x + 
                     e.xxx * map(p + e.xxx).x);
}

float calcShadow(vec3 p, vec3 lightPos, float sharpness) {
    vec3 rd = normalize(lightPos - p);
    
    float h;
    float minH = 1.0;
    float d = 0.7;
    for (int i = 0; i < 16; i++) {
        h = map(p + rd * d).x;
        minH = abs(h / d);
        if (minH < 0.01)
            return 0.0;
        d += h;
    }
    
    return minH * sharpness;
}

float calcOcc(vec3 p, vec3 n, float strength) {
    const float dist = 0.3;
    return 1.0 - (dist - map(p + n * dist).x) * strength;
}

/**********************************************************************************/

vec3 vignette(vec3 col) {
    vec2 q = gl_FragCoord.xy / resolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.4);
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec3 col;

    // Raymarch.
    vec3 ro = vec3(sin(time * 0.3) * 2.0, 4.0 + cos(time * 0.6) * 0.5, -12.0);
    vec3 rd = getRayDir(ro, vec3(0.0, 1.0, 0.0), uv);

    int hit = 0;
    float d = 0.01;
    vec3 p;
    for (float steps = 0.0; steps < 128.0; steps++) {
        p = ro + rd * d;
        vec2 h = map(p);

        if (h.x < 0.001) {
            hit = int(h.y);
            break;
        }

        d += h.x;
    }

    if (hit > 0) {
        vec3 n = calcNormal(p);
        vec3 lightPos = vec3(10.0, 7.0, -10.0);
        vec3 lightCol = vec3(1.0, 0.9, 0.8);
        vec3 lightToPoint = normalize(lightPos - p);
        vec3 skyCol = vec3(0.15, 0.2, 0.25);
        float sha = calcShadow(p, lightPos, 5.0);
        float occ = calcOcc(p, n, 4.0);
        float spe = pow(max(0.0, dot(rd, reflect(lightToPoint, n))), 15.0);
        float mainLight = max(0.0, dot(n, lightToPoint));
        float backLight = clamp(dot(n, -rd), 0.01, 1.0) * 0.1;
        vec3 skyLight = clamp(dot(n, vec3(0.0, 1.0, 0.0)), 0.01, 1.0) * 0.4 * skyCol;
        float fog = 1.0 - exp(-d * 0.03);

        vec3 mat;
        if (hit == 1) {
            // Donut.
            mat = vec3(0.5, 0.3, 0.2);
        } else if (hit == 2) {
            // Cream.
            mat = vec3(1.0, 0.43, 0.85);
        } else if (hit == 3) {
            // Plane.
            mat = vec3(0.53, 0.81, 0.94);
        } else if (hit == 4) {
            // Eyes - White
            mat = vec3(0.8);
        } else if (hit == 5 || hit == 8) {
            // Eyes - Black
            mat = vec3(0.0001);
        } else if (hit == 6) {
            // Cat
            mat = vec3(1.0, 1.0, 0.5);
        } else if (hit == 7) {
            // Paws.
            mat = vec3(0.4, 0.4, 0.2);
        } else if (hit >= 10) {
            // Sprinkles!
            vec3 c = vec3(float(hit)) + vec3(1.0, 2.0, 3.0);
            mat = sin(floor(c * 3.0) / 3.0);
        }

        col = (mainLight * sha + (spe + backLight) * occ) * lightCol;
        col += skyLight * occ;
        col *= mat;
        
        if (hit == 5)
            col += (pow(max(0.0, dot(rd, reflect(normalize(vec3(0.0, 6.0, -10.0) - p), n))), 15.0) +
                   pow(max(0.0, dot(rd, reflect(normalize(vec3(2.0, -5.0, -10.0) - p), n))), 45.0)) * 2.0;
        
        col = mix(col, skyCol, fog);
    } else {
        // Sky.
        col = vec3(0.15, 0.2, 0.25);
    }

    // Output to screen
    col = pow(col, vec3(0.4545)); // Gamma correction
    col = vignette(col); // Fade screen corners
    glFragColor = vec4(col, 1.0);
}
