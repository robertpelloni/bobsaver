#version 420

uniform float time;uniform vec2 resolution;float N(vec2 v){return fract(sin(dot

out vec4 glFragColor;
(vec2(7.,23.),v))*519.);}vec2 e=vec2(1.,0.),s=vec2(0.0),f,F;float M(vec2 v){F=floor(v);f=
fract(v);f*=f*(3.-2.*f);return mix(mix(N(F),N(F+e.xy),f.x),mix(N(F+e.yx),N(F+e.
xx),f.x),f.y);}float B(vec2 v){return M(v)+.5*M(v*2.)+.2*M(v*8.);}float t=time,
l=0.,r;void main(){for(int i=0;i<99;++i){vec3 q=vec3(gl_FragCoord.xy/resolution
.xy-.5,1.)*l;q.z-=2.;q.x*=1.8;r=length(q)-1.;s=42.*(q.xy+M(vec2(r-t*.5))-M(vec2
(r-t*.3))*e.xy);l+=.4*(r+.2*B(s));}glFragColor=1.-vec4(B(s),B(s+.1),B(s+.3),1.)
;}
