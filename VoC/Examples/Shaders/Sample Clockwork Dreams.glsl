#version 420

// original https://www.shadertoy.com/view/3d3GRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float GRID_SIZE = 5.;
const float GEAR_TOOTHS = 8.;
const float GEAR_DEPTH = 0.125;
const float GEAR_RADIUS = 0.49;

const float TWO_PI = 6.283;
const float PI = 3.145;
const float HALF_PI = 0.5 * PI;

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec2 rotate(vec2 uv, vec2 center, float theta)
{
    float c = cos(theta);
    float s = sin(theta);
   
    uv -= center;
    uv *= mat2(c, -s, s, c); 
 
    return uv + center;
}

vec3 gear(vec2 uv, vec2 gearPos, 
           float tooths,
           float speed)
{
    vec2 delta = uv - gearPos;

    float d = length(delta); 
    float angle = speed * time + atan(delta.y, delta.x);
    float toothMul = floor(mod(.5 * tooths * angle, PI) / HALF_PI);
    float radius = .5 * tooths;
    float inside = min(1., .5 * d / radius);
    float shine = radius / (d - .1*radius);
    inside = smoothstep(.2449, 0.25, inside);
    
    float gearDepth = 1.5 / tooths;
    
    radius *= (1. - .5*gearDepth) + 
        (gearDepth * toothMul);
       
    float g = smoothstep(radius, radius - 0.0001, d);
    
    
    return (.5 + .5*shine)* g * vec3(inside, inside, inside);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy) / resolution.y;
    
 
    vec3 col = vec3(0.);
    float direction = 1.;
    float count = 50.;
    float scaleFactor = .9;
    
    
    float speed = -6.;
    float timeScale = (.5+.5*sin(.5*time));
    float rotFactor = .2 + .1 * (1. + cos(.14*time + 10.));
    
    
    
    float uvScale = 2048. * timeScale;
    
    uv *= 32. + uvScale;
    
    

    for (float i = 0.; i < count; i++)
    {
        float scale = (1. + 0.1 * i);
        
        vec3 thisCol = vec3(0.);
        
        
        thisCol = gear(uv, vec2(0., 0.), 16., speed * direction * 1.);
        thisCol += gear(uv, vec2(12., 0.), 8., speed * direction * -2.);
        
        
        thisCol *= .15 + .7 * vec3(mod(i, 2.) / 2., mod(i, 3.) / 3., mod(i, 4.) / 4.);

        uv = rotate(uv, vec2(0.), rotFactor * PI);
        uv *= scaleFactor;
        uv += vec2(12.,0);
        
        col += .75 * (1. - (i/count)) * thisCol;
        direction = -direction;
        speed *= scaleFactor;
    }
       
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
