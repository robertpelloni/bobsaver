#version 420

// original https://www.shadertoy.com/view/wtB3zd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float SinLerp(float min, float max, float t) {
     return mix(min, max, sin(t) * 0.5 + 0.5);   
}

float Sin01(float t) {
     return SinLerp(0., 1., t);
}

void main(void)
{
    float t = time * .2;
    
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    // polar
    vec2 st = vec2(atan(uv.x, uv.y), length(uv));
    st.x = st.x/6.28+0.5;
    
    //rotate
    //st.x += .5 * cos(t * .123);
    
    
       // remap to polar
    uv = st;
    
    
    // zig zag
    float p = 7.;//SinLerp(3., 17., t*0.1); // petals
    float x = uv.x * p;// + t * 0.5;
    float y = uv.y * SinLerp(.2, 1., t);
    
    // RINGS
    float r = y + sin( uv.y * 7. * SinLerp(1., 2., t) - t*3.);
    // FLOWER
    float z = min(fract(x), fract(1.-x)); 
    
    
    float s = SinLerp(4., 10., SinLerp(t*1., t*2., t*.0001) ); // split of the petal
    float c = fract(r + fract(z * s) ); // combined effects
    float m = min(1., pow(st.y*1., .5) ); // mask
    vec3 col = vec3(c * m + m);
    
    
    
    // color
    float c1 = SinLerp(uv.y, 1., t);
    float c2 = SinLerp(0., uv.y, t*1.5+1.1);
    col *= vec3(.5,c2,c1);
   
    
    // Output to screen
    glFragColor = vec4(col, 1.);
}
