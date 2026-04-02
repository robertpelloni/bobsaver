#version 420

// original https://www.shadertoy.com/view/wllXWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PIXELSIZE 15.0
#define GRIDSIZE 5.0

vec3 gridColor = vec3(0.0, 0.0, 0.0);
vec3 color = vec3 ( 0.4, 0.4, 0.4);
float barrelContrast = 1.0;

void MakeGrid (vec2 uv)
{
    vec2 moduloXY = mod(uv.xy, PIXELSIZE);

    //grid mask
    if(moduloXY.x <GRIDSIZE || moduloXY.y<GRIDSIZE)
    {
    color.x= gridColor.x;
    color.y= gridColor.y;
    color.z= gridColor.z;
    }
}

vec2 BarrelDistortion (vec2 uv)
{
    //angle 
    float theta = atan(uv.y, uv.x);
    //ammount
    float anim_effect_1 = ((sin (time + 0.3))*0.005);
    float radius = length(uv) + anim_effect_1;
    //contrast
    radius = pow(radius, barrelContrast);
    
    uv.x = radius * cos(theta);
    uv.y = radius * sin(theta);
    color.r = 0.5 * (uv.y +1.0);
    color.b = radius;
    return 0.5 * (uv + 1.0);
}

void main(void) {
     
    //animation
    barrelContrast += (((sin(time) + cos(cos(time)))/2.0)-0.5);
    //screen coord
    vec2 normalizedUV = (gl_FragCoord.xy/(resolution.xy/2.0)) -1.0;
    vec2 distortedUV = BarrelDistortion(normalizedUV)* resolution.xy;
    MakeGrid(distortedUV.xy);
    
   
    glFragColor = vec4( color, 1.0);
}
