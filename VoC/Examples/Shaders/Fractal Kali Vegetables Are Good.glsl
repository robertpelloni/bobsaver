#version 420

//original https://www.shadertoy.com/view/ls23Wz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time2 time*.1

#define width .02

vec3 colo=vec3(0.);
float ot=0.;
float pix;

float formula(vec2 z) {
    z=z.yx;
    float ot1,ot2=ot1=1000.;
    for (int i=0; i<14; i++) {
        z=(z+vec2(z.x,-z.y)/dot(z,z)-vec2(2.,.0))*-.345;
        ot1=min(ot1,abs(z.x/z.y)*.3-.03);
        ot2=min(ot2,length(z)-.04);
    }
    ot=min(ot1,ot2);
    colo+=mix(vec3(.5,0.15,0.),vec3(.2,.4,.2),clamp((ot2-ot1)*150.,0.,1.));
    float h=max(0.,width-ot)/width;
    return pow(h,.1)*5.;
}

vec3 normal(vec2 z) {
    vec2 d=vec2(0.,pix);
    vec3 n=normalize(cross( //get normal
    vec3(d.y*2.,0.,formula(z-d.yx)-formula(z+d.yx)),
    vec3(0.,d.y*2.,formula(z-d.xy)-formula(z+d.xy))));
    return n;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
    uv=uv+vec2(sin(time2)+1.5,cos(time2)+1.);
    uv*=.5;
    pix=1./resolution.x*.5;
    vec2 d=vec2(0.,pix);
    colo=vec3(0.);
    vec3 n= normal(uv-d.xy)+normal(uv+d.xy);
         n+=normal(uv-d.xy)+normal(uv+d.yx);
         n*=.25;
    colo/=16.;
    float t=time2*3.;
    vec3 lightdir=normalize(vec3(1.,1.,.2));
    colo*=max(0.4,dot(n,vec3(0.,0.,1.)))+max(0.,dot(-n,lightdir));
    colo+=pow(max(0.,dot(reflect(-n,vec3(0.,0.,-1.)),lightdir)),30.)*.3;
    colo=mix(vec3(0.,.2,.6),colo,pow(max(0.,width*3.-ot)/width/3.,4.));    
    colo=mix(vec3(length(colo)),colo,.8)*.5*vec3(.7,.8,1.);
    glFragColor = vec4(colo,1.0);
}
