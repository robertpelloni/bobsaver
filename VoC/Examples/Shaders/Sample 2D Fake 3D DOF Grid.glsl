#version 420

// original https://www.shadertoy.com/view/ssdGD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(in vec2 p) {

    float depth = p.y+1.5;
    
    p.y += 6.;
    //p.x += (p.y+12.)*0.2*p.x;
    p.xy += vec2(p.y+12.)*0.2*p.xy;
    
    p.y += time*5.;
    float s = sin(p.y+p.x) + sin(p.x-p.y);
    
    
    
    float w = fwidth(s);
    w *= abs(depth)*1.25;
    
    s = smoothstep(-w, w, s);

    return  s -abs((depth+3.5)*0.025);
}

void main(void) {
    vec2 p = (2. * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y)*12.;
    
    float s = map(p);
    s = max( map(p+vec2(0.,0.125))*0.25, s );

    glFragColor = vec4(vec3(s), 1.);
}
