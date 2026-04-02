#version 420

// original https://www.shadertoy.com/view/ws2yDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define CENTER (resolution.xy / 2.0)
#define PI 3.1415
#define TAU (2.0 * PI)

//Convert rectangular to polar coordinates
vec2 rect_to_polar(vec2 rect) {
    float r = length(rect);
    float theta = atan(rect.y, rect.x);
    
    //Fix the coordinates so they go from 0 to 2PI
    //instead of -PI to PI. These two lines are optional
    if (theta < 0.0)
        theta += TAU;
    
    return vec2(r, theta);
}

vec2 normalized_polar(vec2 coord) {
    //Centered UV coordinates accounting for aspect ratio
    vec2 uv = (coord - CENTER ) / resolution.y;
    
    //Convert to polar. Normalize the angle component by
    //dividing by a full circle.
    vec2 polar = rect_to_polar(uv);
    polar.y /= TAU;
    
    return polar;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
     vec2 st = gl_FragCoord.xy/resolution.xy;
    
    vec2 uv = normalized_polar(gl_FragCoord.xy);
    
    
    float gp = uv.y;
    float gx = uv.x;
    
    
    uv.x = -pow(uv.x,.1);
    uv.x = uv.x + time/10.;
//    uv.x = mod(uv.x, 1.);
    
    vec3 col = vec3(0,0,0);
      
//  col.x = sin(uv.x*100.);
    col.x = -8.+sin(uv.x*100.-(gp*TAU))*10.;
    col.x = clamp(col.x, 0., 1.);
    col.x = min(col.x, gx+.01);

    col.y = -20.+sin(uv.y*TAU*8.+time)*25.;
    col.y = clamp(col.y, 0., 1.);
    col.y = min(col.y, gx+.01);
        
    // Output to screen
    glFragColor = vec4(col,1.0);
}
