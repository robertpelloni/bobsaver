#version 420

// original https://www.shadertoy.com/view/ltGcR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
    a=radians(a);
    float s=sin(a);
    float c=cos(a);
    return mat2(c,s,-s,c);
}

float hash(vec2 p) {
    return fract(sin(dot(p,vec2(.213,.432))*243.2343));
}

float cir(vec2 p, float r) {
    return max(0.,r-length(p))/r;
}

vec4 heart(vec2 p) {
    p.x*=1.05;
    float l=.3+(.5+p.y+p.x*.7)*.4;
    float fc=time*10.;
    p*=1.3+min(sin(fc),sin(fc+2.))*.05;
    p.x+=pow(max(0.,-p.y),2.);
    p.y-=.1;
    float br=pow(cir(p-vec2(0.1,.1),.5),1.)*.2;
    vec3 col=vec3(1.,0.25,0.15);
    float sp=pow(cir(p+vec2(-.3,-.2),.3),2.)*.2;
    sp+=pow(cir(p+vec2(.15,-.21),.3),1.5)*.25;
    p.x=abs(p.x);
    p+=pow(smoothstep(-.035,.48,-p.y*.34),1.1);
    float h=cir(p+vec2(-.21,-.04), .25);    
    return vec4(col*1.1*(min(1.,pow(h*5.,.05))+br)*l+sp,h);
    
}

vec4 hearts(vec2 p) {
    p*=1.+sin(time)*.2;
    p.y-=time*.2;
    float r=3.;
    float t=1./r;
    float s=hash(floor(r*p)*5.2345);
    float v=hash(floor(r*p)*2.2345);
    float x=hash(floor(r*p)*3.4234)-.5;
    float y=hash(floor(r*p)*5.3454)-.5;
       p=mod(p,t)-t*.5;
    vec2 pos=vec2(x,y)*t*.25+vec2(sin(time*5.+s*100.)*t*.1,0.);
    return heart((p+pos)*r*(1.5+v*2.))*step(s,.2);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    float l=1.-length(uv)*1.5;
    uv.x*=resolution.x/resolution.y;
    vec4 h=heart(uv);
    vec4 hs=hearts(uv)*.7;
    float mi=1.-smoothstep(0.,.01,h.w);
    vec3 col = max(h.xyz,hs.xyz*mi);
    uv+=time*.1;
    float bk = mod(uv.x*.5+uv.y,.05)/.05;
    bk = 2. - max(bk,mod(uv.x-uv.y,.05)/.05);
    mi=1.-smoothstep(0.,.03,max(hs.w,h.w));
    vec3 back = vec3(bk*bk*bk, bk*bk, bk*5.)*mi*.02+l*vec3(.2,.3,.4);
    vec3 final = mix(back,col,length(col))*vec3(.8,.9,1.);
    glFragColor = vec4(final,1.0);
}
