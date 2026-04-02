#version 420

// original https://www.shadertoy.com/view/WsfBDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(float s) {
    return fract(sin(s)*3908213.21321);
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    vec2 q = p;
    q.y -= -0.4;
    
    float t = fract(time/4.0)*10.0 - 5.0;
    float c = floor(time/4.0);
    
    for(float i=0.0; i<=3.0; i+=1.0) {
        q.y -= +0.3*smoothstep(0.0, rand(c+i*11.0)*0.5+0.05, abs(q.x-t-rand(c+i*13.0))-rand(c+i));
        q.y -= -0.3*smoothstep(0.0, rand(c+i*17.0)*0.5+0.05, abs(q.x-t-rand(c+i*23.0))-rand(c+i*0.5));
    }
    
    vec3 col = vec3(0.02);
    float pi = acos(-1.0);
    float banner = smoothstep(0.64, 0.63, abs(q.y-0.45));
    col = mix(col, vec3(1.0), banner);
    col -=
        0.8*smoothstep(0.3, -0.3, sin( (q.x+time*0.2+floor(q.y*9.)*pi*0.5)*30. ))*
        banner;
    col = pow(col, vec3(0.45));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
