#version 420

// original https://www.shadertoy.com/view/ttBGRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float remap (float a, float b, float d)
{
return a*d+(1.-d)*b;
}

vec4 Eye(vec2 uv, vec2 p, float r,float t)
{
    //t =1.;
    //vec4 c = vec4 (.6,.4,.15,1.);
    vec4 c = mix(vec4 (.6,.4,.15,1.),vec4 (1.),t);
    //posish
    vec2 _p = uv+p;
    _p.x += (t*r);
    _p.y += t*.05;
    //ratio
    
    _p.y *=.85;
    _p.y += t*_p.x*r*5.;
    float d = length(_p);
    r = abs(r*(1.+t));
    //infill
    float e = 1.- smoothstep(r,r+0.01,d);
    c.a = e;
    
       //drop shadow
    vec4 c2 = vec4 (.3,.2,.05,1.);
    float drop = e * -_p.y*20.;
    drop = step(0.,drop)*drop;
    drop = mix(drop,0.,t);
    c = mix(c,c2,drop);
    
    //inner glow
    // c2 = vec4 (.5,.28,.08,1.);
    c2 = mix(vec4 (.5,.28,.08,1.),vec4(0.),t);
    e *= smoothstep(r-0.05,r+.1,d);
    c = mix(c,c2,e);

    //ring
    c2 = vec4 (.2,.1,.01,1.);
    e = smoothstep(r+.005,r,d);
    e *=smoothstep(r-0.005,r,d);
    c = mix(c,c2,e);
 

    //c = vec4(e);
return vec4(c);
    
}
vec4 Mouth(vec2 uv, vec2 p, float r,float t){
    vec4 c = vec4 (.6,.4,.15,1.);
    //posish
    vec2 _p = uv+p;
    //ratio
    _p.y *=2.5-t*(1.8);
    _p.y -= abs(pow(2.*_p.x,2.))*2.*(1.-t);
     _p.y -= .02;
    float d = length(_p);
    //infill
    float e = 1.- smoothstep(r,r+0.01,d);
    c.a = e;
     //drop shadow
    vec4 c2 = vec4 (.3,.2,.05,1.);
    e *= -_p.y*10.;
    e = step(0.,e)*e;
    c = mix(c,c2,e);
     //inner glow
    c2 = vec4 (.5,.28,.08,1.);
    e *= smoothstep(r-0.1,r+.1,d);
    c = mix(c,c2,e);
    //ring
    c2 = vec4 (.2,.1,.01,1.);
    e = smoothstep(r+.01,r,d);
    e *=smoothstep(r-0.01,r,d);
    c = mix(c,c2,e);

    //c = vec4(e);
    return vec4(c);
}
vec4 Brows(vec2 uv, vec2 p, float r,float t){
    vec4 c = vec4 (.6,.4,.15,1.);
    //posish
    vec2 _p = uv+p;
    _p.y += t*.15;
    //ratio
    _p.y *=10.;
    //_p.y -= abs(pow(2.*_p.x,2.))*2.;
    _p.y += -pow(sin(_p.x/(1.5*r)-abs(1.6*r)),2.);
    r=abs(r);
    float d = length(_p);
    //infill
    float e = 1.- smoothstep(r,r+0.01,d);
    c.a = e;
     //drop shadow
    vec4 c2 = vec4 (.3,.2,.05,1.);
    e *= -_p.y*10.;
    e = step(0.,e)*e;
    c = mix(c,c2,e);
     //inner glow
    c2 = vec4 (.5,.28,.08,1.);
    e *= smoothstep(r-0.1,r+.1,d);
    c = mix(c,c2,e);
    //ring
    c2 = vec4 (.2,.1,.01,1.);
    e = smoothstep(r+.01,r,d);
    e *=smoothstep(r-0.01,r,d);
    c = mix(c,c2,e);
    c.a = mix(c.a,0.,t);
    //c = vec4(e);
    return vec4(c);
}
vec4 head(vec2 uv,float r,float t){
    
    vec4 c = vec4(.89,.65,.25,1.);
    vec4 c2 = vec4(.87,.42,.19,1.);
    
    float d = length(uv);
    d =mix(length(uv),
        step(0.,-uv.y)*length(uv)+ 
        step(0.,uv.y)*(length(uv)+(uv.y*.1))*pow(cos(uv.y/2.),4.),
          t);
    
    //center
    float face = 1.- smoothstep(r,r+0.01,d);
    c.a = face;
    
    float blue = face * (t*.5-uv.y)*t;
    c = mix(c,vec4(.2,.3,1.,1.),blue);
    
    //side curve
    face *= 1.-smoothstep(r+.1,r-0.1,d);
    c = mix(c,c2, face);
    
    
    
    //edge 
    float edge = smoothstep(r+.02,r+0.01,d);
    edge *= smoothstep(r,r+0.01,d);
    edge *=.7;
    
    c2 = vec4(.87,.42,.19,1.);
    c = mix(c,c2,edge);
    
    //hightlight
    float highlight= smoothstep(r -0.05,r-.15,d);
    highlight *= step(0.,(-uv.y)*2.)*(-uv.y)*2.;
        
    c2 = vec4(1.);
    c =  mix(c,c2,highlight);
    
    //shadow
    float shadow = smoothstep(r -0.05,r-.15,d);
    shadow *= step(0.,(uv.y)*2.)*(uv.y)*2.;   

    c2 = vec4(.9,.7,.3 ,1.);
    c =  mix(c,c2,shadow);  

return vec4(c);
}
vec4 Hand(vec2 uv, vec2 p, float r, float t)
{
     //t =1.;
    vec4 c = vec4(.89,.65,.25,1.);
    vec4 c2 = vec4(.87,.42,.19,1.);
    //posish
    vec2 _p = uv+p;
    //ratio
    _p.y += (t-1.)*.7;
    _p.x += (t-1.)*r*8.;
    _p.y *= .2;
    _p.x += pow(_p.y*2.,2.)*r*100.;
    float d = length(_p);

    r = abs(r);
    //infill
    float e = 1.- smoothstep(r,r+0.001,d);
    c.a = e;
    
       //drop shadow
    c2 = vec4 (.8,.3,.3,1.);
    float drop = e * -_p.y*10.;
    c = mix(c,c2,drop);
    
    //inner glow
     c2 = vec4 (.5,.28,.08,1.);
    e *= smoothstep(r-0.05,r+.08,d);
    c = mix(c,c2,e);

    //ring
    c2 = vec4 (.2,.1,.01,1.);
    e = smoothstep(r+.004,r,d);
    e *=smoothstep(r-0.005,r,d);
    c = mix(c,c2,e);
 

    //c = vec4(e);
return vec4(c);

}

vec4 emoji(vec2 uv,vec2 p,float t){
    vec4 c = vec4(0.);
    vec2 pos = p-uv;
    vec4 head = head( pos,.5,t);
    c = mix(c, head, head.a);
    vec4 eye = Eye(pos,vec2 (.13,.07),.05,t);
    c = mix(c, eye, eye.a);
    eye = Eye(pos,vec2 (-.13,.07),-.05,t);
    c = mix(c, eye, eye.a);
    vec4 mouth = Mouth(pos,vec2 (0.,-.2),.12,t);
    c = mix(c,mouth,mouth.a);
    vec4 brows = Brows(pos,vec2 (.18,.3),.1,t);
    c = mix(c,brows,brows.a);
    brows = Brows(pos,vec2 (-.18,.3),-.1,t);
    c = mix(c,brows,brows.a);
    vec4 hand=Hand(pos,vec2 (.33,-.4),.06,t);
    c = mix(c,hand,hand.a);
    hand=Hand(pos,vec2 (-.33,-.4),-.06,t);
    c = mix(c,hand,hand.a);

return vec4(c);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv -=.5;
    uv.x *= resolution.x/resolution.y;

    // Time variable t 0 < > 1
    float t = sin(time*.8)*.5+.5;
    //vec4 col = head(uv, vec2(0.,0.),.5);
    vec4 col = emoji(uv, vec2(0.,0.),t);
    
    // Output to screen
    glFragColor = vec4(col);
}
