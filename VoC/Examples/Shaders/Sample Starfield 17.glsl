#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float h(float i){
    return fract(pow(3., sqrt(i/2.)));
}

void main(void){
    
    
    vec2 p=gl_FragCoord.xy*2.-resolution;
    
    float a=floor(degrees(4.+atan(p.y,p.x))*2.)/4.;
    
    float tt = floor(mod(1.+time*2.,90.));
    
    float tt2 = pow(abs(time*2.),1.2);
    
    float d=pow(2.,-10.*fract(0.5*tt2*(h(a+.5)*-.1-.1)-h(a)*1000.));
    
    if(abs(length(p)-d*length(resolution)) < d*tt){
        glFragColor=vec4(d*(h(a+.5)*3.));
    }else{
        glFragColor=vec4(0.);
    }
}
