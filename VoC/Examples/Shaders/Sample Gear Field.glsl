#version 420

// original https://www.shadertoy.com/view/lsKSRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// relying on hexagonal tiling tutos https://www.shadertoy.com/view/4dKXR3
//                               and https://www.shadertoy.com/view/XdKXz3

void main(void)
{ 
    vec2 R = resolution.xy;
    vec2 U = (gl_FragCoord.xy-R/2.)/R.y * 6.;                           // centered coords
    
    U *= mat2(1.73/2.,-.5, 0,1);                          // conversion to
    vec3 g = vec3(U, 1.-U.x-U.y),                         // hexagonal coordinates
        id = floor(g);                                    // cell id
    
    g = fract(g); g.z = 1.-g.x-g.y;                       // triangle coords    
    U = (g.xy-ceil(1.-g.z)/3.) * mat2(1,.5, 0,1.73/2.);   // screenspace local coords (centered)
    float r = length(U)/(1.73/2.)*3., // discs r=1 in contact     // to polar coords
          a = atan(U.y,U.x) - time*sign(g.z); 

        //anti-aliasing    // gears pattern      // color per cell-id
    glFragColor = smoothstep(.07,.0, r-.9 -.1*sin(15.*a) ) *(1.+mod(id,3.).xyzx)/4.; 
}
