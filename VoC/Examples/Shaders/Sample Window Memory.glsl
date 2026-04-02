#version 420

// original https://www.shadertoy.com/view/wldXDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)
mat2 rot(float m){
    return mat2(cos(m),-sin(m),sin(m),-cos(m));
}

float box(vec2 uv,vec2 r, float blur){
    float d=length(max(abs(uv)-r,0.));
    d= S(blur,-blur,d);
    return d;
}

float strips(vec2 st){
    float strip=box(st,vec2(0.003,0.5),0.015);
    strip+=box(st-vec2(0.,0.47),vec2(0.25,0.008),0.015);
    strip+=box(st-vec2(0.,0.31),vec2(0.25,0.004),0.015);
    strip+=box(st-vec2(0.,0.29),vec2(0.25,0.004),0.015);
    strip+=box(st-vec2(0.,0.00),vec2(0.25,0.004),0.015);
    strip+=box(st-vec2(0.,-0.29),vec2(0.25,0.004),0.015);
    return strip;
}

float curtain (vec2 uv, float blur)
{
    vec2 st2=uv;
    st2.x=abs(st2.x);
    st2.x+=(0.25+0.0*sin(time))*2.*(st2.y+0.5)*abs(st2.x);
    st2.y=sin(st2.x*60.+time/1.+1000.5*0.0)*0.01+st2.y+0.05*0.0;
    float d2= box(st2-vec2(0.17,0.),vec2(0.12-0.01*sin(time),0.49),blur)*(0.6+0.4*0.0*(2.*sin(st2.x*50.+time/1.)+1.0))*(sin(st2.x*500.+time/1.)*0.05+1.0);
    return d2;

}
float monster(vec2 uv){
    float d;
    uv*=2.;
    uv.y-=10.*fract(time/30.)-0.5;
    float dist= length(uv*rot(1.2)-vec2(-0.1,0.12));
    d=S(0.2,0.13,dist);
    dist= length(vec2(uv.x+0.8*uv.y,0.3*sin(time*2.)*uv.x+0.7*uv.y+1.5*uv.y*uv.y));
    d+=S(0.1,0.03,dist);
    dist= length(vec2(0.2*uv.x+0.1*sin(time*3.)*uv.y-0.1,0.1*uv.x+0.7*uv.y+1.5*uv.y*uv.y));
    d+=S(0.1,0.03,dist);
    dist= length(vec2(0.5*uv.x-0.87*uv.y-0.6,-0.1*uv.x-0.7*uv.y+1.5*uv.y+0.2));
    d+=S(0.1,0.03,dist);
    d=clamp(d,0.,1.);
    return d;

}
vec3 windowColor(vec2 uv){
    float t = 0.1*time;
    
    vec4 c,col;
    col = vec4 (0.7);
   
    col+=vec4(1.,1.,0.7,1.)*(0.10/length(uv+vec2(0.7*sin(2.*t),0.1*cos(t))));
    col+=vec4(0.7,0.7,1.,1.)*(0.10/length(uv+vec2(0.,0.3)+vec2(0.7*sin(1.*t),0.1*cos(3.*t))));
    col= clamp(col,0.,2.);
    float x=0.0;
    col-=vec4(-0.1)+vec4(0.5*sin(uv.x*uv.y*100.),0.5*cos(uv.y*uv.y*100.),0.,1.)*monster(vec2(-uv.y+0.3,-uv.x));
    col= clamp(col,0.,2.);
    col-=vec4(2.7)*box(uv-vec2(0.2,-0.3),vec2(0.1,0.3),0.1);
    col-=vec4(2.0)*box(uv-vec2(-0.2,-0.4),vec2(0.05,0.2),0.1);
    col-=vec4(0.4)*box(uv-vec2(-0.1,-0.3),vec2(0.002,0.5),0.02);
    
    return col.rgb;

}

vec3 window(vec2 uv){
    vec2 st=uv;
    st.y+=0.05;
    float d= box(st,vec2(0.2,0.44),0.1);
    
    
    // Time varying pixel color
    vec3 col = vec3(0.01);
    col=mix(col,vec3(1.),0.2*(1.-box(uv,vec2(0.7,0.5),0.05))*abs(uv.x));
    //col*=S(0.01,-0.01,uv.x+uv.y);
    //col*=texture(iChannel0,uv*1.).r;
    col=mix(col,windowColor(uv),d);
    float strip=strips(st);
    col=mix(col,vec3(0.0),0.8*strip);
    st=abs(st);
    //st*=rot(3.14/4.);
    //col= vec3(1./length())/10.;
    float d2=curtain(uv*vec2(0.8,0.9),0.05);
    d2+=curtain(uv*vec2(1.2,0.9),0.03)/2.;
    d2+=curtain(uv*vec2(1.05,0.9),0.02)/4.;
    d2*=S(0.5,0.35,uv.y);
    col=mix(col,vec3(0.8),0.7*d2)*1.3;
    return col;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    //uv*=1.1;
    vec3 col=window(uv);
    //col+=window(uv-vec2(0.9,0.))/3.;
    //col+=window(uv-vec2(-0.9,0.));
    //col=vec3(monster(uv));
    // Output to screen
    glFragColor = vec4(col,1.0);
}
