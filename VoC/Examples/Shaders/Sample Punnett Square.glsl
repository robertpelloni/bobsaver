#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tltcRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// This is the visualisation of the Punnett square with an infinite number of alleles
// New alleles are added over time
// Each color represents a different resulting genotype (the colors are shifted to make room for more genotypes)

// Use HSB colors to make it more visually appealing
// Function from Iñigo Quiles
// https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 pos = gl_FragCoord.xy/resolution.xy;
    pos.x= 1.-pos.x;
    
    // Time
    float overflow = 34.;   //DO NOT CHANGE (dependant on the float precision)
                            //Overflow error exactly at 2^5 sec , +2 sec fo visual effect
    
        //Preferences
    float repeat = 7.5; //Loop time
    
    //Float to int
    float gridStep = pow(2., floor(fract((time*overflow/repeat)/overflow)*overflow));   //PLAY AROUND WITH THIS
                                                                                 //The number of alleles
    ivec2 gridCoord = ivec2(floor(pos*gridStep));
    
    
    //Bitwise operations
    //WARNING: magic happens here (the bitewise or operator)
    float comb = float(gridCoord.x | gridCoord.y)/gridStep;
    
    vec3 color = hsb2rgb(vec3(comb));
    
    // Output
    glFragColor = vec4(color, 1.0);
}
