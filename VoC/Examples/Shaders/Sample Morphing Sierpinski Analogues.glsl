#version 420

// original https://www.shadertoy.com/view/WttcRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define CS(a) vec2(cos(a), sin(a))
#define hue(v) ( .6 + .6 * cos( 2.*PI*(v) + vec4(0,-2.*PI/3.,2.*PI/3.,0)))
vec2 cmul(vec2 a, vec2 b) {
    return mat2(a,-a.y,a.x)*b;
}

vec2 target (vec2 z, float twist) {
    vec2 weightedSum=vec2(0); float weight=0.;
#define N 3.
    for (float i = 0.; i < N; i++) {
        float theta = 6.28*(i/N);
        vec2 point = CS(theta), d = z-point;
        float L = length(d), w = pow(L, -10.);
        vec2 scale = 2.*CS(twist*theta);
        weight += w;
        weightedSum += w*cmul(scale, d);
    }
    return weightedSum/weight;
}

void main(void) {
    vec2 R = resolution.xy, pw = 1./R, uv = gl_FragCoord.xy*pw;
    
    float cycleT=30., t = fract(time/cycleT), cycle = floor(time/cycleT),
          twist = mod(cycle, 3.)-1., maxIt = (twist < -.5 ? 5. : 6.), 
          iterations = maxIt*(smoothstep(0.,.5,t)-smoothstep(.5,1.,t)),
          zoom = 3.+smoothstep(0., 1., iterations)*(twist < -.5 ? 6. : (twist < .5 ? 1. : 2.));

    vec2 p = ((gl_FragCoord.xy-.5*R)/R.y)*zoom;
    for (float i = 0.; i < 10.; i++){
        if (i < floor(iterations)) p = target(p, twist);
    }
    p = mix(p, target(p, twist), fract(iterations));
    
    float mag = length(p);
    vec4 col = mix(vec4(.5), vec4(1.), min(1., mag));
    col = mix(col, hue(.6), smoothstep(1., 1.5, mag)-smoothstep(1.5,2., mag));
    col = col*min(1., pow(length(p), -2.));
    glFragColor = col;
    //glFragColor = hue(atan(p.y, p.x)/6.28);
}
