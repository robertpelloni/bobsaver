#version 420

// original https://www.shadertoy.com/view/wd3Xz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){ return mat2(cos(a),sin(a),-sin(a),cos(a));}
float circle(vec2 uv,float r) {
 
    return smoothstep(r,r+.01,length(uv)-r-.70);
}
float ring(vec2 uv,float r) {
    return abs(circle(uv,r)-r);
}

#define PI 3.141592
void main(void)
{
     vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    uv+=vec2(cos(-time)/50. ,sin(time)/50.);
    uv*=rot(time/20.*(1.+floor(5.* length(uv) * sign(cos(length(uv*4.*PI)))  )));
      uv+=vec2(cos(time)/66. ,sin(-time)/66.);
     vec2 q = vec2(1.0,0.);
     float d = ring(uv,.25- (fract(6.*PI*smoothstep(2.*-PI,2.*PI, atan(uv.x,uv.y)  ))));
     vec3 col = mix(vec3(.1),vec3(.9,.5,.2),vec3(d));
     col.b -=mod(-time/50.+smoothstep(2.*-PI,2.*PI, atan(uv.x,uv.y)),.1)*10. ; 
    glFragColor = vec4(col,1.0);
}
