#version 420

// original https://www.shadertoy.com/view/DdySzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson (Plento)

#define R resolution.xy
#define ss(a, b, t) smoothstep(a, b, t)
#define m vec2(R.x/R.y*(mouse*resolution.xy.x/R.x-.5),mouse*resolution.xy.y/R.y-.5)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

void main(void){
    vec2 u = gl_FragCoord.xy;
    
    vec3 col = vec3(0);

    float n = 30.;
    for(float i = n; i >= 0.; i--){
        float r = (.7+.48*sin(i*0.5))*.3;
        vec2 uv = vec2(u.xy - 0.5*R.xy)/R.y; // -1 to 1 uvs
                
        uv *= (i*.005 + .08); // scale
        uv *= rot(-i*.05); // rotate
        uv.y += time*.02; // translate
        
        //if(mouse*resolution.xy.z>0.)uv-=m*.1; // mouse
        
        vec2 id = floor(uv*19.), ruv = fract(uv*19.)-.5; // cell id and repeat uv
        
        vec3 nc = .55+.3*cos(vec3(2.,3.,0.4)*(id.x+id.y+i*0.2 + time*.5)*3.); // pick color
        float s = pow(abs(dot(ruv, .8*vec2(cos(time), sin(time))))*4.9, 6.0); // shiny
        nc *= (s+.55); // shiny
        nc *= ((n-i) / n); // distance fade

        col = mix(col, nc, ss(r, r - .015, length(ruv))); // main color
        col *= ss(0.003, 0.008, abs(length(ruv) - r+.005)); // outlines
    }
    glFragColor = vec4(1.-exp(-col),1.0); // smooth clamp color and output
}