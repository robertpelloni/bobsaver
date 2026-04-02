#version 420

// original https://www.shadertoy.com/view/4sc3DB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    //if (mouse*resolution.xy.w < 1.) {
    //    if (length(vec2(sin(time)*.75, cos(time*1.1294)*.75)-(uv*2.-1.)) < .06) {
    //                glFragColor = vec4(1.,0.,1.,1.);
    //    return;
    //    }
    //} else {
    if (length(mouse*resolution.xy.xy/resolution.xy-uv) < .03) {
        glFragColor = vec4(1.,1.,1.,1.);
        return;
    }
    //}
    
    vec4 c = texture(backbuffer, uv)*5.;
    
    vec2 odr = 1./resolution.xy;
    
    vec4 cLeft = texture(backbuffer, uv-vec2(odr.x,0.)),
         cRight = texture(backbuffer, uv+vec2(odr.x,0.)),
         cUp = texture(backbuffer, uv-vec2(0.,odr.y)),
         cDown = texture(backbuffer, uv+vec2(0.,odr.y));
    
    c += cLeft.wyzx*(abs(cos(time+uv.x*32.234+cRight.w*32.234))+1.);
    c += cRight.zxyw*(abs(cos(uv.x*32.234+cLeft.z*32.34+time*1.36))+1.);
    c += cUp*(abs(cos(time*2.12+uv.y*32.1432+cDown.y*32.24))+1.);
    c += cDown.wzyx*(abs(cos(uv.y*32.345+cUp.x*32.234))+1.);
        
    glFragColor = max(c/11.6-.0001, 0.);
}
