#version 420

// original https://www.shadertoy.com/view/wdyBWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// pseudo-random function, returns value between [0.,1.]
float rand (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(31.7667,14.9876)))
                 * 833443.123456);
}
//bilinear value noise function
float bilinearNoise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners of a 2D square
    float f00 = rand(i);
    float f10 = rand(i + vec2(1.0, 0.0));
    float f01 = rand(i + vec2(0.0, 1.0));
    float f11 = rand(i + vec2(1.0, 1.0));

    vec2 u = smoothstep(0.,1.,(1.-f));
    return u.x*u.y*f00+(1.-u.x)*u.y*f10+
    u.x*(1.-u.y)*f01+(1.-u.x)*(1.-u.y)*f11;
    
}

#define OCTAVES 5
float fbm (in vec2 st) {
    // Initial parameters
    float value = 0.0;
    float amplitude = .65;
    float frequency = 1.;
    //-----
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * bilinearNoise(frequency*st);
        frequency *= 2.;
        amplitude *= .5;
    }
    return value;
}

void main(void)
 {
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st.x *= resolution.x/resolution.y;

    float color =0.;
    vec2 q=vec2(0.);
    q.x=fbm(10.*st+.55*time);
    q.y=fbm(10.*st+.21*time);
    vec2 r=vec2(0.);
    r.x=fbm(100.*st+21.5*q+.1*time);
    r.y=fbm(100.*st+21.5*q+.34*time);
    color=fbm(10.*st+1.*r+3.*mouse*resolution.xy.xy/resolution.xy);
    glFragColor = vec4(color*clamp(q.x+q.y,0.,1.),color*color,color*clamp(length(r),0.,1.),1.0);
}
