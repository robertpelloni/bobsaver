#version 420

// original https://www.shadertoy.com/view/ttKfzD

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
mat2 scale(vec2 _scale){
    return mat2(_scale.x,0.0,
                0.0,_scale.y);
}

float brick(vec2 st, vec2 size, float thickness) {
    float xt = fract(st.x*size.x);
    float yt = fract(st.y*size.y);
    return step(1.-thickness*(size.x/size.y), xt)+step(1.-thickness,yt);
}
void main(void)
{
    // fix coordinate pixels
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv-0.5;
    float screenRatio = resolution.x/resolution.y;
    uv.x *= screenRatio;

    // distort the space with noise
    vec2 st = uv;
    float noise = (noise(uv*3.))*2.+0.5;
    st = uv * scale(vec2(1.+noise));
    
    //BRICKS:
    // green (no scale)
    float brickScale = 10.*sin(time*0.5)+10.001;
    float green = brick(st, vec2(brickScale), 0.1);
    // blue and red (scale down and scale up based on distance to center) 
    float difference = length(st)*0.01;
    vec2 contract = st * scale(vec2(1.-difference));
    float blue = brick(contract, vec2(brickScale), 0.1);
    vec2 expand = st * scale(vec2(1.+difference));
    float red = brick(expand, vec2(brickScale), 0.1);
    
    
    // final color 
    vec3 col = vec3(red, green, blue);
    glFragColor = vec4(col,1.0);
}
