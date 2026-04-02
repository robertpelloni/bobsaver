#version 420

// original https://www.shadertoy.com/view/ldXcDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 colorMap( in float c )
{
    return vec4(c, c, c, 1);
    
    float d = 7.0;
    float i = 1.0;
    if (c > (i-1.0)/d && c < i/d) return vec4(c, 0, 0, 1); i++;
    if (c > (i-1.0)/d && c < i/d) return vec4(0, c, 0, 1); i++;
    if (c > (i-1.0)/d && c < i/d) return vec4(0, 0, c, 1); i++;
    if (c > (i-1.0)/d && c < i/d) return vec4(c, c, 0, 1); i++;
    if (c > (i-1.0)/d && c < i/d) return vec4(0, c, c, 1); i++;
    if (c > (i-1.0)/d && c < i/d) return vec4(c, 0, c, 1); i++;
    if (c > (i-1.0)/d && c < i/d) return vec4(c, c, c, 1); i++;
}

vec2 cpow( in vec2 z, in float n)
{
    //float r = pow(z.x, n);
    //float x = r*cos(n*z.y);
    //float y = r*sin(n*z.y);
    float x = z.x*z.x - z.y*z.y;
    float y = z.x*z.y + z.y*z.x;
    return vec2(x, y);
    
}

vec2 mandelbrot( in vec2 z, in vec2 c )
{
    return cpow(z, 2.0) + c;
}

int mandelbrotIterate( in vec2 c, in int iterations )
{
    vec2 z = c;
    //int iterations = int(abs(sin(time)*30.0));
    int i = 0;
    for (; i < iterations; i++) {
        z = mandelbrot(z, c);
        if (length(z) > 2.0)
            break;
    }
    return i;
}

float zoom = -0.9;
float speed = 0.3;
vec2 center = vec2(-0.761574,-0.0847596);

vec2 toComplexCoords()
{
    // Get integer version of coords and resolution
    vec2 xy = vec2(int(gl_FragCoord.x), int(gl_FragCoord.y));
    vec2 wh = vec2(int(resolution.x), int(resolution.y));
    vec2 ar = vec2(wh.x/wh.y, 1.0);
    
    // Transformations
    xy -= wh*0.5;        // Center as origin
    xy /= wh;            // To homogeneous coords
    xy *= ar;            // Fix aspect ratio
    xy /= zoom;
    xy += center;
    return xy;
}

void main(void)
{
    zoom += exp(time * speed);
    
    vec2 click = mouse*resolution.xy.xy;
    click = toComplexCoords();
    //center -= click * zoom;
    //center = vec2(0.26, 0);
    vec2 xy = toComplexCoords();
    
    // Calculate color
    float levels = 255.0;
    int m = mandelbrotIterate(xy, int(levels));
    float c = (float(m))/float(levels);
    
    glFragColor = 1.0-colorMap(c);
}
