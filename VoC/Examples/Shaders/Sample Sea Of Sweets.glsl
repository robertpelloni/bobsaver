#version 420

// original https://www.shadertoy.com/view/wtjyWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define ss(a, b, t) smoothstep(a, b, t)

float h(float p){
    return cos(p*5.)*.04 + cos(p*7. + 4.)*.07 + cos(p*10. + 6.)*.05 + cos(p*15.)*.03
        +cos(p*20. + 2.)*.017;
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    uv.y += .5;
    uv.y+=abs(sin(time*.08))*1.66;
    
    vec3 col = vec3(0);
    
    for(float i = 28.; i > 0.; i--){
        uv.y += cos(43.3+i*46. + time*4.5)*.005;
        float t = uv.x + i+4. + time*.1;
        vec3 c = .61 + .33*cos(vec3(0.7, 2., 0.9)*(t*1.1 + uv.y) - vec3(8., 6., 6.7));
        float val = h(t);
        col = mix(c, col,  ss(.0, .01, uv.y - val - i*.1));
        col = mix(vec3(0.), col,  ss(.0038, .009, abs(uv.y - val - i*.1)));
    }
    col *= .7;
    
    col = pow(col, vec3(2.))*3.5;
    col = 1.-exp(-col);
    col *= ss(.0, .25, 1.-abs(uv.x));
    
    glFragColor = vec4(col, 1.0);
}
