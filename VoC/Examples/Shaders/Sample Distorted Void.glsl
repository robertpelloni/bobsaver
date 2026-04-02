#version 420

// original https://www.shadertoy.com/view/tlKfRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}
mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

// Gradient Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/XdXGW8
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}
vec2 noise2d(vec2 st) {
    return vec2(noise(st), noise(st+1243.1234));
}

void main(void)
{
    // map pixel location
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    // apply transformations to correct screen size
    vec2 st = uv-0.5;
    st.y -= 0.4;
    st.x *= resolution.x/resolution.y;
    
    // add global transforms and rotations
    st = rotate2d(time*0.1) * st; // rotate
    st = st + noise2d(vec2(time*0.05)); // translate
    
    // detail noise
    float val = noise(st*10. + vec2(time*2.4,0))+0.55;
    
    // distort the noise so that there are portions with high detail and low detail
    float distortion = (noise(st*2.2 + vec2(0,time*0.4))-0.05)*10.;
    
    // clamp out anything we don't need
    vec3 col = fract(vec3(val) * distortion*5.1) + distortion*0.15;
    glFragColor = vec4(col,1.0);
}
