#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/7sBGR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// variant of quadripole https://shadertoy.com/view/7sBGzh

#define F(P)     1./dot(P-U,P-U)       // point field
#define CS(a)    vec2(cos(a),sin(a))
#define hash2(p) fract(sin((p)*mat2(127.1,311.7, 269.5,183.3)) *43758.5453123)
#define hash(p)  fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453)
#define rot(a)   mat2(cos(a + vec4(0,11,33,0)))

int n =17;  // neighborhod. big since 1/d² don't decrease fast enough.
            //              should approx F with narrower support
void main(void)
{
    vec4 O = glFragColor;
    vec2 u = gl_FragCoord.xy;

    vec2 R = resolution.xy,
         U = 4.* ( 2.*u - R ) / R.y,
         I = floor(U), P,I1,
         A = CS(1.9111),  // 109.5° : tetraedron vertical angle
         j = CS(2.0944);  // 2pi/3 
    mat4x3 J = mat4x3( vec3(0,0,1) ,vec3(1,0,1)*A.yyx, vec3(j,1)*A.yyx, vec3(j.x,-j.y,1)*A.yyx );
    vec3 F = vec3(0);

    float f, f0;
    for (int k=0; k<n*n; k++) {    // --- sum influences from neighbor particlse 
        I1 = I + vec2(k%n -n/2,k/n -n/2);         // neighbor cell
        P = I1 + (hash2(I1)-.5) *rot(time*8.*(hash(I1)-.5)) +.5; // random dot in the current neighbor cell
        float f =  F(P);
        F += J[int(mod(I1.x+2.*I1.y,4.))] * F(P); // particle potential ( checkered tetrasign )
        f0 = max( f0, f );
    }   
    O =  F * J; 
    O += O.w *vec4(1,1,0,0);       // remap O.w as yellow
    
    //if (mouse*resolution.xy.z<=0.) O = .5+.5*O; // not click: [0,1] values, otherwise signed
    glFragColor = max( O, f0/R.y );          // display white dot at particle location
}
