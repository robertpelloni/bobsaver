#version 420

// original https://www.shadertoy.com/view/wlVXzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    //Gotta go fast af
    float time2k = time*2.0-5.0;
    
    //Normalize to the middle of the screen, -0.5 -> 0.5
    vec2 uv = gl_FragCoord.xy/resolution.xy-vec2(0.5);
    
    //Norm so that the primary distortions are round. Large effect on the shape of distortions
    float norm = dot(uv,uv)*0.05-0.4; 
    
    /*The amount of times the distortion patterns are calculated, higher detail = more detail(Wow!). 
    >25 gives quickly a headache, the amount of detail could be compared to a fractal: the more detail
    you compute for the swirlies, the deeper you could zoom to have a clear pattern. Also, time-variance 
    gives an interesting effect, for example 17 + int(round(x.*sin/cos(time2k))) */
    int detail = 17;

    /*Where the "magic" happens. A time varying vector, from which sin & cos components are subtracted or added
    This creates the swirly effect they have with some math-%&*$ery
    Varying these parameters changes the distortion completely*/
    vec3 magic = sin(time2k*1.5*norm*vec3(0.2,0.29,0.33));
    for(int i = 0; i < detail; i++){
        //Playing around with these parameters has the biggest impact on the created distortions and their formation
        //Especially changing the vector components changes to flow of waves
         magic += sin(magic.yzx-uv.yxy*norm*float(i)*float(i)-0.1);
        magic += cos(magic.yxz-uv.xyx*norm*float(i)*float(i)+0.1);
    }    
    //Take the x-component of the vector. Other components also give interesting patterns, and they also have some weird symmetries
    float value = magic.x*0.45;
    
    //Mainly for adding contrast
    value -= smoothstep(0.5,0.5,norm*0.4)*1.2-0.6;
    
    //Choose the colors, time-based variance also adds an interesting effect here
    glFragColor = vec4(vec3(0.0,value/4.5,value/2.0),1.0);   
}
