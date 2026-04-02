#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D bb;

out vec4 glFragColor;

float hash( float n ){
    return fract(sin(n)*758.5453);
}

float noise3d( in vec3 x ){
    vec3 p = floor(x);
    vec3 f = fract(x);
    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*157.0 + 113.0*p.z;

    return mix(mix(    mix( hash(n+0.0), hash(n+1.0),f.x),
            mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
           mix(    mix( hash(n+113.0), hash(n+114.0),f.x),
            mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}

vec2 mirrored_repeat(vec2 uv){
    uv.x += 1.0 * step(0.0, -uv.x);
    uv.y += 1.0 * step(0.0, -uv.y);
    uv.x -= 1.0 * step(1.0, uv.x);
    uv.y -= 1.0 * step(1.0, uv.y);
    return uv;
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );

    vec3 coord = vec3(position * 5.0, time);
    vec2 wind = vec2(noise3d(coord), noise3d(-coord.yxz)) * 2.0 - 1.0;
    vec2 pixel = 1.0 / resolution;
    wind *= 4.0;
    wind += vec2(0.0, -4.0);
    vec3 color = texture2D(bb, mirrored_repeat(position + pixel * wind * 2.0)).rgb;
    
    vec3 c = vec3(sin(time), cos(time), sin(time * 2.0 + 2.0)) * 0.5 + 0.5;
    color += vec3(c) * (1.0 - smoothstep(0.019, 0.021, distance(mouse, position)));
    color += c * 0.01 * smoothstep(0.2, 0.9, noise3d(vec3(position * 10.0, time)));
    glFragColor = vec4( color * 0.99, 1.0 );

}
