#version 420

// original https://www.shadertoy.com/view/WsGfWW

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

    // four corners of a 2D square
    float f00 = rand(i);
    float f10 = rand(i + vec2(1.0, 0.0));
    float f01 = rand(i + vec2(0.0, 1.0));
    float f11 = rand(i + vec2(1.0, 1.0));

    vec2 u = smoothstep(0.,1.,(1.-f));
    return u.x*u.y*f00+(1.-u.x)*u.y*f10+
    u.x*(1.-u.y)*f01+(1.-u.x)*(1.-u.y)*f11;    
}

float circle(in vec2 st, in float noise,in float radius){
    float noiseStep=.05; //noise step size
    float d=length(st+noiseStep*noise-vec2(.5));
    return smoothstep(radius,radius-.01,d);
}

void main(void) {
    vec3 cArray[3]; //array holding colors
    cArray[0]=vec3(1.,0.,0.);
    cArray[1]=vec3(0.,1.,0.);
    cArray[2]=vec3(0.,0.,1.);
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float Nshapes=1.; // number of shapes
    vec2 f=fract(uv*Nshapes);
    vec2 pos = vec2(f*5.0)+2.*float(mouse*resolution.xy)/resolution.xy;
    // Using the bilinear value noise
    float noise = bilinearNoise(pos+vec2(cos(time),sin(time)));
    float gray=0.;
    vec3 color=vec3(0.);
    for(float i=0.;i<12.;++i){
        gray=circle(f,noise,.45-.04*i)-circle(f,noise,.43-.04*i);
        color+=gray*cArray[int(mod(i,3.))];
    }
    glFragColor = vec4(color, 1.0);
}
