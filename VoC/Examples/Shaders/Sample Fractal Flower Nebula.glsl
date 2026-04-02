#version 420

// original https://www.shadertoy.com/view/7sBBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change these constants to get different patterns!
#define bend1 2.
#define c1 vec3(1.,0.5,1.5)

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
    //return abs(fract((a+c1.xy)*scale+time/500.)-.5); //morphing
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 3.;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = c1.z;

    vec2 t2 = vec2(0.);
        vec2 t3 = vec2(0.);   
        for(int k = 0; k < 9; k++){

            //uv -= (t2.yx+.5)/scale;
            uv -= (t2.yx)*(bend1+uv.x+uv.y);
            if(k > 3){
             uv -= (time)/16.;}
            //uv -= (t2.yx)/(1.-uv.y-uv.x);
            
            //uv -= float(k%3)*float(k%2); //this makes it even more colorful
            
            float bend = bend1*(t2.y*bend1+1.)*(t2.x*bend1-1.);

            t2 = -triangle_wave(-uv.yx-1.5,scale)/bend;

            t3 = -triangle_wave(-uv,scale)*bend;
            
            uv.yx = (t3-t2)/bend1*2.;

        col.x = abs(abs((uv.x+uv.y+col.x)-1.));
        col = col.yzx;
        
        uv /= scale*scale;
      }
    glFragColor = vec4((col),1.0);   
}
