#version 420

// original https://www.shadertoy.com/view/tlsfzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec4 SUN = vec4(1.0, 0.870, 0.482, 1.0);
const vec4 SKY = vec4(0.525,0.78,0.86, 1.0);
const float PI = 3.14159265359;

void PalmTree(inout vec4 col, vec2 p, vec2 c, float size, float leaf_count, 
               float orientation, float band, float leaf_size, 
              float trunk_width, float trunk_curve)
{
    // leaves
    vec2 q = p - c;    
    float r = size + leaf_size * cos(atan(q.x, q.y) * leaf_count - band * q.x + orientation);
    col *= smoothstep(r, r + 0.02, length(q));
    
    // trunk
    r = trunk_width * (1. + abs(sin(12. * q.y)));
    r += 0.0015 * exp(-80. * p.y / 68.5); // the thick part at the end
    col *= 1.0 - (1.0 - smoothstep(r, r + 0.02, abs(q.x + trunk_curve * sin(0.4 * q.y))) + 0.01)
        * (1.0- smoothstep(0., 0.01, q.y));
}

void Pyramid(inout vec4 col, vec2 p, vec2 c, float h)
{
    // We are in 2D world, so a triangle will be used. 
    p -= c;
    p /= 9.0;
    p.x /= 2.0;
    int N = 3;
    float a = (atan(p.x, p.y) + PI);
    float r = 2.0 * PI/ float(N) ;
    float d = cos(floor(0.5 + a / r) * r - a) * length(p);
    col *= smoothstep(0.101, 0.102, d / h); 
}
                                                                               
void main(void)
{
    vec4 col=vec4(0.0);

    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;      
    col = mix(SKY, SUN, (1.0 - uv.y * vec4(0.8, 0.8, 1.0, 1.0)) * 0.5);

    uv *= 9.0;
       
    Pyramid(col, uv, vec2(0., -5.5), 2.8);

    Pyramid(col, uv, vec2(3.7, -5.5), 2.2);

    Pyramid(col, uv, vec2(-4., -5.5), 1.7);
    
    PalmTree(col, uv, vec2(-3.0, 2.7), 0.7, 13., 
             0.7 * cos(time), 4.5, -1.2, 0.06, -1.5);

     PalmTree(col, uv, vec2(-5.5, 0.7), 0.3, 17., 
             0.5 * sin(time), 5.5, -1.9, 0.08, 1.8);   
    
    PalmTree(col, uv, vec2(4.8, 1.7), 0.6, 18., 
             1.1 * cos(time / 3.0), 8.0, -0.9, 0.06, -.5);

    PalmTree(col, uv, vec2(6.3, 3.1), 0.8, 21., 
             1.1 * cos(time), 8.0, -0.9, 0.05, .5);
    
    PalmTree(col, uv, vec2(0.9, 2.2), 0.6, 14.,
             0.9 * cos(time), 4.0, -0.9, 0.05, .6);

    PalmTree(col, uv, vec2(-1.3, 0.5), 0.6, 14.,
             0.9 * cos(time), 8.0, -0.7, 0.04, -.75);

    PalmTree(col, uv, vec2(3.3, 3.3), 0.4, 9.,
             0.5 * cos(time), 5.0, 0.6, 0.06, -.35);

    PalmTree(col, uv, vec2(-7.3, 3.3), 0.8, 9.,
             0.9 * sin(time), 5.0, -0.6, 0.06, 1.25);

    glFragColor=col;
    
}
