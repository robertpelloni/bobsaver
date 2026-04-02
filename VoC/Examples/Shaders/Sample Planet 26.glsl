#version 420

// original https://www.shadertoy.com/view/wlGfDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (vec2 uv)
{
    return fract(sin(dot(uv,vec2(12.9898,78.233)))*43758.5453123);
}

float step(float x, float start, float stop, float max, float min)
{
    if (start == stop) return max;
    if (x >= stop) return max;
    else if (x <= start) return min;
    else {
        return (x - start)/(stop - start) * (max - min) + min;
    }
}

void main(void)

{
    vec2 center = resolution.xy/2.;
    float radius = resolution.x/5.;
    float distance = distance(gl_FragCoord.xy, center);
    
    float speed_scale = (radius - abs(gl_FragCoord.xy.y - center.y)/5.)/radius;
    
    vec3 atmosphereColor = vec3(.7, .6, .5);

    // blend two colors
    
    if (distance < radius){
    vec3 color1 = vec3(201.,144.,57.)/255.;
    vec3 color2 = vec3(227.,220.,203.)/255.;
    
    float speed = .9;
    float scale = .05;
    vec2 p = gl_FragCoord.xy * scale;
    p.x = (p.x / resolution.x) * 1000.;
    p.y = (1.5-p.y / resolution.y) * 2300.;
    
    for(int i=1; i<5; i++)
    {
        float x_cycle = (1. * float(i) * p.y + time * speed);
        p.x += 0.3 * sin(x_cycle) + 0.3 * sin(x_cycle/2.) + 0.5 * sin(x_cycle/4.) + 9. * sin(x_cycle/8.);
        float y_cycle = .8 * float(i) * p.x + time * speed;
        p.y += 0.3 * cos(y_cycle) + 0.3 * cos(y_cycle/2.) + 0.3 * cos(y_cycle/4.) + .5 * cos(y_cycle/8.);
    }
    
    p.y += speed_scale * .01 * time;
    

    float mask1 = 0.5 * sin(p.y/2.) + 0.5* sin(p.y/1.8 + 2.5);
    float mask2 = 1. - mask1;
    
    vec3 color = color1 * mask2 + color2 * mask1;
        
    // calculate day and night lighting
    float sphere_y = abs(gl_FragCoord.xy.y - center.y);
    float lat = sqrt(radius*radius - sphere_y*sphere_y);
    float light_mask_x = step(gl_FragCoord.xy.x, center.x-lat, center.x+lat, .8 * cos(time/2.) + .1, .8 * sin(time/2.) + .1);
    float light_mask_y = step(abs(gl_FragCoord.xy.y - center.y), 0., radius, 0.7, .9);
    
    
    float atmosphere_mask = step(gl_FragCoord.xy.x, center.x + lat/1.5, center.x+lat, 0.7, .1) + step(gl_FragCoord.xy.x, center.x - lat, center.x-lat/1.5, 0.1, 0.7);
    color = mix(color, atmosphereColor, atmosphere_mask);

    color *= light_mask_x * light_mask_y;
    
    glFragColor = vec4(color, 1.0);}
    
    
    else if(distance < (radius + 30. ))
    {
        float scale = pow(-distance + radius + 50.,2.)/5000.;
        atmosphereColor *= scale;
        glFragColor = vec4(atmosphereColor,0.0);
    }
    else {
        
        glFragColor = vec4(0.0, 0.0, 0.0,1.0);
    }
}
