#version 420

// original https://www.shadertoy.com/view/3dXyRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Originally posted to glslsandbox... somewhere :/

// hash without sine
// https://www.shadertoy.com/view/4djSRW
#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

#define pi 3.14159265

#define T .4*time

// pill shape for walls
float pill(vec2 p, vec2 d) {
    return length( vec2(max(0., (dot(p, d))), abs(dot(p, vec2(d.y, -d.x)))) );
}

// for the input pattern, it's like Gabor noise
float rStripes(vec2 p, vec2 o, float freq) {
    float ang = 2. * pi * hash12(floor(p)-o);
    vec2 dir = vec2(sin(ang), cos(ang));
    float f;
    
    // choose one
    f = .5 + .5 * cos(2.*T+freq*pi*dot(p, dir));
    //f = 2. * abs(fract(dot(freq*p, dir)+3.*T)-.5);
    //f = 4. * pow(abs(fract(dot(freq*p, dir)+.5*T)-.5), 2.);
    //f = fract(dot(freq*p, dir)+.5*T);
    
    return f;
}
// continuation of above
float rStripesLin(vec2 p, float freq) {
    vec3 o = vec3(-1., 0., 1.); 
    return
        mix(
            mix(
                rStripes(p, o.zy, freq),
                rStripes(p, o.yy, freq),
                smoothstep(0., 1., fract(p.x))
            ),
            mix(
                rStripes(p, o.zx, freq),
                rStripes(p, o.yx, freq),
                smoothstep(0., 1., fract(p.x))
            ),
            smoothstep(0., 1., fract(p.y))
        );
}

// input pattern
float map(in vec2 p) {
    
    vec2 p_ = p;
    p = floor(p);
   
    float f = 2.*rStripesLin(p/5., 1.);
    
    return f*1.75+.1;
}

void main(void) {
    vec2 res = resolution.xy;
    vec2 p = (gl_FragCoord.xy-res/2.) / res.x;
    
    float zoom = 64.;
    
    p *= zoom;
    
    float f = 0.;
    
    vec3 o = vec3(-1., 0., 1.);
    vec2 O[4];
    O[0] = o.xy;
    O[1] = o.zy;
    O[2] = o.yx;
    O[3] = o.yz;
    
    // value for wall direction
    float rv = radians(90.*floor(map(p)));
    
    // initial wall
    f = 2. * pill(fract(p)-.5, vec2(sin(rv), cos(rv)));
    
    // add walls from surrounding directions
    for(int i=0; i<4; i++) {
        rv = radians(90.*floor(2.+map(p-O[i])));
        vec2 sc = vec2(sin(rv), cos(rv));
        if(dot(sc, O[i])>.5)
            f = min(f, 2. * pill(fract(p)-.5, sc));
    }
    
    // aa
    f = smoothstep(.5-2./res.x*zoom, .5+2./res.x*zoom, f);
    
    // mouse input
    if (p.x <= (mouse.x*resolution.xy.x/res.x-.5)*zoom) f = floor(map(p)) / 3.;
    
    glFragColor = vec4(vec3(f), 1.);
}
