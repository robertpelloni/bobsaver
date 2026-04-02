#version 420

// original https://www.shadertoy.com/view/NltGzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // normalize position
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/min(resolution.y,resolution.x);
    
    // interesting points
    //float x0 = 0.42884;
    //float y0 = -0.231345;
    float x0 = -0.761574;
    float y0 = -0.0847596;
    
    uv /= 1.0 * exp(6.0 * (1.0 + sin((time + 23.5)/ 5.0)));
    uv = vec2((uv.x + x0), (uv.y + y0) );
    
    // mandelbrot algo
    int max_it = 300;
    vec2 z = vec2(0.0, 0.0);
    int cnt = 0;
    for (int i = 0; i < max_it && dot (z,z) < 4.0; i++)
    {
        float x = z.x * z.x - z.y * z.y + uv.x;
        z.y = 2.0 * z.x * z.y + uv.y;
        z.x = x;
        cnt += 1;
    }
    
    // set the default funky colors and obscure them
    // using madelbrot result depending on how quickly
    // they exploded (if)
    vec3 col;
    col = 0.75 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
     if (cnt < max_it - 1) 
    { 
        col  *= (float(cnt) / (float(max_it) - 1.0));
    }
    
    glFragColor = vec4(col,1.0);
}
