#version 420

// original https://www.shadertoy.com/view/MsGyWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Another tuto by Etienne Jacob https://necessarydisorder.wordpress.com/2017/11/15/drawing-from-noise-and-then-making-animated-loopy-gifs-from-there/

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

    for (int i = 0; i < 2; i++, p*=2.,a/=2.) 
        p.xy *= R, p.yz *= R,
        v += a * noise3(p);

    return v;
}
// -------------------------------------

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    vec2 R = resolution.xy;
    U = ( U+U - R ) / R.y;
    O -= O;
    
    float t = 2.*time;
    U += .5*max(1.-.5*length(U),0.)
         * vec2( fbm3(vec3(U, t)), fbm3(vec3(U+5., t)) );
    U = sin(60.*U); U = smoothstep(1.5,0.,abs(U)/fwidth(U));
    O += U.x+U.y;  // * if you want points
    glFragColor=O;
}
