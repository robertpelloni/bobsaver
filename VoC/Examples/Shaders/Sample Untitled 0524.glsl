#version 420

// original https://neort.io/art/bpd26pk3p9f4nmb8bceg

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

#define R resolution
#define T time
#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define pmod(p,n) mod(p,n)-n*.5

float df(vec3 p){
    vec3 q = abs(p) - vec3(.01, .22, .01);
    return length(max(q,0.)) + min(max(q.x,max(q.y,q.z)),0.);
}

float map(vec3 p){
    p.xz *= rot(p.y*10.);
    float d = df(p);
    p.xz *= rot(-p.y*10.);
    
    for(int i = 0; i < 20; i++){
        p = abs(p);
        p.xz -= .4;
        p.xy *= rot(.2);
        p.zy *= rot(.4);
        p.xz *= rot(p.y*10.);
        d = min(d, df(p));
        p.xz *= rot(-p.y*10.);
    }
    
    return d;
}

vec3 norm(vec3 p){
    vec2 e = vec2(.001, 0.);
    float d = map(p);
    return normalize(vec3(d-map(p-e.xyy),d-map(p-e.yxy),d-map(p-e.yyx)));
}

void main(){
    vec2 p = (gl_FragCoord.xy*2.-R)/max(R.x,R.y);
    vec3 cp = vec3(sin(T*.51),sin(T*.31)*.2,cos(T*.23)*.8), ct = vec3(0.,sin(T*.17),0.), cf = normalize(ct-cp),
        cu = vec3(0.,1.,0.), cl = normalize(cross(cu,cf));
        cu = normalize(cross(cf,cl));
    vec3 ray = normalize(p.x*cl+p.y*cu+cf),
        bc = vec3(.8,.9,1.)+(1.-length(p))*.5, c = bc, rp, lc = vec3(.8, .9, 1.);
    float d, t = 0.;
    
    for(int i = 0; i < 64; i++){
        rp = cp + t*ray;
        d = map(rp) * .5;
        t += min(min((step(0.,ray.x)-fract(rp.x))/ray.x,(step(0.,ray.z)-fract(rp.z))/ray.z)+.01,d);
        if(d < .001){
            vec3 no = norm(rp), lp1 = vec3(-3.,3.,-3.), lp2 = vec3(3.,3.,3.),
                ld1 = normalize(lp1-rp), ld2 = normalize(lp2-rp);
            float dif1 = max(dot(no,ld1),0.);
            float dif2 = max(dot(no,ld2),0.);
            float spe1 = pow(max(dot(-ray,reflect(-ld1,no)),0.),8.)*.6;
            float spe2 = pow(max(dot(-ray,reflect(-ld2,no)),0.),8.)*.6;
            c = lc * (dif1+dif2) + (spe1+spe2)*.5 + vec3(.1) + bc*t*.1;
            break;
        }
    }

    glFragColor = vec4(c, 1.);
}
