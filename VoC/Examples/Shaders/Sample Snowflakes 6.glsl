#version 420

// original https://www.shadertoy.com/view/dtl3zj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))*43758.5453123);
}

void main(void)
{
    // Normalized pixel coordinates
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x/resolution.y;
    
    
    vec3 camera = vec3(.0,.0,-20.0);
    
    vec3 pointOnScreen = vec3( uv , 0.0);
    
    float t = 4.0;
    
    vec3 col = vec3(0.0);
    
    for(float i = 0.0 ; i < 250.0 ; i++)
    {
        float d = 10000.0;
        float originRad = 1000.0;
        float randx = -originRad/2.0 + random(vec2(i+1.0)) * originRad;
        float randy = -originRad/2.0 + random(vec2(i+2.0)) * originRad;
        float randz = random(vec2(i+3.0)) * 1000.0;
        float offsetTime = random(vec2(i)) * 4.0;

        float seedRandom = floor( ( time + offsetTime  ) / t);
        
        //float x = -25.0 + random( vec2(seedRandom) ) * 50.0;
        //float y = -75.0 + random( vec2(seedRandom) ) * 500.0;
        float z =  d - fract( ( time + offsetTime ) / t) * d;
        
        vec3 point = vec3(randx , randy , z + randz);
        float rotvel = 3.14;
        float rotamp = 30.0;
        point.x += cos((time+offsetTime)*rotvel) * rotamp;
        point.y += sin((time+offsetTime)*rotvel) * rotamp;
        float h =  length( cross(pointOnScreen - camera, point) ) / distance(camera , pointOnScreen);
        h = 1.0 - h/2.0;
        h = smoothstep( 0.0 , 0.5, h);
        col += vec3(h);
        
        
        

    }
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}
