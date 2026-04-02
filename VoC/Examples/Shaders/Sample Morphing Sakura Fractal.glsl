#version 420

// original https://www.shadertoy.com/view/3l3cR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define CS(a) vec2(cos(a), sin(a))
#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
#define hue(v) ( .6 + .6 * cos( 2.*PI*(v) + vec4(0,-2.*PI/3.,2.*PI/3.,0)))

float smoothhill(float a, float b, float c, float x) {
    return smoothstep(a,b,x)-smoothstep(b,c,x);
}
float smoothParity(float x, float b) {
    float m = mod(x-.5, 2.);
    return smoothstep(.5-b, .5+b, m) - smoothstep(1.5-b, 1.5+b, m);
}

vec2 target (vec2 z, float power) {
    if (length(z) > 100.) return z;  // Prevent blowup.
    vec2 weightedSum=vec2(0); float weight=0.;
#define N 5.
    for (float i = 0.; i < N; i++) {
        float theta = 6.28*(i/N);
        vec2 point = CS(theta), d = z-point;
        float L = length(d), w = pow(L, -10.);
        float scale = 2.*pow(L, power-1.);
        weight += w;
        weightedSum += w*scale*d;
    }
#undef N
    return weightedSum/weight;
}

vec4 render (in vec2 coord) {
    vec2 R = resolution.xy, pw = 1./R, uv = coord*pw;
    float cycleT=20., t = fract(time/cycleT), maxIt = 5., 
          iterations = maxIt*smoothhill(0.,.5,1.,t), zoom = 4.;
    float parity = smoothParity(time/cycleT, .05);
    vec4 bandColor = mix(hue(.0), hue(.6)*.5, parity);
    float b = mix(.5, .5, parity);
    float bw = mix(.2, .3, parity);
    float power = mix(3., 1.8, parity);
    
    vec2 p = rot(radians(36.+90.))*((coord-.5*R)/R.y)*zoom;
    for (float i = 0.; i < 10.; i++){
        if (i < floor(iterations)) p = target(p, power);
    }
    p = mix(p, target(p, power), fract(iterations));
    
    float m = length(p);
    vec4 col = vec4(mix(.85, 1., smoothhill(0.,.5,1.5,m)));
    col = mix(col, bandColor, .3*smoothhill(b-bw,b,b+bw,m));
    return col;
}

void main(void) {
    // 2D Antialiasing:
    vec2 d = vec2(.5,0);
    glFragColor = (render(gl_FragCoord.xy+d.xy)+render(gl_FragCoord.xy-d.xy)+render(gl_FragCoord.xy+d.yx)+render(gl_FragCoord.xy-d.yx))*.25;
}
