#version 420

// original https://www.shadertoy.com/view/wdVGRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 colFromFloat(float f)
{
    vec3 col = vec3(0.);
    
    col.x = sin(f*5. + 0.5);
    col.y = sin(f*5.);
    col.z = sin(f*5. - 0.5);
    
    return col*col/distance(vec3(0.), col) * f * 2.;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - resolution.xy*0.5)/resolution.y * 2.5; 

    // Time varying pixel color
    vec3 col = vec3(0.);
    
    col = vec3(0.);
    
    vec2 c = vec2(sin(time/10.), cos(time/10.)) * sin(time / 50.);
    vec2 z = uv;
    
    float l;
    
    for (float i = 0.; i < 200.; i++)
    {
        z = vec2(z.x*z.x + c.x - z.y*z.y, 2.*z.x*z.y + c.y);
        
        if (z.x*z.x + z.y*z.y > 5.) {
            l = i / 50.;
            break;
        }
    }
        
      
    col = colFromFloat(l);
    

    // Output to screen
    glFragColor = vec4(col, 1.0);
}
