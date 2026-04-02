#version 420

// original https://www.shadertoy.com/view/MdXyWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

#define MAX 128

void main(void)
{
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.xy;   
    uv -= 1.0;         // -0.5 <> 0.5
    uv *= vec2(2.0,1.15);
    
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    mouse -= 0.5;
    
    float t = (time+16.)/10.;

    vec2 c = vec2(-0.5*sin(t),-0.5*cos(t));
    c = vec2(mouse.x, mouse.y);
    float f = 1e20;
    float m = 0.0;
    float escape = 0.0;
    for( int i=0; i<MAX; i++ ) 
    {
        escape = float(i);
        uv=abs(uv);
        // uv.y=abs(uv.y);
        m=dot(uv,uv);
        uv = uv/m+c;
          // f = min( f, fract(m) + m/32.0 );
        f = min( f, pow(cos(uv.x/1.0),0.55));
        if( m >(100.0)) break;
    }

    f = 0.0-log(f)/10.0;   // Orbit Trap
    vec3 FragColor1 = vec3(f,0.45-f,0.0);
    
    escape /= float(MAX);  // Escape Value
    vec3 FragColor2 = pal( escape, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(2.0,1.0,0.0),vec3(0.5,0.20,0.25) );

    vec3 col = mix(FragColor1,FragColor2,0.55);
    // Increase contrast alpha(color-0.5)+0.5+beta
    col = 1.45*(col-0.5) + 0.50;
    glFragColor = vec4(col, 1.0);
}
