#version 420

// original https://www.shadertoy.com/view/WsdSR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float f(vec2 uv) {
    float t = atan(uv.y, uv.x);
    float r = length(uv);
    if(t > .0)
        t = -t;
     return r - (.4 + .2*abs(sin(time*4.)) + sin(t) * sin(t + .7) + fract(sin(t*.8)) + cos(t) - .6*(pow(abs(cos(t)), 4.)));       
}

vec2 grad2(vec2 uv) {
     vec2 h = vec2( 0.001, 0.0 );
    return vec2(f(uv+h.xy) - f(uv-h.xy),
                f(uv+h.yx) - f(uv-h.yx)) / (2.0*h.x);
}
float sdf(vec2 uv, vec2 g) {
     float v = f(uv);
    float de = v/length(g);
    return de; 
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    uv *= 3.;
    uv.y -= .9;
    uv = vec2(-uv.y, uv.x);    //90 rotation
    vec3 color;
    //color = mix( vec3(.8, .33, .3), vec3(1.), smoothstep(.0, .05, length(uv) - f(uv)) );    //edges not properly drawn
    
    vec2 g = grad2(uv);
    float de = sdf(uv, g);
    float eps = 20. / resolution.y;
    color = mix(vec3(.8, .33, .3), vec3(1.), smoothstep(.0, 2.*eps, de));    //for isosurface only do abs(de)
    
    uv.x -= .9;
    color *= (7. - pow(length(uv), .8 - .08*abs(sin((time)*4.)))) * vec3(.3, .1, .2);
    glFragColor = vec4(color,1.0);
}
