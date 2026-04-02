#version 420

//MODS BY NRLABS 2016

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 flag ( vec2 u ) 
{
    vec3 c = vec3(1.0);
    
    if (fract(u.y*21.25)>0.5) 
    {    
        c = vec3(1,0.0,0.0);    
    }
    
    if (u.x<0.35&&u.y>0.65) 
    {
        c = vec3(0.0, 0.0, 1.0);
        
    vec2 pos = u;

    float shade = 0.8 + (0.6 + pos.x) * cos(pos.x * 6.0 - time * 4.0) * 0.2;
    vec3 color;
    if(pos.x <= 0.35 && pos.y>0.65)
    {

        color = vec3(0.0, 0.0, 1.0);
        float x, y;
        
        x = -pos.x * 28.0 - .05;
        y = pos.y * 43.0 ;
        vec2 t = vec2(fract(x)*0.9 - .45, fract(y) - .5);
        float d = length(t);
        const float starsize = .275;
        bool isstar = true;
        if(pos.y > 0.33) isstar = false;
        if(d > starsize)
        {
            t = vec2(fract(x + .5)*0.9 - .5, fract(y + .5) - .5);
            d = length(t);
        }
        {
            // following approach seems slightly faster than atan one
            // rotation matrix -36 degrees
            mat2 r = mat2(.80901699,-.58778525,.58778525,.80901699);
            mat2 r2 = mat2(.30901699,-.95105652,.95105652,.30901699);
            t.x = abs(t.x);
            t*=r2;
            t.x = abs(t.x);
            t*=r2;
            t.x = abs(t.x);
            t*=r;
            t.x = abs(t.x);
            t /= starsize;
            if(t.y < .381966 + t.x*.72654253)
                color = vec3(1.0);
        }
    } 
    c= vec3(color*shade);

        
    }
    
    return c;    
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    uv-=0.5;
    uv*=2.0;
    uv+=0.5;

    vec3 col = vec3(0.1, 0.4, 1.0);

    if (uv.y<cos(uv.x*3.0)/3.0) {col = vec3(0.0,.3,0);}
   
    float sv = sin(time*5.0-uv.x*20.0+uv.y*5.0);
    
    vec2 u = uv+vec2(0.0, sv/20.0*(uv.x-0.2));
    
    if (u.x>0.2&&u.x<0.5)
    {
        if (u.y<0.8&&u.y>0.5)
        {
            
            col = flag(u)*(1.8-max(0.9, sv/4.0+0.8));
        
        } 
    }
 
    if (abs(u.x-0.2)<.002&&uv.y<0.8) {col = vec3(min(.7/(abs(u.x-0.2)*700.0), 0.8));}

    if (uv.y<cos(uv.x*10.0)/10.0) col = vec3(0.0,.6,0);

    if (uv.y<sin(uv.x*5.0)/10.0) col = vec3(0.0,1,0);

    col*=1.27-length(uv-0.5);

    glFragColor = vec4(col,1.0);
}
