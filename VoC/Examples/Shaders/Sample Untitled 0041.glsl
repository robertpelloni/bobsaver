#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
    return mat2(0.0, sin(a), 0.0, cos(a));
}

void main( void ) {

    vec2 position = gl_FragCoord.xy/resolution-vec2(0.5,0.0)*vec2(1.0,2.0);
    float color = 0.0;
    float height = 0.0;
    for(int i=0;i<30;i++) {
    
    position.y += sin(time/2.0)*0.0017+0.0057;
    vec2 a = floor(rot(3.1415*(.3+time/16.0))*(position+sin(-time/4.0)/2.0)*20.0);
    vec2 b = floor(rot(-3.1415*(.2-time/16.0))*(position-sin(time/4.0)/2.0)*20.0);

    height = max(height, float(26-i)*0.016*floor(3.0*sin(a+sin(a*b+time/10.0)-b*sin(a+2.0)).y));
    //    height = max(height, float(30-i)*0.04*sin(sin(a*b+time)).y);
    }
    
    color += ceil(height);
    
    //glFragColor = vec4( vec3( color, color * 0.5, sin( color + time / 1.0 )-.8 ), 0.0 );
    glFragColor = vec4(vec3( floor(color*1.17)-color*0.8, (height+.5)*((height+.1)/1.5 ), (height+.1)/1.5 ), 0.0 );
}
