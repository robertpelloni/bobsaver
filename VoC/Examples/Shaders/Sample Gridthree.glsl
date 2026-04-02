#version 420

// original https://www.shadertoy.com/view/3sGGzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

# define PI 3.141592653589793
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float r(vec2 uv, int f ){
    float k = 2.;
    float t = floor(time*.6);
    return rand( floor( uv * pow(k, float(f))));
}

vec3 colors[8] = vec3[]( 
    vec3( 1.0, 0.2, 0.0 ),
    vec3( 0.1, 0.2, 0.3 ),
    vec3( 0.1, 0.1, 0.0 ),
    vec3( 0.4, 0.9, 0.8 ),
    vec3( 1.0, 1.0, 0.9 ),
    vec3( 0.4, 0.2, 1.0 ),
    vec3( 0.6, 1.0, 0.9 ),
    vec3( 1.0, 0.1, 0.2 ));

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 u = uv*2.0;
    //u += mouse*resolution.xy.xy / resolution.xy * 10.0;
    u.y+=time*0.5;
    
    //if(mouse*resolution.xy.z > 0.0){
    // float angle = 0.0;
    // float rad = rand(u*1.5)*0.9;
    //  u.x += sin(angle)*rad;
    //    u.y += cos(angle)*rad;
    //}

    float s  = r(u, 3);
    float m = r(u, 2);
    float l   = r(u, 1);
    float xl = r(u, 0);
    float f1 = round( r(u + 33., 1));
    float f2 = round( r(u + 10., 2));
    float f3 = round( r(u + 64., 0));
    float g = mix(s, m, f2);
    g = mix(g, l, f1);
    g = mix(g, xl, f3);
  //  g = fract(g * uv.y );
   // float k = rand(u)*g*2.2;
    vec3 col = colors[int(g*8.)];
    glFragColor = vec4(col,1.);
}
