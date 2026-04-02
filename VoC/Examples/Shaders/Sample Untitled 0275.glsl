#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;
void main( void ) {

    vec2 p = 2.0*( gl_FragCoord.xy / resolution.xy ) -1.0;
    vec2 uv = gl_FragCoord.xy / (resolution.x, resolution.y);
    p.x *= resolution.x/resolution.y;
    vec3 col = vec3(0);
    vec3 col2 = vec3(0);
    vec2 uv2 = gl_FragCoord.xy / (resolution.x,resolution.y);
    vec2 op = p; 
    for (int i = 0; i < 6; i++) {
        
        p = op; 
    p.x = mod(p.x+2.0+time, 4.0)-2.0;
    p.y = -abs(p.y)+ 0.6;
    uv2 = uv2 * sin(time*p.y);
    float d = sin(p.x+0.5*smoothstep(0.0,5.0,p.x-5.*0.0+0.0)-0.5*smoothstep(0.0,1.0,p.x+2.0));
        
    col += vec3(1,1,1)*3.0/(1.0+100.0*-d)/(1.0+p.y*float(i));
        col2 += vec3(3,5,1)*10.0/(1.0+45.0*d)/(10.0+p.y*float(i));
    if (d < 0.005) col += vec3(0)/(1.0+0.2*float(i)); 
    op *= 1.4;    
    }
    col *= 0.1*col2;
    glFragColor = vec4(sqrt(col2*col)-exp(col2-time)*0.5, 1.0); 
}
