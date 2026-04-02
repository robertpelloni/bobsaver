#version 420

// original https://www.shadertoy.com/view/flSyDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define hue(v) ( .6 + .6 * cos( 2.*PI*(v) + vec3(0,-2.*PI/3.,2.*PI/3.) ) )
#define PI 3.14159265359
mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}
float getRect(in vec2 uv, in float size, in float innerSize)
{
    return (-1. * (sign(length(max(abs(uv)-vec2(size),0.0)))) + sign(length(max(abs(uv)-vec2(innerSize),0.0))));
}

float getErect(in vec2 uv, in float size, in float thickness)
{
    float p = getRect(uv, size, size - thickness);
    float s = size * 0.5;    
    float s2 = s - thickness;
    
    p += getRect(uv-size, s, s2);    
    p += getRect(uv+size, s, s2);
    p += getRect(uv+vec2(-size,size), s, s2);
    p += getRect(uv+vec2(size , -size), s, s2);
    return p;
    
}

float getCircle(in vec2 uv, in float size, in float thickness)
{
    return smoothstep(thickness, 0., abs(length(uv)-size));

}
float getECircle(in vec2 uv, in float size, in float thickness)
{
    float p = getCircle(uv, size, thickness);
    float s = size * 0.5;            
    p += getCircle(uv-size, s, thickness);    
    p += getCircle(uv+size, s, thickness);
    p += getCircle(uv+vec2(-size,size), s, thickness);
    p += getCircle(uv+vec2(size , -size), s, thickness);
    return p;
    
}
void main(void)
{
    
    float T = time;
    vec2 uv = (gl_FragCoord.xy -.5 * resolution.xy) /resolution.y;
    
    
    vec2 screenUV = uv;

    uv *= 8. + (2. * sin(T*0.1)); // zoom   
    uv *= Rot(length(screenUV )* .2); // twist
    uv *= Rot(T * -.05); // general rot
    uv *= pow(length(screenUV), -.2); // "fov"    
    
    vec2 ID = floor(uv);
    vec2 gv = fract(uv) -.5;    
    vec3 col = vec3(0);  
    
    
    if (mod(ID.x, 2.) == 0.)  // mirrors grid
        gv.x *= -1.;
    if (mod(ID.y, 2.) == 0.)
        gv.y *= -1.;
    
    
    // pattern
    float p = 0.; 
    float p2 =0.;
    float posSpeed = T * 0.5;
    vec2 posRot = vec2(cos(posSpeed + sin(posSpeed)), sin(posSpeed + cos(posSpeed*.5))); // center position of pattern
    vec2 pos = gv + (posRot * (0.6 + (0.3 * sin(T * .5))));
    mat2 RotMatrix = Rot(asin(sin(T * 0.2)));
    float thickness = 22. / resolution.y;
    for(float i=1.; i > 0.01; i *= .8 + (.1 * sin(T * .9)))
    {
        float scale = 0.75 * i;
        float darkness = pow(i, 2.);
        p += (getErect(pos, scale, thickness) * darkness);
        p2 += (getECircle(pos, scale, thickness) * darkness);
        pos *= RotMatrix;
    }
      
    p = mix(p, p2,0.6 * abs(asin(sin(T * .1))));
    vec3 pCol = (hue((p * .7) + (T * .1) + length(screenUV *.5)) *p);
    
    
    // background 
    uv *= 3.;
    uv *= Rot(T);    
    gv *= Rot(abs(dot(uv.x + uv.y * sin(T), length(gv))) + T);    
    float bg = pow(length(gv + 3. * .5) * .3, 4.);                    
    vec3 bgCol = hue(bg * 24.) *bg * .25; 
    float bgLum = (bgCol.r + bgCol.g + bgCol.b) / 3.;    
    bgCol = mix(bgCol, vec3(bgLum), 0.15);
      
      
      
    col +=  bgCol+ pCol;           
    glFragColor = vec4(col,1.0);
}
