#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.1415926535

vec2 cartesian(){
    vec2 p = 2.0*( gl_FragCoord.xy / resolution.xy )-1.0;
    p.x *= resolution.x / resolution.y;
    return p;
}

vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0, 
                     0.0, 
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main( void ) {
    vec2 p = cartesian();
    
    float ang = atan(p.y,p.x);
    float dist = length(p);
    ang += log(dist)+time; //spiral and animation
    ang += cos(dist);
    ang = mod(ang, PI/3.0);
    
    float ang2 = ang+PI*2.0; //change the multiplier
    
    vec3 col = hsb2rgb(vec3(ang, 1.0, 1.0));
    vec3 col2 = hsb2rgb(vec3(ang2, 1.0, 1.0));
    col = mix(col, col2, dist);
    
    glFragColor = vec4(col, 1.0);
    
    
    
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    vec4 me = texture2D(backbuffer, position);
    float rnd1 = mod(fract(sin(dot(position + time * 0.001, vec2(14.9898,78.233))) * 43758.5453), 1.0);
    float rnd2 = mod(fract(sin(dot(position + time * 0.001, vec2(24.9898,44.233))) * 27458.5453), 1.0);
    float nudgex = 20.0 * cos(time * 0.03775);
    float nudgey = 20.0 * cos(time * 0.02246);
    float ratex = -0.005 + 0.02 * (0.5 + 0.5 * normalize(nudgex * position.y + time * 0.137));
    float ratey = -0.005 + 0.02 * (0.5 + 0.5 * normalize(nudgey * position.x + time * 0.262));
    
    
    vec4 new = vec4(col, 1.0);
    
    if (dist > mouse.x) {
        float multx = 1.0 - ratex;
        float multy = 1.0 - ratey;
        float jitterx = 1.1 / resolution.x;
        float jittery = 1.1 / resolution.y;
        float offsetx = (ratex - jitterx) * 0.5;
        float offsety = (ratey - jittery) * 0.5;
        vec4 source = texture2D(backbuffer, vec2(position.x * multx + offsetx + jitterx * rnd1 , position.y * multy + offsety + jittery * rnd2));
        new.r = source.r;
        new.g = source.g;
        new.b = source.b;
    }
    
    float mx = 253.0/255.0;
    new.rgb = new.rgb*mx + me.rgb * (1.0-mx);
    glFragColor = new;
}
