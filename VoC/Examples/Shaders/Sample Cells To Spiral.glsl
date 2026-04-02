#version 420

// original https://www.shadertoy.com/view/mdSGDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SCALE 35.0
#define R resolution.xy
#define M mouse*resolution.xy
#define K(xy,n) floor(mod((xy.x-0.5+n), 3.0)/2.0)

void main(void)
{
    float t = time/10.0;
    vec2 mc = M.xy/R.y; // mouse coords
    vec2 sc = (gl_FragCoord.xy-0.5*R)/R.y*SCALE; // screen coords
    
    // cartesian to polar
    float a = atan(sc.x, sc.y); // screen arc
    float r = length(sc); // screen radius
    if (mc.x > 1.0) mc.x = 1.0; // limit mouse x to 1
    if (round(mc.x*2.0)/2.0 == 0.0) mc.x = 0.0; // snap mouse x to 0 when close
    float mxt = 1.0-mc.x; // mouse x transform
    sc.x = (sc.x*mxt)+(a*mc.x); // x to angular
    sc.y = (sc.y*mxt)+(r*mc.x); // y to radial
    
    vec2 pc = vec2(sc.x*0.955+t*round(sc.y), sc.y); // point coords
    vec3 rgb = vec3(K(pc, 0.0), K(pc, 1.0), K(pc, 2.0)); // color
    vec3 c = smoothstep(0.5, 0.2, length(fract(pc+0.5)-0.5))*rgb; // dots
    
    glFragColor = vec4(c, 1.0);
}
