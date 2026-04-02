#version 420

// original https://www.shadertoy.com/view/tldSWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 r(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}

float bump(vec2 uv,float offset) {
 uv *=r(time+offset);
 return smoothstep(0.,4.,abs(cos(time+2.*atan(uv.x,uv.y))))/8.;
}
float circl(vec2 uv,float r,float offset) {
    return smoothstep(
    0.09-(length(uv)*.05),
    0.1,
    length(uv)-r- 
    bump(uv,offset)
    );
}
float fig(vec2 uv, float offset) {

return max(circl(uv,.33,offset) , 1.-circl(uv,.3,offset));
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy )/ resolution.y;
      vec2 uuv = uv;  
      uv*=2.;
      
      vec2 gid = floor(uv);
      uv *= r(atan(uv.x,uv.y));
      uv *=r(time*.123);
      
      uv = fract(+time*.124+uv*length(0.1*cos(uv+time)*10.))-.5;
    
    float d = min(fig(uv,0.) ,fig(uv,3.15/4.)) ;
  
    vec3 col = vec3(0.);
    col.r = fig(uv,0.+sin(-time+gid.x*11.));
    col.g = fig(uv,0.3-cos(time-gid.y*47.));
    col.b = fig(uv,-0.3+tan(sin(length(gid)+time)));
    glFragColor = vec4(col,1.0);
}
