#version 420

// original https://www.shadertoy.com/view/tdGyWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 p, float a){return p * mat2(cos(a), -sin(a), sin(a), cos(a));}
 
const vec3 c1 = vec3(.1,.05,.2);
const vec3 c2 = vec3(1,.5,.1);

void main(void) {
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.0) / resolution.yy /3. ;    
    vec2 uv1 = rotate(uv, 1.6+sin(time)*.4);    
    float w = sin(uv1.x*160.+time*20. + sin(uv1.y*30.)*3.)*20.; 
    w += sin(uv.x*150. + sin(uv.y*20.)*5.)*20.;    
    w = clamp(w, .0, 1.);
    vec3 col = mix(c1, c2, w);
    glFragColor = vec4(col,1.);
}
