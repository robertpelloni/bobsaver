#version 420

// original https://www.shadertoy.com/view/wtt3RX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

    vec3 col = vec3(0);
    float time = fract(time / 1000.) * 1000.;
    
    
    vec2 wv = uv;
    
    wv *= 1. - sin(time * 0.5) * 0.2;
    
    wv.x += sin(wv.y * 8. + 2. * time)/12.;
    wv.y += sin(wv.x * 8. + 2. * time)/8.;
    wv.x += sin(wv.y * 12. + 1. * time)/20.;
//    wv.x += sin(wv.y * 20. + time)/60.;
    
    //wv.x += sin(wv.y * 12. + time)/14.;
    //wv.y += sin(wv.x * 12. + time)/20.;
    //wv.x += sin(wv.y * 30. - time * 2.)/100.;
    
    
    float w = sin(wv.x * 200.) * 0.5 + 0.5;
    w = smoothstep(0.5, 0., w);
    w *= step(0.8, 1. - abs(wv.x));
    
    float bc = 1. * smoothstep(0.01, 0., sin(wv.y * 2. - 2. * time) * 0.5 + 0.5);
    //w = clamp(w + bc * w, 0., 1.);
    
    
    vec3 c = vec3(0.1) * w;
    
//    c.r += sin(wv.x * 121. + time) * w;
//    c.g += sin(wv.x * 132.) * w * 0.;
//    c.b += sin(wv.x * 143. - time) * w;
    
//    c = c * 0.4;
    c.rb += 0.6 * vec2(wv.x + 0.5 + sin(time)/10., wv.y + 0.5) * smoothstep(0.8, 0.9, 1. - abs(wv.x));
    
    
    col = c;

    glFragColor = vec4(col,1.0);
}
