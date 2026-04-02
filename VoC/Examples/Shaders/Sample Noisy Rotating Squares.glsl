#version 420

// original https://www.shadertoy.com/view/3dKfDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846

// 2D rotation with pivot point (.5,.5)
vec2 rotate2D(vec2 st, float angle){
    st -= 0.5;
    st =  mat2(cos(angle),-sin(angle),
                sin(angle),cos(angle)) * st;
    st += 0.5;
    return st;
}
// a square with given size as side 
float square(vec2 st, vec2 side){
    vec2 border = vec2(0.5)-side*0.5;
    vec2 pq = smoothstep(border,border+.01,st);
    pq *= smoothstep(border,border+.01,vec2(1.0)-st);
    return pq.x*pq.y;
}
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

void main(void)
{    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv-=.5;
    vec3 color = vec3(0.0);
    float scale=6.;//-4.;// *mouse*resolution.xy.x/resolution.x;
    // Divide the space into cells
    vec2 ixy=.5+floor(scale*uv);
    uv = fract(scale*uv);
    // Using a 2x2 matrix to rotate with given angle
    uv = rotate2D(uv,.5*PI*sin((ixy.x+ixy.y)*time));
     float nr=bilinearNoise(uv);
    // Draw a noisy square
    color =vec3(1.*nr)+vec3(square(uv,vec2(0.7)));
    color*=vec3(1.,.5+.5*sin(40.*nr+ixy.x*time), .5+.5*sin(40.*nr+ixy.y*time));

    glFragColor = vec4(color,1.0);
}
