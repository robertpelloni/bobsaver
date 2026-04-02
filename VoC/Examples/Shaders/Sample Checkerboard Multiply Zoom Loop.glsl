#version 420

// original https://www.shadertoy.com/view/NtccWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159265358979323846264338327950288 //π
mat2 rotationMatrix(float angle) //https://www.shadertoy.com/view/3lVGWt
{   
    float s=sin(angle), c=cos(angle);
    return mat2( c, -s, s, c );
}

void main(void) {
    
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.x; 
    
    float tl = -time; //https://www.shadertoy.com/view/4sVczV
    tl *= .5; //speed
    tl += .25; //where start
    tl = mod(tl, 1.); //loop
    
    uv*=rotationMatrix(tl*pi*0.25);
    
    float z = .25*mix(30.,42.445,tl); 
    float p = atan(sin(pi*tl - uv.y *pi*z ), sin(uv.x *pi*z ));
        
    float c =  1.0;
    float r = abs(fract(-0.25*tl+(p/pi)*(c))-0.5)*2.0;

    float s = -0.5;
    r = (smoothstep(0.0-s,1.0+s,r));
    
    glFragColor = vec4(vec3(r),0.0);
}
