#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// hash without sine
// https://www.shadertoy.com/view/4djSRW
#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
//#define MOD3 vec3(.1031, .11369, .13787) // int range
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

#define pi 3.14159265
#define tx(o) texture(iChannel0, uv-o)

#define T .25*time
#define res resolution.xy

float rStripes(vec2 p, vec2 o, float freq) {
    float ang = 2. * pi * hash12(floor(p)-o);
    vec2 dir = vec2(sin(ang), cos(ang));
    
    float f;
    
    float v = fract(hash12(floor(p)-o+4.)*8.15);
    
    // pick one
    //f = .5 + .5 * cos(T+freq*pi*dot(p, dir));
    //f = 2. * abs(fract(freq*dot(p, dir)+.1*T)-.5);
    //f = pow(2. * abs(fract(freq*dot(p, dir)+.1*T)-.5), 2.);
    f = pow(2. * abs(fract(freq*dot(p+.1*sin(4.*p.x)+.1*cos(4.*p.y), dir)+T)-.5), 2.);
    //f = fract(dot(p, dir)+.1*T);
    
    f *= pow(v, 3.);
    
    
    return f;
}

float rStripesLin(vec2 p, float freq) {
    vec3 o = vec3(-1., 0., 1.); 
    return
        mix(
            mix(
                rStripes(p, o.zy, freq),
                rStripes(p, o.yy, freq),
                //fract(p.x)
                smoothstep(0., 1., fract(p.x))
            ),
            mix(
                rStripes(p, o.zx, freq),
                rStripes(p, o.yx, freq),
                //fract(p.x)
                smoothstep(0., 1., fract(p.x))
            ),
            //fract(p.y)
            smoothstep(0., 1., fract(p.y))
        );
}

float map(vec2 p) {
    float f = 0.;
    const float I = 8.;
    for(float i=1.; i<=I; i++) {
        float pw = pow(2.5, i);
        f += rStripesLin(p*pw+i*10., 1.3) / pw;
    }
    return f;
}

vec3 getnorm(vec2 p) {
    float acc = 2./res.y;
    vec3 o = vec3(-1., 0., 1.);
    return
        normalize(
            vec3(
                map(p-o.zy*acc)-map(p-o.xy*acc),
                map(p-o.yz*acc)-map(p-o.yx*acc),
                acc
            )
        );
}

void main( void ) {
    //vec2 res = iResolution.xy;
    vec2 p = (gl_FragCoord.xy-res/2.) / res.y;
    
    float zoom = 3.;
    
    p *= zoom;
    
    //vec3 lpos = zoom * vec3((iMouse.xy-res/2.)/res.y, .2);
    vec3 lpos = zoom * vec3(sin(T), cos(T), .2);
    vec3 norm = getnorm(p);
    vec3 hit = vec3(p, 0.);
    
    vec3 diffuse = 1. * vec3(.9, .6, .45) * (1.-dot(hit-lpos, norm)) / pow(length(p-lpos.xy), 2.);
    
    //diffuse = vec3(length(p-lpos.xy));
    
    vec3 RGB;
    
    RGB = diffuse;
    
       //RGB = norm;
    
    glFragColor = vec4(RGB, 1.);
}
