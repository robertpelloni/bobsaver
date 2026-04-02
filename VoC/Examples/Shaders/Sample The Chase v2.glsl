#version 420

// original https://www.shadertoy.com/view/XscBDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 target;

// Hash and noise from iq
float hash(vec3 p){
    p  = fract(p*0.3183099+.1);
    p *= 17.0;
    return fract(p.x*p.y*p.z*(p.x+p.y+p.z));
}

float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix(hash(p+vec3(0,0,0)), 
                       hash(p+vec3(1,0,0)),f.x),
                   mix(hash(p+vec3(0,1,0)), 
                       hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash(p+vec3(0,0,1)), 
                       hash(p+vec3(1,0,1)),f.x),
                   mix(hash(p+vec3(0,1,1)), 
                       hash(p+vec3(1,1,1)),f.x),f.y),f.z)-0.5;
}

float turb(vec3 uvw) {
    float c = 0.0;
//    int i;
    float s1 = 2.0;
    float s2 = 1.0;
    float t = 0.0;
    for (int i = 0; i < 7; ++i) {
        c += s2*noise(s1*uvw);
        //c += s2*noise1(s1*uv);
        t += s2;
        s1 *= 2.0;
        s2 *= 1.0;
    }
    return c/t;
}

float concrete(vec3 uvw) {
    float d = turb(1.0*uvw+vec3(23.45, 763.1, -123.2));
    float c = 0.1+0.26*smoothstep(-0.4, 0.4, d);

    d = turb(1.0*uvw+vec3(-13.12, 1245.0, 12.11));
    c += -0.1*smoothstep(0.0, 0.1, d);

    //d = turb(40.0*uv+vec2(12.0, 152.11));
    //c += d > 0.2 ? 0.1 : 0.0;

    return 0.5+1.0*c;
}
float theTime = 0.0;

mat4 translate(vec3 p) {
    return mat4(1.0,  0.0,  0.0,  -p.x,
              0.0,  1.0,  0.0,  -p.y,
              0.0,  0.0,  1.0,  -p.z,
              0.0, 0.0, 0.0, 1.0);
}

mat4 scale(vec3 s) {
    return mat4(s.x,  0.0,  0.0,  0.0,
              0.0,  s.y,  0.0,  0.0,
              0.0,  0.0,  s.z,  0.0,
              0.0, 0.0, 0.0, 1.0);
}

mat4 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(c,  -s,  0.0,  0.0,
              s,  c,  0.0,  0.0,
              0.0,  0.0,  1.0,  0.0,
              0.0, 0.0, 0.0, 1.0);
}

mat4 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(c,  0.0, s,  0.0,
              0.0,  1.0, 0.0, 0.0,
              -s,  0.0, c,  0.0,
              0.0, 0.0, 0.0, 1.0);
}

mat4 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat4(1.0, 0.0, 0.0, 0.0,
                0.0, c,  -s,  0.0, 
                0.0, s,  c,  0.0,
                0.0,  0.0,  0.0,  1.0);
}

// Assume n normalised
vec3 fold(vec3 n, vec3 x) {
    float nx = dot(n, x);
    return nx >= 0.0 ? x : x-2.0*nx*n;
}

vec4 myreflect(vec3 n, vec3 p, vec4 x) {
    vec3 xyz = x.xyz-p;
    n = normalize(n);
    float nx = dot(n, xyz);
    vec4 nn;
    nn.xyz = p+(nx >= 0.0 ? xyz : xyz-2.0*nx*n);
    nn.w = 2.0*x.w+(nx >= 0.0 ? 1.0 : 0.0);
    return nn;
}

float cube(vec3 x) {
    //return length(x)-0.9;
    return max(x.z,max(-x.z,max(x.y,max(-x.y,max(x.x, -x.x)))))-1.25;
}

float sphere(vec3 x) {
    return length(x)-0.2;
}

#if 0
float h(vec3 x) {
    mat4 m = rotateZ(0.2101*theTime-3.128)*rotateY(0.1311*theTime+1.234);
    return g((vec4(x, 1.0)*m).xyz);
}
#endif

vec2 xy;

// {{1., 0., 0.}, {0., -1., 0.}, {0.809017, 0.5, -0.309017}}
//vec3 pc = vec3(1.95, -0.82, -0.94);
//vec3 pc = vec3(0.80, 0.5, -0.3);
vec3 pc = vec3(0.809017, 0.5, -0.309017);

vec3 dodecafold(vec3 x) {
    x.xy = -abs(x.xy);
    x = fold(pc, x);
    x.xy = -abs(x.xy);
    x = fold(pc, x);
    x.xy = -abs(x.xy);
    x = fold(pc, x);
    x.xy = -abs(x.xy);
    x = fold(pc, x);
    x.xy = -abs(x.xy);
    x = fold(pc, x);

    return x;
}

vec3 cv(int i) {
    if (i== 0) return vec3(-3.75, -3.2, -18.0);
    if (i== 1) return vec3(-4.25, -1.6, -14.0);
    if (i== 2) return vec3(-5.0, -0.8, -10.0);
    if (i== 3) return vec3(-3.0, 0.0, -9.0);
    if (i== 4) return vec3(-4.0, 0.0, -10.0);
    if (i== 5) return vec3(-10.0, 1.0, -8.0);
    if (i== 6) return vec3(-10.0, 2.0, -5.0);
    if (i== 7) return vec3(-10.0, 4.1, -2.0);
    if (i== 8) return vec3(-9.0, 6.0, 0.3);
    if (i== 9) return vec3(-7.5, 7.0, 0.7);
    if (i== 10) return vec3(-6.0, 6.0, -2.0);
    if (i== 11) return vec3(-3.5, 6.5, -5.0);//
    if (i== 12) return vec3(-4.6, 8.0, -6.0);//
    if (i== 13) return vec3(-3.9, 6.2, -7.0);
    if (i== 14) return vec3(-3.3, 7.5, -8.2);//beam
    if (i== 15) return vec3(-4.9, 6.1, -7.0);//step
    if (i== 16) return vec3(-2.5, 3.2, -12.0);
    if (i== 17) return vec3(-1.5, -1.0, -22.0);
    if (i== 18) return vec3(0.5, -4.0, -21.0);
    if (i== 19) return vec3(-2.5, -6.0, -21.0);
    if (i== 20) return vec3(-2.3, -8.0, -19.0);
    if (i== 21) return vec3(-3.0, -10.0, -20.0);
    if (i== 22) return vec3(-4.0, -11.0, -21.0);
    if (i== 23) return vec3(-2.0, -12.0, -19.0);
    if (i== 24) return vec3(-4.0, -6.6, -18.0);
}

#define N 25
vec3 path(float t) {
//    vec3 pos[N];
//    pos[0] = vec3(-3.75, -3.2, -18.0);
//    pos[1] = vec3(-4.25, -1.6, -14.0);
//    pos[2] = vec3(-5.0, -0.8, -10.0);
//    pos[3] = vec3(-3.0, 0.0, -9.0);
//    pos[4] = vec3(-4.0, 0.0, -10.0);
//    pos[5] = vec3(-10.0, 1.0, -8.0);
//    pos[6] = vec3(-10.0, 2.0, -5.0);
//    pos[7] = vec3(-10.0, 4.1, -2.0);
//    pos[8] = vec3(-9.0, 6.0, 0.3);
//    pos[9] = vec3(-7.5, 7.0, 0.7);
//    pos[10] = vec3(-6.0, 6.0, -2.0);
//    pos[11] = vec3(-3.5, 6.5, -5.0);//
//    pos[12] = vec3(-4.6, 8.0, -6.0);//
//    pos[13] = vec3(-3.9, 6.2, -7.0);
//    pos[14] = vec3(-3.3, 7.5, -8.2);//beam
//    pos[15] = vec3(-4.9, 6.1, -7.0);//step
//    pos[16] = vec3(-2.5, 3.2, -12.0);
//    pos[17] = vec3(-1.5, -1.0, -22.0);
//    pos[18] = vec3(0.5, -4.0, -21.0);
//    pos[19] = vec3(-2.5, -6.0, -21.0);
//    pos[20] = vec3(-2.3, -8.0, -19.0);
//    pos[21] = vec3(-3.0, -10.0, -20.0);
//    pos[22] = vec3(-4.0, -11.0, -21.0);
//    pos[23] = vec3(-2.0, -12.0, -19.0);
//    pos[24] = vec3(-4.0, -6.6, -18.0);
    //pos[0] = vec3(-3.75, -3.2, -18.0);

    int it = int(floor(t));
    it = it-N*(it/N);
//    while (it >= N) {
//        it -= N;
//    }
    float ft = fract(t);
    vec3 qos0 = cv(it);
    ++it;
    if (it >= N) {
        it = 0;
    }
    vec3 qos1 = cv(it);
    ++it;
    if (it >= N) {
        it = 0;
    }
    vec3 qos2 = cv(it);
    ++it;
    if (it >= N) {
        it = 0;
    }
    vec3 qos3 = cv(it);
    vec3 pos0 = 2.0*qos1;
    vec3 pos1 = -0.333333*qos0+2.0*qos1+0.333333*qos2;
    vec3 pos2 = 0.333333*qos1+2.0*qos2-0.333333*qos3;
    vec3 pos3 = 2.0*qos2;
    pos0 = mix(pos0, pos1, ft);
    pos1 = mix(pos1, pos2, ft);
    pos2 = mix(pos2, pos3, ft);
    pos0 = mix(pos0, pos1, ft);
    pos1 = mix(pos1, pos2, ft);
    pos0 = mix(pos0, pos1, ft);
    return pos0;
}

vec4 scene(vec3 x0) {
    vec4 x = vec4(x0, 0.0);
    x = myreflect(vec3(0.0, 1.0,2.00), vec3(0.0, -26.00, -26.25), x);
    x = myreflect(vec3(1.0, 0.0,1.00), vec3(-21.0, 0.00, -26.50), x);
    x = myreflect(vec3(1.0, 1.0,0.00), vec3(-33.0, 0.00, 0.00), x);
    x = myreflect(vec3(0.0, -1.0,0.00), vec3(0.0, 20.00, 0.00), x);
    x = myreflect(vec3(0.0, 1.0,0.00), vec3(0.0, -25.00, 0.00), x);
    x = myreflect(vec3(-1.0, 0.0,0.00), vec3(18.0, 0.00, 0.00), x);
    x = myreflect(vec3(1.0, 1.0,0.00), vec3(-9.0, -19.00, 0.00), x);
    x = myreflect(vec3(0.0, 0.0, 1.00), vec3(0.0, 0.00, -35.00), x);
    x = myreflect(vec3(0.0, 1.0, 1.00), vec3(5.0, 5.00, -11.00), x);
    x = myreflect(vec3(1.0, 0.0, -1.00), vec3(-3.0, 5.00, 11.00), x);
    x = myreflect(vec3(0.0, 1.0, -1.00), vec3(-2.0, 6.00, 8.00), x);
    x = myreflect(vec3(1.0, -1.0, 0.00), vec3(-4.0, 21.00, -8.00), x);
    x = myreflect(vec3(1.0, 0.0, 0.00), vec3(-4.0, 12.00, -10.00), x);
    x = myreflect(vec3(0.0, 0.0, 1.00), vec3(4.0, 10.00, -8.00), x);
    x = myreflect(vec3(1.0, 0.0, 1.00), vec3(-1.0, 8.00, -2.00), x);
    x = myreflect(vec3(0.0, 1.0, 1.00), vec3(8.0, -10.00, 4.00), x);
    x = myreflect(vec3(1.0, -1.0, 0.00), vec3(-6.0, 4.00, 1.00), x);
    x = myreflect(vec3(0.0, -1.0, 0.00), vec3(2.0, 1.00, 3.00), x);
    x = myreflect(vec3(0.0, -1.0, 1.00), vec3(4.0, 0.00, 0.00), x);
    x = myreflect(vec3(1.00, 0.0, 1.0), vec3(-2.00, 5.0, -6.00), x);
    x = myreflect(vec3(0.0, 1.00, 1.0), vec3(1.0, -4.0, -4.0), x);
    x = myreflect(vec3(1.0, 1.0, 0.0), vec3(-5.00, -1.0, -1.0), x);
    x = myreflect(vec3(1.0, -1.0, 0.0), vec3(-7.0, -4.0, 8.0), x);
    x = myreflect(vec3(-1.0, 1.0, 0.0), vec3(0.0, -3.0, 2.0), x);
    x = myreflect(vec3(-1.0, 0.0, 1.0), vec3(7.0, -5.0, 4.00), x);
    x = myreflect(vec3(-1.0, 1.0, 0.0), vec3(1.0, -0.0, -2.0), x);
    x = myreflect(vec3(1.0, 1.0, 0.0), vec3(6.0, -8.0, 0.0), x);
    x = myreflect(vec3(0.0, 1.0, 0.0), vec3(-1.0, -4.0, -1.0), x);
    x = myreflect(vec3(0.0, 1.0, 1.0), vec3(1.0, -5.0, -3.0), x);
    x = myreflect(vec3(0.0, -1.0, 1.0), vec3(2.0, 3.0, 0.0), x);
    x = myreflect(vec3(1.0, 0.0, 1.0), vec3(1.0, -5.0, -3.0), x);
    x = rotateZ(theTime)*x;
    //x = rotateY(0.5*theTime)*x;

//    float d = cube(x.xyz);
//    for (int i = 0; i < 5; ++i) {
//        d = min(d, sphere(x0-path(theTime+0.5+0.5*i)));
//    }
//    return vec4(x.xyz, d);
    return vec4(x.xyz, min(cube(x.xyz), sphere(x0-target)));
    //return vec4(x.xyz, sphere(x0-target));
}

float eps = 0.0001;
float lambda = 2.0;

vec3 ico[12];

//vec3 hash3(vec3 x) {
//    float u = 1000.0*sin(x.x*x.y+3.3*x.z-2.2*x.y+10.123*x.y+11.12*x.y*x.z);
//    float v = 1000.0*sin(x.z*x.y-2.1*x.z+3.0*x.z+7.211*x.y+32.12*x.y*x.x);
//    float w = 1000.0*cos(x.z*x.y+3.4*x.z-3.0*x.x+17.97*x.y+11.12*x.x*x.y);
//    return vec3(u-floor(u), v-floor(v), w-floor(w));
//}

float lighting(vec3 x, vec3 n) {
    float t = 0.0;
    for (int i = 0; i < 12; ++i) {
        //float p = scene(x-0.05*n+0.10*ico[i]);
        //t += 0.8+10.0*p;
        vec3 dd = ico[i];//faceforwrd(ico[i], ico[i], n);
        float p = scene(x+1.0*n+2.0*dd).w;
        t += 0.5*p;
    }
    return t/12.0-0.5;
}

mat4 view() {
    return rotateY(0.25*theTime)*rotateX(0.00*theTime);
}

vec3 march(vec3 p, vec3 d) {
    float c;
    c = scene(p).w;
    if (c < 0.0) {
        return vec3(0.0, 0.0, 0.0);
    }
    for (int i = 0; i < 100; ++i) {
        float step = max(0.004, c);
        p = p+step*d;
        vec4 ff = scene(p);
        vec3 x = ff.xyz;
        c = ff.w;
        if (c <= 0.0) {
            float ex, ey, ez;
            ex = scene(p+vec3(eps, 0.0, 0.0)).w;
            ey = scene(p+vec3(0.0, eps, 0.0)).w;
            ez = scene(p+vec3(0.0, 0.0, eps)).w;
            vec3 n = vec3(ex-c, ey-c, ez-c)/eps;
            n = normalize(n);
            mat4 m = view();
            vec3 light = (vec4(1.0,1.0,-1.0,1.0)*m).xyz;
            float l0 = 0.25+0.75*max(dot(n, light)/sqrt(3.0), 0.0);
            float l1 = 0.75*lighting(p, n);
            float s = concrete(0.5*p);
//            float l3 = 1.0+min(1.0/length(p-target),2.0);
            //return 2.5*s*(0.1+0.7*l0+0.7*l1)*vec3(0.74, 0.72, 0.7);
            return 1.1*s*(0.3+0.5*l0+0.7*l1)*vec3(1.61, 1.36, 1.27);
        }
    }
    return vec3(0.0, 0.0, 0.0);
}

mat3 complete(vec3 y, vec3 z) {
    vec3 x = normalize(cross(y, z));
    y = normalize(cross(z, x));
    return mat3(x, y, z);
}

void main(void) {
    theTime = 0.5*time;
    pc = normalize(pc);

    ico[0] = vec3(-0.26286500, 0.0000000, 0.42532500);
    ico[1] = vec3(0.26286500, 0.0000000, 0.42532500);
    ico[2] = vec3(-0.26286500, 0.0000000, -0.42532500);
    ico[3] = vec3(0.26286500, 0.0000000, -0.42532500);
    ico[4] = vec3(0.0000000, 0.42532500, 0.26286500);
    ico[5] = vec3(0.0000000, 0.42532500, -0.26286500);
    ico[6] = vec3(0.0000000, -0.42532500, 0.26286500);
    ico[7] = vec3(0.0000000, -0.42532500, -0.26286500);
    ico[8] = vec3(0.42532500, 0.26286500, 0.0000000);
    ico[9] = vec3(-0.42532500, 0.26286500, 0.0000000);
    ico[10] = vec3(0.42532500, -0.26286500, 0.0000000);
    ico[11] = vec3(-0.42532500, -0.26286500, 0.0000000);    
    
    vec2 uv = gl_FragCoord.xy-0.5*resolution.xy;
    uv = 2.0*uv/resolution.y;
    xy = mouse*resolution.xy.xy/resolution.xy;

//    theTime = N*xy.x;
//    theTime = 13.7;
//    theTime = 14+mod(theTime, 4.0);

    vec3 p = path(theTime);//ec3(-4.0, 0.0, -41.0);
    vec3 z = normalize(path(theTime+0.5)-p);
    mat3 m = complete(vec3(0.0, 1.0, 0.0), z);
    vec3 d = normalize(vec3(0.5*uv, 0.75));
    target = path(theTime+0.5);
    d = m*d;
    //mat4 m = view();
    //p = (m*vec4(p, 1.0)).xyz;
    //d = (m*vec4(d, 1.0)).xyz;
    vec3 color = march(p, d);
    glFragColor = vec4(color, 1.0);
}

