#version 420

// original https://www.shadertoy.com/view/WlfXRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

// 2D Random
float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

/*void main() {
    vec2 st = gl_FragCoord.xy/u_resolution.xy;

    // Scale the coordinate system to see
    // some noise in action
    vec2 pos = vec2(st*5.0);

    // Use the noise function
    float n = noise(pos);

    glFragColor = vec4(vec3(n), 1.0);
}
*/

/*vec2 rotate2D(vec2 _st, float _angle){
    _st -= 0.5;
    mat2 rot = rotateMatrix2D(_angle);
    _st =  rot * _st;
    _st += 0.5;
    return _st;
}
*/

vec2 rotate2d (vec2 _st, float _angle) {
    _st -= 0.5;
    _st =  mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle)) * _st;
    _st += 0.5;
    return _st;
}
    

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    vec2 pos = vec2(uv*5.0+time/0.50);
    
    
    
    pos.x = uv.x*5.0+time/0.50;
    pos.y = uv.y+time/1.50;

    
    
    pos = rotate2d( vec2(noise(pos)),30.0 ) * pos; // rotate the space
    //pattern = lines(pos,.5); // draw lines
    
    
    
    // Use the noise function
    float n = noise(pos);

    //glFragColor = vec4(vec3(n), 1.0);
    
    
    
    // Output to screen
    //glFragColor = vec4(col,1.0);
    //glFragColor = vec4(vec3(n)-col,1.0);
    glFragColor = vec4(vec3(n*col),1.0);
}
