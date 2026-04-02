#version 420

uniform float time;

out vec4 glFragColor;

uniform vec2 resolution;

#define PI 3.14159265

void rotate2D (inout vec2 vertex, float rads)
{
  mat2 tmat = mat2(cos(rads), -sin(rads),
                   sin(rads), cos(rads));
 
  vertex.xy = vertex.xy * tmat;
}

void main( void ) {

    
    
    vec2 p = ( gl_FragCoord.xy / resolution.xy ) - 0.5;
    
    p.x /= resolution.y/resolution.x;
    
    rotate2D(p, (-2.0*PI/12.0) );
    
    vec2 p2 = vec2((p.x - 0.5)*2.0, (p.y - 0.5)*2.0);
    float x = p.x;
    
    float t = atan(p.y,p.x);
    
    float h = t / (2.0* PI) * 6.0 + time;
    
    
    rotate2D(p, floor(2.0+h)*(-2.0*PI/6.0) );
    
    
    
    
    float dy = 1./ ( 50. * abs(length(p.y) - 0.3));
    
    glFragColor = vec4( (x + 0.2) * dy, 0.5 * dy, dy, 1.0 );

}
