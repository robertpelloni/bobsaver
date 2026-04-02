#version 420

// original https://www.shadertoy.com/view/Xs33WB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// by @paulofalcao
// Nostalgia moment, remake of somethingt I made a long time ago in DOS  :) 
// pf-blue.zip at http://ftp.scene.org/mirrors/hornet/demos/1997/b/

const float PI=3.14159265359;

vec2 rot(vec2 uv,float a){
    return vec2(uv.x*cos(a)-uv.y*sin(a),uv.y*cos(a)+uv.x*sin(a));
}

vec3 rotsim(vec2 p,float s){
    vec2 ret=p;
    ret=rot(p,-PI/(s*2.0));
    float pa=floor(atan(ret.x,ret.y)/PI*s)*(PI/s);
    ret=rot(p,pa);
    return vec3(ret.x,ret.y,pa);
}

float drawPoint(vec2 uv){
    return max(1.0-length(uv)*192.0,0.0);    
}

void main(void) {

    vec2 uv=resolution.xy;uv=-.5*(uv-2.0*gl_FragCoord.xy)/uv.x;
    
    //draw points
    uv=rot(uv,time);
    vec3 rs=rotsim(uv,16.0);
    uv=rs.xy;
    float f=drawPoint(uv-vec2(0,0.08+sin(rs.z*19.0+time*6.0)*0.03));
    vec3 dots = vec3(f*0.5,f*1.3,f*3.0);
   
    //draw lastframe
    uv=gl_FragCoord.xy/resolution.xy-0.5;
    uv*=0.8+sin(time*0.2)*0.2;
    uv+=0.5;
    vec3 back=texture2D(backbuffer,uv).xyz;
    
    //mix lastframe + points
    glFragColor=vec4(back*0.8+dots,1.0);    

}
