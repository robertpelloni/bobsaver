#version 420

// original https://www.shadertoy.com/view/WdyGRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ssin(a)  (.5 + .5*(sin(a)))
#define scos(a)  (.5 + .5*(cos(a)))

void main(void)
{

    vec2 suv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec2 uv = suv;
    float asp = resolution.y/resolution.x;
    //uv.y += .5;
    //uv.x *= 1.12;
    //uv.x = abs(uv.x);
    vec2 puv = vec2(atan(uv.x, uv.y)/3.1415, length(uv));
    uv = puv;
    
    vec3 col = vec3(.3,.2,.08);
    
    
    float t = time*4.;
    
    vec2 tuv = fract(uv*floor(uv.y*(uv.y+.002)*30.+1.));
    vec2 ttuv = fract(uv*floor(uv.y*(uv.y+.004)*30.+1.));
    uv = fract(uv*floor(uv.y*uv.y*30.+1.));

    col += .33*smoothstep(-.02,.02,sin(uv.x*3.1415*2. - t));
    col += .33*smoothstep(-.02,.02,sin(tuv.x*3.1415*2. - t));
    col += .33*smoothstep(-.02,.02,sin(ttuv.x*3.1415*2. - t));
    
    col *=.6;
    col *= 1.*(1.-length(suv));
    col += length(suv)*vec3(.13, .1, .2);
    //col -= 1.*smoothstep(.1,-.05,(fract(puv.y*puv.y*30.)))*step(.1, length(puv.y));
    col -= .3*smoothstep(.5,-.4,(fract(puv.y*puv.y*30.)))*step(.12, length(puv.y));
    col -= .3*smoothstep(.9,1.1,(fract(puv.y*puv.y*30.)))*step(.12, length(puv.y));

    col += vec3(.1, .08, .22);
    
    if (true) { //optional version with orange spiral center
        float mask = smoothstep(.185,.191, length(puv.y));
        col *= mask;
        vec3 cc = vec3(.0);
        cc += vec3(.8, .4, .22);
        cc += .5*vec3(.16,.14,.08)*ssin(puv.x*3.1415*10. - puv.y*100. + 5.*time);
        cc += .4*vec3(.09,.12,.09)*ssin(puv.x*3.1415*12. - puv.y*100. + 4.*time);

        col += (1.-mask)*cc;
    }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
