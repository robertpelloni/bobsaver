#version 420

// original https://www.shadertoy.com/view/Wddyzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265359;

vec2 random2( vec2 p ) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float voronoi(vec2 i_st, vec2 f_st, float anim) {
    float m_dist = 1.;  // minimum distance
    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            // Neighbor place in the grid
            vec2 neighbor = vec2(float(x),float(y));

            // Random position from current + neighbor place in the grid
            vec2 point = random2(i_st + neighbor);

            // Animate the point
            point = 0.5 + 0.5*sin(anim + 6.2831*point);

            // Vector between the pixel and the point
            vec2 diff = neighbor + point - f_st;

            // Distance to the point
            float dist = length(diff);

            // Keep the closer distance
            m_dist = min(m_dist, dist);
        }
    }
    return m_dist;
}

float gain(float x, float k) 
{
    float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
    return (x<0.5)?a:1.0-a;
}

vec2 gain2(vec2 v, float k)
{
    return vec2(gain(v.x, k), gain(v.y, k));
}

float parabola( float x, float k )
{
    return pow( 4.0*x*(1.0-x), k );
}

vec2 parabola2( vec2 x, float k )
{
    return vec2(parabola(x.x, k), parabola(x.y, k));
}

float the_func(vec2 uv, float time)
{
    vec2 uv_i = floor(uv);
    vec2 uv_f = fract(uv);
    float gain_k = mix(0.2, 0.4, 0.5 * (1. - cos(time * 2.4 * (mod(uv_i.x, 4.) + 2.) + 3. * uv_i.y)));
    vec2 uv_sf = gain2(uv_f, gain_k);
    vec2 voro_uv = (uv_i + uv_sf) * 40.; // Voronoi subtiles
    voro_uv += (random2(uv_i + 0.3f) - .5) * time * 20.;
    float voro = voronoi(floor(voro_uv), fract(voro_uv), time);
    
    vec2 center = parabola2(uv_f, 0.4/gain_k);
    float val = voro * center.x * center.y;
    return val;
}

void main(void)
{
    float time = time;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv.x -= .5 * (resolution.x / resolution.y - 1.); // aspect
    
    uv *= 3.; // tiles
    uv += vec2(3. * time, 3. * time + .7 * sin(time * 3.)); // scrolling
    
    float k = 4.;
    float t = (1.1*time + sin(.1*time)) * 10.;
    float off_r = gain(clamp(abs(mod(1.1*time-1.5, 4.)-2.)-.5, 0., 1.), k);
    float off_g = gain(clamp(abs(mod(1.1*time+1.5, 4.)-2.)-.5, 0., 1.), k);
    
      float r = the_func(uv + vec2(0.01 * cos(off_g * PI), -fract(off_r+.5)+.5), time);
      float g = the_func(uv + vec2(-fract(off_g+.5)+.5, 0.01 * cos(off_r * PI)), time);
      float b = the_func(uv, time);
    vec3 col = vec3(0.);
    col = vec3(r, g, b);
    // col.xy = fract(voro_uv);
    //col.xy = random2(uv);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
