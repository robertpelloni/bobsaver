#version 420

// original https://www.shadertoy.com/view/Nt3GDs

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 coords = (gl_FragCoord.xy-0.5*resolution.xy )/max(resolution.x,resolution.y) ;
    
    float angle = ((atan(coords.y,coords.x)+(3.14159*1.0))/(3.14159*2.0))-0.25;
    float timeH = smoothstep(0.9995,1.0,sin(fract(angle+date.w/(3600.0*12.0))*3.14159))*smoothstep(0.88,0.89,1.0-length(coords));;
    float timeM = smoothstep(0.9995,1.0,sin(fract(angle+date.w/(3600.0))*3.14159))*smoothstep(0.83,0.84,1.0-length(coords));;
    float timeS = smoothstep(0.9999,1.0,sin(fract(angle+date.w/(60.0))*3.14159))*smoothstep(0.8,0.81,1.0-length(coords));
    
    float clockInnerCircle = smoothstep(0.227,0.230,length(coords));
    float clockOuterCircle = smoothstep(0.255,0.258,length(coords));
    
    float clockLines = smoothstep(0.99,1.0,abs(sin(angle*3.14159*12.0 + 3.14159*0.5)))*smoothstep(0.165,0.17,length(coords))*smoothstep(0.785,0.786,1.0-length(coords));
    float clockLinesSeconds = smoothstep(0.97,1.0,abs(sin(angle*3.14159*60.0 + 3.14159*0.5)))*smoothstep(0.189,0.19,length(coords))*smoothstep(0.785,0.786,1.0-length(coords));
    
    float clockShape=clockLinesSeconds+clockInnerCircle-clockOuterCircle+clockLines + timeS+timeH+timeM+smoothstep(0.975,0.980,1.0-length(coords));
    
    glFragColor = vec4(clockShape,clockShape,clockShape,1.0);
}
