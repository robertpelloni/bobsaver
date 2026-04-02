#version 420

// original https://www.shadertoy.com/view/7dKBRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926538

//// Comparison functions
float gt(float v1, float v2)
{
    return step(v2,v1);
}

float lt(float v1, float v2)
{
    return step(v1, v2);
}

float s_lt(float v1, float v2, float e)
{
    return smoothstep(v1-e, v1+e, v2);
}

//// Shapes functions
float circle_df(vec2 xy, vec2 pos)
{
    float d = distance(xy, pos);
    //float d = dot(xy-pos, xy-pos)*2.; // Cheaper distance function but will require more epsilon if using with smoothstep
    return d;
}

float s_circle(vec2 xy, vec2 pos, float r, float e)
{
    float d = circle_df(xy, pos);
    return s_lt(d, r, e);
}

float rectangle_df(vec2 p, float w, float h)
{
    vec2 b = vec2(w, h);
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float s_rectangle(vec2 xy, vec2 pos, float w, float h, float roundness, float e) // roundness == 0 means no roundess, roundness == 1 means full roundess
{
    h = h/2.;
    w = w/2.;
    float r = clamp(roundness, 0., 1.)*w;
    float d = rectangle_df(xy-pos, w-r, h-r);
    return s_lt(d, r, e);
}

float triangle_df(vec2 xy, vec2 pos, float l)
{
    vec2 p = (xy-pos)/l;
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    return -length(p)*sign(p.y);
}

float s_triangle(vec2 xy, vec2 pos, float l, float roundness, float e) // roundness == 0 means no roundess, roundness == 1 means full roundess
{
    float r = clamp(roundness, 0., 1.)*l;
    float d = triangle_df(xy, pos, l);
    return clamp(s_lt(d, r, e*2.)*2., 0., 1.);
}

//// Rotation function
vec2 rotate(vec2 vec, float a)
{
    return vec2(vec.x*cos(a)-vec.y*sin(a), vec.x*sin(a)+vec.y*cos(a));
}

void main(void)
{
    // Getting values
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    
    // Setting up view port
    float zoom = 10.;
    vec2 zoomCenter = vec2(0., 0.);
    float viewPortCenter = 0.5;
    float ratio = resolution.y/resolution.x;
    
    // Establishing screen xy values
    vec2 xy = (uv - viewPortCenter) * zoom + zoomCenter;
    xy = vec2(xy.x, xy.y*ratio);
    
    // Establishing mouse xy values
    mouse = (mouse - viewPortCenter) * zoom + zoomCenter;
    mouse.y *= ratio;
    
    // Width of a single pixel 
    float pixel = zoom / resolution.x;
    vec3 col = vec3(0.);
    
    // Creating the mod repitition
    xy = rotate(xy, PI/4.);
    
    float rep = 0.5;
    float time2 = time*3.;
    xy.x += gt(mod(xy.y+rep, 2.), 1.)*lt(mod(time2, 2.), 1.)*time2;
    xy.y += gt(mod(xy.x+rep, 2.), 1.)*gt(mod(time2, 2.), 1.)*time2;
    xy = mod(xy+rep, rep*2.)-rep;
    
    xy = rotate(xy, time*2.);
    
    // Crust
    float crust = s_rectangle(xy, vec2(0, -0.25), 0.75, 0.25, 0.3, pixel);
    col.r += crust;
    col.g += crust/2.;
    
    // Bread
    float bread = s_triangle(xy, vec2(0), .25, 0.5, pixel*2.);
    col.rgb -= bread;
    col.rg += bread*2.;
    
    // Toppings
    float toppings = s_circle(  mod(xy+vec2(0.01,0.1), 0.3)  , vec2(0.1), 0.1, pixel)*bread;
    col.rgb -= toppings;
    col.r += toppings;

    glFragColor = vec4(col,1);
}
