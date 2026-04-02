#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3djcWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 s) {
    return fract(sin(dot(s, vec2(4212.3213, 2889.32)))*132132.2312);
}

void main(void)
{
    vec2 p = (2.*gl_FragCoord.xy - resolution.xy)/resolution.yy;

    float e = 0.005;
    float r = 2.0;
    
    float s = sin(time*0.2), c = cos(time*0.2);
    p.x -= 0.2;
    p *= mat2(c, -s, s, c);
    
    vec2 q = p;
    q = abs(q);
    
    float d = smoothstep(-e, e, length(q) - r);
    for(int i=0; i<6; i++) {
        float pr = r;
        r /= (sqrt(2.) + 1.);
        q = abs(q);
        q.xy -= vec2( (pr - r)*1./sqrt(2.));
        
        float phase = sin(time+rand(step(0., p)+float(i)))*0.5+0.5;
        
        if(i%2 == 0) {
            d = max(d, smoothstep(-e, e, -(length(q)-r*phase)));
        } else {
            d = min(d, smoothstep(-e, e, length(q)-r*phase));
        }
    }
    
    
    vec3 col = mix(vec3(242.0, 226.0, 214.0)/255.,
                   mix(vec3(0.44, 0.27, 0.09), vec3(153., 100., 60.)/255., p.x)*length(p),
                   d);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
