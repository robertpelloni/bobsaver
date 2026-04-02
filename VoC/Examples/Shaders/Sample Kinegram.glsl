#version 420

// original https://www.shadertoy.com/view/4lK3WR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265358979323846264338327950288
#define clamps(x) clamp(x,0.,1.)
mat2 rotation(float angle){
    return mat2(cos(angle),-sin(angle),sin(angle),cos(angle));
}
float atans(vec2 uv){
    return (atan(uv.x,uv.y)+PI)/(PI*2.);
}
float chessDist(vec2 uv) {
    return max(abs(uv.x),abs(uv.y));
}
vec3 draw(vec2 uv,float time){//Time loops 0 to 1
    float dist=chessDist(uv*rotation(time*PI*0.5))-0.25;
    //float dist=length(uv+vec2(0.,(0.1*sin(time*PI*2.))))-0.3;
    return vec3(clamps(dist*200.));
}
void main(void) {
    vec2 uv=(gl_FragCoord.xy/resolution.xy)-.5;uv.x/=resolution.y/resolution.x;
    float time=time;
    vec2 pixelSize=floor(1./resolution.xy);
    vec2 pixel=floor(gl_FragCoord.xy);
    float pixelWidth=10.;
    vec3 background=draw(uv,fract(pixel.x/pixelWidth));
    vec4 foreground=vec4(0.,0.,0.,float(abs(uv.y+(sin(time)*0.2))<0.25)*clamps(mod(floor(pixel.x-(time*pixelWidth)),pixelWidth)));
    glFragColor = vec4(mix(background,foreground.rgb,foreground.a),1.);
}
