#version 420

// original https://www.shadertoy.com/view/3tGXzz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float fbm(vec3 x) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100);
    for (int i = 0; i < 5; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void makeRoRd(in vec2 uv, out vec3 ro, out vec3 rd) {
    ro = vec3(0,0,-5);
    vec2 mou = (mouse*resolution.xy.xy/resolution.xy-.5) * 10.;
    vec3 lookat = vec3(mou,0);
    vec3 f = normalize(lookat-ro);
    float z = 1.;
    vec3 c = ro+f*z;
    vec3 r = cross(vec3(0,1,0), f);
    vec3 u = cross(f, r);
    vec3 i = c + uv.x * r + uv.y * u;
    rd = normalize(i-ro);
}

mat2 rot (float a) {
    return mat2(
        cos(a), sin(a),
        -sin(a), cos(a)
    );
}

float getDist(in vec3 p) {
    p.xz *= rot(time*.1);
    float wave = sin(time)*.05;
    float d2 = fbm(p)-.15 + wave;
    float t = 10.;
    float r = .1;
    return length(max(vec2(d2,abs(p.y)-t),0.0))-r;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(1.);

    vec3 ro,rd;
    makeRoRd(uv, ro, rd);
    col = rd;

    float t=0., step=0.;
    vec3 hitPos;
    for(int i=0; i<=100; i++) {
        vec3 p = ro+rd*t;
        float dS = getDist(p);

        if(dS<0.01) {
            hitPos = p;
            col.r = 1.;
            break;
        }
        if(t>100.) break;
        t += dS;
        step += 1./100.;
    }

    float m = pow(step, 2.0);

    col.rgb = vec3(m);

    
    glFragColor = vec4(col,1.0);
}
