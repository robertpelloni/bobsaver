#version 420

// original https://www.shadertoy.com/view/Wlccz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define CS(a) vec2(cos(a), sin(a))
#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
#define hue(v) ( .6 + .6 * cos( 2.*PI*(v) + vec4(0,-2.*PI/3.,2.*PI/3.,0)))
vec2 cmul(vec2 a, vec2 b) {
    return mat2(a,-a.y,a.x)*b;
}
vec2 cpow(vec2 z, float n) {
    float mag = pow(length(z),n), angle = atan(z.y, z.x)*n;
    return mag*CS(angle);
}
float smoothHill(float a, float b, float c, float x) {
    return smoothstep(a,b,x)-smoothstep(b,c,x);
}
float smoothParity(float x, float b) {
    float m = mod(x-.5, 2.);
    return smoothstep(.5-b, .5+b, m) - smoothstep(1.5-b, 1.5+b, m);
}

vec2 target (vec2 z, float twist) {
    vec2 weightedSum=vec2(0); float weight=0.;
#define N 3.
    for (float i = 0.; i < N; i++) {
        float theta = 6.28*(i/N);
        vec2 point = CS(theta), d = z-point, d2 = cmul(CS(-theta+twist), cpow(d, 2.));
        float L = length(d), w = pow(L, -10.);
        weight += w;
        weightedSum += w*2.5*mix(d2, d, (L > 1. ? 1. : pow(L, 15.)));
    }
    return weightedSum/weight;
}

vec4 render(vec2 gl_FragCoord2){
    vec2 R = resolution.xy, pw = 1./R, uv = gl_FragCoord2.xy*pw;
    
    float cycleT=30., t = fract(time/cycleT),
          parity = smoothParity(time/cycleT, .05),
          twistA = 2.*PI*(fract(2.*t+.5)-.5),
          twist = mix(0., twistA, parity),
          maxIt = 5., iterations = maxIt*(smoothHill(0.,.75,1.,t)),
          zoom = 4.;

    vec2 p = rot(radians(-90.))*((gl_FragCoord2.xy-.5*R)/R.y)*zoom;
    for (float i = 0.; i < 10.; i++){
        if (i < floor(iterations)) p = target(p, twist);
    }
    p = mix(p, target(p, twist), fract(iterations));
    
    float mag = length(p);
    vec4 col = mix(vec4(.1), vec4(.8), min(1., mag));
    col = mix(col, hue(.3), smoothHill(1., 1.5, 2., mag));
    col = col*min(1., pow(length(p), -2.));
    return col;
    //return hue(atan(p.y, p.x)/6.28);
}
void main(void) {
    // 2D Antialiasing:
    vec2 d = vec2(.5,0);
    glFragColor = (render(gl_FragCoord.xy+d.xy)+render(gl_FragCoord.xy-d.xy)+render(gl_FragCoord.xy+d.yx)+render(gl_FragCoord.xy-d.yx))*.25;
}
