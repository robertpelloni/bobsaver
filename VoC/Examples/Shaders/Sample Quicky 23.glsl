#version 420

// original https://www.shadertoy.com/view/3tKXzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 r(float a) {
    float c=cos(a),s=sin(a);
    return mat2(c,-s,s,c);
}
float xor(float a,float b) {
    return a*(1.-b) +b*(1.-a);
}
void main(void)
{
    float realTime = time + 5500.; // Yeah, effect works far in time
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;
    vec2 uuv = uv;
    uv *=length(cos(uv*2.8));
    float z= (cos(realTime*.1)*.5+1.);
    uv*=r(cos(realTime)*.1)*z;
    
    
    float aid = atan(uv.x,uv.y)*4.;
    uv=12.*abs(uv*r(aid+fract(length(uv*4.)+aid*.25) ));
    uv.x = sin(floor(uv.x)+-realTime*.5*cos(realTime*.25)*.005)*.5+.5;
    uv.x = xor(uv.x,cos(floor(uv.y)+realTime*.5*sin(realTime*.25)*.005)*.5+.5);
    vec3 col = vec3(uv.x);
   
    float flash = smoothstep(.5,1.,col).r;
     col =col* 0.10/(length(uuv)-(.03*z+floor(cos(aid*4.+flash))*.005)) ;
    col = mix(vec3(.1,.0,.1),vec3(.1 , .1 +flash*.5,1.-(1.-flash)*.5 ),col);
    //col = ;
    glFragColor = vec4(col,1.0);
}
