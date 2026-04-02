#version 420

// original https://www.shadertoy.com/view/XtlfzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 sundir = normalize(vec3(0.75, 0.21, -0.06));

float hash(vec3 x) {
    return fract(cos(dot(x, vec3(73.51, 27.13, -36.32))) * 3459.43) * 2.0 - 1.0;
}

float noise(vec3 x) {
    vec3 s = floor(x);
    vec3 t = fract(x);
    
    vec3 u = t * t * (3.0 - 2.0 * t);
    
    float a = hash(s + vec3(0.0, 0.0, 0.0));
    float b = hash(s + vec3(1.0, 0.0, 0.0));
    float c = hash(s + vec3(0.0, 1.0, 0.0));
    float d = hash(s + vec3(1.0, 1.0, 0.0));
    float e = hash(s + vec3(0.0, 0.0, 1.0));
    float f = hash(s + vec3(1.0, 0.0, 1.0));
    float g = hash(s + vec3(0.0, 1.0, 1.0));
    float h = hash(s + vec3(1.0, 1.0, 1.0));
    
    return mix(mix(mix(a, b, u.x), mix(c, d, u.x), u.y), 
                   mix(mix(e, f, u.x), mix(g, h, u.x), u.y), u.z);
    
}

float fbm(vec3 x) {
    
    float v = 0.0;
    float a = 1.0;
    for (int i = 0; i < 5; i++) {
           v += a * noise(x);
        a *= 0.5;
        x *= 2.0;
        x += 30.0;
       }
    return v;
}

float density(vec3 p) {
    return clamp(-p.y * 0.1 + 3.0 * fbm(p * 0.05 + 100.0 + time * 0.04), 0.0, 1.0);
}

vec4 map(vec3 p) {
    float d = density(p);
    vec3 c = mix(vec3(0.75), vec3(1.0), d);
    return vec4(c, d);
}

vec3 background(vec3 rd) {
    vec3 c =  mix(vec3(0.92, 0.89, 0.67), vec3(0.56, 0.15, 0.11), clamp(rd.y * 0.5 + 0.5, 0.0, 1.0));
    c += 0.3 * vec3(0.95, 0.72, 0.56) * pow(clamp(dot(rd, sundir), 0.0, 1.0), 4.0);
    return c;
}

float shadow(vec3 ro, vec3 rd) {
    float t = 0.0;
    float sum = 0.0;
    for (int i = 0; i < 3; i++) {
           vec3 p = ro + t * rd;
        sum += density(p);
        t += 1.0;
    }
    return clamp(sum / 3.0, 0.0, 1.0);
}

vec3 render(vec3 ro, vec3 rd) {
    
    float t = 0.0;
    vec4 sum = vec4(0.0);
    for (int i = 0; i < 30; i++) {
        if (sum.a > 0.99) break;
        vec3 p = ro + t * rd;
        vec4 res = map(p);
        float sh = shadow(p, sundir);
        vec3 c = res.rgb;
        vec3 lin = vec3(0.0);
        lin +=  0.7 * mix(vec3(1.53, 1.21, 1.01), vec3(0.82, 0.75, 0.62), shadow(p, sundir));
        lin += 0.3 * mix(vec3(1.4, 1.31, 1.07), vec3(0.83, 0.67, 0.72), shadow(p, vec3(0.0, 1.0, 0.0)));
        c *= lin;
        res.a *= 0.7;
        float a = (1.0 - sum.a) * res.a;
        sum += vec4(c * a, a);
        t += 4.0;
    }
    vec3 col = sum.rgb;
    
    col = mix(col, background(rd), 1.0 - pow(sum.a, 2.2));
    col += 0.15 * vec3(0.94, 0.32, 0.15) * pow(clamp(dot(rd, sundir), 0.0, 1.0), 32.0);
    
    col = sqrt(col);
    
    return col;
}

void main(void)
{
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    vec2 m = 3.14 * (mouse*resolution.xy.xy * 2.0 - resolution.xy) / resolution.xy;
    
    vec3 ro = vec3(0.0, 2.2, 0.0);
    vec3 ta = vec3(5.0 * cos(m.x), 1.8, 5.0 * sin(m.x));
    vec3 nz = normalize(ta - ro);
    vec3 nx = cross(nz, vec3(0.0, 1.0, 0.0));
    vec3 ny = cross(nx, nz);
    vec3 rd = normalize(nx * st.x + ny * st.y + nz * 1.0);
    
    vec3 col = render(ro, rd);
    
    glFragColor = vec4(col,1.0);
}
