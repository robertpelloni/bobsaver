#version 420

// original https://www.shadertoy.com/view/sdcSDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

// Code modified from here:
// https://thebookofshaders.com/edit.php#09/marching_dots.frag
// https://www.osar.fr/notes/logspherical/

// used for generating random radii for each tile
float h21 (float a, float b, float zoom) {
    a = mod(a, zoom); b = mod(b, zoom);
    return fract(sin(dot(vec2(a, b), vec2(12.9898, 78.233)))*43758.5453123);
}

// Determines how tiles move
// (modified bookofshaders code, replaced if statements with step functions)
vec2 movingTiles(vec2 _st, float _zoom, float _speed){
    //_st.x = fract(2. * _st.x);
    //_st.y = fract(2. * _st.y);
    float time = time * _speed;
    
    // Change me for different patterns
    float ft = fract(2. * abs(_st.x - 0.5) + 2. * abs(_st.y - 0.5) + time);
    
    // e.g.
    // float ft = fract(2. * abs(_st.x) + 2. * abs(_st.y) + time);
    // float ft = fract(2. * max(abs(_st.x - 0.5), abs(_st.y - 0.5)) + time);
    // float ft = .5 + .5 * cos(length(_st-0.5) - 8. * time);
    
    _st *= _zoom;//sqrt(_zoom);
    
    float k = step(0.5, ft);
    _st.x +=      k * sign(fract(_st.y * 0.5) - 0.5) * ft * 2.;
    _st.y += (1.-k) * sign(fract(_st.x * 0.5) - 0.5) * ft * 2.;
    
    // Multiply _st here to get more than 1 shape per tile
    return fract(_st * 1.);
}

// Provides the shape in each tile
float circle(vec2 uv, float r){
    uv = uv - .5;
    return smoothstep(1.0-r, 1.0-r+r*0.2, 1.-dot(uv,uv)*3.14);
}

void main(void)
{
    vec2 st = gl_FragCoord.xy / resolution.xy;
    st.x *= resolution.x / resolution.y;
    
    float zoom = 16.;
    
    // Cut uv into smaller uvs
    vec2 uv = fract(vec2(st.x * zoom, st.y * zoom));
    vec2 ft = floor(st * zoom);
    
    // Generate values for each corner of uv, used for circle radii
    float l  = h21(ft.x+1.,  ft.y,      zoom);
    float t  = h21(ft.x,     ft.y + 1., zoom);
    float tl = h21(ft.x +1., ft.y+1.,   zoom);
    float id = h21(ft.x,     ft.y,      zoom);

    // Smooth the cut uvs so different uvs meet continuously on the edges
    uv = uv * uv * (3. - 2. * uv);
    
    // Box lerp between the corner values to get a radius value for this pixel
    float v = l * uv.x * (1.-uv.y)
             + t * (1.-uv.x) * uv.y
             + tl * uv.x * uv.y
              + id * (1.-uv.x) * (1.-uv.y);
        
    // Do the tile pattern
    st = movingTiles(st, zoom, 0.2);

    // Generate circle using radius we've obtained
    vec3 color = vec3( circle(st, 0.7 * v) - circle(st, 0.2 * v) );
    color += vec3(circle(st, 0.2 * v),circle(st, 0.18 * v),0.);
    
    //color += (0.3 + .7 * h21(-10.*ft.x,ft.y)) * vec3(st.xy,1.);
  
    glFragColor = vec4(color,1.0);
}
