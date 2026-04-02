#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int MoveMode = 3;

const float PI = 3.14;

const int Steps = 200;
const float Eps = 0.0001;
const float dMin = 0.001;
const float lMax = 8.0;
const int Iterations = 15;
const float Bailout = 4.0;
const float Power = 4.0;

vec3 Lights = vec3(-0.5,-0.5,3.0);

struct dist{
    float d;
    float c;
};
struct hit{
    float l;
    float dMin;
    vec3 pos;
    vec3 dir;
    int obj;
    float c;
};
mat3 rot(float phiX,float phiZ){
    return    mat3(cos(phiZ), sin(phiZ), 0.0, -sin(phiZ), cos(phiZ),0.0, 0.0, 0.0, 1.0)
        * mat3(1.0, 0.0, 0.0, 0.0, cos(phiX), sin(phiX), 0.0, -sin(phiX), cos(phiX));
}
dist DE(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    float dMin = lMax;
    for (int i = 0; i < Iterations ; i++) {
        r = length(z);
        if (r<dMin) dMin = r;
        if (r>Bailout) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return dist(0.5*log(r)*r/dr,dMin);
}

vec3 norm(vec3 pos){
    float d0 = DE(pos).d;
    float dx = DE(pos+vec3(Eps,0.0,0.0)).d;
    float dy = DE(pos+vec3(0.0,Eps,0.0)).d;
    float dz = DE(pos+vec3(0.0,0.0,Eps)).d;
    return normalize(vec3(dx-d0,dy-d0,dz-d0));
}
hit trace(vec3 pos, vec3 dir){
    hit h = hit(0.0,lMax,pos,dir,0,0.0);
    for (int i=0; i<Steps; i++){
        dist d = DE(h.pos);
        h.pos += h.dir*d.d;
        h.l += d.d;
        if (d.d<h.dMin) h.dMin = d.d;
        if (h.l>lMax) break;
        else if (d.d<dMin) {
            h.obj = 1;
            h.c = d.c;
            break;
        }
    }
    return h;
}

vec3 getcol(float f){
    return vec3(sqrt(1.0-f*0.2),f*f,0.5-.5/f);
//    return 0.5*(1.0+vec3(cos(f*0.9),cos(f*f),cos(pi+0.01*f)));
}
void main( void ) {

    float phiX = 0.0;
    float phiZ = 0.0;
    float scale = 1.0;
    if (MoveMode ==1){
        phiX = mouse.y*PI/2.0;
        phiZ = -mouse.x*PI/2.0;
        scale = 1.0;
    }
    else if (MoveMode == 2) {
        phiX = sin(time*0.1)*PI/4.0;
        phiZ = -time*0.2;
        scale = 1.0-mouse.x;
    }
    else if (MoveMode ==3){
        phiX=PI/2.0+cos(time*0.3)*0.3;
        phiZ = cos(time*0.3)*0.1+PI*time*0.3/(2.0*PI)+0.2*cos(PI+time*0.3);
        scale = 0.3+pow(0.5*(1.0+sin(time*0.3)),2.0);
    }
    mat3 rmat = rot(phiX,phiZ);
    vec3 pixel = rmat*vec3(scale*( gl_FragCoord.xy*2.0-resolution.xy) / resolution.y,1.0);
    vec3 camera = rmat*vec3(0.0,0.0,1.0+3.0*scale);
    Lights = rot(phiX/2.0,phiZ/2.0)*Lights;
    
    
    
    vec3 dir = normalize(pixel-camera);
    
    hit h = trace(camera,dir);
    
    vec3 color = vec3(0.0);
    if (h.obj==0){
        float f = 0.0005/h.dMin;
        color = vec3(0.2*f,f,0.0);
    }
    else {
        vec3 N = norm(h.pos);
        vec3 V = -h.dir;
        vec3 L = normalize(Lights-h.pos);
        hit h2 = trace(Lights,-L);
        float intensity = 0.0;
        if (length(h2.pos-h.pos)<dMin*5.0)
            intensity = 1.0;//(h2.l*h2.l);
            
        
        vec3 H = normalize(V+L);
        float cosHN = dot(H,N);
        
        float kd = 0.25;
        float ka = 0.07;
        vec3 albedo = getcol(h.c);
        
        color += kd*intensity*albedo*cosHN;
        color += ka*albedo*cosHN;
        
        color += (1.0-kd-ka)*intensity*pow(cosHN,4.0);
        
    }

    
    glFragColor = vec4(  color/(1.0+color) , 1.0 );

}
