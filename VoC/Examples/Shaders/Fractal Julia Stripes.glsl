#version 420

// original https://www.shadertoy.com/view/wtscDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// dashxdr was here
// Trying to implement Stripe Average Coloring for mandelbrot fractal
// https://en.wikibooks.org/wiki/Fractals/Iterations_in_the_complex_plane/triangle_ineq
// Then see the paper:
// On Smooth Fractal Coloring Techniques master thesis by Jussi Haerkoenen

void main(void) {
    vec2 v = (gl_FragCoord.xy - resolution.xy/2.0) / min(resolution.y,resolution.x);
    float zt = fract(time*.01);
    zt=1.0-2.*min(zt,1.0-zt);
    vec2 center = vec2(-0.39075330, 0.30274829);
    float zoom = (1.0+zt*16.)*.02374716/1.33333333;
    v*=zoom;v+=center; // sets initial point of interest
    vec2 m;// = mouse;
    m = vec2(0.42, 0.6); // uncomment this to mess with brightness + contrast
    vec2 z = v;
    vec2 c = vec2(0.4, -.325);
    float iter = 1.;
    vec3 sum = vec3(0.0);
    vec3 sum2;
    float M = 200000.;
    float M2=M*M;
    #define N 60
    for( int i=1;i<N;++i)
    {
        iter = float(i);
        float angle = atan(z.y, z.x);
        sum2 = sum;
        sum  += sin(angle*vec3(7,9,6))*.5 + .5;
        if(dot(z,z)>M2) break;
        z = vec2(z.x*z.x - z.y*z.y, z.x*z.y + z.y*z.x) + c;
    }
    sum/=iter;
    sum2/=iter-1.0;
    // thanks to iq for following mixing scheme...
    float f = -log2(log(length(z))/log(M2));
    sum = mix(sum2, sum, clamp(f, 0. , 1.));
    vec3 color = sum*vec3(1.0,.9,.82);
    color = (color - m.x)*(m.y*10.+1.);
    if(dot(z,z)<M) color=vec3(0);
    glFragColor.rgb = color;
}
