#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 circle(in vec2 p, float r, vec3 rcol)
{
    if (length(p) < r)
        return rcol*20.0*(r- length(p));
    
    
    return vec3(0,0,0); 
}
void main( void ) {

    vec2 p = 2.0*(gl_FragCoord.xy / resolution.xy) - 1.0;
    p.x *= resolution.x/resolution.y;
    //p.x += sin(time*5.0)*0.2;
    
    vec2 p2 = p;
    float r2 = 0.0;
    
    vec3 col = vec3(0.0,0.0,0.0);
    float xoffset = 0.0;
    
    for (int x = -11; x < 11; x++)
    {
        p2.x = p.x+float(x)*0.2;
        p2.y = p.y + cos((time+float(x))*7.0) * 0.2 * (0.2+1.5*sin(time*0.39));
        r2 = sin(time*5.0+float(x))*0.1+0.3;
        
        col += circle( vec2( p2.x, p2.y ), 
                   r2, 
                   vec3(p2.x+(r2*0.25),-0.1,-p2.y*0.2));
    }
    
    glFragColor = vec4(0.1,0.11,0.22,1.0);
    
    glFragColor += vec4(col,1.0);

}
