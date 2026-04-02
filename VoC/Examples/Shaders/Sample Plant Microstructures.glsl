#version 420

// original https://www.shadertoy.com/view/7tdGWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define R (resolution.xy)
#define s(v,l) smoothstep(l/R.y,0.,v) // AA
#define ro(a) (mat2(cos(a),sin(a),-sin(a),cos(a))) // 2d rotation matrix

float hash21(vec2 p) {
    p = fract(p*vec2(123.34, 456.21));
    p += dot(p, p+45.32);
    return fract(p.x*p.y);
}

float cir (vec2 p, vec2 c, float r, float w) {return abs(length(p-c)-r)- w;}

void main(void) {
   
    vec2 o = (gl_FragCoord.xy - R*.5) / R.x;
    o *= 5.;
    o += vec2(time * .1);
    
    vec3 col = vec3(1.);
    vec3 oc = col;
    vec2 u;
    
    float id, aa;
    
    vec2 gr, ce;
    for (float g = 0.; g < 3.; g++){
        for (float i = 0.; i < 1. ; i+=.5) {
            for (float j = 0.; j < 1.; j+=.5) {
                u = o + vec2(i, j);
            
                gr = floor(u);
                id = hash21(gr);
                if (id * g > .25) continue;
                
                ce = (u - gr - .5) * 2.;
                ce *= ro((PI / 2.) * floor(id * 10.));
    
                vec3 c1 = mod(g, 2.) == 0. ? oc : vec3(.6,.9,.6);
                vec3 c2 = mod(g, 2.) == 0. ? vec3(.7,.95,.5) : oc;
                vec3 c3 = mod(g, 2.) == 0. ? vec3(.6,.95,.8) : oc;
                vec3 c4 = mod(g, 2.) == 0. ? vec3(.7,.9,.7) : vec3(1.,1.,.8);
                
                aa = 2. * (g * 2. + 2.);
               
                col = mix(col, c1, s(cir(ce, vec2(0.), .0, .5), aa));
                col = mix(col, c2, s(cir(ce, vec2(0.), .0, .11), aa));
                col = mix(col, c1, s(cir(ce, vec2(0.), .0, .05), aa));
                col = mix(col, c4, s(cir(ce, vec2(0.), .0, .02), aa));
                
                col = mix(col, c1, s(cir(ce, vec2( .5, .5), .0, 1. / 3.), aa));
                col = mix(col, c1, s(cir(ce, vec2(-.5, .5), .0, 1. / 3.), aa));
                col = mix(col, c1, s(cir(ce, vec2( .5,-.5), .0, 1. / 3.), aa));
                col = mix(col, c1, s(cir(ce, vec2(-.5,-.5), .0, 1. / 3.), aa));

                col = mix(col, c2, s(cir(ce, vec2( .5, .5), .0, 1. / 4.), aa));
                col = mix(col, c2, s(cir(ce, vec2(-.5, .5), .0, 1. / 4.), aa));
                col = mix(col, c2, s(cir(ce, vec2( .5,-.5), .0, 1. / 4.), aa));
                col = mix(col, c2, s(cir(ce, vec2(-.5,-.5), .0, 1. / 4.), aa));

                col = mix(col, c3, s(cir(ce, vec2( .5, .5), .0, 1. / 5.), aa));
                col = mix(col, c3, s(cir(ce, vec2(-.5, .5), .0, 1. / 5.), aa));
                col = mix(col, c3, s(cir(ce, vec2( .5,-.5), .0, 1. / 5.), aa));
                col = mix(col, c3, s(cir(ce, vec2(-.5,-.5), .0, 1. / 5.), aa));
 
                col = mix(col, c4, s(cir(ce, vec2( .5, .5), .0, 1. / 6.1), aa));
                col = mix(col, c4, s(cir(ce, vec2(-.5, .5), .0, 1. / 6.1), aa));
                col = mix(col, c4, s(cir(ce, vec2( .5,-.5), .0, 1. / 6.1), aa));
                col = mix(col, c4, s(cir(ce, vec2(-.5,-.5), .0, 1. / 6.1), aa));
                
                col = mix(col, c1, s(cir(ce, vec2( .5, .5), .0, 1. / 12.1), aa));
                col = mix(col, c1, s(cir(ce, vec2(-.5, .5), .0, 1. / 12.1), aa));
                col = mix(col, c1, s(cir(ce, vec2( .5,-.5), .0, 1. / 12.1), aa));
                col = mix(col, c1, s(cir(ce, vec2(-.5,-.5), .0, 1. / 12.1), aa));
                
                col = mix(col, c3, s(cir(ce, vec2(-.18, .18), .0, 1. / 9.), aa));
                col = mix(col, c3, s(cir(ce, vec2( .18,-.18), .0, 1. / 9.), aa));
                col = mix(col, c1, s(cir(ce, vec2(-.18, .18), .0, 1. / 18.), aa));
                col = mix(col, c1, s(cir(ce, vec2( .18,-.18), .0, 1. / 18.), aa));

                col = mix(col, c3, s(cir(ce, vec2(-.5, .0), .0, 1. / 6.1), aa));
                col = mix(col, c3, s(cir(ce, vec2( .5, .0), .0, 1. / 6.1), aa));
                col = mix(col, c3, s(cir(ce, vec2( .0,-.5), .0, 1. / 6.1), aa));
                col = mix(col, c3, s(cir(ce, vec2( .0, .5), .0, 1. / 6.1), aa));
                
                col = mix(col, c2, s(cir(ce, vec2(-.5, .0), .0, 1. / 9.), aa));
                col = mix(col, c2, s(cir(ce, vec2( .5, .0), .0, 1. / 9.), aa));
                col = mix(col, c2, s(cir(ce, vec2( .0,-.5), .0, 1. / 9.), aa));
                col = mix(col, c2, s(cir(ce, vec2( .0, .5), .0, 1. / 9.), aa)); 
         
                if (ce.y > -(1. / .6) && ce.y < .5 && ce.x < .5)
                    col = mix(col, c2, s(cir(ce, vec2(.5), .5, 1. /  20.), aa));
                if (ce.y <  (1. / .6) && ce.y >-.5 && ce.x >-.5) 
                    col = mix(col, c2, s(cir(ce, vec2(-.5), .5, 1. / 20.), aa)); 
                
                col = mix(col, c1, s(cir(ce, vec2(-.147,-.147), .0, 1. / 40.), aa));
                col = mix(col, c1, s(cir(ce, vec2(-.25,-.065), .0, 1. / 40.), aa));
                col = mix(col, c1, s(cir(ce, vec2(-.065,-.25), .0, 1. / 40.), aa));
                
                col = mix(col, c1, s(cir(ce, vec2( .147, .147), .0, 1. / 40.), aa));
                col = mix(col, c1, s(cir(ce, vec2( .25, .065), .0, 1. / 40.), aa));
                col = mix(col, c1, s(cir(ce, vec2( .065, .25), .0, 1. / 40.), aa));
            }
        }
        // magic formula (works only for g < 3.), i gonna fix this in the near future
        o += pow(1./8., g + 1.) * (g * 7. + 1.);
        o *= 2.;
    }
    
    glFragColor = vec4(col,1.0);
}
