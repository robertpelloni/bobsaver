#version 420

// original https://neort.io/art/bpbc70s3p9f4nmb8b000

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

#define R resolution
#define T time

#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))
#define pmod(p,x) mod(p,x) - x*.5

float df(vec3 p) {
    float k = 4.;
    
    p.z = pmod(p.z, k);
    p.xy -= 2.;
    p.xy = pmod(p.xy, 4.);
    vec4 q = vec4(p.xyz, 1.);
    vec4 c = vec4(1., 1., 1., .1);
    vec4 u = vec4(.1, 1., 1., 1.);
    for(int i = 0; i < 2; i++){
        q.xyz = abs(q.xyz) - c.xyz;
        float dpp = dot(q.xyz, q.xyz);
        q = q*(1.3 + u)/clamp(dpp, .5, 1.) - mix(q, c, 1.);
        q.xy *= rot(1.);
    }
    q.xyz = abs(q.xyz);
    q.xz *= rot(.2);
    float d = max(q.x - 0., max(q.y - 3., q.z - 3.))/q.w;

    return d*.5;
}

float map(vec3 p) {
    p.z -= T*3. ;
    
    float o = df(p);
    return o;
}

vec3 norm(vec3 p) {
    vec2 e = vec2(.001, 0.);
    float d = map(p);
    return normalize(vec3(d-map(p-e.xyy),d-map(p-e.yxy),d-map(p-e.yyx)));
}

void main() {
    vec2 p = (gl_FragCoord.xy*2.-R)/max(R.x,R.y);
    
    vec3 cp = vec3(sin(T),cos(T),sin(T*.3)*2. - 1.), ct = vec3(0.,0.,0.), cf = normalize(ct-cp),
        cu = vec3(0.,1.,0.), cl = normalize(cross(cu,cf)); cu = normalize(cross(cf,cl));
    vec3 ray = normalize(p.x*cl+p.y*cu+cf), c = vec3(0.,.05,.1);
    float d, t = 0.;
    
    for(int i = 0; i < 128; i++){
        vec3 rp = cp + t*ray;
        d = map(rp);
        t += min(min((step(0.,ray.x)-fract(rp.x))/ray.x,(step(0.,ray.z)-fract(rp.z))/ray.z)+.01,d);
        if(d < .001){
            vec3 no = norm(rp), lp = vec3(0.,0.,-1.), ld = normalize(lp-rp);
            float dif = max(dot(no,ld),0.);
            float spe = pow(max(dot(-ray,reflect(-ld,no)),0.),8.)*.3;
            c = vec3(.9, .95, 1.) * dif + spe + c*.2 - t*.1;
            break;
        }
    }
    
    glFragColor = vec4(c,1.);
}
