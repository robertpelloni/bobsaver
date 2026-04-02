#version 420

// original https://www.shadertoy.com/view/XtB3DK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// UTILITIES --------------------------------------------------------
const float pi2 = 3.14159 * 2.;

vec2 getuv_centerX(vec2 Coord, vec2 newTL, vec2 newSize)
{
    vec2 ret = vec2(Coord.x / resolution.x, (resolution.y - Coord.y) / resolution.y);// ret is now 0-1 in both dimensions
    ret *= newSize;// scale up to new dimensions
    float aspect = resolution.x / resolution.y;
    ret.x *= aspect;// orig aspect ratio
    float newWidth = newSize.x * aspect;
    return ret + vec2(newTL.x - (newWidth - newSize.x) / 2.0, newTL.y);
}

vec4 mixColors(vec4 inp, vec4 other, float a)
{
    return vec4(mix(inp.rgb, other.rgb, other.a * a), inp.a);
}

float nsin(float a)// 0-1 sin
{
    return (sin(a)+1.)/2.;
}
float saturate(float a)
{
    return clamp(a,0.,1.);
}

// convert distance to alpha value
float dtoa(float d, float amt)
{
    return clamp(1.0 / (clamp(d, 1.0/amt, 1.0)*amt), 0.,1.);
}

//--------------------------------------------------------
// this function returns the "distance" to the interference pattern.
float xorCircles_d(vec2 uv, vec2 p1, float p1period, vec2 p2, float p2period)
{
    float d1 = sin(distance(uv, p1) / p1period * pi2);
    float d2 = sin(distance(uv, p2) / p2period * pi2);
    return d1 * d2;
}

void main(void)
{
    // adjust global speed, and start at a nice offset to make the thumbnail look nice :P
    float time = (time + 47.) * 0.8;
    
    vec2 uv = getuv_centerX(gl_FragCoord.xy, vec2(-1.), vec2(2.));
    glFragColor = vec4(0.89,0.97,0.99,1.);// background
    
    // define positions & periods of the circles
    vec2 p1 = vec2(sin(time * 1.7), sin(time * 0.55));
    float p1period = (nsin(time * 1.8) / 3.) + 0.3;
    
    vec2 p2 = vec2(sin(time * .77), sin(time * 1.64));
    float p2period = (nsin(time * 4.1) / 4.) + 0.3;

    // distance to pattern
    float d = xorCircles_d(uv, p1, p1period, p2, p2period);
    
    // generate a cool fill pattern by using the distance more
    float fillA = nsin(d * d * 15.);
    vec4 patternColor = vec4(.99,.7,.22,1.);
    patternColor = mix(patternColor, vec4(.2,.7,.9,1.), saturate(d * d) * fillA);
    
    glFragColor = mixColors(glFragColor, patternColor, dtoa(d, 20.));
    
    // add a little vignette
    glFragColor.rgb *= saturate(1.3 / length(uv));

}

