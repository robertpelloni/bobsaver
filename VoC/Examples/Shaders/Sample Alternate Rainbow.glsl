#version 420

// original https://www.shadertoy.com/view/wstfD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson
#define R resolution
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void main(void)
{
    vec3 col = vec3(0);

    float r = .47;
    float n = 20.;
    
    for(float i = n; i > 0.; i--)
    {
        vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;;
        uv *= (i*.007 + .2);
        uv *= rot(i*.05);
        uv.x += time*.075;
        //if(mouse*resolution.xy.z>0.)uv-=m.x*.5;
        vec2 id = floor(uv*8.);
        
        uv.y += sin(i*.5 + time*4. + id.y*345. + id.x*883.)*0.007;
        uv.x += cos(i*.5 + time*4. + id.y*845. + id.x*383.)*0.007;
        
        vec2 ruv = fract(uv*8.)-.5;
        id = floor(uv*8.);
        
        vec3 nc = .55+.3*cos(vec3(2.,3.,0.4)*(id.x+id.y+i*0.05 + time*.6)*3.);
        
        float s = max(pow(dot(ruv, vec2(-.8, .5))*4.4, 4.0), 0.001);
        nc *= abs(s)+.6;
        nc *= ((n-i) / n);
        
        col = mix(col, nc, smoothstep(r, r - .015, length(ruv)));
        col *= 1.-smoothstep(0.01, 0.003, abs(length(ruv) - r+.005));
        r -= .0215;
    }
    glFragColor = vec4(col,1.0);
}
