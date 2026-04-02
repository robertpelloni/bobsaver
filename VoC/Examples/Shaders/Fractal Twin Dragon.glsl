#version 420

// original https://www.shadertoy.com/view/MtXSWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//size of block = 1.
float time2;

float shift(float p, float divide,float amount){
    return amount*sign(mod(p*divide,2.)-1.);
}

void main(void) {
    
    vec2 ScreenRatio = resolution.xy/resolution.y;

    time2 = mod(time,20.);

    vec2 pixel = (gl_FragCoord.xy/resolution.xy*2.-1.)*ScreenRatio*2.;
    
    // actual fractal                      THIS IS ANIMATIONS
    pixel.y += shift(pixel.x, 256. ,-1./512. *clamp(time2-14.,0.,2.)/2.);
    pixel.x += shift(pixel.y, 128. , 1./256. *clamp(time2-12.,0.,2.)/2.);
    pixel.y += shift(pixel.x,  64. ,-1./128. *clamp(time2-10.,0.,2.)/2.);
    pixel.x += shift(pixel.y,  32. , 1./ 64. *clamp(time2- 8.,0.,2.)/2.);
    pixel.y += shift(pixel.x,  16. ,-1./ 32. *clamp(time2- 6.,0.,2.)/2.);
    pixel.x += shift(pixel.y,   8. , 1./ 16. *clamp(time2- 4.,0.,2.)/2.);
    pixel.y += shift(pixel.x,   4. ,-1./ 8.  *clamp(time2- 2.,0.,2.)/2.);
    pixel.x += shift(pixel.y,   2. , 1./ 4.  *clamp(time2- 0.,0.,2.)/2.);

    // prettifying
    vec2  block  = ceil(pixel+.5);               //index for blocks from wich the fractal is shifted
    float dis    = length(fract(pixel+.5)*2.-1.);//distance to middle of block
    vec3 color = sin(block.x*300.+block.y*1000.+vec3(0.,2.09,4.18))*.5+.5;//rainbow palette using block index as t
    color *= .5+dis*.7;//using distance within block for some more pretty.
    
    glFragColor = vec4(color,1.);
    
}
