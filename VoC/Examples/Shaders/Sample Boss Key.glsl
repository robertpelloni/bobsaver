#version 420

// original https://www.shadertoy.com/view/wdtSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, XT95, lsdlive, lamogui, Coyhot, Alkama and YX for teaching me
// Thanks LJ for giving me the love of shadercoding :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and others to sprout :)  https://twitter.com/CookieDemoparty

#define ITER 64.
#define time time 
#define PI 3.141592

#define circle(uv,r) smoothstep(0.13,0.1, length(uv)-r)
#define anim (2.*(mouse*resolution.xy.xy/resolution.xy)-1.)

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

void moda(inout vec2 p, float rep)
{
    float per = (2.*PI)/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    a = mod(a, per)-per*0.5;
    p = vec2(cos(a),sin(a))*l;
}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r, abs(p.z)-h);}

float key (vec3 p)
{
    vec3 pp = p;

    float c1 = cyl(p.xzy, 0.2-p.y*0.08, 1.);
    float c2 = cyl(p.xzy-vec3(0.,0.,0.7), 0.2,0.1);
    float c3 = cyl(p.xzy-vec3(0.,0.,0.96), 0.2,0.1);

    p.y -= 0.45;
    moda(p.xz, 4.);
    p.x -= 0.25;
    float c4 = cyl(p.yzx, 0.02-p.x*0.4, 0.2);

    p = pp;
    p.y += 0.45;
    p.y -= pow(max(0.,p.x),5.)*0.3;
    p.x -= 0.5;
    float c5 = cyl(p.yzx, 0.05-p.x*0.2, 0.55);
    p.y += 0.35;
    p.x -= 0.1;
    c5 = min(c5, cyl(p.yzx, 0.05-p.x*0.2, 0.55));

    p = pp;
    p.y -= 1.88;
    float c6 = max(abs(cyl(p, 0.7,1.))-0.1,abs(p.z)-0.21);

    p = pp;
    float cut_c = cyl(p-vec3(0.,1.7,0.), 0.77,2.);
    p.x = abs(p.x);
    p.y -= 1.8;
    p.x -= .8;

    p.xy *= rot(PI/8.);
    p.y -= pow(abs(p.x+0.2), 2.)*0.5;

    float c7 = max(-cut_c,cyl(p.yzx, 0.2-p.x*0.2, 1.));

    return min(c7,min(min(c5,c6),min(min(c3,c2),min(c1,c4))));
}

float center_key (vec3 p)
{
    p.y -= 1.8;
    return cyl(p, .65, 0.1);
}

int mat_id;
vec3 final_p;
float SDF (vec3 p)
{
    p.xz *= rot(time);
    p.xy *= rot(PI/4.);
    p.y += 0.8;
    final_p = p;
    float k = key(p);
    float ck = center_key(p);
    float d = min(k,ck);

    if(d == k) mat_id = 1;
    if(d == ck) mat_id = 2;

    return d;
}

vec3 getnorm (vec3 p)
{
    vec2 eps= vec2(0.01,0.);
    return normalize(SDF(p) - vec3(SDF(p-eps.xyy),SDF(p-eps.yxy),SDF(p-eps.yyx)) );
}

float lighting (vec3 n, vec3 l)
{return dot(n, normalize(l))*0.5+0.5;}

vec4 eye (vec2 uv)
{
    float spec_stain = circle(uv-vec2(.1),0.01);
    float pupil = clamp(circle(uv,0.05)-spec_stain,0.,1.);
    float iris = clamp(circle(uv, 0.2) - (spec_stain + pupil),0.,1.);
    float outer_ring = clamp(circle(uv, 0.3)-(iris+pupil + spec_stain),0.,1.);

    return vec4(spec_stain,pupil,iris,outer_ring);
}

vec3 eye_color (vec2 uv)
{
    vec4 e = eye(uv);
    return vec3(1.)*e.x +
        vec3 (0.)*e.y + 
        vec3(0.9,0.,0.)*e.z +
        vec3 (0.9,0.8,0.)*e.w+
        vec3 (0.5,0.2,0.7) * (1.-clamp(e.x+e.y+e.z+e.w,0.,1.));
}

// courtesy of Alkama
float pales (vec2 uv, float speed, float number)
{
    uv *= rot(-time*speed);
    return floor(smoothstep(0.1, 0.2,cos(atan(uv.y, uv.x)*number)));
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    vec3 ro = vec3(0.,0.,-6.),
        p = ro, 
        rd = normalize(vec3(uv,1.)),
        col = mix(vec3(0.1,0.5,0.1),vec3(0.7,0.8,0.5),pales(uv, 0.2, 5.))+pales(uv, -0.5, 10.)*0.3;

    float shad = 0.;
    bool hit = false;

    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.01)
        {
            hit = true;
            shad = i/ITER;
            break;
        }

        p += d*rd*0.5;
    }

    if (hit)
    {
        vec3 n = getnorm(p),
            l = normalize(vec3(5., 2., -4.)),
            h = normalize(l-rd);
        float spec = pow(abs(dot(n,h)), 25.);

        if (mat_id == 1) 
        {
            vec3 diffuse = mix(vec3(0.3,0.2,0.0), vec3(0.7,0.7,0.2),smoothstep(0.5,0.65,lighting(n,l)));

            float fre = pow(clamp(1.-abs(dot(-rd,n)),0.,1.), 2.);

            col = diffuse + vec3(1.,0.7,0.7)*spec + fre * vec3(0.8,0.7, 0.3);
        }
        
        if (mat_id == 2)
        {
            vec2 p_eye = (final_p.xy-clamp(anim,-0.3,.3))-vec2(0.,1.88); 
            vec3 diffuse = eye_color(p_eye);

            col = diffuse * lighting(n,l) + spec*(eye(p_eye).w);
        }
    }
    glFragColor = vec4(col,1.);
}
