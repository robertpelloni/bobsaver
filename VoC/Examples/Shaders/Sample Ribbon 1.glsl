#version 420

// original https://www.shadertoy.com/view/3dsSW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float e;

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                * 43758.5453123);
}

// Value noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( random( i + vec2(0.0,0.0) ),
                     random( i + vec2(1.0,0.0) ), u.x),
                mix( random( i + vec2(0.0,1.0) ),
                     random( i + vec2(1.0,1.0) ), u.x), u.y);
}

//  Function from Iñigo Quiles
//  www.iquilezles.org/www/articles/functions/functions.htm
float expStep( float x, float k, float n ){
    return exp( -k*pow(x,n) );
}

// Copyright © 2013 Inigo Quilez
// More info here:
//
// http://www.iquilezles.org/www/articles/distance/distance.htm
float ellipse(float r1, float r2,vec2 p)
{
    
    float f = length( p*vec2(r1,r2));
    return abs(f-1.0);
}

void stroke(float dist, vec3 color, inout vec3 glFragColor, float thickness, float aa)
{
    float alpha = smoothstep(0.5 * (thickness + aa), 0.5 * (thickness - aa), abs(dist));
    glFragColor = mix(glFragColor, color, alpha);
}

void renderEllipseA(float r1, float r2, vec2 st, inout vec3 col)
{
    float f = ellipse(r1,r2,st);
    float g = length( vec2(ellipse(r1,r2,st+vec2(e,0.0))-ellipse(r1,r2,st-vec2(e,0.0)),
                           ellipse(r1,r2,st+vec2(0.0,e))-ellipse(r1,r2,st-vec2(0.0,e))) )/(2.0*e);
    stroke(f/g*1.0, vec3(0., 0., 1.), col, 0.002, length(fwidth(st)));
}

void renderEllipseB(float r1, float r2, vec2 st, inout vec3 col)
{
    float f = ellipse(r1,r2,st);
    float g = length( vec2(ellipse(r1,r2,st+vec2(e,0.0))-ellipse(r1,r2,st-vec2(e,0.0)),
                           ellipse(r1,r2,st+vec2(0.0,e))-ellipse(r1,r2,st-vec2(0.0,e))) )/(2.0*e);
    col = mix( col, vec3(0.,0.,0.),expStep(f/g,200.,0.7));
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float distort(float r, vec2 st) {
    st = rotate2d(0.0)*st;
    float a = atan(st.y,st.x);
    
    return r-r*0.5*sin(3.0*a);
}

void main(void)
{
    e = 1.0/resolution.y;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 pix = uv;
    uv.x *= resolution.x/resolution.y;
    
    vec3 col = vec3(1.0);
    
    uv -= 0.5;
    uv -= vec2(0.6,0.0);
    

    float u = 0.0;
    int n = 300;
    float du = 2.*3.14159/float(n);
    for (int i = 0; i < n; i++) {
        
        u += du;
        uv += vec2(0.2, 0.0);
        uv = rotate2d(du) * uv;
        uv -= vec2(0.2, 0.0);
        vec2 shift = vec2(noise(3.*(pix+vec2(0.6*sin(time)*sin(2.0*u), 1.0)))*0.1);
        uv -= shift;
        renderEllipseB(1.0/0.15, 1.0/0.02, uv, col);
        uv += shift;
    }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
