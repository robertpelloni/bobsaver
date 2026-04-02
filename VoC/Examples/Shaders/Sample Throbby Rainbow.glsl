#version 420

// original https://www.shadertoy.com/view/4tcyWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 rainbow( vec2 st, float time )
{
       //band thickness
    float thick = 0.4;
    //start distance
    float off = 0.1;
    //drop UVs down to center the rainbow
    vec2 lower = clamp(st + vec2(0.,0.5),vec2(-2,0.),vec2(2.));
    
    //distance from center (for a nice arc)
    float rbg = length(lower);
    //angle
    float angle = atan(lower.x,lower.y);
    
    //animate the gradient a little
    rbg += sin(angle*2.+time*1.3)*0.1*thick;
    rbg += sin(rbg*3.1+time)*0.2*thick;
    //band logic
    float band1 = step(0.5*thick+off,rbg)*step(rbg,1.*thick+off);
    float band2 = step(1.0*thick+off,rbg)*step(rbg,1.5*thick+off);
    float band3 = step(1.5*thick+off,rbg)*step(rbg,2.*thick+off);
    float band4 = step(2.*thick+off,rbg)*step(rbg,2.5*thick+off);
    float band5 = step(2.5*thick+off,rbg)*step(rbg,3.*thick+off);
    float block = step(-0.75,st.y);
    
    //apply colors to bands
    //it's not ROYGBIV but this is cartoons
    //there's an unused "band" but whatever 4 seemed ok
    vec4 rb = vec4(1.,0.,0.,1.)*band1;
    rb += vec4(1.,0.8,0.,1.)*band2;
    rb += vec4(0.7,1.,0.2,1.)*band3;
    rb += vec4(0.,0.7,1.,1.)*band4;
    rb *= block;
    
    return rb;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    // Signed normalized
    uv = uv*2.-1.;
    // with aspect ratio applied
    uv *= vec2(resolution.x/resolution.y,1.);

    // Output to screen
    glFragColor = rainbow(uv,time*3.);
}
