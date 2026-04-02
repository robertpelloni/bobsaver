#version 420

// original https://www.shadertoy.com/view/WdXfDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// simple helper to smoothstep
float vsmooth(float c, float s, float val ) {
    float v = s/2.;
    return smoothstep(c-v,c+v,val);
}

// draw circle
float circle(vec2 uv, float r, float thick, float fuz) {
    float len = length(uv);
    float b = thick/2.;
       return vsmooth(r-b,-fuz,len) + vsmooth(r+b,fuz,len);
}

// rotate uv in time 
vec2 uv_rotator(vec2 uv, float time) {
    float a = sin(time*.02);
    float s = 1.*sin(a);
    float c = 2.*cos(a+.3);
    // rotation
    uv*= mat2(c, -s,s,c);
    // offset
    uv +=vec2(s,s)-vec2(c,c);
    return uv;   
}

void main(void)
{
    float t = time*2.;

    vec2 uv_g = 4.*(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv_g += length(uv_g-vec2(.5))/20.; // little disortion
    uv_g =uv_rotator(uv_g,t); // uv rotation
   
    vec2 uv1 = fract(uv_g); // cell uv
    vec2 uv2 = 1. - uv1;
    vec2 uvc = fract(uv_g + .5);
        
    // prepare parameters
    float fuz = .03;
    float thick = sin(t * .2 / 1.) / 15. + .15;
        
    // waves patterns
    float r = .5;
    float wave1 = circle(uv1, r, thick, fuz);
    float wave2 = circle(uv2, r, thick, fuz);
    
    // circle pattern
    r /= 2.;
    float c = circle(uvc - .5, r, thick, fuz);
    
    // whole pattern    
    float p = (1. - wave1) + (1. - wave2) + (1. - c);
    
    // preapre color
    float contrast = cos(t * .1) * .07 + uv_g.x*.02;
    //contrast = clamp(contrast,-.1,.1);
    p *= contrast;
    float G = sin(t * .21) * .05 + .1;
    float R = cos(t * .3) * .03 + .1;
    
    // mix
    vec3 rgb = vec3(R - p * .2-.1, G, .5) + p ;
    //vec3 col = vec3(rgb + p);

    glFragColor = vec4(rgb, 1.0); 
}
