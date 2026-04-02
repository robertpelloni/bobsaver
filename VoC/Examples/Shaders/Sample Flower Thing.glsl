#version 420

// original https://www.shadertoy.com/view/ldVyDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdCircle(vec2 p, float r) {
     return length(p) - r;
}

vec2 cMov(vec2 p, vec2 trans) {
     return p - trans;   
}

vec4 cRep4(vec2 p, float n) {
    vec2 pn = p * n;
     return vec4(fract(pn) * 2.0 - 1.0, floor(pn));   
}

vec2 cRot(vec2 xy, float angle) {
    float s = sin(angle);
    float c = cos(angle);
     return xy * mat2(c, -s, s, c);
}

float correct(float d) {
      float e = 2.0/resolution.y;
      return d<0.1 ? d/length(vec2(dFdx(d),dFdy(d))/e) : d;
}

float asLine(float d) {
    return smoothstep(0.01,.0,abs(d));
}

float asFilled(float d) {
    return smoothstep(0.01,0., d);
} 

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec4 m =  vec4(0.0);//(2.*mouse*resolution.xy  - resolution.xyxy) / resolution.y;
    
    uv = cRot(uv,-time/10.0);
    vec4 uv4 = cRep4(uv,1.0/(0.3 + sin(time*.6)*0.2));
 
    uv = uv4.xy; 
    float dist = length(uv4.zw);
    float id = 5.0*uv4.z+uv4.w;
    vec3 bgColour = vec3(1.0+uv4.z/16.0, 0.5+uv4.w/16.0, dist/time);
    
    float radius = 0.6 + sin(time * dist * max(1.0,3.0/(abs(id)+1.)) + atan(uv.x,uv.y)*min(10.0,abs(id)))*0.2;
    float d = correct(sdCircle(uv, radius));
    
    glFragColor = vec4(bgColour * (abs(id)<10. ? asLine(d): asFilled(d)),1);
}
