#version 420

// original https://www.shadertoy.com/view/XtGSzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Z-buffer version. compare to fake 3D https://www.shadertoy.com/view/XlGXRR

// in the Amiga superdemos, this would be a sprite
void sphere(inout vec4 O,inout float zmin, vec2 U, vec3 P, float r, vec3 C) { // O, U, pos, radius, color
    
    U -= P.xy;
    r = length(U)/r; if (r>1.) return;

    U = normalize(U)*r;
    float z = sqrt(1.-dot(U,U)); 
    if (zmin < P.z-.1*z) return; 
    zmin = P.z-.1*z;
    vec3 N = vec3(U,z);
    O.rgb =  clamp(  C*(.2 + max(0.,(-N.x+N.y+N.z)/1.732))    // ambiant, diffus
                       + pow(max(0.,dot(N,normalize(vec3(-1,1,2.73)))),50.) // spec
                       ,0.,1.);               // L=(-1,1,1), E=(0,0,1), z toward eye 
}

void main(void) //WARNING - variables void ( out vec4 O, vec2 U ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    vec2 R = resolution.xy;
         U = (U+U-R)/R.y;
    float t = time, z=1e9;
    O -= O;
    for (float a=0.; a<100.; a+=.1)
        sphere( O,
                z, 
                U, 
                .7*vec3(1.5*cos(a+t)+.3*sin(.9*a),sin(1.13*a)+.3*cos(.81*a+t),cos(1.3*a)-.4*sin(.9*a)),
                .05, 
                .5+.5*sin(6.28*a/100.+vec3(0,-2.1,2.1)));
    glFragColor = O;
}
