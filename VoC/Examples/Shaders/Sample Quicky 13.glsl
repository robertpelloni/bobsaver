#version 420

// original https://www.shadertoy.com/view/3sc3Rs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(vec2 p) {

    p = fract(p*vec2(232.3414,389.264));
    p += dot(p.yx,p+325.45);
    return fract(p.x * p.y);
    
    
    
    
}
mat2 r(float a){return mat2(cos(a),sin(a),-sin(a),cos(a));}
void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv*=(length(uv)-2.)*r(time/4.+cos(time/2.)*2.)*5.;
    uv.x+=-time;
    vec2 id = floor(uv);
    vec2 guv= fract(uv+time)-.5;
    guv *= r(hash(id)*2.);
    vec2 q = (guv +.0) ;
    float d = 0.;
    d = mix(
     max(smoothstep(0.041,0.04,abs(dot(q.x,q.y))),step(0.4,length(guv))),
     min(smoothstep(0.041,0.04,abs(dot(q.x,q.y))),step(0.4,length(guv))),
     hash(id)
     );
    
    

    
    vec3 col =  vec3(d,d*hash(id),d*hash(vec2(hash(id))));
    glFragColor = vec4( 
        col,
        1.0);
}
