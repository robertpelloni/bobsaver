#version 420

// original https://www.shadertoy.com/view/wsVGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: Colormixing Metaballs
// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders" and inspiration 

// translate color from HSB space to RGB space
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float rand (vec2 st) {
    float f = fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
    return max(f,0.2);
}

vec3 random_color (vec2 p){
    return hsb2rgb(vec3(rand(p),0.6,1.0));
 // blood cells bellow
 // return hsb2rgb(vec3(0.02,clamp(rand(p),0.7,0.8),clamp(rand(p),0.4,1.0)));

}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

void main(void)
{
    vec2 st = gl_FragCoord.xy/resolution.xy;
    st -= 0.5;
    if (resolution.y > resolution.x ) 
        st.y *= resolution.y/resolution.x;
    else 
        st.x *= resolution.x/resolution.y;
   
    vec3 color = vec3(.0);

    // Scale
    float scale = sin(time*0.2)*2.0 + 5.0;
       st *= scale;

    //st += noise(st*.005*scale)*100.05/scale;
    //st += random2(st)*0.02;

    // Tile the space
    vec2 i_st = floor(st);
    vec2 f_st = fract(st);
    
    vec3 c = vec3(0.0);
    vec3 c1;

    float m_dist = 10.;  // minimun distance
    float meta_dist = 10.;  // minimun distance
    vec2 cl_point;
    vec2 cl_dist;

    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            // Neighbor place in the grid
            vec2 neighbor = vec2(float(x),float(y));
            
            // Random position from current + neighbor place in the grid
            vec2 point = random2(i_st + neighbor);

            // Animate the point
            point = 0.5 + 0.5*sin(time + 6.2831*point);

            // Vector between the pixel and the point
            vec2 diff = neighbor + point - f_st;

            // Distance to the point
            float dist = length(diff);
            
            if (m_dist>dist) {
                cl_point = neighbor +i_st;
                cl_dist = diff;
            }
            
            // mix color with neighbors
            c = mix (c,random_color(neighbor+i_st),1.0-smoothstep(.0,1.0,dist*0.90));

            // Keep the closer distance
            m_dist = min(m_dist, dist);
            meta_dist = min(meta_dist, meta_dist*dist*1.0);
            
        }
    }
    

    // Draw the min distance (distance field)
    // base color
    color = mix(random_color(cl_point),c,1.0);
    // inner borders of cells
    color -= smoothstep(-0.1,1.0,m_dist)*0.24;
    // borders of metaballs
    color = (color)*abs(1.0-smoothstep(0.7,1.0,meta_dist*0.4)*0.3-smoothstep(0.95,1.0,meta_dist*0.4));

    glFragColor = vec4(color,1.);
}
