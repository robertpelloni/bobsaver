#version 420

// original https://www.shadertoy.com/view/WltfzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float bbox(vec2 uv, vec2 a,vec2 b,float t){
    float l = length(b-a);
    vec2 d = (b-a)/l;
    vec2 q = uv - (a+b)*.5;
    q = mat2(d.x,-d.y,d.y,d.x)*q;
    q = abs(q) - vec2(l,t)*.5;
    return length(max(q,vec2(0.))) + min(max(d.x,d.y),0.);
}
float tt (vec2 uv,vec2 offset){
    float d = bbox(uv,vec2(.0,.2)+offset,vec2(.2,-.2)-offset,.001);
     d = min(d,bbox(uv,vec2(-.2,-.2)-(offset/offset),vec2(0,.2)+offset,.001));
      d = min(d,bbox(uv,vec2(-.2,-.2)+offset,vec2(.2,-.2)-offset,.001));
    d = (.01+sin(uv.y*20.+uv.x*10.+time)*.005)/d;
    return d;
}
vec2 h21(float t){
    float x = fract(sin(t*546.54)*815.2);
    float y = fract(sin(t*461.541)*401.5);
    return vec2(x,y);
}

mat2 r(float a){
    float c=cos(a),s= sin(a);
    return mat2(c,-s,s,c);
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy -.5* resolution.xy) / resolution.y;
    uv*=2.0;
    vec3 col = vec3(0.);
    const float lim = 10.;
    for(float i=0.;i<lim;i++){
      float rr = fract((-time-100.)*i/lim);
      rr = mix(.05,10.,rr);
      vec2 lv = uv;
      
    float d = tt((lv*r(time+100.+i)*rr),h21(floor(100.+time*.05+i))*.09);
      col += vec3(d,d-.1,d-.2);
    }
   
    glFragColor = vec4(col,1.0);
}
