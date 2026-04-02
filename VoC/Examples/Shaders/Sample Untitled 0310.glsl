#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    vec2 p = abs((gl_FragCoord.xy*2.0-resolution.xy)/resolution.x);
    p.x+=sin(time*0.317)*.23;
    p.y+=cos(time*0.081)*.07;
    float t1 = time*0.2;
    mat2 rot = mat2(cos(t1),sin(t1),-sin(t1),cos(t1));
    p *= 6.3;
    float r = length(p);
    p*=rot;
    p*=0.6*cos(p.yx*1.5)*sin(p*1.3)-r*0.;
    //float a =atan(p.y,p.x)*11.;
    //r = a+length(p)*sin(time)*0.3;
    //r = length(p)*sin(time)*0.3;
    float s = sin(r*2.3+p.x*2.3-time*0.5)+sin(p.y*2.9+2.7*sin(r*0.+time*1.5));
    float t = sin(r*0.+p.x*2.7+time*3.2)+sin(p.y*1.1-s+2.3*sin(r*3.3+time*0.9));
    float f = (s+t);
    //glFragColor = vec4(f,f-t,t-f,1)/2.0;
    //glFragColor = vec4(t,f,s,1)/2.0;
    glFragColor = vec4(f,t,s,1)/2.0;
}
