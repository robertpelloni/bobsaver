#version 420

// original https://www.shadertoy.com/view/wlXyRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 haircolor=vec3(.05,.02,.0);
vec3 skincolor=vec3(1.,.8,.65);
vec3 lipcolor=vec3(1.,.4,.4);

vec3 rnd23(vec2 p)
{
    vec3 p3 = fract(p.xyx * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

float box(vec2 p, vec2 c) {
    return length(max(vec2(0.),abs(p)-c));
}

float nose(vec2 p) {
    vec2 p2=p;
    p.y+=.08;
    p.y*=20.;
    p.x=abs(p.x*1.3);
    p.y+=cos(pow(p.x,1.4)*200.)*.1;
    float d=smoothstep(.11,0.,length(p));
    return d*.5;
}

float eyebrows(vec2 p) {
    p.y-=.13;
    p.y*=10.;
    p.x=abs(p.x);
    p.y-=p.x*1.5;
    p.y+=smoothstep(.16,.25,p.x)*.6;
    p.x-=.13;
    float d=smoothstep(.1,0.05,length(p));
    return d*.7;
}

vec4 eyes(vec2 p) {
    p.x=abs(p.x*1.1);
    p.x-=.125;
    p.y-=.08;
    float d=smoothstep(.03,.02,length(p));
    float pup=smoothstep(.02,.00,length(p));
    float bri=smoothstep(.012,.0,length(p));
    p.y*=2.;
    p.x*=1.1;
    p.y+=p.x*p.x*5.;
    p.y-=p.x*.1;
    p.y=abs(p.y);
    p.y+=.02;
    p.x-=.003;
    float blanc=smoothstep(.065,.055,length(p));
    return vec4(vec3(blanc-d*.75-pup+bri*1.3),blanc);
}

float mouth(vec2 p) {
    p.x=abs(p.x*1.1);
    vec2 p2=p;
    p2.x-=.11;
    p2.y+=.13;
    float oy=smoothstep(.015,.0,length(p2));
    p.y+=.16;
    p.y*=20.;
    p.y-=smoothstep(0.05,.1,p.x)*.2;
    p.y-=pow(p.x,1.7)*20.;
    p.y+=smoothstep(0.,.05,p.x)*.1;
    float mo=(smoothstep(.05,.0,length(p)-.07));
    mo+=oy*.5;
    return mo*.5;
}

vec4 lips(vec2 p) {
    p.x=abs(p.x*1.2);
    vec2 p2=p;
    p.y+=.152;
    p.y+=p.x*.05;
    p.y*=15.;
    float d=smoothstep(.1,.0,length(p));
    p2.y+=.17;
    p2.y*=8.;
    p2.y-=p.x;
    d=max(d,smoothstep(.1,.0,length(p2)));
    return vec4(lipcolor,d);

}

vec4 head(vec2 p) {
    p.y-=.02;
    p.x*=1.4;
    p.x*=1.-+p.y*.8;
    p.x*=1.+pow(smoothstep(.15,.3,-p.y),2.)*.3;
    p.x*=1.-pow(smoothstep(-.1,.5,-p.y),.3)*.05;
    p.x*=1.+pow(smoothstep(-.2,.2,p.y+.1),3.)*.1;
    float d=smoothstep(.02,.0,length(p)-.3);
    return vec4(skincolor,d);
}

float touchs(vec2 p) {
    p.x=abs(p.x);
    vec2 p2=p,p3=p,p4=p,p5=p;
    p.y-=.06;
    p.y*=10.;
    p.y+=p.x*1.5;
    p.x-=.1;
    p.y-=pow(abs(p.x),2.)*50.;
    float d=smoothstep(.05,.03,length(p));
    p2.y+=.05;
    p2.x-=.14;
    float li=smoothstep(.08,.0,length(p2));
    p3.y+=.05;
    p3.x*=1.5;
    li=max(li,smoothstep(.08,.0,length(p3)));
    p4.x-=.07;   
    p4.y-=.065;
    float oj=smoothstep(.04,.0,length(p4));
    p5.x-=.05;
       p5.y+=.03;
    p5.x*=2.+(p.y*2.5-1.);
    float on=smoothstep(.05,.0,length(p5));
    d-=li*.6;
    d+=oj;
    d+=on*.5;
    return d*.2;
}

vec4 hairfront(vec2 p) {
    p.y-=.25+p.x*.3;
    p.x-=p.y*.5;
    p.x-=p.y*p.y*2.;
    p.x+=.12;
    p.y-=fract(p.x*20.)*.1;
    float d=smoothstep(.01,.0,box(p,vec2(.12,.1)));
    float lines=fract(p.x*50.)*.1;
    return vec4(haircolor+lines,d);
}

vec4 hairback(vec2 p) {
    p.x=abs(p.x);
    p.x-=.18;
    p.x*=1.+p.y*p.y*5.;
    float d=smoothstep(.01,.0,box(p,vec2(.1,.3)));
    float lines=fract(p.x*50.)*.1;
    return vec4(haircolor+lines,d);
}

vec3 neck(vec2 p) {
       p.y+=.5;
    float d=step(length(p),.3);
    return d*skincolor*.7;
}

vec4 glasses(vec2 p) {
    p.x=abs(p.x);
    vec2 p2=p;
    p.x-=.13;
    p.y-=.035;
    p.x*=1.-smoothstep(.0,.1,p.y)*.5;
    p.y-=p.x*.1;
    p.y+=pow(abs(p.x)*4.,2.)*.15*sign(p.y);
    float frame=abs(box(p,vec2(.06,.02))-.05);
    float glass=smoothstep(.01,.0,box(p,vec2(.06,.02))-.05);
    float d=smoothstep(.01,.0,frame);
    p2.y-=.05-p.x*.2;
    float u=smoothstep(.01,.0,box(p2,vec2(.02,.01)));
    d=max(d,u);
    return vec4(.2+vec3(length(p*2.)*max(0.,p.x)*10.),d+glass*.25);
}

vec3 render(vec2 p) {
    vec2 pos=floor(p*50.);
    p*=.57;
    p.y-=.01;
    vec3 c=neck(p);
    vec4 haback=hairback(p);
    c=mix(c,haback.rgb,haback.a);
    vec4 he=head(p);
    c=mix(c,he.rgb,he.a);
    c-=mouth(p);
    c-=eyebrows(p);
    c-=nose(p);
    c-=touchs(p);
    vec4 ey=eyes(p);
    vec4 haf=hairfront(p);
    vec4 lip=lips(p);
    vec4 gla=glasses(p);
    c=mix(c,ey.rgb,ey.a);
    c=mix(c,haf.rgb,haf.a);
    c=mix(c,lip.rgb,lip.a);
    c=mix(c,gla.rgb,gla.a);
    float frame=box(p,vec2(.25,.3));
    c*=smoothstep(.06,.05,frame);
    c+=pow(frame,1.)*2.*rnd23(pos*123.+floor(time*5.)*.345);
    return c;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    uv=floor(uv*100.)/100.;
    
    vec3 col = render(uv);

    glFragColor = vec4(col,1.0);
}
