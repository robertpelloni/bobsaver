#version 420

// original https://www.shadertoy.com/view/tdXyzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float t = time*.2;

    //camera
    vec3 ro = vec3(0,0,-1);
    vec3 look = vec3(0);
    float zoom = mix(.4, .9, sin(3.*t)*.5+.5) ;
    
    vec3 f = normalize(look - ro),
        r = normalize(cross(vec3(0,1,1), f)),
        u = cross(f,r),
        c = ro + f*zoom,
        i = c + uv.x*r + uv.y*u,
        rd = normalize(i-ro);
        
    
    float dSurf, d0rigin;
    vec3 pos;
    
    for(int i = 0; i < 100; i++)
    {
        pos = ro + rd*d0rigin;
        dSurf = -(length(vec2(length(pos.xz) - 1., pos.y)) - .75);
        if(dSurf < 0.001) break;
        d0rigin += dSurf;
    }
    
    // Time varying pixel color
    vec3 col = vec3(0);
    
                    if(dSurf < .001){
                        float x = atan(pos.x,pos.z)+t*.5;
                        float y = atan(length(pos.xz) - 1., pos.y);
                        
                        float bands =sin(y*10.+x*30.);
                        float ripples =sin((x*10.-y*30.)*3.)*.5+.5;
                        float waves =sin(x*2.-y*6.+t*20.);
                        
                        
                        float b1 = smoothstep(-.2,.2,bands);
                        float b2 = smoothstep(-.2,.2,bands-.5);
                        float m = b1*(1.-b2);
                        m = max(m, ripples*b2*max(0.,waves));
                        m+= max(0., waves*.3*b2);
                        
                        col = col+ mix(m, 1.-m, smoothstep(-.3, .3, sin(x*2.+t)));
                    }
    // Output to screen
    glFragColor = vec4(col,1.0);
}
