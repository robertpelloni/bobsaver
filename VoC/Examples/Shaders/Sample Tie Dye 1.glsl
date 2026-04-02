#version 420

// Based on....
// Cellular Colorspiller Fun
// http://twitter.com/rianflo

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 nrand3( vec2 co )
{
    vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
    vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
    vec3 c = mix(a, b, 0.5);
    return c;
}

void main( void ) 
{
    vec2 Delta = vec2(1.0)/resolution;
    vec2 uv = gl_FragCoord.xy / resolution;
    
    //move uv towards center so it causes a zoom in effect
    //gl_fragcoord goes from 0,0 lower left to imagesizewidth,imagesizeheight at upper right
    float deltax = gl_FragCoord.x-resolution.x/2.0;
    float deltay = gl_FragCoord.y-resolution.y/2.0;
    //float angleradians = atan2(deltay,deltax) * 180.0/3.14159265;
    float angleradians = atan(deltay,deltax) * 90.0;
    //now walk the vector/angle between current pixel and center of screen to get pixel to average around
    float zoomrate=3.0;
    float newx = gl_FragCoord.x + cos(angleradians)*zoomrate;
    float newy = gl_FragCoord.y + sin(angleradians)*zoomrate;
    uv = vec2(newx,newy)/resolution;
    
    // current pixel and 8 neighbors
    vec4 L = texture2D(backbuffer, uv+vec2(-Delta.x, 0.0));
    vec4 R = texture2D(backbuffer, uv+vec2(Delta.x, 0.0));
    vec4 U = texture2D(backbuffer, uv+vec2(0.0, Delta.y));
    vec4 D = texture2D(backbuffer, uv+vec2(0.0, -Delta.y));
    vec4 UL = texture2D(backbuffer, uv+vec2(-Delta.x, Delta.y));
    vec4 UR = texture2D(backbuffer, uv+vec2(Delta.x, Delta.y));
    vec4 LL = texture2D(backbuffer, uv+vec2(-Delta.x, -Delta.y));
    vec4 LR = texture2D(backbuffer, uv+vec2(Delta.x, -Delta.y));
    vec4 C = texture2D(backbuffer, uv);
    
    vec4 val = vec4(0.0);
    
    if(length(mouse*resolution-gl_FragCoord.xy) < 35.)
    {
        val = vec4(nrand3(vec2(time,-time)), 1.0);
    } else {
        // PLAY WITH ME:
        // ====================================
        // vec4 s = (L*R+U+D+UL+UR+LL*LR+C);
        vec4 s = (L*R+U*D+UL+UR+LL+LR+C);
        // vec4 s = (L+R+U+D+UL+UR+LL+LR+C);
        // ====================================
        val = vec4(normalize(s.xyz), s.w / 9.0);
        val /= val.w;
    }
    
    glFragColor = vec4(val);
}
