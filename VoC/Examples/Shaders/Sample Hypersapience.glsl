#version 420

// original https://www.shadertoy.com/view/fdjyWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

#define rotate(p, a) vec2(p.x*cos(a) - p.y*sin(a), p.x*sin(a) + p.y*cos(a))

vec2 c_inv(vec2 p, vec2 o, float r) {
    return (p-o) * r * r / dot(p-o, p-o) + o;
}

// hash without sine
// https://www.shadertoy.com/view/4djSRW
#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float grid(in vec2 p){ p = abs(fract(p+.5)-.5); return 2. * min(p.x, p.y); }

void main(void) {
    vec2 res = resolution.xy;
    vec2 p = (gl_FragCoord.xy-res/2.) / res.y;
    vec2 m = vec2(0.0);//(mouse*resolution.xy.xy-res/2.) / res.y;
    float f;
    
    // zoom
    p *= 1.3;
    
    float T = .35*time;
    
    // building face shape from summed-up circle inversions
    vec2 p_grp1, p_grp2 = vec2(0.);
    float I = 19.;
    for(float i=0.; i<I; i++)
        p_grp1 += c_inv(p, vec2(.35*(i-I/2.+.5)/I, -.4+.02*cos(4.*i/(I+1.)-PI/2.)), 4.*(.125+pow(i/I-.5, 2.)));
    I = 14.;
    for(float i=0.; i<I; i++)
        p_grp2 += c_inv(p, vec2(.15*(i-I/2.+.5)/I, -.45-.01*cos(4.*i/(I)-PI/2.)), .75);
    
    // everything is added together in a single statement
    p =
        (
            // eyes
            + c_inv(p, vec2(-.3, .2), 4.)
            + c_inv(p, vec2(.3, .2), 4.)
            
            //nose
            - c_inv(p, vec2(-.065, -.17), 1.7)
            - c_inv(p, vec2(.065, -.17), 1.7)
            
            // upper lip
            + p_grp1/2.
            
            // lower lip
            + p_grp2
        ) / 17.;
    
    // saving coords for later
    vec2 p2 = p;
    
    // translate grid
    p += (.5*T) * vec2(.13, 1.);
    
    // fractalize
    vec2 p3 = p;
    if(true) {
        for(float i=0.; i<14.; i++) {
            p3 += i * vec2(.215, .12);
            p3 = rotate(p3, 1.+1.4*I+.1*sin(.05*T-.1));
            p3 = abs(mod(p3, 40.)-20.);
        }
    }
    
    // apply grid
    f = grid(p3);
    
    //trying make lines an even thickness (produces pixelization artifacts)
    float wd = length(vec2(dFdx(p.x), dFdx(p.y)));
    f /= wd * .015 * res.x;
    
    f = min(1., f+.73);
    
    // apply random cells
    f += .07 * (.5 - hash12(floor(p3)));
    
    vec3 RGB = vec3(f);
    
    // faux lighting
    f += 1.5*(.014 * length(p2+15.) - .85);
    //f += 1.5*(.014 * length(p2+30.*m) - .85);
    
    RGB += mix(vec3(.03, .3, .4), 2.9*vec3(1., .6, .2), f)-.7;    
    
    glFragColor = vec4(RGB, 1.);
}

