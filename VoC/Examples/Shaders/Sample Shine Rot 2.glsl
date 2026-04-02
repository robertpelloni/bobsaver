#version 420

// original https://www.shadertoy.com/view/dssBDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float m(float a){return fract(time*a)*3.141593*4.;}int n=0;mat2 j(float a){float b=sin(a),c=cos(a);return mat2(c,b,-b,c);}vec4 v=vec4(0),e=vec4(0);float g(vec3 a){float b=5.;a.y-=.1,a.yz*=j(.282743),a.xy*=j(m(-.025)),a.xy*=j(a.z*-.8),a.z+=fract(-time*.25),a=mod(a,vec3(.5,.5,.5))-vec3(.25,.25,.25),b=max(length(a.xy)-.05,abs(a.z)-.251),n==1?v.a=b:e.a=b;return b;}vec3 o(in vec3 b){vec2 a=vec2(1,-1)*.5773;return normalize(a.xyy*g(b+a.xyy*5e-4)+a.yyx*g(b+a.yyx*5e-4)+a.yxy*g(b+a.yxy*5e-4)+a.xxx*g(b+a.xxx*5e-4));}vec3 l(vec2 a){vec2 b=a.xy-.5,c=b.xy*b.xy+sin(a.x*18.)/25.*sin(a.y*7.+1.5)+a.x*sin(0.)/16.+a.y*sin(1.2)/16.+a;float d=sqrt(abs(c.x+c.y*.5)*25.)*5.;return vec3(sin(d*1.25+2.),abs(sin(d*1.-1.)-sin(d)),abs(sin(d)*1.));}float p(inout vec3 a,inout float b,inout float c,vec3 h,inout vec3 i,int k){float d=0.;for(int f=0;f<130;f++){a=h+i*b,c=g(a);if(b>1000.)break;b+=c*.32222,d+=c*(1.-(a.z/2.+.5));}return d;}void w(vec3 q,vec3 b){n++;float r=0.,h=0.;vec3 i=normalize(vec3(.57703));i.xy*=j(m(.25));vec3 s=normalize(i-b),c=vec3(0);float d=p(c,r,h,q,b,0);if(h<1e-3){vec3 a=o(c);float z=dot(a,vec3(0,-.3,0)),f=clamp(dot(a,vec3(2.1,-1,-5)),0.,1.),t=clamp(dot(a,vec3(0,-.5,.3)),0.,1.),x=clamp(dot(a,vec3(.5,-1.1,-5.1)),0.,1.),u=pow(clamp(dot(a,s),.52,2.),50.);u*=f+t;vec3 k=reflect(a,b*.1);float y=exp(-.0121*d*d);e.rgb=f*l(k.xy)+t*l(k.xy)*.2+x*l(k.xy)*.15,e.rgb*=.3,e.rgb+=sign(e.rgb)*.6,e.rgb*=f,e.rgb+=vec3(u*vec3(.5))+(.5+.35*cos(f+b.xyx*2.+vec3(0,2,4)))*.4,e.rgb*=y;}}

void main(void) {
    vec2 a=gl_FragCoord.xy/resolution.xy;
    a=(a-.5)*2.,a.x*=resolution.x/resolution.y;
    vec3 b=vec3(1),c=vec3(0,0,-3),d=vec3(a,1);
    w(c,d);b=e.rgb;
    glFragColor=vec4(b,1);
}
