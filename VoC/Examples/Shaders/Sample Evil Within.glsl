#version 420

// original https://www.shadertoy.com/view/WdfXzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 red = vec3(225./255., 95./255., 60./255.);

float Circle (vec2 uv, vec2 p,float radius, float blur)
{
    float dia= length(uv-p);
    float c = smoothstep(radius,radius - blur, dia);
    
    return c;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    uv -= .5;
    uv.x *= resolution.x/resolution.y;
    
    float c = Circle(uv,vec2(.0,-.05),.3,.01);
    float c2;
    c += Circle(uv,vec2(-.3,.2),.15,.01);
    c += Circle(uv,vec2(.3,.2),.15,.01);
    c2 -= Circle(uv,vec2(.1,.01),.1,.01);
    c2 -= Circle(uv,vec2(-.1,.01),.1,.01);
    c += Circle(uv,vec2(-.0,.1),.15,.01);
    c2 -= Circle(uv,vec2(-.0,-.2),.1,.01);
    c += Circle(uv,vec2(-.0,-.16),.1,.01);
      
    c += c2;
    red = mix(vec3(0.),red * 7.,c / 2.);

    //float c = Circle(uv,.3,.01);
    // Output to screen
    glFragColor = sin(time * 5.) - sin(time * 1.) * vec4(vec3(red),2.0) ;
}
