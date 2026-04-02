#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotz(in vec2 p, float ang) { return vec2(p.x*cos(ang)-p.y*sin(ang),p.x*sin(ang)+p.y*cos(ang)); }
void main( void ) {

    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y); 
    
      float d = 2.*length(p);
    
    vec3 col = vec3(0); 

    p = rotz(p, time*0.5+atan(p.x,p.y)*8.0);
     //p *= 2.1+sin(time*0.5); 
    
    for (int i = 0; i < 18; i++) {
        
        float dist = abs(p.y + sin(float(i)+time*0.3+3.0*p.x)) - 0.2;
        if (dist < 1.0) { col += (1.0-pow(abs(dist), 0.28))*vec3(0.8+0.2*sin(time),0.9+0.1*sin(time*1.1),1.2); }
        p *= 0.99/d; 
        p = rotz(p, 30.0) ;
    }
    col *= 0.49 ; 
    glFragColor = vec4( col-d-0.4, 1.0); 
}
