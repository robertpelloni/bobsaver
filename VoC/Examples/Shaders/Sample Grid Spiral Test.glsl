#version 420

// original https://www.shadertoy.com/view/fsySDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// idea:
// change brightness depending on difference in radius from last frame to this one,
// for each cell / circle
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    
    float xr = 40.; float yr = 40.;
    
    vec2 ipos = vec2(floor(xr * uv.x) + 0.5, floor(yr * uv.y) + 0.5);
    vec2 fpos = vec2(fract(xr * uv.x) - 0.5, fract(yr * uv.y) - 0.5);
    
    float id = length(ipos);//max(abs(ipos.x), abs(ipos.y));
    float d = 1.- length(fpos);//max(abs(fpos.x), abs(fpos.y));
   // d *= .5;
    // 3.5 30. 3.5 // 30. / 37.
   // float m = 30./37.;
    float a = atan(ipos.y, ipos.x);
    float b = .5 + .5 * cos(time + 0.1 * length(ipos));
    //b = b * (1.-b) * 4.;
    float e = 1.8 + 0.5 * cos(-0.8 * time + 1. * a + 0.5 * id);
    float e2 = e + cos(0.8 * time + 3. * a - 0.5 * id);

    //float e2= cos(0.1 * id + 0.8 * time);//
    float c = step(max(0.5, pow(0.5 + 0.5 * (1.-b) * e,12.)), d);//(1.-b) * e);
    
    float c2 =  step(max(0.5, pow(0.5 + 0.5 * b * e2, 4.)), d);//(1.-b) * e);//step(0.5 + 0.5 * b * e2, d);
    c = smoothstep(-0.1,0.1,c2-c) * c;
    //c *= .5 + .5 * cos(c + time);
    //c = clamp(c, 0., 1.);
    
    vec3 col = pal(e/c + 0.4 * h21(ipos), vec3(0.5), vec3(0.5), vec3(1.5), vec3(0.,0.333,0.666));
    
    // Time varying pixel color
   // vec3 col = vec3(c * e);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
