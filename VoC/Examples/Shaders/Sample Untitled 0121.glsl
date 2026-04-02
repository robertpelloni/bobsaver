#version 420

//xL

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform sampler2D backbuffer;

float pi=3.14159265;
vec3 color = vec3 (.0,.0,.0);
float freq = 2.2222;
float ratio;
float ti;
vec3 col = vec3 (.0,.0,.0);
float edge = .2;
float edgeW = .04;
float lineW = .01;
int i = 5;

void main( void ) {
    glFragColor=vec4(0.0);
    
    ratio = resolution.x/resolution.y;
    ti = time*.30;

    vec2 p = ( gl_FragCoord.xy / resolution.xy )*vec2(2.0,2.0/ratio) - vec2(1.0,1.0/ratio);
        
        
    for(int j = 1; j < 41; j++){
    
    
    float a = 3.*sin(freq*p.x+float(j)+.1*ti*float(j))/(1.+2.5/sin(p.x-pow(time, 1.100123)*.1)+float(j)*.125)+(p.y*2.0+1.0*.2);
    float b = smoothstep(edge,edge+edgeW, a)-smoothstep(edge+lineW,edge+edgeW+lineW, a);
            
    float h = b;
        float k = mod(float(j),3.);
        if(k == 0.0){
        color.r += h;}
        else if(k == 1.0){ 
        color.g += h;}
        else {color.b += h;}
            
        
    glFragColor = vec4(color, 1.)*.1+pow(length(color), 0.9);                
    }
    glFragColor *= 0.125;        
    glFragColor += texture2D(backbuffer, gl_FragCoord.xy / resolution.xy)*0.6;
    const float lIterLim = 32.;
    for(int l = 0; l < int(lIterLim); l++){
        vec2 delta = 0.032*vec2(sin(float(l)*2.*3.14159265/lIterLim), cos(float(l)*2.*3.14159265/lIterLim));
        glFragColor += texture2D(backbuffer, delta+gl_FragCoord.xy / resolution.xy)*0.25/lIterLim;
    }
    
}    
