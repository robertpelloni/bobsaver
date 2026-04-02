#version 420

// original https://www.shadertoy.com/view/XlBBRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 uv = 120.0 * ((gl_FragCoord.xy - resolution.xy/2.)/ resolution.y) + vec2(0, 0);
    //uv = floor(uv) + smoothstep(0.0, 1.0, fract(uv));
    uv = floor(uv);
    uv = uv / (2.5f + time*0.02);
    
    float d = 1.0; // + sqrt(length(uv)) / 109.0;
    float t = 10. + time + 200.;
    float value = d * t + (t * 0.125) * cos(uv.x) * cos(uv.y);
    float color = sin(value) * 3.0;
    
    float low = abs(color);
    float med = abs(color) - 1.0;
    float high = abs(color) - 2.0;
    
    vec4 lifeColor;
        
    if(color > 0.) {
      lifeColor = vec4(high, high, med,1.0);
    } else {
      lifeColor = vec4(med, high, high,1.0);
    }
        
    glFragColor = lifeColor * 1.1;
}
