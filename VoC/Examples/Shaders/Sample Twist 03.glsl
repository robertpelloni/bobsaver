#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float pi = atan(1.)*4.;
float tau = pi*2.0;

vec3 HLine(float start,float end,vec2 p)
{
    float bounds = max(0.0,step(p.x,start)-step(p.x,end));
    float width = end-start;
    
    p.x = (p.x - start)/width;
    
    vec3 color = vec3(step(sin(p.x*4.0*pi)*sin(p.y*8.0*pi),0.0)*0.5+0.5)*p.x;
    
    return color*bounds;
}

void main( void ) {

    vec2 res = vec2(resolution.x/resolution.y,1.0);
    
    vec2 p = ( gl_FragCoord.xy / resolution.y ) - res/2.0;
    
    float ang = time*1.+p.y*sin(time)*6.;
    
    float x1 = sin(ang + tau * 0.00) * 0.2;
    float x2 = sin(ang + tau * 0.25) * 0.2;
    float x3 = sin(ang + tau * 0.50) * 0.2;
    float x4 = sin(ang + tau * 0.75) * 0.2;
    
    vec3 col = vec3(0.0);
    col += HLine(x1,x2,p) * vec3(1,0,0);
    col += HLine(x2,x3,p) * vec3(0,1,0);
    col += HLine(x3,x4,p) * vec3(0,0,1);
    col += HLine(x4,x1,p) * vec3(1,1,0);
    
    glFragColor = vec4(col, 1.0);

}
