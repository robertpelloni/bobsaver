#version 420

// original https://www.shadertoy.com/view/3sXyDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float box(vec2 uv, vec2 size){
    vec2 d = abs(uv)-size;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
mat2 r(float a){
    float c=cos(a),s=sin(a);
    return mat2(c,-s,s,c);
}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy -.5* resolution.xy) / resolution.y;
    uv*=.8;
    float d = 0.;
    float limit = 12.;
    vec3 col = vec3(0.);
    for(float i=0.1;i<=1.;i+=1./limit){
             
         float q = mix(1.,5.,i)* box( uv*r(i*time+sin(time)) + vec2(i*.1*sin(time),i*.1*cos(time)) , vec2(.3*i,pow(i,2.)*.2+.1) );
         q = abs(q) -(.02*i);
         q = smoothstep(0.001,0.0009*i,q);
         d += q;
           col.g +=  clamp(1.,.0,q*(.02/ (.0001+fract(time*.5+i))));
           col.b +=   fract(time+i)*q  ;
       
          }
   
  
    glFragColor = vec4(col,1.0);
}
