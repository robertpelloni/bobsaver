#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/7lBGWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/**
    Refraction Experiments [017] | [ Mouseable ]
    Spent most of the day tooling around with more for 
    the refraction with objects like fractals.
    
    I'm using an Apollonian gasket offshoot and isolated
    by an intersecting sphere. (or else it goes on forever.. 
    which is also cool to checkout)

    I started this using a midi interface via KodeLife
    https://twitter.com/byt3m3chanic/status/1408768063818829832
    (video above)

    Using a fun and hacky method for reflections/refractions using
    only one pass (thanks @blackle) but definitely a stylized look.

*/

#define R         resolution
#define T         time
#define M         mouse*resolution.xy

#define PI              3.14159265358
#define PI2             6.28318530718

mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }
float lsp(float begin, float end, float t) { return clamp((t - begin) / (end - begin), 0.0, 1.0); }

mat2 turn,rx,ry;
float tmod=0.,timer=0.,ga1=0.;

vec2 dom (vec2 p, float size) {
    float hlf = size/2.;
     return mod(p+hlf,size)-hlf;
}
vec3 dom (vec3 p, float size) {
    float hlf = size/2.;
     return mod(p+hlf,size)-hlf;
}
vec2 map (in vec3 p) {
    float scale = 2.;

    vec3 q = p;
    float orb =1e5;
    p.xz*=turn;
    // phase | explosion point in time 
    float ph = 2.75;
    // iterations
    for( int i=0;i<2;i++ ) {
        p=dom(p,3.5);
        float r2 = dot(p,p);  
        float k = ph/r2;
        p *= k;
        scale *= k;
        orb = max(length(p.xz)/PI2,r2*.075);
    }
    float tubes = length(dom(p.xz,2.5-(ga1*.7)))-1.1;
    float ball = length(q)-1.15;

    float d = max(ball, -(tubes/scale));

    return vec2(d*.85,orb*.5);
}

//Tetrahedron technique
//https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p, float t, float mindist)
{
    float e = mindist*t;
    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
                      h.yyx*map( p + h.yyx*e ).x + 
                      h.yxy*map( p + h.yxy*e ).x + 
                      h.xxx*map( p + h.xxx*e ).x );
}

vec3 clr;
vec3 shade(vec3 p, vec3 rd, float d, float m, inout vec3 n)
{
    n = normal(p,d,1.);
    vec3 lpos = vec3(.1,9,7);
    vec3 l = normalize(lpos-p);

    float diff = clamp(dot(n,l),0.,1.);
    float fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 5.5);
    fresnel = mix(.01, .7, fresnel);

    clr = .5 + .45*sin(m*17.+ vec3(2.25,1.,.5));
    
    vec3 h = mix(vec3(0),clr,diff);

    return h;
}

void main(void)
{    
    vec2 F=gl_FragCoord.xy;
    turn = rot(time*3.33*PI/180.);
    tmod = mod(time*.5, 16.);
    float t1 = lsp(0.0, 3.0, tmod);
    float t2 = lsp(8.0, 11.0, tmod);
    ga1 = (t1-t2);
    
    vec3 C=vec3(.0);
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);

    vec3 ro = vec3(0,0,1.85),
         rd = normalize(vec3(uv,-1));

    float x = 0.6;//M.xy == vec2(0) ? 0.6 : -(M.y/R.y * 1. - .5) * PI;
    float y = 0.4;//M.xy == vec2(0) ? 0.4 : -(M.x/R.x * 2. - 1.) * PI;

    mat2 rx = rot(x);
    mat2 ry = rot(y);
    
    ro.yz *= rx;
    rd.yz *= rx;
    ro.xy *= ry;
    rd.xy *= ry;

    vec3  p = ro + rd * 1e-5;
    float atten = .725;
    float k = 1.;
    
    // loop inspired/adapted from @blackle's 
    // marcher https://www.shadertoy.com/view/flsGDH
    
    // high iteration = more transparent *however slow
    // 150 is very stylized and fast
    // 200 is good mix of speed and clarity
    // 300 is super clear but chunky
    for(int i=0;i<178;i++)
    {
        vec2 ray = map(p);
        vec3 n=vec3(0);
        float fresnel=0.;
        float d = ray.x;
        float m = ray.y;

        p += rd * d *k;
        
        if (d*d < 1e-9) {

            C+=shade(p,rd,d,ray.y,n)*atten;
            if(m==4.)break;
            
            atten *= .625;
            p += rd*.00125;
            k = sign(map(p).x);
            
            fresnel = pow(clamp(1.+dot(rd, n), 0., 1.), 5.);
            fresnel = mix(.01, .9, fresnel);
            
            vec3 rr = vec3(0);
            //reflect or refract based on fragcoord
            if(int(F.x)%3 != int(F.y)%3) {
                rr = refract(rd,n,.45);
                rd=mix(rr,rd,.9-fresnel);
            }else{
                vec3 rr=reflect(-rd,n);
                rd=mix(rr,rd, clr-fresnel);
                p+=n*.05;
            }
        }  
        if(distance(p,rd)>50.) { break; }
    }
    // Saftey
    C = clamp(C,vec3(0),vec3(1));
    // Output to screen
    glFragColor = vec4(sqrt(smoothstep(0.,1.,C)),1.0);
}

//end
