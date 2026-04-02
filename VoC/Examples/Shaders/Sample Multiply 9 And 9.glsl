#version 420

//--- multiply 9 and 9
// by Catzpaw 2017

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//print digits
#define TEXTLINES   8.
#define FONTHEIGHT  8.
float digit(vec2 p,float n){if(abs(p.x-.5)>.5||abs(p.y-.5)>.5)return 0.;float d=0.;
    if(n<0.)d=1792.;else if(n<1.)d=480599.;else if(n<2.)d=139810.;else if(n<3.)d=476951.;
    else if(n<4.)d=476999.;else if(n<5.)d=349556.;else if(n<6.)d=464711.;else if(n<7.)d=464727.;
    else if(n<8.)d=476228.;else if(n<9.)d=481111.;else if(n<10.)d=481095.;else d=2.;
    p=floor(p*vec2(4.,FONTHEIGHT));return mod(floor(d/pow(2.,p.x+(p.y*4.))),2.);}
float putInt(vec2 uv,vec2 p,float n){uv*=TEXTLINES;p+=uv;
    float c=0.,m=abs(n)<1.?2.:1.+ceil(log2(abs(n))/log2(10.)+1e-6),d=floor(p.x+m);
    if(d>0.&&d<m){float v=mod(floor(abs(n)/pow(10.,m-1.-d)),10.);c=digit(vec2(fract(p.x),p.y),v);}
    if(n<0.&&d==0.)c=digit(vec2(fract(p.x),p.y),-1.);
    return c;}

//plot
float line(vec2 p,vec2 p1,vec2 p2){
    vec2 a=p-p1,b=p2-p1;float d=distance(a,b*max(min(dot(a, b)/dot(b, b),1.),0.));return d<.01?1.:clamp(1.-d*15.,0.,1.);}
float circle(vec2 p,vec2 p1,float r){
    float d=abs(distance(p,p1)-r);return d<.001?1.:clamp(1.-d*100.,0.,1.);}

void main(void){
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y); 
    vec2 m=(mouse.xy*2.-1.0);
    vec3 c=vec3(0);

    if(max(abs(uv.x),abs(uv.y))>1.)discard;
    uv*=3.;
    float x=floor(uv.x*.5+1.5);
    float y=floor(1.5-uv.y*.5);
    uv.x=mod(uv.x+1.,2.)-1.;
    uv.y=mod(uv.y+1.,2.)-1.;
    float v=x+y*3.+1.;
    float n=mod(floor(time*2.),10.);
    c=max(c,vec3(.7,.7,.7)*circle(uv,vec2(0,0),.71));
    for(float i=0.;i<10.;i+=1.){
        c=max(c,vec3(1,1,1)*putInt(uv,vec2(-.63-sin(i*.62832)*6.3,.3-cos(i*.62832)*6.3),i));
        float a=mod((i+0.)*v,10.);
        float b=mod((i+1.)*v,10.);
        vec2 p1=vec2(sin(a*.62832),cos(a*.62832))*.7;
        vec2 p2=vec2(sin(b*.62832),cos(b*.62832))*.7;
        c=max(c,vec3(.2,.2,.2)*line(uv,p1,p2));    
        if(i<n+1.)c=max(c,vec3(i*.1,1.-i*.1,1)*line(uv,p1,p2));    
    }
    c=max(c,vec3(1,1,1)*putInt(uv*.3,vec2(-0.63,0.3),v));
    
    glFragColor = vec4(c,1);
}
