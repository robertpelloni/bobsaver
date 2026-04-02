#version 420

// original https://www.shadertoy.com/view/3lSSDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// TODO
// fresnel
// clouds
// occlusion
// reflections 

struct hit {
    float d;
    int m;
};
float sdSphere(vec3 pos,float radius){
    return length(pos)-radius;
}
float terrain(vec2 pos){
   return sin(pos.x*1.4)*0.1+sin(pos.x*0.93)*.3 +
    sin(pos.y*2.3)*0.1+sin(pos.y*1.45)*0.2;
}
float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
  return mix(a, b, h) - k*h*(1.0-h);
}
float smoothMerge(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5*(d2 - d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0-h);
}

float rand(float n) {
    return fract(sin(n) * 43758.5453123);
}

float srand(float n) {
    return rand(n)*2.-1.;
}
float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

mat4 translate(float x, float y, float z){
    return mat4(
        vec4(1.0, 0.0, 0.0, 0.0),
        vec4(0.0, 1.0, 0.0, 0.0),
        vec4(0.0, 0.0, 1.0, 0.0),
        vec4(x,   y,   z,   1.0)
    );
}

mat4 RotateX(float phi){
    return mat4(
        vec4(1.,0.,0.,0),
        vec4(0.,cos(phi),-sin(phi),0.),
        vec4(0.,sin(phi),cos(phi),0.),
        vec4(0.,0.,0.,1.));
}

mat4 RotateY(float theta){
    return mat4(
        vec4(cos(theta),0.,-sin(theta),0),
        vec4(0.,1.,0.,0.),
        vec4(sin(theta),0.,cos(theta),0.),
        vec4(0.,0.,0.,1.));
}

mat4 RotateZ(float psi){
    return mat4(
        vec4(cos(psi),-sin(psi),0.,0),
        vec4(sin(psi),cos(psi),0.,0.),
        vec4(0.,0.,1.,0.),
        vec4(0.,0.,0.,1.));
}

hit map(vec3 pos){
    hit h;
    h.m = 1;
    
    float d = 10000000.;
    float i = float(int(time/10.)+124);
    i = rand(i);
   

    for(int b=0;b<3;b++){
         mat4 m = mat4(
        vec4(1.,0.,0.,0.),
        vec4(0.,1.,0.,0.),
        vec4(0.,0.,1.,0.),
        vec4(0.,0.,0.,1.)
    );
        //m = translate(.0,-1.,.0)*m;
        for(int x=0;x<15;x++){
            vec3 rot = vec3(
             srand(i++)*3.1415,
             srand(i++)*3.1415,
             srand(i++)*3.1415);
            float s = (.5+.5*rand(i++))*.14;
           
            /*
            a += smoothstep(-.4,.4,sin(time*1.5))* srand(i++)*.2;
            a += sin(time*3.0)* srand(i++)*.05;
            a += sin(time*1.0)* srand(i++)*.04;
            a += smoothstep(.5,1.,sin(time*6.))* srand(i++)*.01;
            */
            m = RotateY(rot.y)*m;
            m = RotateZ(rot.z)*m;
            m = RotateX(rot.x)*m;
            m = translate(.0,-s,.0)*m;
            //m = m*RotateX(1.5);
            
            float bs = 0.04+rand(i++)*0.02;
            float ls = 0.02+rand(i++)*0.03;
            float ma = rand(i++);
            
             for(int k=0;k<2;k++){
                 vec3 pp = k==0?pos:pos*vec3(-1.,1.,1.);
                vec4 p2 = m*vec4(pp,1.);
                 
                //vec4 p2 = vec4(pos,1.);
                d = smoothMerge(d,sdCappedCylinder(p2.xyz,ls,s),.08);
               // d = min(d,sdCappedCylinder(p2.xyz,ls,s));
                  mat4 m2 = translate(.0,-s,.0)*m;
                 p2 = m2*vec4(pp,1.);
                d = smoothMerge(d,sdSphere(p2.xyz,bs),.08);
             }
             m = translate(.0,-s,.0)*m;
            
        }
    }
    h.d=d;
    
     float f = pos.y+0.0;
    if(f<h.d){
       // h.d=f;
//        h.m=2;
    }
    return h;
}
    
hit castRay(vec3 ro ,vec3 rd ){
       int s = 0;
    float d = 0.0;
    while(s < 30 && d < 10.0){
        vec3 p = ro + rd * d;
        hit h = map(p);
        float od = abs(h.d);
        if(od<0.004){
            h.d = d;
              return h;
        }
        d+=od;
        s++;
    }
    hit h;
    h.d = d;
    return h;
}
vec3 pixel(vec2 uv){
    float an = time*.5 + .3 + mouse.x*resolution.xy.x/resolution.x*3.1415*2.;
    vec3 ro = vec3(2.*sin(an),0.4,2.*cos(an));
    //vec3 ta = vec3(time,.0,.0);   
    //vec3 ro = vec3(0.,0.,2.);
    vec3 ta = vec3(0.,.0,.0);   
    
    vec3 fo = normalize(ta-ro);
    vec3 ri = normalize(cross(fo,vec3(0.0,1.0,0.0)));
    vec3 up = normalize(cross(ri,fo));
    
    vec3 rd = normalize(uv.x*ri + uv.y*up + 1.5*fo);
    vec3 alb = vec3(.0);
    hit h = castRay(ro,rd);
    if(h.m==0) return vec3(0.);
    return vec3(1./h.d); // dist
   
}

void main(void)
{
    vec2 i = gl_FragCoord.xy;
    //if(mouse*resolution.xy.z<=.0)return;
    
    float pix = 1./resolution.y;
    vec2 uv = ((i)*2.0-resolution.xy)/resolution.y;

    vec2 e = vec2(pix/2.+pix*.2,0.);
    
    vec3 c = pixel(uv+e.xy);   
   // c+=pixel(uv-e.xy);
   // c+=pixel(uv-e.yx);
   // c+=pixel(uv-e.yx);
    //c/=4.0;
    glFragColor = vec4(c,1.0); 
}
