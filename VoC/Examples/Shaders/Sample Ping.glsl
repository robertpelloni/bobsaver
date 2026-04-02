#version 420

// original https://www.shadertoy.com/view/3djcWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

# define PI 3.141592653589793
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv.y+=time*0.1;
    
    vec2 u = fract(uv.xy*5.)-0.5;
    
   
    float z = 5.;
    vec2 g = time*.02 + floor(uv * z);
    float b =  rand(floor(g + 3.321))*3.;
    float r =.7;
    float angle = PI*0.25+floor(rand(floor(g))*4.)*PI*0.5;      
    u.x+=sin(angle)*r;
    u.y+=cos(angle)*r;
    float d = length(u*.3);
 //    float k = smoothstep(d,d*1.01,0.5);
    float k = fract(d*3.0-time*(b-0.5)*0.2);
    k += sin(time * r + angle);
    k = sin(fract(k*.13)*1.5)*1.2;
    vec3 cc = mix( vec3(.08, 0.15, 0.3), vec3(1.2, 0.13, 0.2), k);
    glFragColor = vec4(cc,1.0);
}
