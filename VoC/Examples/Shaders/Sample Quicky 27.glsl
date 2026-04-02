#version 420

// original https://www.shadertoy.com/view/3lVSWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define bpm 124.
#define beat floor(time*bpm/60.)
#define ttime time*bpm/60.
mat2 r(float a){
float c=cos(a),s=sin(a);
return mat2(c,-s,s,c);
}
float fig(vec2 uv){
    uv*=r(-3.1415*.9);
return min(1.,.1/abs( (atan(uv.x,uv.y)/2.*3.1415)-sin(- ttime+(min(.6,length(uv)))*3.141592*8.)));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5* resolution.xy)/resolution.y;
    uv+=vec2(cos(time*.1),sin(time*.1));
    uv*=r(time*.01);
    vec3 col = vec3(-.0);
    for(float y=-1.;y<=1.;y++){
    for(float x=-1.;x<=1.;x++){
    vec2 offset = vec2(x,y);
    vec2 id = floor((uv+offset)*r(length(uv+offset)));
    vec2 gv = fract((uv+offset)*r(length(uv+offset)))-.5;
        gv*=r(cos(length(id)*10.));
    float d = fig(gv);+fig(gv+vec2(sin(ttime+length(id))*.1,cos(time)*.1));
    col += vec3(d)/exp(length(gv)*6.);

    
    }}
    col = mix(vec3(.1,.01,.02),vec3(.8,.4,.2),col);
    glFragColor = vec4(col,1.0);
}
