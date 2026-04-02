#version 420

// original https://www.shadertoy.com/view/3tKcW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI2 6.28

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float DrawShape(vec2 uv, float offset){

   float freq = 5. * pow(uv.y,2.);
   float mag = 0.25;
   float noise = (sin(((-time*4.* (uv.y))+(uv.y*(abs(uv.x))*5.))+offset+(PI2 * (uv.y /2.) * freq) )) * mag;
   noise *= pow(  smoothstep( 0.,1.0, (uv.y/uv.y ))    ,2.);
   noise *= smoothstep(.02,1., uv.y);
   
  
  
   float d = sdSegment(uv, vec2(.5 + noise,0.), vec2(.5 + noise,1.));
   return 1.-step(.02,d);
}

void main(void)
{
    vec2 uv = ( gl_FragCoord.xy -.5*resolution.xy ) /resolution.y;
    uv.x += 0.5; 
    uv.y += 0.5;
    float mask = uv.x < 0. ? 0. : (uv.x > 1. ? 0. : 1.);
    
    vec3 col1 = vec3(0.074, 0.133, 0.149);
    vec3 col2 = vec3(0.321, 0.356, 0.337);
    vec3 col3 = vec3(0.192, 0.250, 0.270);
    vec3 col4 = vec3(0.643, 0.592, 0.556);
    vec3 col5 = vec3(0.811, 0.701, 0.627);
    vec3 col6 = vec3(0.470, 0.423, 0.392);

    vec3 col = vec3(0.015, 0.047, 0.054); //Background 
    col = mix(col, col1, DrawShape( uv- vec2(.1,0), 0.) );
    col = mix(col, col4,DrawShape( uv- vec2(.1,0), 3.0));
    col = mix(col, col2, DrawShape( uv- vec2(.2,0), 6.0));
    col = mix(col, col3, DrawShape( uv- vec2(-.2,0), 8.0));
    col = mix(col, col5, DrawShape( uv- vec2(-.1,0), -1.0));
    col = mix(col, col6, DrawShape( uv- vec2(-.2,0), -8.0));
    
    float fade = 1.-smoothstep(.8,1.,uv.y);
    col*= fade;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
