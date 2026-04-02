#version 420

// original https://www.shadertoy.com/view/4lXGD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 d = gl_FragCoord.xy/resolution.y-.5,
         u = 20.*(vec2(atan(d.y,d.x),.8/length(d))+time);
    int y= int(mod(-u.y,8.));
    glFragColor = cos(vec4(y-3,d,1))*floor(mod(
        float(y>6?6:y>5?40:y>4?47:y>1?12*y*(y-4)+63:8-4*y)/
        exp2(floor(abs(mod(u.x,14.)-7.))),2.))*dot(d,d);
}
