#version 420

// original https://www.shadertoy.com/view/3slfzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 50
#define MAX_DIST 100.
#define SURF_DIST .01

float sdSphere( vec3 p, vec3 b )
{
  return sin(length(p)) - b.x  ;
}
float opRep( in vec3 p, in vec3 c , float s )
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return sdSphere(q,vec3(s,s,s));
}
float getDist(vec3 p) {
    return opRep(p,vec3(1,1,1),0.04);
}
float rayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = getDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return dO;
}
vec3 getNormal(vec3 p) {
    float d = getDist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        getDist(p-e.xyy),
        getDist(p-e.yxy),
        getDist(p-e.yyx));
    
    return normalize(n);
}

float getLight(vec3 p){
    vec3 lightPos = vec3(0,1,time) ;
    //lightPos.xz += vec2(2.*sin(time),2.*cos(time));
    vec3 lv = normalize(lightPos - p ); 
    vec3 n = getNormal(p) ;
    float dif = clamp(dot(n,lv),0.,1.)*5. ;
    float d = rayMarch(p+n*SURF_DIST*2.,lv) ;
    //if(d<length(lightPos-p)) dif *=.1 ;
    return dif ;
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float speed = 0.05 ; 
    mat2 mat = mat2(vec2(cos(time*speed), sin(time*speed)),         // first column (not row!)    
                     vec2(-sin(time*speed), cos(time*speed)));
    uv = mat*uv ;
    vec3 ro = vec3(0,0.5,time);
    vec3 rd = normalize(vec3(uv.x,uv.y,1));
    float d = rayMarch(ro,rd);
    //vec3 p = ro + rd * d ;
    float dif = 1.0/(1.0+d*d*0.1);
    vec3 col = vec3(dif*2.,dif/d*2.0,0);
    //float fog = 1.0 / 1.0 + d*d*0.1;
    //vec3 col  = vec3(fog) ;
    glFragColor = vec4(col,1.0);
}
