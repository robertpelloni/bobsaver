#version 420

// original https://www.shadertoy.com/view/MdyyWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Another tuto by Etienne Jacob https://necessarydisorder.wordpress.com/2017/11/15/drawing-from-noise-and-then-making-animated-loopy-gifs-from-there/
// variant of https://shadertoy.com/view/MsGyWK

// --- pseudo perlin noise 3D

int MOD = 1;  // type of Perlin noise
#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

#define hash31(p) fract(sin(dot(p,vec3(127.1,311.7, 74.7)))*43758.5453123)
float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p); f = f*f*(3.-2.*f); // smoothstep

    float v= mix( mix( mix(hash31(i+vec3(0,0,0)),hash31(i+vec3(1,0,0)),f.x),
                       mix(hash31(i+vec3(0,1,0)),hash31(i+vec3(1,1,0)),f.x), f.y), 
                  mix( mix(hash31(i+vec3(0,0,1)),hash31(i+vec3(1,0,1)),f.x),
                       mix(hash31(i+vec3(0,1,1)),hash31(i+vec3(1,1,1)),f.x), f.y), f.z);
    return   MOD==0 ? v
           : MOD==1 ? 2.*v-1.
           : MOD==2 ? abs(2.*v-1.)
                    : 1.-abs(2.*v-1.);
}

float fbm3(vec3 p) {
    float v = 0.,  a = .5;
    mat2 R = rot(.37);

    for (int i = 0; i < 1; i++, p*=2.,a/=2.) 
        p.xy *= R, p.yz *= R,
        v += a * noise3(p);

    return v/.5;
}
// -------------------------------------

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    vec2 R = resolution.xy;
    U = ( U+U - R ) / R.y;
    O -= O;
    
    float t = 3.*time, K = 1.5, S = 2.;
    
    for (float j = -1.; j < 1.; j += .05)
        for (float i = -1.; i < 1.; i += .05) {
            vec2 P = vec2(i,j);
            float k = K * max(1.-length(P),0.);          // displ amplitude
            if (length(U-P) < k) {                       // optim
                P += k * vec2( fbm3(vec3(S*P, t)), fbm3(vec3(S*P+15., t)) ) / S;
                P = smoothstep( 3./R.y, 0., abs(U-P) );
                O += P.x*P.y; 
            }
        }
    glFragColor = O;
}
