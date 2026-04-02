#version 420

// original https://www.shadertoy.com/view/NdlSDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST 0.02
#define PI 3.1415

//from https://www.shadertoy.com/view/llsSWr
vec2 rotate( vec2 vector, float angle )
{
    vec2 sincos = vec2( sin(angle), cos(angle) );
    return vec2( vector.x * sincos.y - vector.y * sincos.x, 
                vector.x * sincos.x + vector.y * sincos.y );
}

//from IQ
vec3 rotateY( in vec3 p, float t )
{
    float co = cos(t);
    float si = sin(t);
    p.xz = mat2(co,-si,si,co)*p.xz;
    return p;
}

vec3 translate(vec3 p, vec3 t)
{
    return p - t;
}

float dBox(vec3 p, vec3 s){

    return length(max(abs(p)-s,0.));
}

float GetDist(vec3 p) {
    

    float planeDist = p.y+2.;

    float dist_to_0=8.; //center of car rotates around 0.0 with this distance
    
    //grp_translate sets group placement
    vec3 grp_translate = vec3(sin(time)*dist_to_0, 0, cos(time)*dist_to_0);
    float grp_angle  = time+PI/2.;
    
    float dist_to_center=8.;
    float rengas =3.;
    float text_tmp;
    
    vec3 q = p;
    q=translate(q,grp_translate);
    q.xz=rotate(q.xz,grp_angle);
    q=translate(q,vec3(0,1,0));
    float body = dBox(q-vec3(0.0, 0.0, 0.),vec3(1,1,5));
    text_tmp = abs(dot(sin(q*6.),cos(q.yzx*6.))); //texture
    body-=text_tmp*0.1;

    
    q = p;
    q=translate(q,grp_translate);
    q.xz=rotate(q.xz,grp_angle);
    q=translate(q,vec3(2,0,2));
    q.yz=rotate(q.yz,-grp_angle*rengas);//right front wheel rotation
    float bd1 = dBox(q-vec3(0., 0.0, 0.),vec3(1));
    text_tmp = abs(dot(sin(q*6.),cos(q.xzy*6.))); //texture
    bd1-=text_tmp*0.1;
    
    q = p;
    q=translate(q,grp_translate);
    q.xz=rotate(q.xz,grp_angle);
    q=translate(q,vec3(-2,0,2));
    q.yz=rotate(q.yz,-grp_angle*rengas*1.5);//left front wheel rotation
    float bd2 = dBox(q-vec3(0., 0.0, 0.),vec3(1));
    text_tmp = abs(dot(sin(q*6.),cos(q.xzy*6.))); //texture
    bd2-=text_tmp*0.1;
    
    q = p;
    q=translate(q,grp_translate);
    q.xz=rotate(q.xz,grp_angle);
    q=translate(q,vec3(2,0,-2));
    q.yz=rotate(q.yz,-grp_angle*rengas); //right rear wheel rotation
    float bd3 = dBox(q-vec3(0., 0.0, 0.),vec3(1));
    text_tmp = abs(dot(sin(q*6.),cos(q.xzy*6.))); //texture
    bd3-=text_tmp*0.1;
    
    q = p;
    q=translate(q,grp_translate);
    q.xz=rotate(q.xz,grp_angle);
    q=translate(q,vec3(-2,0,-2));
    q.yz=rotate(q.yz,-grp_angle*rengas*1.5); //left rear wheel rotation
    float bd4 = dBox(q-vec3(0., 0.0, 0.),vec3(1));
    text_tmp = abs(dot(sin(q*6.),cos(q.xzy*6.))); 
    bd4-=text_tmp*0.1;

    q = p;
    //q=translate(q,group);
    //q.xz=rotate(q.xz,kulma);
    q=translate(q,vec3(0,0,0));
    float palikka = dBox(q-vec3(0., 0.0, 0.),vec3(1,1,1));
    
    float d = planeDist;
    
    d = min(d, body*0.6); 
    d = min(d, bd1);
    d = min(d, bd2);
    d = min(d, bd3);
    d = min(d, bd4);
    d = min(d, palikka);
    
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p){
    float d = GetDist(p);
    vec2 e = vec2(0.01,0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
        
        return normalize(n);
}

float GetLight(vec3 p){
    
    vec3 lightPos = vec3(4,5,-2);

    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);

    float dif = clamp(dot(n,l),0.,1.);

    float d = RayMarch(p+n*SURF_DIST*1.5,l);

    if(d<length(lightPos-p)){
        dif *=0.7;
    }

    return dif;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy -.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0);

    vec3 ro = vec3(0.,3,-17);
    vec3 rd = normalize(vec3(uv.x,uv.y,1.));
    
    float d = RayMarch(ro,rd);
    
    vec3 p = ro+rd*d;
    
    float dif = GetLight(p);
    col = vec3(dif);
    
    col += 0.2* GetNormal(p);

    // Output to screen
    glFragColor = vec4(col,0.4);
}
