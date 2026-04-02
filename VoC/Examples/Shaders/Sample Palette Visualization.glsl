#version 420

// original https://www.shadertoy.com/view/MtsXR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 Palette(vec3 a, vec3 b, vec3 c, vec3 d, float t){
   return a+b*sin(6.28*(c*t+d)); 
}

vec3 Amplitude = vec3(.5,.5,.5);
vec3 Frequency = vec3(1.,1.,1.);
vec3 XOffset;
vec3 YOffset   = vec3(.5,.5,.5);

void main(void) {
    XOffset   = -vec3(0.,time/2.1,time/2.2);

    vec2 scaledp = gl_FragCoord.xy / resolution.xy;
    
    vec3 palettecolor = Palette(YOffset,Amplitude,Frequency,XOffset,scaledp.x);
    vec3 graphcolor = vec3(0);
    
    vec3 distance3 = abs(palettecolor-scaledp.y*2.+1.);
    if(distance3.x<0.02){
        graphcolor.x = 1.;
    }else if(distance3.y<0.02){
        graphcolor.y = 1.;
    }else if(distance3.z<0.02){
        graphcolor.z = 1.;
    }
     
    vec3 color = vec3(0);
    
    if(dot(graphcolor,vec3(1))>0.01){
        color = graphcolor;
    }else{
        color = palettecolor;
    }
    
    glFragColor = vec4(color,1.0);
}
