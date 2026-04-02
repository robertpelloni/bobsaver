#version 420

// original https://www.shadertoy.com/view/WdsfRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= .5;
   
    //vec2 p = .5*vec2(cos(time), sin(time));
    //uv += p;
    uv.x *= resolution.x/resolution.y;
    
    //uv *= pow(fract(4.*uv), vec2(.3));
    uv  *= 30.;
    vec3 col = vec3(0.);
    
    float d = length(uv);
    float r = 6.5;
    float D = r*r/d;
    vec2 new;
    float wop = 3.5;
    float smt = 1.;
    float smt1 = 2.;
    
    new.x = (uv.x - wop*cos(time))*D/d;
    new.y = (uv.y - wop*sin(time))*D/d;
    
    if(new.x < 0.) new.x -= smt*fract(smt1*time);
        else if (new.x > 0.) new.x += smt*fract(smt1*time);
    
    if(new.y < 0.) new.y -= smt*fract(smt1*time);
        else if (new.y > 0.) new.y += smt*fract(smt1*time);
    
    
    for(float i = -30.; i <= 30.; i++)
    {
        new += vec2(i, -i);
        for (float j = -30.; j <= 30.; j++)    
            if (floor(new) == vec2(j))
                col += vec3(1.4 - .85*pow(.13*(abs(i) + abs(j)), 3.), 1.2 - 1.2*pow(.14*(abs(i) + abs(j)), 3.), 0.)
                        * smoothstep(floor(new.x)-.03, floor(new.x) + .03, new.x)
                        * smoothstep(floor(new.y)-.03, floor(new.y) + .03, new.y);
            
            else if (floor(new) == vec2(j-1., j))
                col += vec3(.38 - 1.2*pow(.13*(abs(i) + abs(j)), 3.), .7 -1.15*pow(.12*(abs(i) + abs(j)), 3.), .85 - 1.1*pow(.13*(abs(i) + abs(j)), 3.))
                        * smoothstep(floor(new.x -1.) - .03, floor(new.x - 1.) + .03, new.x)
                        * smoothstep(floor(new.y) - .03, floor(new.y) + .03, new.y);
                
            else col += vec3(0.);
                
        new -= vec2(i, -i);
    }
    
    
    

    glFragColor = vec4(col,1.0);
}
