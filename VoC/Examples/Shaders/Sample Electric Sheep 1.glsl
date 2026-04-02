#version 420

// original https://www.shadertoy.com/view/wlV3zy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Creative Commons Licence Attribution-NonCommercial-ShareAlike 
   phreax 2020
*/

#define PI 3.141592
#define TAU 2.*PI
#define hue(v) ( .6 + .6 * cos( 6.3*(v) + vec3(0,23,21) ) )
#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
#define COUNT 30.
#define DISTORT .7
#define SQR(x) ((x)*(x))

float tt;

vec2 kalei(vec2 uv) { 
    float n = 5.;
    float r = TAU/n;
    
    for(float i=0.; i<n; i++) {     
        uv = abs(uv);
        uv.x -= .2*i+.2;
        uv *= rot(r*i-.09*tt);
    }
    
    uv = abs(uv) - (sin(.15*tt)+1.2);

    return uv;
}

float flower(vec2 uv, float r) {
    float n = 3.;
    float a = atan(uv.y,uv.x);

    float d = length( uv) - cos(a*n);
    return smoothstep(fwidth(d), 0., abs(d));    
}

vec3 spiral(vec2 uv, float i) {  
    uv *= rot(i*3.14+tt*.3);
    uv += DISTORT*sin(vec2(5)*uv.yx);
    return flower(uv, .8)*SQR(hue(i+tt*.2));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0);
    tt = time;
    
    uv *= 5.;
    uv = kalei(uv);

    float s = 1./COUNT;
    
    for(float i=0.; i<1.; i+=s) {   
        float z = fract(i-.1*tt);
        float fade = smoothstep(1., .88, z);
        vec2 UV = uv;
        col += spiral(UV*z, i);
    }

    col = sqrt(col);
    glFragColor = vec4(col,1.0);
}
