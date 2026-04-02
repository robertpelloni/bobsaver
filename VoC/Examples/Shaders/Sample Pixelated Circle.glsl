#version 420

// original https://www.shadertoy.com/view/wdcSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    vec2 p = vec2(0.);
    //uv = floor(uv*120.)/120.;
    //float steps = abs(sin(time*0.1)*16.)+4.;
    float steps = 32. + sin(time*0.1)*31.;
    //float steps = 64.;
    float s = time*01.25;
    for (float i;i<steps;i++) {
        float ii = i*02.102/steps;
        p = vec2(sin(s+ii),cos(s+ii))*(0.3+sin((s+ii)*8.)*0.1);
        ii = ii*ii*15.;
        //ii += 40.;
        //ii = ii*20.;
        //ii = (steps*3.)-ii;
        vec2 pv = floor(uv*ii)/ii;
        if (length(pv+p) < 0.1*(i/steps)) {
            col = vec3(i/(steps-1.));
            col = col*col*col;
            //col = vec3((i/steps)+(.025));
        }
    }
    glFragColor = vec4(col,1.0);
}
