#version 420

// original https://www.shadertoy.com/view/wstfW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Party Hat Paradise" by Plento. https://shadertoy.com/view/3s3BDN
// 2020-11-12 01:39:10

// Cole Peterson
#define R resolution
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    vec3 col = vec3(0);

    //if(mouse*resolution.xy.z > 0.) uv += m;
    
    float r = .5;
    float n = 20.;
    
    //uv.x -= uv.y*uv.y * uv.x * 0.3;
    //uv.y -= uv.x*uv.x * uv.y * 0.3;
    
    for(float i = 0.; i < n; i++)
    {
        uv.y += sin(i*0.5 + time*4.)*0.01;
        uv.x += cos(i*0.5 + time*4.)*0.01;
        
        vec2 ruv = fract(uv*8.)-.5;
        vec2 id = floor(uv*8.);
        
        vec3 nc = .8+.5*cos(vec3(2.,3.,0.4)*(id.x+id.y+i*48.)*4.);
        
        float s = pow(dot(ruv, vec2(.5, .7))*3.8, 3.0);
        nc += (.3+.4*cos(vec3(4.7,2.,8.4)*(id.x+id.y+i*38.))) * s;
        nc *= (i / n);
        
        col = mix(col, nc, smoothstep(r, r - .015, length(ruv)));
        
        uv *= (0.7 + cos(time*1.2)*0.324);
        r -= 0.023;
    }
    col *= max(((1.-abs(uv.x*1.2)) * (1.-abs(uv.y*1.2))), 0.);
    glFragColor = vec4(col,1.0);
}
