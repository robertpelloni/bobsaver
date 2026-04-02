#version 420

// A terrain julia set raymarcher by Kabuto

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec2 CONSTANT =  vec2(-0.835,-0.2321);    // The mandelbrot set point for which to generate the julia set.
//const vec2 CONSTANT = vec2(-0.70176,-0.3842);
//const vec2 CONSTANT = vec2(-0.74543,+0.11301);
const int MAXITER = 50;
const int LOWITER = 10;
const int MAXTRACE = 200;
const float MAXDEPTH = 300.;

// Distance function. Warning: generates bugs for CONSTANT outside the mandelbrot set's features (so the resulting julia set consists of unconnected dots)
float iter(vec4 p, vec4 n4) {
    for(int i=0; i<MAXITER; i++) {
        // p = p²+n
        // p' = 2*p*p'+1
        p = p*p.x*vec4(1,1,2,2)+p.yxwz*p.y*vec4(-1,1,-2,2)+n4;
        p = p*p.x*vec4(1,1,2,2)+p.yxwz*p.y*vec4(-1,1,-2,2)+n4;
        p = p*p.x*vec4(1,1,2,2)+p.yxwz*p.y*vec4(-1,1,-2,2)+n4;
        p = p*p.x*vec4(1,1,2,2)+p.yxwz*p.y*vec4(-1,1,-2,2)+n4;
        if (dot(p.xy,p.xy) > 64.) break;
    }
    float l = length(p.xy);
    float dl = length(p.zw);
    return l<4. ? 0. : l*log(l)/dl;
}

void main( void ) {
    vec2 n = (gl_FragCoord.xy-resolution*.5)/resolution.x;
    
    
    // Iterating over the isosurface
    vec4 n4 = vec4(CONSTANT,0,0);
    float amplify = 1.5; // how much to amplify height
    float t = time*.5;
    vec2 pos2 = vec2(cos(t)*1.6,sin(t)*1.6001);    // Warning: AMD shader bug lingering in here. Specifying the same factor for both (or the entire vec2) will make it fail.
    vec3 pos = vec3(pos2,iter(vec4(pos2,1,0),n4)*amplify+.2);
    vec3 dir = normalize(-pos*vec3(1,1,.7)+vec3(0,0,-.2));
    vec3 right = normalize(cross(dir, vec3(0,0,1)));
    vec3 up = cross(dir,right);
    vec3 ray = normalize(dir+right*n.x-up*n.y);
    
    float factor = 1./(amplify-ray.z/length(ray.xy)); // correction factor for step distance
    
    float m = 0.;
    float md = 0.;
    
    float steps = float(MAXTRACE);
    for (int i = 0; i < MAXTRACE; i++) {
        m = iter(vec4(pos.xy,1,0),n4)*amplify;
        md = pos.z-m;
        if (md < 1e-4)  {steps = float(i); break;}
        pos += ray*md*factor;
    }
        

    vec3 cb = vec3(30.,1.,.03)*.01;
    vec3 color = cb/(cb+sqrt(m));
    
    glFragColor = vec4(color+1.-sqrt((float(MAXTRACE)-steps)/float(MAXTRACE)), 1.0 );

}
