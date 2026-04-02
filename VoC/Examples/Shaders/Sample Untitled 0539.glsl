#version 420

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;

out vec4 glFragColor;

float lerp(float a, float b, float p){
    return a*(1.-p)+b*p;
}

float mdistance(vec2 x, vec2 y){
    return max(abs(x.x-y.x),abs(x.y-y.y));
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

void main() {
    float newtime = time /5.;
    float ratio = resolution.x/resolution.y;
    vec2 mymouse = vec2(mouse.x*ratio,mouse.y);
    vec2 st = gl_FragCoord.xy/resolution.y;
    float dist = distance(st,mymouse);
    float mandist = mdistance(rotate2d(sin(newtime)*2.)*(st-mymouse),vec2(0.));
    float intensity = lerp(dist,lerp(mandist,mandist/2.,cos(newtime)),abs(sin(newtime*9.)))*50.*(2.+sin(newtime*2.));
    glFragColor = vec4(cos(intensity),sin(intensity+2.*newtime),lerp(cos(intensity),sin(intensity+2.*newtime),sin(newtime*10.)),1.0);
}
