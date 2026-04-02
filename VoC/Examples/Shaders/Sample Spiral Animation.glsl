#version 420

// original https://www.shadertoy.com/view/sllyR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float thickness = 0.05;
float width = 1.0;
float speed = 1.0;

float horizontalTranslate =  0.0;
float verticalTranslate = 0.0;

vec3 c1 = vec3 (58.0/256.0, 56.0/256.0, 69.0/256.0);
vec3 c2 = vec3 (247.0/256.0, 204.0/256.0, 172.0/256.0);

// anti aliasing:
// multi-sampled anti-aliasing
// stratified sampling
// play with color
// export

float v1_length = 1.0;
float v2_length = 2.0;

float two_pi = 6.283185307;

// draw line segment from A to B
float segment(vec2 P, vec2 A, vec2 B, float r) 
{
    vec2 g = B - A;
    vec2 h = P - A;
    float d = length(h - g * clamp(dot(g, h) / dot(g,g), 0.0, 1.0));
    return smoothstep(r, 0.5*r, d);
}

float line(vec2 P, vec2 A, vec2 B, float r)
{
    vec2 g = B - A;
    float d = abs(dot(normalize(vec2(g.y, -g.x)), P - A));
    return smoothstep(r, 0.5*r, d);
}

vec2 inverse_mobius(vec2 cur_uv)
{
    float cur_x = cur_uv.x;
    float cur_y = cur_uv.y;
    float cur_x2 = cur_x * cur_x;
    float cur_y2 = cur_y * cur_y;
    float divisor = (1.0 + cur_x) * (1.0 + cur_x) + cur_y2;
    vec2 result;
    result.x = (cur_x + cur_x2 + cur_y2) / divisor;
    result.y = (cur_y) / divisor;
    return result;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy + vec2(-0.55,-0.5);
    uv.x *= resolution.x/resolution.y;
    uv *= 3.0;
    
    //Inverse Mobius (take f(z) = z / (1 - z) here)
    uv = inverse_mobius(uv);
    
    //Convert to spiral
    float py = atan( uv.y, uv.x );
    float px = log( length( uv ) );
    uv = vec2( px, py );
    
    //Set animation
    uv += time * vec2(1,1);
    
    vec3 color = c1;
    
    vec2 vec_sum = vec2(v1_length, v2_length);
    
    //Set scale
    float scale = (length(vec_sum) / two_pi);
    uv *= scale;
    
    //Set rotation
    float rotation = acos(dot(vec2(0.0, 1.0), vec_sum) / length(vec_sum));
    uv *= mat2(cos(rotation), sin(rotation), -sin(rotation), cos(rotation));
    
    // Draw the vector sum
    //float intensity = segment(uv, vec2(0.0), vec_sum, thickness);
    //color = mix(color, vec3(0.0), intensity);
    
    //Draw Vertical lines    
    float cx = mod(uv.x, width) / width;
    
    if (cx < 0.5) {
        color = mix(c1, c2, cx * 3.0);
    }
    else {
        color = mix(c2, c1, (cx - 0.5) * 3.0);
    }
    
    //color = mix( color, c2, smoothstep( cx, 0.5, 0.1 ) );
    
    glFragColor = vec4(color,1.0);
}
