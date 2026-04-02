#version 420

// original https://www.shadertoy.com/view/tdjczy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define CENTER (resolution.xy / 2.0)
#define PI 3.1415
#define TAU (2.0 * PI)

//Convert rectangular to polar coordinates
vec2 rect_to_polar(vec2 rect) {
    float r = log(length(rect)*10.);
    float theta = atan(rect.y, rect.x);
    
    //Fix the coordinates so they go from 0 to 2PI
    //instead of -PI to PI. These two lines are optional
//    if (theta < 0.0)
//        theta += TAU;
    
    return vec2(r, theta);
}

vec2 normalized_polar(vec2 coord) {
    //Centered UV coordinates accounting for aspect ratio
    
    vec2 nCenter = vec2(CENTER.x,CENTER.y);
    nCenter.x = CENTER.x+sin(time)*(resolution.x/3.);
    nCenter.y = CENTER.y+cos(time)*(resolution.y/5.);

    
    vec2 uv = vec2(1.0,1.0);
    uv.y = (coord.y - nCenter.y ) / resolution.y;
    uv.x = (coord.x - nCenter.x ) / resolution.y;
    
    //Convert to polar. Normalize the angle component by
    //dividing by a full circle.
    vec2 polar = rect_to_polar(uv);
    polar.y /= TAU;
       
    return polar;
}

float Hash21(vec2 p) {
    p = fract(p*vec2(234.34, 435.35));
    p += dot(p, p+34.23);
    return fract(p.x*p.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
     vec2 uv = gl_FragCoord.xy/resolution.xy;
   
    uv = normalized_polar(gl_FragCoord.xy);
    
    float gp = uv.y;
    float gx = uv.x;
        
    uv.x *= 5.;
//    uv.x = fract(uv.x);
    
    uv.x = uv.x + sin(uv.y*TAU+time)*3.;
   
    uv.x = uv.x - time*3.;
       
    vec3 col = vec3(0,0,0);
      
    col.x = .4+sin(uv.x*TAU-(uv.y*TAU*5.))*.5;
    col.x = clamp(col.x, 0., 1.);
    col.x = min(col.x, gx*2.+3.);

//    col.y = -20.+sin(uv.y*TAU*8.+time)*25.;
//    col.y = clamp(col.y, 0., 1.);
//    col.y = min(col.y, gx+.01);

// truchet
    uv.y -= time*.12;
    float rep = 6.;
    uv.y = mod(uv.y, rep/2.);
    uv *= rep;
    uv.y *= rep*2.;
    uv.y = mod(uv.y, rep*2.);
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    
    float n = Hash21(id/rep);
    
    float width = .25;
    
    if(n<.5) gv.x *= -1.;
    float d = abs(abs(gv.x+gv.y)-.5);
    float mask = smoothstep(.01, -.01, d-width);
    
    col.x -= mask;

    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
