#version 420

// original https://www.shadertoy.com/view/WtKcW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// adapted from an old Pixel Bender pbk i had lying around...
vec3 xAxisColor = vec3(1,.3,.4);
vec3 yAxisColor = vec3(.3, .8,.4);
vec3 zAxisColor = vec3(.1,.3,1);
vec3 edgeColor = vec3(.1,.3,1);
    
 float edgeThickness = 0.05;     
float invert = 1.0;    
vec2 dstsize = vec2(300.0, 300.0);
vec3 spin = vec3(.1,.02,.3);

float plunge = -0.0;

float cellDensity = 3.0;
float radius = 0.5;

// evaluatePixel(): The function of the filter that actually does the 
//                  processing of the image.  This function is called once 
//                  for each pixel of the output image.
vec4
evaluatePixel()
{
    spin.x = time / 5.123;
    spin.y = time / 117.2;
    cellDensity = 8.0 + sin(time / 14.4) * 7.0;
    dstsize = resolution.xy;
    vec3 axis1 = vec3(1.0,0.0,0.0);
    vec3 axis2 = vec3(0.0,1.0,0.0);

    mat3 elevR = mat3(1,0,0,0,cos(spin.x),sin(spin.x),0,-sin(spin.x),cos(spin.x));
    mat3 bearR = mat3(cos(spin.y), sin(spin.y), 0,-sin(spin.y), cos(spin.y), 0, 0, 0, 1 );
    mat3 yamR = mat3(cos(spin.z),0,sin(spin.z),0,1,0,-sin(spin.z),0,cos(spin.z));

    axis1 *= elevR * bearR * yamR;
    axis2 *= elevR * bearR * yamR;

    float cellDensity2 = cellDensity / 2000.0;
    vec2 oc = (gl_FragCoord.xy - dstsize / 2.0) * cellDensity2;

    //oc -= outSize/2.0;
    vec3 p = oc.x * axis1 + oc.y * axis2;

    vec3 perp = cross(axis1,axis2);

    float radiusInPixels = radius *  dstsize.x;
    float plungeMore = radiusInPixels * radiusInPixels * cellDensity2 * cellDensity2 - oc.x * oc.x - oc.y * oc.y;
    if(plungeMore < 0.0)
        plungeMore = 0.0;
    plungeMore = sqrt(plungeMore);

    // Strangely, PBT and Flash have opposite senses here.
    // Some sort of arithmetic bug, probably, making them
    // behave differently.
    if(invert > 0.0)
        plungeMore = -plungeMore;

    p += (plunge - plungeMore) * perp;

    vec3 pCell = floor(p);

    p = mod(p,1.0);

    /*
    Our cell size, here, is 1x1x1. Perp is a unit vector representing
    the direction we're now looking, the ray cast if you will. We like
    to cast to the planes x=0, y=0, z=0, because it's easy. So first
    we'll see if each element of perp is negative, and, if so, flip
    it and reposition our starting point, like p.x := 1-p.x.
    */

    /* this is the cleanest way, but Flash doesn't allow bools,
       and ?: doesn't seem to work in this mixed-dimension way
       either

    bool3 perpNeg = lessThan(perp,vec3(0,0,0));
    p = perpNeg ? 1.0 - p : p;
    perp = abs(perp);
    */

    /* We can be clever with step and abs, though. */
    vec3 perpStep = 1.0 - step(0.0,perp);
    p = perpStep - p;
    p = abs(p);
    perp = abs(perp);

    vec3 t = p / perp; // casts from p, in direction of perp, to zero. T is how far to each plane (x,y, or z)
    vec3 co = vec3(0,0,0);
    float z;

    if(t.x >= 0.0)
    {
        co = xAxisColor;
        z = t.x;
    }
    if(t.y >= 0.0 && t.y < t.x)
    {
        co = yAxisColor;
        z = t.y;
    }
    if(t.z >= 0.0 && t.z < t.x && t.z < t.y)
    {
        co = zAxisColor;
        z = t.z;
    }

    vec4 dst;
    dst.rgb = co * (1.0 - z/1.2);
    dst.a = 1.0;

    if(t.x < edgeThickness || t.y < edgeThickness || t.z < edgeThickness)
        dst.rgb = edgeColor;

    if(plungeMore == 0.0)
        dst.xyz *= 0.0;
    return dst;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    glFragColor = vec4(col,1.0);
    
    glFragColor = evaluatePixel();
}
