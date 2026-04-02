#version 420

// original https://www.shadertoy.com/view/WdjfzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(0.5,0.5);

    vec4 col = vec4(0);
    float thickness = 5.0/resolution.y;
    
    for(float k=0.0;k<1.0;k+=0.05){
        if(abs(uv.y - (k-0.5)*sin(uv.x*10.0 + 10.0*(k-0.5)*time))<thickness*(k+0.1))
            col=vec4(1.0,cos(3.14*(1.0-k)/2.0),cos(k*3.14/2.0),1.0);
    }

    // Output to screen
    glFragColor = col;
}
