#version 420

// original https://www.shadertoy.com/view/WtyBWR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 p) {
    p+=10.;
    return sin(fract(dot(p.x*1.3242413, p.y*3.346346)*342.23523523)*232.23423);
}
float cube(vec3 p, float s) {
    p=abs(p);
    return max(p.x,max(p.y,p.z))-s;
}
vec2 c2p(vec2 p) {return vec2(atan(p.y,p.x),length(p));}
vec2 p2c(vec2 p) {return vec2(cos(p.x),sin(p.x))*p.y;}
float map(vec3 p) {
    p=p*1.05;
    vec3 ac=p;
    vec3 sc=p;
    float my=0.0;//mouse*resolution.xy.y/resolution.y;
    for(int i=0;i<7;i++) {
        ac.xy=p2c(c2p(ac.xy)+vec2(mix(0.3,1.6,my),0.));
        ac.xz=p2c(c2p(ac.xz)+vec2(mix(2.0,.4,my),0.));
        ac=abs(ac)-0.1;
        sc.xy=p2c(c2p(sc.xy)+vec2(mix(2.3,.6,my),0.));
        sc.xz=p2c(c2p(sc.xz)+vec2(mix(0.1,1.2,my),0.));
        sc=abs(sc)-0.15;
    }
    return max(cube(ac,0.2),-cube(sc,0.14));
}
vec3 gradient(vec3 p) {
    vec2 e=vec2(0.,0.01);
    return normalize(vec3(
                map(p+e.yxx)-map(p-e.yxx),
                map(p+e.xyx)-map(p-e.xyx),
                map(p+e.xxy)-map(p-e.xxy)
            ));
}
vec3 pixel(vec2 p, vec3 o) {
    vec3 t=vec3(0.);
    vec3 fwd=normalize(t-o);
    vec3 right=cross(fwd,normalize(vec3(0.,-1.,0.)));
    vec3 up=cross(fwd,right);
    vec3 r=normalize(fwd+right*p.x+up*p.y);
    vec3 fp=o+r*mix(1.,3.,mouse.x*resolution.xy.x/resolution.x);
    o=o+(sin(rand(p.xy*1.235313)*3.145)*right+sin(rand(p.yx*0.82352332)*3.145)*up)*0.08;
    r=normalize(fp-o);
    // focal stuff

    // ----- //
    float dt=0.01;
    for(int i=0;i<60;i++) {
        float d=map(o+r*dt);
        if(d<0.001) break;
        dt+=d*0.8;
    }
    if(dt>5.) return vec3(0.);
    vec3 col=vec3(max(0.05,dot(gradient(o+r*dt),normalize(vec3(-4.,-2.,-10.)))));
    col+=vec3(max(0.05,dot(gradient(o+r*dt),normalize(-vec3(-4.,-2.,-10.)))));
    return col;
}
void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy*2.-1.;
    uv.x*=resolution.x/resolution.y;
    if(length(uv)>0.9) {glFragColor=vec4(0.5);return;}
    vec3 col = vec3(0.);
    int ssaa=2;
    for(int i=0;i<ssaa;i++) {
        vec2 offset=vec2(rand(uv)+float(i),rand(uv*vec2(1.234324,0.943534)+vec2(2.,3.)+float(i*2)));
        col+=pixel(uv+offset*1./resolution.xy, vec3(cos(time),sin(time*0.7)*0.8,sin(time))*2.)/float(ssaa);
    }
    glFragColor = vec4(col,1.0);
}
