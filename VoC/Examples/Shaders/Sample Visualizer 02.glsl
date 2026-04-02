#version 420

// original https://www.shadertoy.com/view/3tXXDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = 2.*uv - 1.;
    uv.x *= resolution.x / resolution.y;
    

    float da = time/(5.);
    vec2 pts = vec2(sin(da*2.), cos(da*2.));

    float d = length(cos(  abs((abs(uv)+atan(da))*pts))*sin(atan(abs(uv))));

    d = atan(d) - cos(da+d*d)*sin(da - d*d);
    d -= atan(cos(da)*abs(  fract(d*d)-da) + 0.5);
    
    d -= sin(d)*abs(uv.x*uv.y);
    d *= length(d + abs(uv.y));
    
    float fill = step(tan(fract(abs(d)-0.5)*da),0.2);
     
     
    vec3 col = vec3(fill - sin(d-da ));
    
    
    
    col += vec3(0., 0.2, 1.);
    col *= vec3(1., 0.1, 0.2);
    glFragColor = vec4(col, 1.);
    //da += uv.x;
}
