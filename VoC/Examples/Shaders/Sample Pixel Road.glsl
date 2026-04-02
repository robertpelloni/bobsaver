#version 420

// original https://www.shadertoy.com/view/WdtGzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(vec2 p) {
   
    p = fract(p*vec2(234.34, 435.345));
    p += sin(dot(p, p+342.23));
    return fract(p.x*p.y);
    

}
mat2 r(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
void main(void)
{
     vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
     uv*=r(sin(uv.x))*15.;
     
     vec2 guv = fract(uv+vec2(0,0));
     vec2 id = floor(uv+vec2(0,0));
     float d = guv.x;
     //if(hash(id) >0.5) d = 1.-guv.x;
     vec3 col = mix(vec3(0.1),vec3(.9,.9,.0),vec3(d));
     col.r *= (sin(id.y+time*10.)) ;
     col.g *= .5+hash(id+time/1000000.) ;
     if(mod(id.y,  5.) == 0. ) col.b+=.9 ;
     else col.b=.0;
     
     if(mod(abs(id.x),5.) == 2.-step(0.,sign(id.x))) col*=vec3(1.9,1.2,.0);
    glFragColor = vec4(col,1.0);
}
